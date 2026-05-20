import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { db } from '../lib/db.js';
import { generateToken, authMiddleware, AuthRequest } from '../lib/auth.js';
import { generateOTP, storeOTP, verifyOTP } from '../lib/otp.js';
import { sendError, ErrorCodes } from '../lib/errors.js';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

const registerSchema = z.object({
  name: z.string().min(2),
  phone: z.string().min(9),
  password: z.string().min(4),
  gender: z.enum(['MALE', 'FEMALE']).optional(),
  role: z.enum(['CUSTOMER', 'MERCHANT', 'POS', 'AGENT']).default('CUSTOMER'),
  businessName: z.string().min(2).optional(),
  category: z.enum(['RETAIL', 'RESTAURANT', 'SERVICES', 'GROCERY', 'PHARMACY', 'ELECTRONICS', 'CLOTHING', 'OTHER']).optional(),
});

const loginSchema = z.object({
  phone: z.string().min(9).optional(),
  terminalNumber: z.string().length(6).optional(),
  password: z.string().min(4),
  role: z.enum(['CUSTOMER', 'MERCHANT']).optional(),
}).refine(data => data.phone || data.terminalNumber, {
  message: "يجب إدخال رقم الهاتف أو رقم نقطة البيع"
});

const requestOtpSchema = z.object({
  phone: z.string().min(9),
  purpose: z.enum(['LOGIN', 'PAYMENT', 'TRANSFER', 'CHANGE_PIN', 'VERIFY', 'REGISTER']).default('LOGIN'),
});

const verifyOtpSchema = z.object({
  phone: z.string().min(9),
  code: z.string().length(4),
  purpose: z.enum(['LOGIN', 'PAYMENT', 'TRANSFER', 'CHANGE_PIN', 'VERIFY', 'REGISTER']).default('LOGIN'),
});

const activateKycSchema = z.object({
  nationalId: z.string().min(5),
  firstName: z.string().min(2),
  fatherName: z.string().min(2),
  grandfatherName: z.string().min(2),
  familyName: z.string().min(2),
});

const changePasswordSchema = z.object({
  oldPassword: z.string().min(4),
  newPassword: z.string().min(4),
});

const changeConfirmationCodeSchema = z.object({
  oldCode: z.string().length(4),
  newCode: z.string().length(4),
});

function generateWalletNumber(): string {
  return 'MF' + Date.now().toString().slice(-8) + Math.floor(Math.random() * 100).toString().padStart(2, '0');
}

function generateShortCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function generateTerminalNumber(): string {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit
}

