import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { db } from '../lib/db.js';
import { internalAPIKeyMiddleware } from '../lib/internal-auth.js';

const router = Router();

// جميع الراوتات هنا تستخدم API Key بدلاً من JWT
router.use(internalAPIKeyMiddleware);

// ── توليد رقم مرجعي ──────────────────────────────────────────
function generateReferenceNo(): string {
  return 'PAY' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();
}

// ── توليد معرف معاملة ────────────────────────────────────────
function generateTxId(): string {
  return 'txn-' + Date.now().toString(36) + '-' + Math.random().toString(36).substring(2, 8);
}

// ── التحقق من المدخلات ───────────────────────────────────────
const processTransactionSchema = z.object({
  payerPhone: z.string().min(10),
  posNumber: z.string().min(1),
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
  requestId: z.string().optional(),
});

/**
 * POST /api/internal/process-transaction
 *
 * يستقبل معاملة الدفع من Atheer Switch وينفذها مباشرة (بدون خطوة تأكيد)
 * - يبحث عن المستخدم بـ payerPhone (بدون JWT)
 * - يبحث عن التاجر بـ posNumber (terminalNumber أو shortCode)
 * - ينفذ Atomic: خصم من الدافع + إيداد للتاجر + حفظ المعاملة
 * - يرجع بصيغة متوافقة مع Atheer Switch WalletAdapter
 *
 * المخرجات (صيغة متوافقة مع Switch):
 * {
 *   "transactionId": "uuid-xxx",
 *   "status": "SUCCESS" | "FAILED",
 *   "walletReference": "PAYxxx",
 *   "payerBalance": 495000,
 *   "errorCode": "INSUFFICIENT_BALANCE"  // عند الفشل
 * }
 */
