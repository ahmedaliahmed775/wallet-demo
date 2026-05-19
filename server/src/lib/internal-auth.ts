import { Request, Response, NextFunction } from 'express';
import { config } from '../config/index.js';

/**
 * Internal API Key Middleware
 * للتواصل الداخلي بين Atheer Switch ومحفظة Mahfaz
 * يتحقق من X-API-Key header (نفس نمط Atheer Switch middleware)
 */
export function internalAPIKeyMiddleware(req: Request, res: Response, next: NextFunction): void {
  const apiKey = req.headers['x-api-key'] as string;
  if (!apiKey || apiKey !== config.internalAPIKey) {
    res.status(401).json({
      success: false,
      error: {
        status: '401 UNAUTHORIZED',
        timestamp: new Date().toISOString(),
        message: 'Invalid API Key',
        code: 6000,
      },
    });
    return;
  }
  next();
}