// POST /api/auth/register
router.post('/register', async (req: Request, res: Response) => {
  try {
    const body = registerSchema.parse(req.body);

    // Check if phone already exists
    const existingUser = await db.user.findUnique({ where: { phone: body.phone } });
    if (existingUser) {
      sendError(res, 409, '409 CONFLICT', 'Phone number already registered', ErrorCodes.DUPLICATED_TIMESTAMP, [
        { field: 'phone', message: 'Phone number already registered', rejectedValue: body.phone },
      ]);
      return;
    }

    const hashedPassword = await bcrypt.hash(body.password, 10);

    const user = await db.user.create({
      data: {
        phone: body.phone,
        password: hashedPassword,
        name: body.name,
        role: body.role,
        gender: body.gender || null,
        status: 'ACTIVE',
        isVerified: false,
      },
    });

    // Create default YER wallet
    const yerWallet = await db.wallet.create({
      data: {
        userId: user.id,
        currency: 'YER',
        balance: 0,
        walletNumber: generateWalletNumber(),
        isDefault: true,
      },
    });

    // Create USD wallet
    await db.wallet.create({
      data: {
        userId: user.id,
        currency: 'USD',
        balance: 0,
        walletNumber: generateWalletNumber(),
        isDefault: false,
      },
    });

    // Create SAR wallet
    await db.wallet.create({
      data: {
        userId: user.id,
        currency: 'SAR',
        balance: 0,
        walletNumber: generateWalletNumber(),
        isDefault: false,
      },
    });

    // إنشاء سجل التاجر تلقائياً إذا كان الدور MERCHANT
    let merchant = null;
    if (body.role === 'MERCHANT') {
      merchant = await db.merchant.create({
        data: {
          userId: user.id,
          businessName: body.businessName || body.name,
          shortCode: generateShortCode(),
          terminalNumber: generateTerminalNumber(),
          category: body.category || 'RETAIL',
          isActive: true,
          approvedAt: new Date(),
        },
      });
    }

    const token = generateToken({ id: user.id, phone: user.phone, role: user.role });
    const wallets = await db.wallet.findMany({ where: { userId: user.id } });

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          role: user.role,
          status: user.status,
          isVerified: user.isVerified,
          merchant: merchant ? {
            id: merchant.id,
            businessName: merchant.businessName,
            shortCode: merchant.shortCode,
            terminalNumber: merchant.terminalNumber,
            category: merchant.category,
          } : null,
        },
        wallets,
        token,
      },
    });
  } catch (err: unknown) {
    if (err instanceof z.ZodError) {
      sendError(res, 400, '400 BAD_REQUEST', 'Validation error', ErrorCodes.UNKNOWN_ERROR,
        err.errors.map(e => ({ field: e.path.join('.'), message: e.message, rejectedValue: undefined }))
      );
      return;
    }
    sendError(res, 500, '500 INTERNAL_SERVER_ERROR', (err as Error).message, ErrorCodes.UNKNOWN_ERROR);
  }
});

