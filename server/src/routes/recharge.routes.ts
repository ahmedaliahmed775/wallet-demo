import { Router, Response } from 'express';
import { z } from 'zod';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';

const router = Router();

function generateReferenceNo(): string {
  return 'RCH' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();
}

const rechargeSchema = z.object({
  operatorId: z.string(),
  phone: z.string().min(10),
  amount: z.number().positive(),
  confirmationCode: z.string().length(4),
});

// GET /api/recharge/operators
router.get('/operators', async (_req, res: Response) => {
  try {
    const operators = await db.rechargeOperator.findMany({
      where: { isActive: true },
      orderBy: { nameAr: 'asc' },
    });

    res.json({
      success: true,
      data: { operators },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// POST /api/recharge/apply
router.post('/apply', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = rechargeSchema.parse(req.body);
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

    // Find operator
    const operator = await db.rechargeOperator.findUnique({
      where: { id: body.operatorId },
    });

    if (!operator || !operator.isActive) {
      sendError(res, 404, '404 NOT_FOUND', 'Operator not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    // Use YER wallet for recharge
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
        type: 'RECHARGE',
        status: 'COMPLETED',
        senderWalletId: wallet.id,
        amount: body.amount,
        fee: 0,
        netAmount: body.amount,
        currency: wallet.currency,
        referenceNo,
        description: `Recharge ${operator.nameAr} - ${body.phone}`,
        metadata: JSON.stringify({
          operatorId: operator.id,
          operatorName: operator.nameAr,
          phone: body.phone,
          category: operator.category,
        }),
      },
    });

    // Create notification
    await db.notification.create({
      data: {
        userId: user.id,
        titleAr: 'شحن ناجح',
        titleEn: 'Recharge Successful',
        messageAr: `تم شحن رقم ${body.phone} بمبلغ ${body.amount} ${wallet.currency} عبر ${operator.nameAr}`,
        messageEn: `Recharged ${body.phone} with ${body.amount} ${wallet.currency} via ${operator.nameEn}`,
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
        operator: {
          nameAr: operator.nameAr,
          nameEn: operator.nameEn,
          category: operator.category,
        },
        message: 'Recharge completed successfully',
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
