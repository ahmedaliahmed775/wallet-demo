import { Router, Response } from 'express';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';

const router = Router();

// GET /api/wallet/balance
router.get('/balance', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;

    const wallets = await db.wallet.findMany({
      where: { userId },
      orderBy: { isDefault: 'desc' },
    });

    const totalBalanceYER = wallets.reduce((sum, w) => {
      switch (w.currency) {
        case 'YER':
          return sum + w.balance;
        case 'USD':
          return sum + w.balance * 530;
        case 'SAR':
          return sum + w.balance * 141;
        default:
          return sum;
      }
    }, 0);

    res.json({
      success: true,
      data: {
        wallets: wallets.map(w => ({
          id: w.id,
          walletNumber: w.walletNumber,
          currency: w.currency,
          balance: w.balance,
          isDefault: w.isDefault,
          createdAt: w.createdAt,
        })),
        totalBalanceYER: Math.round(totalBalanceYER),
        currency: 'YER',
      },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// GET /api/wallet/info
router.get('/info', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;

    const user = await db.user.findUnique({
      where: { id: userId },
      include: {
        wallets: { orderBy: { isDefault: 'desc' } },
        merchant: true,
      },
    });

    if (!user) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          role: user.role,
          status: user.status,
          isVerified: user.isVerified,
          gender: user.gender,
          language: user.language,
          isIdentityHidden: user.isIdentityHidden,
          confirmationCode: user.confirmationCode,
        },
        wallets: user.wallets.map(w => ({
          id: w.id,
          walletNumber: w.walletNumber,
          currency: w.currency,
          balance: w.balance,
          isDefault: w.isDefault,
          createdAt: w.createdAt,
        })),
        merchant: user.merchant ? {
          id: user.merchant.id,
          businessName: user.merchant.businessName,
          shortCode: user.merchant.shortCode,
          terminalNumber: user.merchant.terminalNumber,
          isActive: user.merchant.isActive,
        } : null,
      },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

export default router;
