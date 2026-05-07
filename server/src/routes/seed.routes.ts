import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { db } from '../lib/db.js';

const router = Router();

function generateWalletNumber(): string {
  return 'MF' + Date.now().toString().slice(-8) + Math.floor(Math.random() * 100).toString().padStart(2, '0');
}

// POST /api/seed
router.post('/', async (_req, res: Response) => {
  try {
    // Check if data already exists
    const existingUsers = await db.user.count();
    if (existingUsers > 0) {
      res.json({
        success: true,
        data: {
          message: 'Database already seeded. Skipping.',
          existingUsers,
        },
      });
      return;
    }

    const hashedPassword = await bcrypt.hash('123456', 10);

    // =============================================
    // Create Users
    // =============================================

    // Customer 1: محمد الأحمدي
    const customer1 = await db.user.create({
      data: {
        phone: '967770000001',
        password: hashedPassword,
        name: 'محمد الأحمدي',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        gender: 'MALE',
        confirmationCode: '1234',
        isVerified: true,
        language: 'ar',
      },
    });

    // Customer 2: أحمد السعيد
    const customer2 = await db.user.create({
      data: {
        phone: '967770000002',
        password: hashedPassword,
        name: 'أحمد السعيد',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        gender: 'MALE',
        confirmationCode: '1234',
        isVerified: true,
        language: 'ar',
      },
    });

    // Customer 3: فاطمة علي
    const customer3 = await db.user.create({
      data: {
        phone: '967770000003',
        password: hashedPassword,
        name: 'فاطمة علي',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        gender: 'FEMALE',
        confirmationCode: '1234',
        isVerified: true,
        language: 'ar',
      },
    });

    // Merchant/POS 1: متجر الأمان
    const merchant1 = await db.user.create({
      data: {
        phone: '967770000010',
        password: hashedPassword,
        name: 'متجر الأمان',
        role: 'MERCHANT',
        status: 'ACTIVE',
        gender: 'MALE',
        confirmationCode: '1234',
        isVerified: true,
        language: 'ar',
      },
    });

    // Merchant/POS 2: مطعم السعادة
    const merchant2 = await db.user.create({
      data: {
        phone: '967770000011',
        password: hashedPassword,
        name: 'مطعم السعادة',
        role: 'MERCHANT',
        status: 'ACTIVE',
        gender: 'MALE',
        confirmationCode: '1234',
        isVerified: true,
        language: 'ar',
      },
    });

    // Agent: وكيل النور
    const agent = await db.user.create({
      data: {
        phone: '967770000020',
        password: hashedPassword,
        name: 'وكيل النور',
        role: 'AGENT',
        status: 'ACTIVE',
        gender: 'MALE',
        confirmationCode: '1234',
        isVerified: true,
        language: 'ar',
      },
    });

    // =============================================
    // Create Wallets
    // =============================================

    // Customer 1 wallets: 500,000 YER + 500 USD + 200 SAR
    await db.wallet.createMany({
      data: [
        { userId: customer1.id, currency: 'YER', balance: 500000, walletNumber: 'MF00000001', isDefault: true },
        { userId: customer1.id, currency: 'USD', balance: 500, walletNumber: 'MF00000002', isDefault: false },
        { userId: customer1.id, currency: 'SAR', balance: 200, walletNumber: 'MF00000003', isDefault: false },
      ],
    });

    // Customer 2 wallets: 100,000 YER
    await db.wallet.createMany({
      data: [
        { userId: customer2.id, currency: 'YER', balance: 100000, walletNumber: 'MF00000004', isDefault: true },
        { userId: customer2.id, currency: 'USD', balance: 0, walletNumber: 'MF00000005', isDefault: false },
        { userId: customer2.id, currency: 'SAR', balance: 0, walletNumber: 'MF00000006', isDefault: false },
      ],
    });

    // Customer 3 wallets: 250,000 YER
    await db.wallet.createMany({
      data: [
        { userId: customer3.id, currency: 'YER', balance: 250000, walletNumber: 'MF00000007', isDefault: true },
        { userId: customer3.id, currency: 'USD', balance: 0, walletNumber: 'MF00000008', isDefault: false },
        { userId: customer3.id, currency: 'SAR', balance: 0, walletNumber: 'MF00000009', isDefault: false },
      ],
    });

    // Merchant 1 wallets: 1,000,000 YER
    await db.wallet.createMany({
      data: [
        { userId: merchant1.id, currency: 'YER', balance: 1000000, walletNumber: 'MF00000010', isDefault: true },
        { userId: merchant1.id, currency: 'USD', balance: 0, walletNumber: 'MF00000011', isDefault: false },
        { userId: merchant1.id, currency: 'SAR', balance: 0, walletNumber: 'MF00000012', isDefault: false },
      ],
    });

    // Merchant 2 wallets: 750,000 YER
    await db.wallet.createMany({
      data: [
        { userId: merchant2.id, currency: 'YER', balance: 750000, walletNumber: 'MF00000013', isDefault: true },
        { userId: merchant2.id, currency: 'USD', balance: 0, walletNumber: 'MF00000014', isDefault: false },
        { userId: merchant2.id, currency: 'SAR', balance: 0, walletNumber: 'MF00000015', isDefault: false },
      ],
    });

    // Agent wallets: 5,000,000 YER
    await db.wallet.createMany({
      data: [
        { userId: agent.id, currency: 'YER', balance: 5000000, walletNumber: 'MF00000016', isDefault: true },
        { userId: agent.id, currency: 'USD', balance: 0, walletNumber: 'MF00000017', isDefault: false },
        { userId: agent.id, currency: 'SAR', balance: 0, walletNumber: 'MF00000018', isDefault: false },
      ],
    });

    // =============================================
    // Create Merchants
    // =============================================
    await db.merchant.createMany({
      data: [
        {
          userId: merchant1.id,
          businessName: 'متجر الأمان',
          shortCode: '777001',
          terminalNumber: 'T-001',
          category: 'RETAIL',
          isActive: true,
          approvedAt: new Date(),
        },
        {
          userId: merchant2.id,
          businessName: 'مطعم السعادة',
          shortCode: '777002',
          terminalNumber: 'T-002',
          category: 'FOOD',
          isActive: true,
          approvedAt: new Date(),
        },
      ],
    });

    // =============================================
    // Create Services (8 services)
    // =============================================
    await db.service.createMany({
      data: [
        { nameAr: 'تحويل أموال', nameEn: 'Money Transfer', icon: 'transfer', category: 'TRANSFER', sortOrder: 1 },
        { nameAr: 'دفع فواتير', nameEn: 'Bill Payment', icon: 'bill', category: 'BILLS', sortOrder: 2 },
        { nameAr: 'شحن رصيد', nameEn: 'Airtime Recharge', icon: 'recharge', category: 'RECHARGE', sortOrder: 3 },
        { nameAr: 'دفع تجاري', nameEn: 'Merchant Payment', icon: 'payment', category: 'PAYMENT', sortOrder: 4 },
        { nameAr: 'صرف نقدي', nameEn: 'Cash Out', icon: 'cashout', category: 'CASH', sortOrder: 5 },
        { nameAr: 'إيداع نقدي', nameEn: 'Cash In', icon: 'cashin', category: 'CASH', sortOrder: 6 },
        { nameAr: 'مسح QR', nameEn: 'Scan QR', icon: 'qr', category: 'PAYMENT', sortOrder: 7 },
        { nameAr: 'سحب من وكيل', nameEn: 'Agent Withdrawal', icon: 'agent', category: 'CASH', sortOrder: 8 },
      ],
    });

    // =============================================
    // Create Recharge Operators
    // =============================================
    await db.rechargeOperator.createMany({
      data: [
        { nameAr: 'يمن موبايل', nameEn: 'Yemen Mobile', category: 'PREPAID' },
        { nameAr: 'سبأفون', nameEn: 'Sabafon', category: 'PREPAID' },
        { nameAr: 'إم تي إن', nameEn: 'MTN', category: 'PREPAID' },
        { nameAr: 'واي', nameEn: 'Y', category: 'PREPAID' },
        { nameAr: 'يمن موبايل - باقة', nameEn: 'Yemen Mobile - Bundle', category: 'BUNDLE' },
        { nameAr: 'سبأفون - باقة', nameEn: 'Sabafon - Bundle', category: 'BUNDLE' },
        { nameAr: 'إم تي إن - باقة', nameEn: 'MTN - Bundle', category: 'BUNDLE' },
        { nameAr: 'واي - باقة', nameEn: 'Y - Bundle', category: 'BUNDLE' },
        { nameAr: 'يمن موبايل - فاتورة', nameEn: 'Yemen Mobile - Postpaid', category: 'POSTPAID' },
        { nameAr: 'سبأفون - فاتورة', nameEn: 'Sabafon - Postpaid', category: 'POSTPAID' },
      ],
    });

    // =============================================
    // Create Bill Services
    // =============================================
    await db.billService.createMany({
      data: [
        { nameAr: 'إنترنت - يمن نت', nameEn: 'Internet - YemenNet', category: 'INTERNET', serviceCode: 'YN-INTERNET' },
        { nameAr: 'هاتف أرضي - يمن نت', nameEn: 'Landline - YemenNet', category: 'LANDLINE', serviceCode: 'YN-LANDLINE' },
        { nameAr: 'كهرباء - صنعاء', nameEn: 'Electricity - Sanaa', category: 'ELECTRICITY', serviceCode: 'ELEC-SANAA' },
        { nameAr: 'كهرباء - عدن', nameEn: 'Electricity - Aden', category: 'ELECTRICITY', serviceCode: 'ELEC-ADEN' },
        { nameAr: 'مياه - صنعاء', nameEn: 'Water - Sanaa', category: 'WATER', serviceCode: 'WATER-SANAA' },
        { nameAr: 'مياه - عدن', nameEn: 'Water - Aden', category: 'WATER', serviceCode: 'WATER-ADEN' },
      ],
    });

    res.json({
      success: true,
      data: {
        message: 'Database seeded successfully',
        users: {
          customers: [customer1.name, customer2.name, customer3.name],
          merchants: [merchant1.name, merchant2.name],
          agent: agent.name,
        },
        loginCredentials: {
          customer1: { phone: '967770000001', password: '123456', confirmationCode: '1234' },
          customer2: { phone: '967770000002', password: '123456', confirmationCode: '1234' },
          customer3: { phone: '967770000003', password: '123456', confirmationCode: '1234' },
          merchant1: { phone: '967770000010', password: '123456', confirmationCode: '1234', shortCode: '777001' },
          merchant2: { phone: '967770000011', password: '123456', confirmationCode: '1234', shortCode: '777002' },
          agent: { phone: '967770000020', password: '123456', confirmationCode: '1234' },
        },
        services: 8,
        rechargeOperators: 10,
        billServices: 6,
      },
    });
  } catch (err: unknown) {
    console.error('Seed error:', err);
    res.status(500).json({
      success: false,
      error: {
        status: '500 INTERNAL_SERVER_ERROR',
        timestamp: new Date().toISOString(),
        message: (err as Error).message,
        code: 9999,
      },
    });
  }
});

export default router;
