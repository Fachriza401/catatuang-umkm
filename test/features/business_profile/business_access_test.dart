import 'package:catat_uang/features/business_profile/domain/entities/business_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessAccess owner permissions', () {
    test('owner can manage, create, edit, and delete transactions', () {
      final access = _access();

      expect(access.canManageSettings, isTrue);
      expect(access.canCreateTransactions, isTrue);
      expect(access.canEditTransactions, isTrue);
      expect(access.canDeleteTransactions, isTrue);
    });
  });
}

BusinessAccess _access() => BusinessAccess(businessId: 'business-1');
