class ApiEndpoints {
  // ============================================
  // تغيير baseUrl حسب البيئة:
  // ============================================
  //
  // 1) محاكي Android (emulator):
  //    static const String baseUrl = 'http://10.0.2.2:3001';
  //
  // 2) جهاز حقيقي على نفس شبكة WiFi:
  //    static const String baseUrl = 'http://192.168.X.X:3001';
  //    (استبدل X.X بـ IP جهازك)
  //
  // 3) إنتاج (Render.com):
  //    static const String baseUrl = 'https://mahfaz-server.onrender.com';
  //
  // ============================================

  // ← غيّر هذا السطر فقط:
  static const String baseUrl = 'https://mahfaz-server.onrender.com';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String requestOtp = '/api/auth/request-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String activateKyc = '/api/auth/activate-kyc';
  static const String changePassword = '/api/auth/change-password';
  static const String changeConfirmationCode = '/api/auth/change-confirmation-code';

  // Transfer
  static const String transfer = '/api/transfer';
  static const String transferBetweenAccounts = '/api/transfer/between-accounts';

  // Payment
  static const String paymentInit = '/api/payment/init';
  static const String paymentConfirm = '/api/payment/confirm';
  static const String paymentScanQr = '/api/payment/scan-qr';
  static const String paymentByPos = '/api/payment/by-pos';
  static const String paymentGenerateCode = '/api/payment/generate-code';
  static const String paymentRefund = '/api/payment/refund';

  // Recharge
  static const String rechargeOperators = '/api/recharge/operators';
  static const String rechargeApply = '/api/recharge/apply';

  // Bills
  static const String billsServices = '/api/bills/services';
  static const String billsInquiry = '/api/bills/inquiry';
  static const String billsPay = '/api/bills/pay';

  // Cash
  static const String cashDeposit = '/api/cash/deposit';
  static const String cashWithdraw = '/api/cash/withdraw';
  static const String cashAgents = '/api/cash/agents-nearby';

  // Wallet
  static const String walletBalance = '/api/wallet/balance';
  static const String walletInfo = '/api/wallet/info';

  // Transactions
  static const String transactionStatus = '/api/transactions/status';
  static const String transactionHistory = '/api/transactions/history';
  static const String transactionReceipt = '/api/transactions/receipt';

  // Notifications
  static const String notifications = '/api/notifications';

  // Seed
  static const String seed = '/api/seed';
}
