export const config = {
  port: process.env.PORT || 3001,
  jwtSecret: process.env.JWT_SECRET || 'mahfaz-secret-key-2024-yemen',
  jwtExpiry: '24h',
  otpExpiry: '5m',
  otpCode: '1234', // Fixed for simulation
  encryptionKey: process.env.ENCRYPTION_KEY || 'mahfaz-aes-key-2024-32chars!',
  currencyRates: {
    USD_TO_YER: 530,
    SAR_TO_YER: 141,
    YER_TO_USD: 1 / 530,
    YER_TO_SAR: 1 / 141,
  },
  fees: {
    cashWithdrawalPercent: 0.02, // 2%
    transferFee: 0,
    paymentFee: 0,
  },
};
