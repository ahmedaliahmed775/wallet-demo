import db from './db.js';

/**
 * فحص الاتصال بقاعدة البيانات عند بدء التشغيل
 */
export async function checkDatabase(): Promise<boolean> {
  try {
    await db.$queryRaw`SELECT 1`;
    console.log('✅ Database connection successful');
    return true;
  } catch (err: unknown) {
    const error = err as Error;
    console.error('❌ DATABASE CONNECTION FAILED');
    console.error('Error:', error.message);
    console.error('Stack:', error.stack);
    return false;
  }
}