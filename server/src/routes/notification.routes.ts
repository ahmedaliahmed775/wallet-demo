import { Router, Response } from 'express';
import { db } from '../lib/db.js';
import { authMiddleware, AuthRequest } from '../lib/auth.js';
import { sendError, ErrorCodes } from '../lib/errors.js';

const router = Router();

// GET /api/notifications
router.get('/', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;

    const skip = (page - 1) * limit;

    const [notifications, total] = await Promise.all([
      db.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      db.notification.count({ where: { userId } }),
    ]);

    const unreadCount = await db.notification.count({
      where: { userId, isRead: false },
    });

    // Mark all as read
    await db.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    res.json({
      success: true,
      data: {
        notifications: notifications.map(n => ({
          id: n.id,
          titleAr: n.titleAr,
          titleEn: n.titleEn,
          messageAr: n.messageAr,
          messageEn: n.messageEn,
          type: n.type,
          isRead: n.isRead,
          createdAt: n.createdAt,
        })),
        unreadCount,
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

export default router;
