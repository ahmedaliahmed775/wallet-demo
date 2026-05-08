import { Router, Response } from 'express';
import { z } from 'zod';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';

const router = Router();

function generateReferenceNo(): string {
  return 'BIL' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();
}

const inquirySchema = z.object({
  serviceCode: z.string(),
  accountNumber: z.string().min(3),
});

const payBillSchema = z.object({
  serviceCode: z.string(),
  accountNumber: z.string().min(3),
  amount: z.number().positive(),
  confirmationCode: z.string().length(4),
});

// GET /api/bills/services
router.get('/services', async (_req, res: Response) => {
  try {
    const services = await db.billService.findMany({
      where: { isActive: true },
      orderBy: { nameAr: 'asc' },
    });

    res.json({
      success: true,
      data: { services },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// POST /api/bills/inquiry
router.post('/inquiry', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = inquirySchema.parse(req.body);

    const service = await db.billService.findUnique({
      where: { serviceCode: body.serviceCode },
    });

    if (!service || !service.isActive) {
      sendError(res, 404, '404 NOT_FOUND', 'Bill service not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    // Simulate bill inquiry response
    const billAmount = Math.floor(Math.random() * 50000) + 1000; // Random amount between 1,000-50,000
    const dueDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    res.json({
      success: true,
      data: {
        service: {
          nameAr: service.nameAr,
          nameEn: service.nameEn,
          serviceCode: service.serviceCode,
          category: service.category,
        },
        accountNumber: body.accountNumber,
        billDetails: {
          accountHolder: 'المشترك',
          amountDue: billAmount,
          currency: 'YER',
          dueDate,
          billNumber: 'BL-' + Date.now().toString().slice(-8),
          status: 'UNPAID',
        },
        message: 'Bill inquiry completed (simulated)',
      },
    });
  } catch (err: unknown) {
    if (err instanceof z.ZodError) {
      sendError(res, 400, '400 BAD_REQUEST', 'Validation error', ErrorCodes.UNKNOWN_ERROR,
        err.errors.map(e => ({ field: e.path.join('.'), message: e.message }))
      );
      return;
    }
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// POST /api/bills/pay
router.post('/pay', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = payBillSchema.parse(req.body);
    const userId = req.user!.userId;

    const user = await db.user.findUnique({
      where: { id: userId },
      include: { wallets: true },
    });

    if (!user) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    if (user.confirmationCode !== body.confirmationCode) {
      sendError(res, 400, '400 BAD_REQUEST', 'Invalid confirmation code', ErrorCodes.INVALID_OTP);
      return;
    }

    const service = await db.billService.findUnique({
      where: { serviceCode: body.serviceCode },
    });

    if (!service || !service.isActive) {
      sendError(res, 404, '404 NOT_FOUND', 'Bill service not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    const wallet = user.wallets.find(w => w.currency === 'YER') || user.wallets.find(w => w.isDefault);
    if (!wallet) {
      sendError(res, 404, '404 NOT_FOUND', 'No wallet found', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (wallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Deduct from wallet
    await db.wallet.update({
      where: { id: wallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Create transaction
    const referenceNo = generateReferenceNo();
    const transaction = await db.transaction.create({
      data: {
        type: 'BILL_PAYMENT',
        status: 'COMPLETED',
        senderWalletId: wallet.id,
        amount: body.amount,
        fee: 0,
        netAmount: body.amount,
        currency: wallet.currency,
        referenceNo,
        description: `Bill payment - ${service.nameAr} - Account: ${body.accountNumber}`,
        metadata: JSON.stringify({
          serviceCode: body.serviceCode,
          serviceName: service.nameAr,
          accountNumber: body.accountNumber,
        }),
      },
    });

    // Create notification
    await db.notification.create({
      data: {
        userId: user.id,
        titleAr: 'دفع فاتورة ناجح',
        titleEn: 'Bill Payment Successful',
        messageAr: `تم دفع فاتورة ${service.nameAr} بمبلغ ${body.amount} ${wallet.currency}`,
        messageEn: `Paid ${service.nameEn} bill of ${body.amount} ${wallet.currency}`,
        type: 'TRANSACTION',
      },
    });

    res.json({
      success: true,
      data: {
        transaction: {
          id: transaction.id,
          type: transaction.type,
          status: transaction.status,
          amount: transaction.amount,
          currency: transaction.currency,
          referenceNo: transaction.referenceNo,
          description: transaction.description,
          createdAt: transaction.createdAt,
        },
        service: {
          nameAr: service.nameAr,
          nameEn: service.nameEn,
          serviceCode: service.serviceCode,
        },
        accountNumber: body.accountNumber,
        message: 'Bill payment completed successfully',
      },
    });
  } catch (err: unknown) {
    if (err instanceof z.ZodError) {
      sendError(res, 400, '400 BAD_REQUEST', 'Validation error', ErrorCodes.UNKNOWN_ERROR,
        err.errors.map(e => ({ field: e.path.join('.'), message: e.message }))
      );
      return;
    }
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

export default router;