// POST /api/auth/login
router.post('/login', async (req: Request, res: Response) => {
  try {
    const body = loginSchema.parse(req.body);

    // إذا أرسل العميل role، تحقق من تطابقه مع الدور المخزن
    let user;
    if (body.terminalNumber && body.role === 'MERCHANT') {
      // ابحث عن التاجر برقم نقطة البيع (للتجار فقط)
      const merchant = await db.merchant.findFirst({
        where: { terminalNumber: body.terminalNumber, isActive: true },
        include: { user: { include: { wallets: true, merchant: true } } }
      });
      user = merchant?.user;
    } else if (body.phone) {
      user = await db.user.findUnique({
        where: { phone: body.phone },
        include: { wallets: true, merchant: true }
      });
    }

    if (body.role && user && user.role !== body.role) {
      sendError(res, 403, '403 FORBIDDEN',
        body.role === 'MERCHANT'
          ? 'هذا الحساب ليس حساب تاجر. يرجى اختيار زبون.'
          : 'هذا الحساب ليس حساب زبون. يرجى اختيار تاجر.',
        ErrorCodes.SYS_PERMISSION);
      return;
    }

    if (!user) {
      sendError(res, 401, '401 UNAUTHORIZED', 'Invalid phone or password', ErrorCodes.INVALID_CREDENTIALS);
      return;
    }

    if (user.status === 'SUSPENDED' || user.status === 'FROZEN') {
      sendError(res, 403, '403 FORBIDDEN', `Account is ${user.status.toLowerCase()}`, ErrorCodes.SYS_PERMISSION);
      return;
    }

    const isPasswordValid = await bcrypt.compare(body.password, user.password);
    if (!isPasswordValid) {
      sendError(res, 401, '401 UNAUTHORIZED', 'Invalid phone or password', ErrorCodes.INVALID_CREDENTIALS);
      return;
    }

    const token = generateToken({ id: user.id, phone: user.phone, role: user.role });

    // Create session
    await db.session.create({
      data: {
        userId: user.id,
        token,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      },
    });

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
          confirmationCode: user.confirmationCode,
          merchant: user.merchant ? {
            id: user.merchant.id,
            businessName: user.merchant.businessName,
            shortCode: user.merchant.shortCode,
            terminalNumber: user.merchant.terminalNumber,
            category: user.merchant.category,
          } : null,
        },
        wallets: user.wallets,
        token,
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

// POST /api/auth/request-otp
router.post('/request-otp', async (req: Request, res: Response) => {
  try {
    const body = requestOtpSchema.parse(req.body);

    const code = generateOTP();
    await storeOTP(body.phone, code, body.purpose);

    res.json({
      success: true,
      data: {
        phone: body.phone,
        purpose: body.purpose,
        message: 'OTP sent successfully (simulation: code is 1234)',
        code, // Return code for simulation
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

// POST /api/auth/verify-otp
router.post('/verify-otp', async (req: Request, res: Response) => {
  try {
    const body = verifyOtpSchema.parse(req.body);

    const result = await verifyOTP(body.phone, body.code, body.purpose);

    if (!result.valid) {
      sendError(res, 400, '400 BAD_REQUEST', result.message, ErrorCodes.INVALID_OTP);
      return;
    }

    // If purpose is LOGIN, return token
    if (body.purpose === 'LOGIN') {
      const user = await db.user.findUnique({
        where: { phone: body.phone },
        include: { wallets: true, merchant: true },
      });

      if (!user) {
        sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
        return;
      }

      const token = generateToken({ id: user.id, phone: user.phone, role: user.role });

      res.json({
        success: true,
        data: {
          verified: true,
          token,
          user: {
            id: user.id,
            phone: user.phone,
            name: user.name,
            role: user.role,
            status: user.status,
            merchant: user.merchant ? {
              id: user.merchant.id,
              businessName: user.merchant.businessName,
              shortCode: user.merchant.shortCode,
              terminalNumber: user.merchant.terminalNumber,
              category: user.merchant.category,
            } : null,
          },
          wallets: user.wallets,
        },
      });
      return;
    }

    res.json({
      success: true,
      data: {
        verified: true,
        message: result.message,
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

// POST /api/auth/activate-kyc
router.post('/activate-kyc', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = activateKycSchema.parse(req.body);
    const userId = req.user!.userId;

    const user = await db.user.update({
      where: { id: userId },
      data: {
        firstName: body.firstName,
        fatherName: body.fatherName,
        grandfatherName: body.grandfatherName,
        familyName: body.familyName,
        nationalId: body.nationalId,
        isVerified: true,
      },
    });

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          name: user.name,
          isVerified: user.isVerified,
          firstName: user.firstName,
          fatherName: user.fatherName,
          grandfatherName: user.grandfatherName,
          familyName: user.familyName,
          nationalId: user.nationalId,
        },
        message: 'KYC activated successfully',
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

// POST /api/auth/change-password
router.post('/change-password', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = changePasswordSchema.parse(req.body);
    const userId = req.user!.userId;

    const user = await db.user.findUnique({ where: { id: userId } });
    if (!user) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    const isPasswordValid = await bcrypt.compare(body.oldPassword, user.password);
    if (!isPasswordValid) {
      sendError(res, 400, '400 BAD_REQUEST', 'Current password is incorrect', ErrorCodes.EXPIRED_PASSWORD);
      return;
    }

    const hashedPassword = await bcrypt.hash(body.newPassword, 10);
    await db.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    res.json({
      success: true,
      data: { message: 'Password changed successfully' },
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

// POST /api/auth/change-confirmation-code
router.post('/change-confirmation-code', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const body = changeConfirmationCodeSchema.parse(req.body);
    const userId = req.user!.userId;

    const user = await db.user.findUnique({ where: { id: userId } });
    if (!user) {
      sendError(res, 404, '404 NOT_FOUND', 'User not found', ErrorCodes.INVALID_CUSTOMER);
      return;
    }

    if (user.confirmationCode !== body.oldCode) {
      sendError(res, 400, '400 BAD_REQUEST', 'Current confirmation code is incorrect', ErrorCodes.INVALID_OTP);
      return;
    }

    await db.user.update({
      where: { id: userId },
      data: { confirmationCode: body.newCode },
    });

    res.json({
      success: true,
      data: { message: 'Confirmation code changed successfully' },
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
