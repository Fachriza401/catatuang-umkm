import 'package:flutter/material.dart';

import '../../domain/entities/payment_method.dart';
import '../../domain/entities/transaction_category.dart';

extension TransactionCategoryUi on TransactionCategory {
  IconData get icon {
    return switch (id) {
      'sales' => Icons.point_of_sale_rounded,
      'capital' => Icons.account_balance_rounded,
      'other_income' => Icons.add_card_rounded,
      'ingredients' => Icons.inventory_2_rounded,
      'operations' => Icons.settings_rounded,
      'salary' => Icons.groups_rounded,
      'rent' => Icons.storefront_rounded,
      'transport' => Icons.local_shipping_rounded,
      'marketing' => Icons.campaign_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }
}

extension PaymentMethodUi on PaymentMethod {
  IconData get icon {
    return switch (id) {
      'cash' => Icons.payments_rounded,
      'bank_transfer' => Icons.account_balance_rounded,
      'qris' => Icons.qr_code_2_rounded,
      'ewallet' => Icons.wallet_rounded,
      _ => Icons.more_horiz_rounded,
    };
  }
}
