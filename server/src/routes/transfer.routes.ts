import { Router, Response } from 'express';
import { z } from 'zod';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';
import { config } from '../config/index.js';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

function generateReferenceNo(): string {
  return 'TXN' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();
}

const transferSchema = z.object({
  receiverPhone: z.string().min(10),
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']),
  note: z.string().optional(),
  confirmationCode: z.string().length(4),
});

const betweenAccountsSchema = z.object({
  fromCurrency: z.enum(['YER', 'USD', 'SAR']),
  toCurrency: z.enum(['YER', 'USD', 'SAR']),
  amount: z.number().positive(),
  confirmationCode: z.string().length(4),
});

function convertCurrency(amount: number, fromCurrency: string, toCurrency: string): number {
  if (fromCurrency === toCurrency) return amount;

  // Convert to YER first, then to target currency
  let amountInYER: number;
  switch (fromCurrency) {
    case 'YER':
      amountInYER = amount;
      break;
    case 'USD':
      amountInYER = amount * config.currencyRates.USD_TO_YER;
      break;
    case 'SAR':
      amountInYER = amount * config.currencyRates.SAR_TO_YER;
      break;
    default:
      return amount;
  }

  switch (toCurrency) {
    case 'YER':
      return Math.round(amountInYER);
    case 'USD':
      return Math.round((amountInYER * config.currencyRates.YER_TO_USD) * 100) / 100;
    case 'SAR':
      return Math.round((amountInYER * config.currencyRates.YER_TO_SAR) * 100) / 100;
    default:
      return amount;
  }
}

// POST /api/transfer
router.post('/', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = transferSchema.parse(req.body);
    const userId = req.user!.userId;

    // Get sender user and verify confirmation code
    const sender = await db.user.findUnique({
      where: { id: userId },
      include: { wallets: true },
    });

    if (!sender) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    if (sender.confirmationCode !== body.confirmationCode) {
      sendError(res, 400, '400 BAD_REQUEST', 'Invalid confirmation code', ErrorCodes.INVALID_OTP);
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

    if (receiver.id === userId) {
      sendError(res, 400, '400 BAD_REQUEST', 'Cannot transfer to yourself. Use between-accounts instead.', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Find sender wallet with matching currency
    const senderWallet = sender.wallets.find(w => w.currency === body.currency);
    if (!senderWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${body.currency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Check balance
    if (senderWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR, [
        { field: 'amount', message: 'Insufficient balance', rejectedValue: body.amount },
      ]);
      return;
    }

    // Find or create receiver wallet with matching currency
    let receiverWallet = receiver.wallets.find(w => w.currency === body.currency);
    if (!receiverWallet) {
      // Use default wallet
      receiverWallet = receiver.wallets.find(w => w.isDefault) || receiver.wallets[0];
    }

    // Execute transfer in a transaction
    const fee = config.fees.transferFee; // 0
    const netAmount = body.amount - fee;

    const referenceNo = generateReferenceNo();

    // Deduct from sender
    await db.wallet.update({
      where: { id: senderWallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Add to receiver
    await db.wallet.update({
      where: { id: receiverWallet.id },
      data: { balance: { increment: netAmount } },
    });

    // Create transaction
    const transaction = await db.transaction.create({
      data: {
        type: 'TRANSFER',
        status: 'COMPLETED',
        senderWalletId: senderWallet.id,
        receiverWalletId: receiverWallet.id,
        amount: body.amount,
        fee,
        netAmount,
        currency: body.currency,
        referenceNo,
        description: body.note || 'Transfer',
        isIdentityHidden: sender.isIdentityHidden,
      },
    });

    // Create notifications
    await db.notification.createMany({
      data: [
        {
          userId: sender.id,
          titleAr: 'تحويل ناجح',
          titleEn: 'Transfer Successful',
          messageAr: `تم تحويل ${body.amount} ${body.currency} إلى ${receiver.name}`,
          messageEn: `Transferred ${body.amount} ${body.currency} to ${receiver.name}`,
          type: 'TRANSACTION',
        },
        {
          userId: receiver.id,
          titleAr: 'استلام تحويل',
          titleEn: 'Transfer Received',
          messageAr: `تم استلام ${netAmount} ${body.currency} من ${sender.name}`,
          messageEn: `Received ${netAmount} ${body.currency} from ${sender.name}`,
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
        message: 'Transfer completed successfully',
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

// POST /api/transfer/between-accounts
router.post('/between-accounts', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = betweenAccountsSchema.parse(req.body);
    const userId = req.user!.userId;

    if (body.fromCurrency === body.toCurrency) {
      sendError(res, 400, '400 BAD_REQUEST', 'Source and target currencies must be different', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

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

    const fromWallet = user.wallets.find(w => w.currency === body.fromCurrency);
    const toWallet = user.wallets.find(w => w.currency === body.toCurrency);

    if (!fromWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${body.fromCurrency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (!toWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${body.toCurrency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (fromWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    const convertedAmount = convertCurrency(body.amount, body.fromCurrency, body.toCurrency);
    const referenceNo = generateReferenceNo();

    // Deduct from source wallet
    await db.wallet.update({
      where: { id: fromWallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Add to target wallet
    await db.wallet.update({
      where: { id: toWallet.id },
      data: { balance: { increment: convertedAmount } },
    });

    // Create transaction
    const transaction = await db.transaction.create({
      data: {
        type: 'TRANSFER',
        status: 'COMPLETED',
        senderWalletId: fromWallet.id,
        receiverWalletId: toWallet.id,
        amount: body.amount,
        fee: 0,
        netAmount: convertedAmount,
        currency: body.fromCurrency,
        referenceNo,
        description: `Currency conversion: ${body.amount} ${body.fromCurrency} → ${convertedAmount} ${body.toCurrency}`,
        metadata: JSON.stringify({
          fromCurrency: body.fromCurrency,
          toCurrency: body.toCurrency,
          originalAmount: body.amount,
          convertedAmount,
          rate: body.fromCurrency === 'YER'
            ? (body.toCurrency === 'USD' ? config.currencyRates.YER_TO_USD : config.currencyRates.YER_TO_SAR)
            : (body.fromCurrency === 'USD' ? config.currencyRates.USD_TO_YER : config.currencyRates.SAR_TO_YER),
        }),
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
          fee: transaction.fee,
          netAmount: transaction.netAmount,
          currency: transaction.currency,
          referenceNo: transaction.referenceNo,
          description: transaction.description,
          createdAt: transaction.createdAt,
        },
        conversion: {
          fromAmount: body.amount,
          fromCurrency: body.fromCurrency,
          toAmount: convertedAmount,
          toCurrency: body.toCurrency,
        },
        message: 'Transfer between accounts completed successfully',
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
