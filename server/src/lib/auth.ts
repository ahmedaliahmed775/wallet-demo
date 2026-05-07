import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';
import { config } from '../config/index.js';

interface TokenPayload {
  userId: string;
  phone: string;
  role: string;
}

export function generateToken(user: { id: string; phone: string; role: string }): string {
  const payload: TokenPayload = {
    userId: user.id,
    phone: user.phone,
    role: user.role,
  };
  return jwt.sign(payload, config.jwtSecret, { expiresIn: config.jwtExpiry });
}

export function verifyToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, config.jwtSecret) as TokenPayload;
  } catch {
    return null;
  }
}

export interface AuthRequest extends Request {
  user?: TokenPayload;
}

export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      success: false,
      error: {
        status: '401 UNAUTHORIZED',
        timestamp: new Date().toISOString(),
        message: 'Authentication required',
        code: 6000,
      },
    });
    return;
  }

  const token = authHeader.substring(7);
  const payload = verifyToken(token);

  if (!payload) {
    res.status(401).json({
      success: false,
      error: {
        status: '401 UNAUTHORIZED',
        timestamp: new Date().toISOString(),
        message: 'Invalid or expired token',
        code: 6023,
      },
    });
    return;
  }

  req.user = payload;
  next();
}