router.post('/process-transaction', async (req: Request, res: Response) => {
  try {
    const body = processTransactionSchema.parse(req.body);

    // ── 1. Idempotency: فحص requestId مكرر ──────────────────
    if (body.requestId) {
      const existingTxn = await db.transaction.findFirst({
        where: { transactionRef: body.requestId },
      });
      if (existingTxn) {
        console.log(`[Internal] ⟲ طلب مكرر: ${body.requestId}`);
        res.json({
          transactionId: existingTxn.id,
          status: existingTxn.status === 'COMPLETED' ? 'SUCCESS' : 'FAILED',
          walletReference: existingTxn.referenceNo,
          payerBalance: null,
          errorCode: existingTxn.status === 'COMPLETED' ? undefined : 'DUPLICATED_REQUEST_ID',
          message: existingTxn.status === 'COMPLETED' ? 'Duplicate request - previous result returned' : 'Duplicate request ID',
        });
        return;
      }
    }

    // ── 2. البحث عن المستخدم الدافع ─────────────────────────
    const sender = await db.user.findUnique({
      where: { phone: body.payerPhone },
      include: { wallets: true },
    });

    if (!sender) {
      res.json({
        transactionId: '',
        status: 'FAILED',
        errorCode: 'INVALID_CUSTOMER',
        message: `المستخدم ${body.payerPhone} غير موجود`,
      });
      return;
    }

    // ── 3. البحث عن التاجر ──────────────────────────────────
    const merchant = await db.merchant.findFirst({
      where: {
        OR: [
          { terminalNumber: body.posNumber },
          { shortCode: body.posNumber },
        ],
        isActive: true,
      },
      include: { user: { include: { wallets: true } } },
    });

    if (!merchant) {
      res.json({
        transactionId: '',
        status: 'FAILED',
        errorCode: 'INVALID_CUSTOMER',
        message: `التاجر ${body.posNumber} غير موجود`,
      });
      return;
    }

    // ── 4. اختيار المحافظ حسب العملة ─────────────────────────
    const senderWallet = sender.wallets.find(w => w.currency === body.currency);
    if (!senderWallet) {
      res.json({
        transactionId: '',
        status: 'FAILED',
        errorCode: 'UNKNOWN_ERROR',
        message: `لا توجد محفظة ${body.currency} للمستخدم`,
      });
      return;
    }

    const receiverWallet = merchant.user.wallets.find(w => w.currency === body.currency)
      || merchant.user.wallets.find(w => w.isDefault);

    if (!receiverWallet) {
      res.json({
        transactionId: '',
        status: 'FAILED',
        errorCode: 'UNKNOWN_ERROR',
        message: `لا توجد محفظة للتاجر بالعملة ${body.currency}`,
      });
      return;
    }

    // ── 5. فحص الرصيد ────────────────────────────────────────
    if (senderWallet.balance < body.amount) {
      console.log(`[Internal] ✗ رصيد غير كافٍ: ${body.payerPhone} لديه ${senderWallet.balance}، المطلوب ${body.amount}`);

      // حفظ معاملة فاشلة
      const referenceNo = generateReferenceNo();
      const failedTxn = await db.transaction.create({
        data: {
          type: 'PAYMENT',
          status: 'FAILED',
          senderWalletId: senderWallet.id,
          receiverWalletId: receiverWallet.id,
          amount: body.amount,
          fee: 0,
          netAmount: body.amount,
          currency: body.currency,
          referenceNo,
          transactionRef: body.requestId || null,
          description: `Internal payment to ${merchant.businessName} - FAILED`,
          posNumber: body.posNumber,
        },
      });

      res.json({
        transactionId: failedTxn.id,
        status: 'FAILED',
        errorCode: 'INSUFFICIENT_BALANCE',
        message: `الرصيد غير كافٍ لإتمام العملية`,
        payerBalance: senderWallet.balance,
      });
      return;
    }

    // ── 6. تنفيذ المعاملة: خصم + إيداد + حفظ ───────────────
    const referenceNo = generateReferenceNo();
    let transaction: Awaited<ReturnType<typeof db.transaction.create>>;

    // Atomic: نستخدم تفاعل Prisma
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await db.$transaction(async (tx: any) => {
      // خصم من الدافع
      await tx.wallet.update({
        where: { id: senderWallet.id },
        data: { balance: { decrement: body.amount } },
      });

      // إيداد للتاجر
      await tx.wallet.update({
        where: { id: receiverWallet.id },
        data: { balance: { increment: body.amount } },
      });

      // حفظ المعاملة
      transaction = await tx.transaction.create({
        data: {
          type: 'PAYMENT',
          status: 'COMPLETED',
          senderWalletId: senderWallet.id,
          receiverWalletId: receiverWallet.id,
          amount: body.amount,
          fee: 0,
          netAmount: body.amount,
          currency: body.currency,
          referenceNo,
          transactionRef: body.requestId || null,
          description: `Internal payment to ${merchant.businessName}`,
          posNumber: body.posNumber,
        },
      });
    });

    // الحصول على الرصيد المحدث
    const updatedWallet = await db.wallet.findUnique({
      where: { id: senderWallet.id },
      select: { balance: true },
    });

    console.log(`[Internal] ✓ معاملة ناجحة: ${body.payerPhone} → ${merchant.businessName}, مبلغ: ${body.amount} ${body.currency}`);

    // ── 7. إنشاء إشعار ────────────────────────────────────────
    try {
      await db.notification.create({
        data: {
          userId: sender.id,
          titleAr: 'دفعة ناجحة',
          titleEn: 'Payment Successful',
          messageAr: `تم دفع ${body.amount} ${body.currency} إلى ${merchant.businessName} بنجاح`,
          messageEn: `Payment of ${body.amount} ${body.currency} to ${merchant.businessName} completed`,
          type: 'TRANSACTION',
        },
      });
    } catch {
      // الإشعار فشل - لا نوقف المعاملة
    }

    // ── 8. إرجاع النتيجة بصيغة Atheer Switch ──────────────
    res.json({
      transactionId: (transaction! as typeof transaction).id,
      status: 'SUCCESS',
      walletReference: referenceNo,
      payerBalance: updatedWallet?.balance ?? 0,
    });

  } catch (err: unknown) {
    if (err instanceof z.ZodError) {
      res.json({
        transactionId: '',
        status: 'FAILED',
        errorCode: 'INVALID_REQUEST',
        message: 'جسم الطلب غير صالح: ' + (err as z.ZodError).errors.map((e: z.ZodIssue) => `${e.path.join('.')}: ${e.message}`).join(', '),
      });
      return;
    }
    console.error('[Internal] خطأ:', (err as Error).message);
    res.json({
      transactionId: '',
      status: 'FAILED',
      errorCode: 'UNKNOWN_ERROR',
      message: (err as Error).message || 'خطأ داخلي',
    });
  }
});

