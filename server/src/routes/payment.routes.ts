import { Router, Response } from 'express';
import { z } from 'zod';
import QRCode from 'qrcode';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';
import { config } from '../config/index.js';

const router = Router();

function generateReferenceNo(): string {
  return 'PAY' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 6).toUpperCase();
}

const initPaymentSchema = z.object({
  senderPhone: z.string().min(10),
  posNumber: z.string().optional(),
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
  description: z.string().optional(),
  requestId: z.string().optional(),
});

const confirmPaymentSchema = z.object({
  transactionId: z.string(),
  confirmationCode: z.string().length(4),
});

const scanQrSchema = z.object({
  qrData: z.string(),
  amount: z.number().positive(),
  confirmationCode: z.string().length(4),
});

const payByPosSchema = z.object({
  posNumber: z.string(),
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
  confirmationCode: z.string().length(4),
});

const generateCodeSchema = z.object({
  amount: z.number().positive(),
  currency: z.enum(['YER', 'USD', 'SAR']).default('YER'),
});

const refundSchema = z.object({
  transactionId: z.string(),
  note: z.string().optional(),
});

// POST /api/payment/init
router.post('/init', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = initPaymentSchema.parse(req.body);
    const userId = req.user!.userId;

    // Find sender
    const sender = await db.user.findUnique({
      where: { id: userId },
      include: { wallets: true },
    });

    if (!sender) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    // Verify sender phone matches
    if (sender.phone !== body.senderPhone) {
      sendError(res, 400, '400 BAD_REQUEST', 'Sender phone does not match authenticated user', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    // Find merchant by posNumber if provided
    let merchant = null;
    let receiverWallet = null;

    if (body.posNumber) {
      merchant = await db.merchant.findFirst({
        where: { terminalNumber: body.posNumber, isActive: true },
        include: { user: { include: { wallets: true } } },
      });

      if (!merchant) {
        // Also check by shortCode
        merchant = await db.merchant.findFirst({
          where: { shortCode: body.posNumber, isActive: true },
          include: { user: { include: { wallets: true } } },
        });
      }

      if (!merchant) {
        sendError(res, 404, '404 NOT_FOUND', 'Merchant/POS not found', ErrorCodes.INVALID_CUSTOMER);
        return;
      }

      receiverWallet = merchant.user.wallets.find(w => w.currency === body.currency) || merchant.user.wallets.find(w => w.isDefault);
    }

    // Find sender wallet
    const senderWallet = sender.wallets.find(w => w.currency === body.currency);
    if (!senderWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${body.currency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Check balance
    if (senderWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Check for duplicate requestId
    if (body.requestId) {
      const existingTxn = await db.transaction.findFirst({
        where: { transactionRef: body.requestId },
      });
      if (existingTxn) {
        sendError(res, 409, '409 CONFLICT', 'Duplicate request ID', ErrorCodes.DUPLICATED_REQUEST_ID);
        return;
      }
    }

    const referenceNo = generateReferenceNo();

    // Create PENDING transaction
    const transaction = await db.transaction.create({
      data: {
        type: 'PAYMENT',
        status: 'PENDING',
        senderWalletId: senderWallet.id,
        receiverWalletId: receiverWallet?.id || null,
        amount: body.amount,
        fee: config.fees.paymentFee,
        netAmount: body.amount,
        currency: body.currency,
        referenceNo,
        transactionRef: body.requestId || null,
        description: body.description || 'Payment',
        posNumber: body.posNumber || null,
        otpCode: '1234', // For simulation
        otpExpiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });

    res.json({
      success: true,
      data: {
        transactionId: transaction.id,
        referenceNo: transaction.referenceNo,
        status: 'PENDING',
        amount: transaction.amount,
        currency: transaction.currency,
        fee: transaction.fee,
        confirmationCode: 'required',
        message: 'Payment initiated. Confirm with confirmation code.',
        merchant: merchant ? {
          businessName: merchant.businessName,
          shortCode: merchant.shortCode,
        } : null,
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

// POST /api/payment/confirm
router.post('/confirm', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = confirmPaymentSchema.parse(req.body);
    const userId = req.user!.userId;

    const transaction = await db.transaction.findUnique({
      where: { id: body.transactionId },
    });

    if (!transaction) {
      sendError(res, 404, '404 NOT_FOUND', 'Transaction not found', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    if (transaction.status !== 'PENDING') {
      sendError(res, 400, '400 BAD_REQUEST', 'Transaction is not pending', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    // Verify confirmation code
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

    // Verify sender wallet
    const senderWallet = sender.wallets.find(w => w.id === transaction.senderWalletId);
    if (!senderWallet) {
      sendError(res, 403, '403 FORBIDDEN', 'Not authorized for this transaction', ErrorCodes.SYS_PERMISSION);
      return;
    }

    // Re-check balance
    const currentSenderWallet = await db.wallet.findUnique({ where: { id: senderWallet.id } });
    if (!currentSenderWallet || currentSenderWallet.balance < transaction.amount) {
      // Mark as failed
      await db.transaction.update({
        where: { id: transaction.id },
        data: { status: 'FAILED' },
      });
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Deduct from sender
    await db.wallet.update({
      where: { id: transaction.senderWalletId },
      data: { balance: { decrement: transaction.amount } },
    });

    // Add to receiver if exists
    if (transaction.receiverWalletId) {
      await db.wallet.update({
        where: { id: transaction.receiverWalletId },
        data: { balance: { increment: transaction.netAmount } },
      });
    }

    // Update transaction status
    const updatedTxn = await db.transaction.update({
      where: { id: transaction.id },
      data: { status: 'COMPLETED' },
    });

    // Create notification
    await db.notification.create({
      data: {
        userId: sender.id,
        titleAr: 'دفعة ناجحة',
        titleEn: 'Payment Successful',
        messageAr: `تم دفع ${transaction.amount} ${transaction.currency} بنجاح`,
        messageEn: `Payment of ${transaction.amount} ${transaction.currency} completed successfully`,
        type: 'TRANSACTION',
      },
    });

    res.json({
      success: true,
      data: {
        transaction: {
          id: updatedTxn.id,
          type: updatedTxn.type,
          status: updatedTxn.status,
          amount: updatedTxn.amount,
          fee: updatedTxn.fee,
          netAmount: updatedTxn.netAmount,
          currency: updatedTxn.currency,
          referenceNo: updatedTxn.referenceNo,
          description: updatedTxn.description,
          posNumber: updatedTxn.posNumber,
          createdAt: updatedTxn.createdAt,
        },
        message: 'Payment confirmed successfully',
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

// POST /api/payment/scan-qr
router.post('/scan-qr', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = scanQrSchema.parse(req.body);
    const userId = req.user!.userId;

    // Parse QR data
    let qrData: Record<string, unknown>;
    try {
      qrData = JSON.parse(body.qrData);
    } catch {
      sendError(res, 400, '400 BAD_REQUEST', 'Invalid QR code data', ErrorCodes.INVALID_MD5);
      return;
    }

    const posNumber = qrData.posNumber as string;
    if (!posNumber) {
      sendError(res, 400, '400 BAD_REQUEST', 'QR code does not contain POS number', ErrorCodes.INVALID_MD5);
      return;
    }

    // Find merchant
    const merchant = await db.merchant.findFirst({
      where: {
        OR: [
          { terminalNumber: posNumber },
          { shortCode: posNumber },
        ],
        isActive: true,
      },
      include: { user: { include: { wallets: true } } },
    });

    if (!merchant) {
      sendError(res, 404, '404 NOT_FOUND', 'Merchant not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    // Verify confirmation code
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

    const currency = (qrData.currency as string) || 'YER';
    const senderWallet = sender.wallets.find(w => w.currency === currency);
    if (!senderWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${currency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (senderWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    const receiverWallet = merchant.user.wallets.find(w => w.currency === currency) || merchant.user.wallets.find(w => w.isDefault);

    const referenceNo = generateReferenceNo();

    // Deduct from sender
    await db.wallet.update({
      where: { id: senderWallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Add to receiver
    if (receiverWallet) {
      await db.wallet.update({
        where: { id: receiverWallet.id },
        data: { balance: { increment: body.amount } },
      });
    }

    // Create transaction
    const transaction = await db.transaction.create({
      data: {
        type: 'PAYMENT',
        status: 'COMPLETED',
        senderWalletId: senderWallet.id,
        receiverWalletId: receiverWallet?.id || null,
        amount: body.amount,
        fee: 0,
        netAmount: body.amount,
        currency,
        referenceNo,
        description: `QR Payment to ${merchant.businessName}`,
        posNumber,
        qrCodeData: body.qrData,
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
        merchant: {
          businessName: merchant.businessName,
          shortCode: merchant.shortCode,
        },
        message: 'QR payment completed successfully',
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

// POST /api/payment/by-pos
router.post('/by-pos', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = payByPosSchema.parse(req.body);
    const userId = req.user!.userId;

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
      sendError(res, 404, '404 NOT_FOUND', 'Merchant/POS not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

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

    const senderWallet = sender.wallets.find(w => w.currency === body.currency);
    if (!senderWallet) {
      sendError(res, 404, '404 NOT_FOUND', `No ${body.currency} wallet found`, ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    if (senderWallet.balance < body.amount) {
      sendError(res, 400, '400 BAD_REQUEST', 'Insufficient balance', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    const receiverWallet = merchant.user.wallets.find(w => w.currency === body.currency) || merchant.user.wallets.find(w => w.isDefault);

    const referenceNo = generateReferenceNo();

    // Deduct from sender
    await db.wallet.update({
      where: { id: senderWallet.id },
      data: { balance: { decrement: body.amount } },
    });

    // Add to receiver
    if (receiverWallet) {
      await db.wallet.update({
        where: { id: receiverWallet.id },
        data: { balance: { increment: body.amount } },
      });
    }

    const transaction = await db.transaction.create({
      data: {
        type: 'PAYMENT',
        status: 'COMPLETED',
        senderWalletId: senderWallet.id,
        receiverWalletId: receiverWallet?.id || null,
        amount: body.amount,
        fee: 0,
        netAmount: body.amount,
        currency: body.currency,
        referenceNo,
        description: `POS Payment to ${merchant.businessName}`,
        posNumber: body.posNumber,
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
          posNumber: transaction.posNumber,
          createdAt: transaction.createdAt,
        },
        merchant: {
          businessName: merchant.businessName,
          shortCode: merchant.shortCode,
        },
        message: 'POS payment completed successfully',
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

// POST /api/payment/generate-code
router.post('/generate-code', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = generateCodeSchema.parse(req.body);
    const userId = req.user!.userId;

    const user = await db.user.findUnique({
      where: { id: userId },
      include: { wallets: true, merchant: true },
    });

    if (!user) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    // Generate QR data with merchant info
    const qrDataObj = {
      posNumber: user.merchant?.shortCode || user.merchant?.terminalNumber || user.phone,
      amount: body.amount,
      currency: body.currency,
      userId: user.id,
      timestamp: Date.now(),
    };

    const qrDataString = JSON.stringify(qrDataObj);

    // Generate QR code image as base64
    const qrCodeBase64 = await QRCode.toDataURL(qrDataString);

    res.json({
      success: true,
      data: {
        qrData: qrDataString,
        qrCodeImage: qrCodeBase64,
        amount: body.amount,
        currency: body.currency,
        posNumber: qrDataObj.posNumber,
        message: 'Payment code generated. Show this QR code to the POS.',
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

// POST /api/payment/refund
router.post('/refund', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = refundSchema.parse(req.body);

    const originalTxn = await db.transaction.findUnique({
      where: { id: body.transactionId },
    });

    if (!originalTxn) {
      sendError(res, 404, '404 NOT_FOUND', 'Original transaction not found', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    if (originalTxn.status !== 'COMPLETED') {
      sendError(res, 400, '400 BAD_REQUEST', 'Only completed transactions can be refunded', ErrorCodes.MUST_INITIATE_PAYMENT);
      return;
    }

    if (originalTxn.type === 'REFUND') {
      sendError(res, 400, '400 BAD_REQUEST', 'Cannot refund a refund transaction', ErrorCodes.UNKNOWN_ERROR);
      return;
    }

    // Reverse the amounts
    if (originalTxn.senderWalletId) {
      await db.wallet.update({
        where: { id: originalTxn.senderWalletId },
        data: { balance: { increment: originalTxn.amount } },
      });
    }

    if (originalTxn.receiverWalletId) {
      await db.wallet.update({
        where: { id: originalTxn.receiverWalletId },
        data: { balance: { decrement: originalTxn.netAmount || originalTxn.amount } },
      });
    }

    // Mark original as reversed
    await db.transaction.update({
      where: { id: originalTxn.id },
      data: { status: 'REVERSED' },
    });

    // Create refund transaction
    const referenceNo = generateReferenceNo();
    const refundTxn = await db.transaction.create({
      data: {
        type: 'REFUND',
        status: 'COMPLETED',
        senderWalletId: originalTxn.receiverWalletId,
        receiverWalletId: originalTxn.senderWalletId,
        amount: originalTxn.amount,
        fee: 0,
        netAmount: originalTxn.netAmount || originalTxn.amount,
        currency: originalTxn.currency,
        referenceNo,
        description: `Refund for transaction ${originalTxn.referenceNo}`,
        notes: body.note || null,
        metadata: JSON.stringify({ originalTransactionId: originalTxn.id, originalReferenceNo: originalTxn.referenceNo }),
      },
    });

    res.json({
      success: true,
      data: {
        refundTransaction: {
          id: refundTxn.id,
          type: refundTxn.type,
          status: refundTxn.status,
          amount: refundTxn.amount,
          fee: refundTxn.fee,
          netAmount: refundTxn.netAmount,
          currency: refundTxn.currency,
          referenceNo: refundTxn.referenceNo,
          description: refundTxn.description,
          createdAt: refundTxn.createdAt,
        },
        originalTransaction: {
          id: originalTxn.id,
          referenceNo: originalTxn.referenceNo,
          status: 'REVERSED',
        },
        message: 'Refund processed successfully',
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
