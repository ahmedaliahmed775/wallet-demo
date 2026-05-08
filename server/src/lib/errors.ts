import { Request, Response, NextFunction } from 'express';

export interface SubError {
  field: string;
  message: string;
  rejectedValue?: unknown;
}

export interface ApiError {
  status: string;
  timestamp: string;
  message: string;
  uri?: string;
  code: number;
  subErrors?: SubError[];
}

export const ErrorCodes = {
  SYS_PERMISSION: 6000,
  DUPLICATED_TIMESTAMP: 6001,
  INVALID_CUSTOMER: 6007,
  MUST_INITIATE_PAYMENT: 6008,
  INVALID_OTP: 6010,
  INVALID_MD5: 6015,
  DUPLICATED_REQUEST_ID: 6018,
  EXPIRED_PASSWORD: 6022,
  INVALID_CREDENTIALS: 6023,
  UNKNOWN_ERROR: 9999,
} as const;

export function createApiError(
  status: string,
  message: string,
  code: number,
  subErrors?: SubError[],
  uri?: string
): ApiError {
  return {
    status,
    timestamp: new Date().toISOString(),
    message,
    uri: uri || '/api',
    code,
    subErrors,
  };
}

export function sendError(
  res: Response,
  statusCode: number,
  status: string,
  message: string,
  code: number,
  subErrors?: SubError[]
): void {
  res.status(statusCode).json({
    success: false,
    error: createApiError(status, message, code, subErrors),
  });
}

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  console.error(`[ERROR] ${req.method} ${req.path}:`, err.message);

  res.status(500).json({
    success: false,
    error: createApiError(
      '500 INTERNAL_SERVER_ERROR',
      err.message || 'Internal server error',
      ErrorCodes.UNKNOWN_ERROR
    ),
  });
}