// ── التحقق من مدخلات حقن الرصيد ──────────────────────────────
const injectBalanceSchema = z.object({
  phone: z.string().min(10),
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
  note: z.string().optional(),
});

/**
 * POST /api/internal/inject-balance
 *
 * حقن رصيد مباشر إلى محفظة مستخدم (للمسؤولين عبر API Key داخلي)
 * - يبحث عن المستخدم برقم الهاتف
 * - يبحث عن محفظته حسب العملة أو المحفظة الافتراضية
 * - يضيف الرصيد مباشرة + ينشئ سجل معاملة CASH_IN
 */
router.post('/inject-balance', async (req: Request, res: Response) => {
  try {
    const body = injectBalanceSchema.parse(req.body);

    // البحث عن المستخدم
    const user = await db.user.findUnique({
      where: { phone: body.phone },
      include: { wallets: true },
    });

    if (!user) {
      res.json({
        success: false,
        error: {
          status: '404 NOT_FOUND',
          timestamp: new Date().toISOString(),
          message: `المستخدم ${body.phone} غير موجود`,
          code: 1404,
        },
      });
      return;
    }

    // البحث عن المحفظة المناسبة
    const wallet = user.wallets.find(w => w.currency === body.currency)
      || user.wallets.find(w => w.isDefault);

    if (!wallet) {
      res.json({
        success: false,
        error: {
          status: '404 NOT_FOUND',
          timestamp: new Date().toISOString(),
          message: `لا توجد محفظة ${body.currency} للمستخدم ${body.phone}`,
          code: 1404,
        },
      });
      return;
    }

    const referenceNo = 'INJ' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();

    // حقن الرصيد + إنشاء معاملة
    await db.transaction.create({
      data: {
        type: 'CASH_IN',
        status: 'COMPLETED',
        receiverWalletId: wallet.id,
        amount: body.amount,
        fee: 0,
        netAmount: body.amount,
        currency: body.currency,
        referenceNo,
        description: body.note || `Admin balance injection - ${body.amount} ${body.currency}`,
      },
    });

    // تحديث الرصيد
    const updated = await db.wallet.update({
      where: { id: wallet.id },
      data: { balance: { increment: body.amount } },
    });

    console.log(`[Internal] 💉 رصيد +${body.amount} ${body.currency} → ${body.phone} | الرصيد الجديد: ${updated.balance}`);

    res.json({
      success: true,
      data: {
        phone: body.phone,
        userName: user.name,
        role: user.role,
        walletNumber: wallet.walletNumber,
        currency: body.currency,
        injectedAmount: body.amount,
        newBalance: updated.balance,
        referenceNo,
      },
    });
  } catch (err: unknown) {
    if (err instanceof z.ZodError) {
      res.status(400).json({
        success: false,
        error: {
          status: '400 BAD_REQUEST',
          timestamp: new Date().toISOString(),
          message: 'جسم الطلب غير صالح: ' + (err as z.ZodError).errors.map((e: z.ZodIssue) => `${e.path.join('.')}: ${e.message}`).join(', '),
          code: 1400,
        },
      });
      return;
    }
    console.error('[Internal] inject-balance error:', err);
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