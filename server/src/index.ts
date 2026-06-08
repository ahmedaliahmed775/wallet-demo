import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config/index.js';
import { errorHandler } from './lib/errors.js';
import { checkDatabase } from './lib/startup.js';
import authRoutes from './routes/auth.routes.js';
import transferRoutes from './routes/transfer.routes.js';
import paymentRoutes from './routes/payment.routes.js';
import rechargeRoutes from './routes/recharge.routes.js';
import billsRoutes from './routes/bills.routes.js';
import cashRoutes from './routes/cash.routes.js';
import walletRoutes from './routes/wallet.routes.js';
import transactionRoutes from './routes/transaction.routes.js';
import seedRoutes from './routes/seed.routes.js';
import notificationRoutes from './routes/notification.routes.js';
import internalRoutes from './routes/internal.routes.js';

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json({ limit: '10mb' }));

// Request logging
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Health check (Atheer Switch ping)
app.get('/health', (_req, res) => {
  res.json({ status: 'UP' });
});

// Health check (detailed)
app.get('/api/health', (_req, res) => {
  res.json({
    success: true,
    data: {
      service: 'مِحْفَظ (Mahfaz)',
      version: '1.0.0',
      status: 'healthy',
      timestamp: new Date().toISOString(),
    },
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/transfer', transferRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/recharge', rechargeRoutes);
app.use('/api/bills', billsRoutes);
app.use('/api/cash', cashRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/seed', seedRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/internal', internalRoutes);
// Atheer Switch new contract path (v1)
app.use('/api/v1/atheer', internalRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    error: {
      status: '404 NOT_FOUND',
      timestamp: new Date().toISOString(),
      message: 'Endpoint not found',
      code: 9999,
    },
  });
});

// Error handling middleware
app.use(errorHandler);

// Start server
const PORT = config.port;

async function start() {
  const dbOk = await checkDatabase();
  if (!dbOk) {
    console.error('Cannot start server - database connection failed');
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`
╔══════════════════════════════════════════╗
║   مِحْفَظ (Mahfaz) - Yemeni E-Wallet      ║
║   Server running on port ${PORT}            ║
║   http://localhost:${PORT}                  ║
╚══════════════════════════════════════════╝
    `);
  });
}

start();

export default app;
