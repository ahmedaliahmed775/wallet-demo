import { db } from './db.js';
import { config } from '../config/index.js';

export function generateOTP(): string {
  // Fixed OTP for simulation
  return config.otpCode;
}

export async function storeOTP(phone: string, code: string, purpose: string): Promise<void> {
  // Invalidate previous OTPs for this phone and purpose
  await db.oTPVerification.updateMany({
    where: { phone, purpose, isUsed: false },
    data: { isUsed: true },
  });

  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + 5); // 5 minute expiry

  await db.oTPVerification.create({
    data: {
      phone,
      code,
      purpose,
      expiresAt,
    },
  });
}

export async function verifyOTP(phone: string, code: string, purpose: string): Promise<{ valid: boolean; message: string }> {
  const otpRecord = await db.oTPVerification.findFirst({
    where: {
      phone,
      purpose,
      isUsed: false,
      expiresAt: { gte: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!otpRecord) {
    return { valid: false, message: 'OTP not found or expired' };
  }

  // Increment attempts
  await db.oTPVerification.update({
    where: { id: otpRecord.id },
    data: { attempts: { increment: 1 } },
  });

  if (otpRecord.attempts >= 3) {
    await db.oTPVerification.update({
      where: { id: otpRecord.id },
      data: { isUsed: true },
    });
    return { valid: false, message: 'Too many attempts. Please request a new OTP.' };
  }

  if (otpRecord.code !== code) {
    return { valid: false, message: 'Invalid OTP code' };
  }

  // Mark as used
  await db.oTPVerification.update({
    where: { id: otpRecord.id },
    data: { isUsed: true },
  });

  return { valid: true, message: 'OTP verified successfully' };
}
