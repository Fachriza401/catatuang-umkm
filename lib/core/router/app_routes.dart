abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';
  static const setupProfile = '/setup-profile';
  static const home = '/home';
  static const transactions = '/transactions';
  static const reports = '/reports';
  static const calculator = '/calculator';
  static const settings = '/settings';
  static const transactionNew = '/transactions/new';
  static const debts = '/debts';
  static const debtNew = '/debts/new';

  static String transactionEdit(String id) => '/transactions/$id/edit';
  static String debtDetail(String id) => '/debts/$id';
}
