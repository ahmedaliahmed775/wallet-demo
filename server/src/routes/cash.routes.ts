import { Router, Response } from 'express';
import { z } from 'zod';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';
import { config } from '../config/index.js';

const router = Router();

function generateReferenceNo(): string {
  return 'CSH' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();
}

const depositSchema = z.object({
  agentWallet: z.string(), // Agent's wallet number
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
  receiverPhone: z.string().min(10),
});

const withdrawSchema = z.object({
  agentWallet: z.string(), // Agent's wallet number
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
  confirmationCode: z.string().length(4),
});

// POST /api/cash/deposit
router.post('/deposit', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = depositSchema.parse(req.body);
    const userId = req.user!.userId;

    // Verify the user is an agent
    const agent = await db.user.findUnique({
      where: { id: userId },
      include: { wallets: true },
    });

    if (!agent) {
      sendError(res, 404, '404 NOT_FOUND', 'Agent not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    if (agent.role !== 'AGENT') {
      sendError(res, 403, '403 FORBIDDEN', 'Only agents can process deposits', ErrorCodes.SYS_PERMISSION);
      return;
    }

    // Find agent wallet
    const agentWallet = agent.wallets.find(w => w.walletNumber === body.agentWallet);
    if (!agentWallet) {
      sendError(res, 404, '404 NOT_FOUND', 'Agent wallet not found', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (agentWallet.currency !== body.currency) {
      sendError(res, 400, '400 BAD_REQUEST', `Agent wallet currency is ${agentWallet.currency}, not ${body.currency}`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (agentWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Agent has insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Find receiver
    const receiver = await db.user.findUnique({
      where: { phone: body.receiverPhone },
      include: { wallets: true },
    });

    if (!receiver) {
      sendError(res, 404, '404 NOT_FOUND', 'Receiver not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    const receiverWallet = receiver.wallets.find(w => w.currency === body.currency) || receiver.wallets.find(w => w.isDefault);
    if (!receiverWallet) {
      sendError(res, 404, '404 NOT_FOUND', 'Receiver wallet not found', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    const referenceNo = generateReferenceNo();

    // Deduct from agent
    await db.wallet.update({
      where: { id: agentWallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Add to receiver
    await db.wallet.update({
      where: { id: receiverWallet.id },
      data: { balance: { increment: body.amount } },
    });

    // Create transaction
    const transaction = await db.transaction.create({
      data: {
        type: 'CASH_IN',
        status: 'COMPLETED',
        senderWalletId: agentWallet.id,
        receiverWalletId: receiverWallet.id,
        amount: body.amount,
        fee: 0,
        netAmount: body.amount,
        currency: body.currency,
        referenceNo,
        description: `Cash deposit by agent ${agent.name} to ${receiver.name}`,
        metadata: JSON.stringify({
          agentName: agent.name,
          receiverName: receiver.name,
          receiverPhone: body.receiverPhone,
        }),
      },
    });

    // Create notifications
    await db.notification.createMany({
      data: [
        {
          userId: agent.id,
          titleAr: 'إيداع ناجح',
          titleEn: 'Deposit Successful',
          messageAr: `تم إيداع ${body.amount} ${body.currency} إلى ${receiver.name}`,
          messageEn: `Deposited ${body.amount} ${body.currency} to ${receiver.name}`,
          type: 'TRANSACTION',
        },
        {
          userId: receiver.id,
          titleAr: 'استلام إيداع',
          titleEn: 'Deposit Received',
          messageAr: `تم استلام ${body.amount} ${body.currency} من الوكيل ${agent.name}`,
          messageEn: `Received ${body.amount} ${body.currency} from agent ${agent.name}`,
          type: 'TRANSACTION',
        },
      ],
    });

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
          createdAt: transaction.createdAt,
        },
        message: 'Deposit completed successfully',
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

// POST /api/cash/withdraw
router.post('/withdraw', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = withdrawSchema.parse(req.body);
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

    // Find user wallet
    const userWallet = user.wallets.find(w => w.currency === body.currency);
    if (!userWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${body.currency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Calculate fee (2% for withdrawal)
    const fee = body.amount * config.fees.cashWithdrawalPercent;
    const totalDeduction = body.amount + fee;

    if (userWallet.balance < totalDeduction) {
      sendError(res, 400, '400 BAD_REQUEST', `Insufficient balance. Need ${totalDeduction} ${body.currency} (including ${fee} fee)`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Find agent wallet
    const agentWallet = await db.wallet.findUnique({
      where: { walletNumber: body.agentWallet },
      include: { user: true },
    });

    if (!agentWallet) {
      sendError(res, 404, '404 NOT_FOUND', 'Agent wallet not found', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (agentWallet.user.role !== 'AGENT') {
      sendError(res, 400, '400 BAD_REQUEST', 'Wallet is not an agent wallet', ErrorCodes.SYS_PERMISSION);
      return;
    }

    if (agentWallet.currency !== body.currency) {
      sendError(res, 400, '400 BAD_REQUEST', `Agent wallet currency is ${agentWallet.currency}, not ${body.currency}`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Check agent has enough balance for the cash out
    if (agentWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Agent has insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    const referenceNo = generateReferenceNo();

    // Deduct from user (amount + fee)
    await db.wallet.update({
      where: { id: userWallet.id },
      data: { balance: { decrement: totalDeduction } },
    });

    // Deduct from agent (cash given to user)
    await db.wallet.update({
      where: { id: agentWallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Create transaction
    const transaction = await db.transaction.create({
      data: {
        type: 'CASH_OUT',
        status: 'COMPLETED',
        senderWalletId: userWallet.id,
        receiverWalletId: agentWallet.id,
        amount: body.amount,
        fee,
        netAmount: body.amount - fee,
        currency: body.currency,
        referenceNo,
        description: `Cash withdrawal via agent ${agentWallet.user.name}`,
        metadata: JSON.stringify({
          agentName: agentWallet.user.name,
          agentWalletNumber: body.agentWallet,
          fee,
          feePercent: config.fees.cashWithdrawalPercent,
        }),
      },
    });

    // Create notifications
    await db.notification.createMany({
      data: [
        {
          userId: user.id,
          titleAr: 'سحب ناجح',
          titleEn: 'Withdrawal Successful',
          messageAr: `تم سحب ${body.amount} ${body.currency} من الوكيل ${agentWallet.user.name} (رسوم: ${fee} ${body.currency})`,
          messageEn: `Withdrew ${body.amount} ${body.currency} from agent ${agentWallet.user.name} (fee: ${fee} ${body.currency})`,
          type: 'TRANSACTION',
        },
        {
          userId: agentWallet.userId,
          titleAr: 'عملية صرف',
          titleEn: 'Cash Out Processed',
          messageAr: `تم صرف ${body.amount} ${body.currency} للعميل ${user.name}`,
          messageEn: `Cash out of ${body.amount} ${body.currency} for customer ${user.name}`,
          type: 'TRANSACTION',
        },
      ],
    });

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
          createdAt: transaction.createdAt,
        },
        fee,
        totalDeduction,
        message: 'Withdrawal completed successfully',
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

// GET /api/cash/agents-nearby
router.get('/agents-nearby', authMiddleware, async (_req: AuthRequest, res: Response) => {
  try {
    const agents = await db.user.findMany({
      where: { role: 'AGENT', status: 'ACTIVE' },
      include: { wallets: true },
    });

    res.json({
      success: true,
      data: {
        agents: agents.map(a => ({
          id: a.id,
          name: a.name,
          phone: a.phone,
          wallets: a.wallets.map(w => ({
            walletNumber: w.walletNumber,
            currency: w.currency,
          })),
        })),
        message: 'Nearby agents (simulated - returns all active agents)',
      },
    });
  } catch (err: unknown) {
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

export default router;
