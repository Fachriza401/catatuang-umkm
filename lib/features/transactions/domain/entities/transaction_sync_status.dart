enum TransactionSyncStatus {
  pending('pending'),
  syncing('syncing'),
  synced('synced'),
  failed('failed'),
  conflict('conflict');

  const TransactionSyncStatus(this.storageValue);

  final String storageValue;

  static TransactionSyncStatus fromStorage(String value) {
    return TransactionSyncStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => TransactionSyncStatus.pending,
    );
  }
}
