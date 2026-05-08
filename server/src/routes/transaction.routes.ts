import { Router, Response } from 'express';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';

const router = Router();

// GET /api/transactions/status
router.get('/status', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { transactionId, referenceNo } = req.query as { transactionId?: string; referenceNo?: string };

    if (!transactionId && !referenceNo) {
      sendError(res, 400, '400 BAD_REQUEST', 'Provide transactionId or referenceNo', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    let transaction = null;

    if (transactionId) {
      transaction = await db.transaction.findUnique({
        where: { id: transactionId },
        include: {
          senderWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
          receiverWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
        },
      });
    } else if (referenceNo) {
      transaction = await db.transaction.findUnique({
        where: { referenceNo: referenceNo as string },
        include: {
          senderWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
          receiverWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
        },
      });
    }

    if (!transaction) {
      sendError(res, 404, '404 NOT_FOUND', 'Transaction not found', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    res.json({
      success: true,
      data: {
        transaction: {
          id: transaction.id,
          type: transaction.type,
          status: transaction.status,
          amount: transaction.amount,
          fee: transaction.fee,
          netAmount: transaction.netAmount,
          currency: transaction.currency,
          referenceNo: transaction.referenceNo,
          description: transaction.description,
          posNumber: transaction.posNumber,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
          sender: transaction.senderWallet?.user
            ? {
                name: transaction.isIdentityHidden ? '***' : transaction.senderWallet.user.name,
                phone: transaction.isIdentityHidden ? '***' : transaction.senderWallet.user.phone,
              }
            : null,
          receiver: transaction.receiverWallet?.user
            ? { name: transaction.receiverWallet.user.name, phone: transaction.receiverWallet.user.phone }
            : null,
        },
      },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// GET /api/transactions/history
router.get('/history', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const type = req.query.type as string | undefined;
    const status = req.query.status as string | undefined;

    // Get user wallets
    const wallets = await db.wallet.findMany({
      where: { userId },
      select: { id: true },
    });

    const walletIds = wallets.map(w => w.id);

    const where: Record<string, unknown> = {
      OR: [
        { senderWalletId: { in: walletIds } },
        { receiverWalletId: { in: walletIds } },
      ],
    };

    if (type) where.type = type;
    if (status) where.status = status;

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      db.transaction.findMany({
        where,
        include: {
          senderWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
          receiverWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      db.transaction.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        transactions: transactions.map(t => ({
          id: t.id,
          type: t.type,
          status: t.status,
          amount: t.amount,
          fee: t.fee,
          netAmount: t.netAmount,
          currency: t.currency,
          referenceNo: t.referenceNo,
          description: t.description,
          posNumber: t.posNumber,
          isIdentityHidden: t.isIdentityHidden,
          createdAt: t.createdAt,
          direction: walletIds.includes(t.senderWalletId || '') ? 'OUTGOING' : 'INCOMING',
          sender: t.senderWallet?.user
            ? { name: t.isIdentityHidden && walletIds.includes(t.receiverWalletId || '') ? '***' : t.senderWallet.user.name }
            : null,
          receiver: t.receiverWallet?.user
            ? { name: t.isIdentityHidden && walletIds.includes(t.senderWalletId || '') ? '***' : t.receiverWallet.user.name }
            : null,
        })),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// GET /api/transactions/receipt
router.get('/receipt', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { transactionId } = req.query as { transactionId?: string };

    if (!transactionId) {
      sendError(res, 400, '400 BAD_REQUEST', 'transactionId is required', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    const transaction = await db.transaction.findUnique({
      where: { id: transactionId },
      include: {
        senderWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
        receiverWallet: { include: { user: { select: { id: true, name: true, phone: true } } } },
      },
    });

    if (!transaction) {
      sendError(res, 404, '404 NOT_FOUND', 'Transaction not found', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    res.json({
      success: true,
      data: {
        receipt: {
          referenceNo: transaction.referenceNo,
          type: transaction.type,
          status: transaction.status,
          amount: transaction.amount,
          fee: transaction.fee,
          netAmount: transaction.netAmount,
          currency: transaction.currency,
          description: transaction.description,
          notes: transaction.notes,
          posNumber: transaction.posNumber,
          date: transaction.createdAt,
          sender: transaction.senderWallet?.user
            ? {
                name: transaction.isIdentityHidden ? '***' : transaction.senderWallet.user.name,
                phone: transaction.isIdentityHidden ? '***' : transaction.senderWallet.user.phone,
                walletNumber: transaction.senderWallet.walletNumber,
              }
            : null,
          receiver: transaction.receiverWallet?.user
            ? {
                name: transaction.receiverWallet.user.name,
                phone: transaction.receiverWallet.user.phone,
                walletNumber: transaction.receiverWallet.walletNumber,
              }
            : null,
          metadata: transaction.metadata ? JSON.parse(transaction.metadata) : null,
        },
      },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

export default router;
