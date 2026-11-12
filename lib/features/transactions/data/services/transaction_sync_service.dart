import 'dart:async';
import 'dart:convert';
import 'dart:io' as io if (dart.library.html) 'package:catat_uang/core/platform/io_stub.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/supabase_service.dart';
import '../mappers/transaction_mapper.dart';

class TransactionSyncService {
  TransactionSyncService(
    this._database,
    this._supabaseService, {
    Connectivity? connectivity,
    this.pollInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : _connectivity = connectivity ?? Connectivity(),
        _clock = clock ?? DateTime.now {
    _initialize();
  }

  static const _table = 'transactions';
  static const _bucket = 'transaction-attachments';
  static const _maxBackoff = Duration(hours: 6);

  final AppDatabase _database;
  final SupabaseService _supabaseService;
  final Connectivity _connectivity;
  final Duration pollInterval;
  final DateTime Function() _clock;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _pollTimer;
  Timer? _retryTimer;
  DateTime? _retryAt;
  bool _isSyncing = false;
  bool _syncAgain = false;
  bool _isDisposed = false;

  void _initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          requestSyncForCurrentUser();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _scheduleRetry();
      },
    );
    _pollTimer = Timer.periodic(pollInterval, (_) {
      requestSyncForCurrentUser();
    });
    unawaited(_recoverAndSync());
  }

  void requestSync(String userId) {
    if (_isDisposed) return;
    if (_isSyncing) {
      _syncAgain = true;
      return;
    }
    unawaited(syncPending(userId));
  }

  void requestSyncForCurrentUser() {
    unawaited(_requestSyncForCurrentBusiness());
  }

  Future<void> _requestSyncForCurrentBusiness() async {
    final client = _supabaseService.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      final response = await client.rpc('get_my_business_access');
      final access = Map<String, dynamic>.from(
        (response as Map).cast<String, dynamic>(),
      );
      final businessId = access['business_id'] as String;
      if (businessId != userId) {
        requestSync(userId);
        return;
      }
      await _database.writePreference(
        'business-access:$userId',
        jsonEncode(access),
      );
      requestSync(businessId);
    } on Object {
      final cached = await _database.readPreference('business-access:$userId');
      if (cached == null) {
        requestSync(userId);
        return;
      }
      try {
        final access = Map<String, dynamic>.from(
          (jsonDecode(cached) as Map).cast<String, dynamic>(),
        );
        final businessId = access['business_id'] as String? ?? userId;
        requestSync(businessId == userId ? businessId : userId);
      } on Object {
        requestSync(userId);
      }
    }
  }

  Future<void> _recoverAndSync() async {
    try {
      await _database.recoverInterruptedSyncs();
      requestSyncForCurrentUser();
    } on Object {
      _scheduleRetry();
    }
  }

  Future<void> syncPending(String userId) async {
    if (_isDisposed) return;
    if (_isSyncing) {
      _syncAgain = true;
      return;
    }
    _isSyncing = true;
    try {
      do {
        _syncAgain = false;
        await _syncPass(userId);
      } while (_syncAgain && !_isDisposed);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPass(String userId) async {
    final client = _supabaseService.client;
    if (!_supabaseService.isConfigured ||
        client == null ||
        client.auth.currentUser == null) {
      return;
    }
    if (!await _isEndpointReachable(client, userId)) {
      _scheduleRetry();
      return;
    }

    final pending = await _database.getDueOutboxEntries(userId, now: _clock());
    for (final outbox in pending) {
      if (_isDisposed) return;
      final local = await _database.getTransactionIncludingDeleted(
        outbox.transactionId,
      );
      if (local == null) {
        await _database.markOutboxFailed(
          transactionId: outbox.transactionId,
          idempotencyKey: outbox.id,
          error: 'Data transaksi lokal tidak ditemukan.',
          nextAttemptAt: _clock().add(_backoff(outbox.attemptCount)),
        );
        _scheduleRetry(delay: _backoff(outbox.attemptCount));
        continue;
      }

      final isCurrentOutbox = await _database.markOutboxSyncing(
        transactionId: outbox.transactionId,
        idempotencyKey: outbox.id,
      );
      if (!isCurrentOutbox) continue;
      try {
        final attachmentUrl = await _uploadAttachment(client, local);
        final result = await client.rpc(
          'sync_transaction',
          params: {
            'p_transaction': TransactionMapper.toRemote(
              local,
              attachmentUrl: attachmentUrl,
            ),
            'p_operation': outbox.operation,
            'p_idempotency_key': outbox.id,
            'p_expected_updated_at':
                outbox.baseServerUpdatedAt?.toUtc().toIso8601String(),
          },
        );
        final payload = result is Map
            ? Map<String, dynamic>.from(result.cast<String, dynamic>())
            : <String, dynamic>{};
        if (payload['status'] == 'conflict') {
          final remote = payload['remote'];
          if (remote != null && remote is! Map) {
            throw const FormatException(
              'Respons konflik Supabase tidak valid.',
            );
          }
          await _database.markOutboxConflict(
            transactionId: local.id,
            idempotencyKey: outbox.id,
            remoteSnapshot: jsonEncode(remote),
          );
          continue;
        }
        if (payload['status'] != 'synced' || payload['transaction'] is! Map) {
          throw const FormatException(
            'Respons sinkronisasi Supabase tidak valid.',
          );
        }
        final remote = payload['transaction'];
        final serverUpdatedAt = DateTime.parse(
          (remote as Map)['updated_at'] as String,
        ).toLocal();
        await _database.markTransactionSynced(
          id: local.id,
          idempotencyKey: outbox.id,
          attachmentUrl: attachmentUrl ?? local.attachmentUrl,
          serverUpdatedAt: serverUpdatedAt,
        );
      } on Object catch (error) {
        await _database.markOutboxFailed(
          transactionId: local.id,
          idempotencyKey: outbox.id,
          error: error.toString(),
          nextAttemptAt: _clock().add(_backoff(outbox.attemptCount)),
        );
        _scheduleRetry(delay: _backoff(outbox.attemptCount));
      }
    }

    try {
      await _pullRemote(client, userId);
    } on Object {
      _scheduleRetry();
    }
    if ((await _database.getDueOutboxEntries(
      userId,
      now: _clock(),
    ))
        .isNotEmpty) {
      _scheduleRetry();
    }
  }

  Future<bool> _isEndpointReachable(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      await client
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return true;
    } on Object {
      return false;
    }
  }

  Future<String?> _uploadAttachment(
    SupabaseClient client,
    TransactionEntry entry,
  ) async {
    final localPath = entry.attachmentPath;
    if (localPath == null || localPath.isEmpty) return entry.attachmentUrl;
    if (entry.attachmentUrl != null && entry.attachmentUrl!.isNotEmpty) {
      return entry.attachmentUrl;
    }
    if (kIsWeb) {
      return entry.attachmentUrl;
    }

    final file = io.File(localPath);
    if (!await file.exists()) {
      throw io.FileSystemException('Lampiran lokal tidak ditemukan.', localPath);
    }
    final extension =
        p.extension(localPath).isEmpty ? '.jpg' : p.extension(localPath);
    final storagePath = '${entry.userId}/${entry.id}$extension';
    await client.storage.from(_bucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return storagePath;
  }

  Future<void> _pullRemote(SupabaseClient client, String userId) async {
    final rows = await client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('updated_at');
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _database.getOutboxEntry(id) != null) continue;
      final existing = await _database.getTransactionIncludingDeleted(id);
      final remoteUpdated = DateTime.parse(
        row['updated_at'] as String,
      ).toLocal();
      if (existing?.serverUpdatedAt != null &&
          existing!.serverUpdatedAt!.isAfter(remoteUpdated)) {
        continue;
      }
      await _database.markRemoteTransactionSynced(
        transaction: TransactionMapper.fromRemote(
          Map<String, dynamic>.from(row),
          attachmentPath: existing?.attachmentPath,
        ),
        serverUpdatedAt: remoteUpdated,
      );
    }
  }

  Duration _backoff(int attempts) {
    final exponent = attempts.clamp(0, 14);
    final seconds = 2 * (1 << exponent);
    return Duration(seconds: seconds).compareTo(_maxBackoff) > 0
        ? _maxBackoff
        : Duration(seconds: seconds);
  }

  void _scheduleRetry({Duration? delay}) {
    if (_isDisposed) return;
    final retryDelay = delay ?? pollInterval;
    final retryAt = _clock().add(retryDelay);
    if (_retryTimer?.isActive == true &&
        _retryAt != null &&
        !_retryAt!.isAfter(retryAt)) {
      return;
    }
    _retryTimer?.cancel();
    _retryAt = retryAt;
    _retryTimer = Timer(retryDelay, () {
      _retryTimer = null;
      _retryAt = null;
      requestSyncForCurrentUser();
    });
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _pollTimer?.cancel();
    _retryTimer?.cancel();
    await _connectivitySubscription?.cancel();
  }
}
