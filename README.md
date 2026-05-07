# مِحْفَظ (Mahfaz) — محفظة إلكترونية يمنية محاكية

> محفظة إلكترونية محاكية مبنية بأحدث التقنيات، تحاكي آليات جميع المحافظ الإلكترونية اليمنية (فلوسك، جوالي، الكريمي، كاش، سبا كاش، بنك عدن، القطيبي)

## 📦 هيكل المستودع

```
mahfaz/
├── server/          ← سيرفر Node.js + Express + Prisma
├── app/             ← تطبيق Flutter (Android + iOS)
├── docs/            ← التوثيق
└── README.md
```

## 🛠️ التقنيات

### السيرفر
| التقنية | الوظيفة |
|---|---|
| Node.js + Express | إطار APIs |
| TypeScript | لغة البرمجة |
| Prisma + SQLite | قاعدة البيانات |
| JWT | المصادقة |
| AES-CBC + MD5 | التشفير (مثل كاش والقطيبي) |

### التطبيق
| التقنية | الوظيفة |
|---|---|
| Flutter | إطار التطبيق الأصلي |
| Dart | لغة البرمجة |
| flutter_bloc | إدارة الحالة |
| Dio | اتصال HTTP |
| Flutter Secure Storage | تخزين آمن |

---

## 🚀 التثبيت والتشغيل

### 1. تشغيل السيرفر

```bash
cd server

# تثبيت الحزم
npm install

# إعداد قاعدة البيانات
npx prisma generate
npx prisma db push

# إضافة البيانات التجريبية
npx tsx src/scripts/seed.ts
# أو عبر API:
curl -X POST http://localhost:3001/api/seed

# تشغيل السيرفر
npm run dev
# السيرفر يعمل على: http://localhost:3001
```

### 2. تشغيل تطبيق Flutter

```bash
cd app

# تثبيت الحزم
flutter pub get

# تشغيل على محاكي Android
flutter run

# أو بناء APK
flutter build apk --release
```

### 3. ربط التطبيق بالسيرفر

في ملف `app/lib/core/network/api_endpoints.dart`:

```dart
// لمحاكي Android:
static const String baseUrl = 'http://10.0.2.2:3001';

// لجهاز حقيقي على نفس الشبكة:
// static const String baseUrl = 'http://192.168.x.x:3001';

// للإنتاج (Render):
// static const String baseUrl = 'https://your-app.onrender.com';
```

---

## 📱 البيانات التجريبية

| الدور | الهاتف | كلمة المرور | كود التأكيد | الرصيد | الاسم |
|---|---|---|---|---|---|
| 👤 عميل | 967770000001 | 123456 | 1234 | 500,000 ر.ي + $500 + 200 ر.س | محمد الأحمدي |
| 👤 عميل | 967770000002 | 123456 | 1234 | 100,000 ر.ي | أحمد السعيد |
| 👤 عميلة | 967770000003 | 123456 | 1234 | 250,000 ر.ي | فاطمة علي |
| 🏪 نقطة بيع | 967770000010 | 123456 | 1234 | 1,000,000 ر.ي | متجر الأمان (777001) |
| 🏪 نقطة بيع | 967770000011 | 123456 | 1234 | 750,000 ر.ي | مطعم السعادة (777002) |
| 🏢 وكيل | 967770000020 | 123456 | 1234 | 5,000,000 ر.ي | وكيل النور |

---

## 🖥️ APIs السيرفر

### المصادقة
| الطريقة | المسار | الوصف |
|---|---|---|
| POST | /api/auth/register | إنشاء حساب |
| POST | /api/auth/login | تسجيل دخول |
| POST | /api/auth/request-otp | طلب OTP |
| POST | /api/auth/verify-otp | تأكيد OTP |
| POST | /api/auth/activate-kyc | تفعيل الحساب |
| POST | /api/auth/change-password | تغيير كلمة المرور |
| POST | /api/auth/change-confirmation-code | تغيير كود التأكيد |

### التحويلات
| الطريقة | المسار | الوصف |
|---|---|---|
| POST | /api/transfer | تحويل لمستخدم |
| POST | /api/transfer/between-accounts | تحويل بين حساباتي |

### الدفع
| الطريقة | المسار | الوصف |
|---|---|---|
| POST | /api/payment/init | بدء عملية دفع |
| POST | /api/payment/confirm | تأكيد الدفع |
| POST | /api/payment/scan-qr | دفع بمسح QR |
| POST | /api/payment/by-pos | دفع برقم نقطة بيع |
| POST | /api/payment/generate-code | توليد كود دفع |
| POST | /api/payment/refund | استرجاع |

### الخدمات
| الطريقة | المسار | الوصف |
|---|---|---|
| GET | /api/recharge/operators | شبكات الاتصال |
| POST | /api/recharge/apply | شحن رصيد |
| GET | /api/bills/services | خدمات الفواتير |
| POST | /api/bills/inquiry | استعلام فاتورة |
| POST | /api/bills/pay | سداد فاتورة |
| POST | /api/cash/deposit | إيداع نقدي |
| POST | /api/cash/withdraw | سحب نقدي |
| GET | /api/cash/agents-nearby | وكلاء قريبون |

### المحافظ والعمليات
| الطريقة | المسار | الوصف |
|---|---|---|
| GET | /api/wallet/balance | الأرصدة |
| GET | /api/wallet/info | تفاصيل المحفظة |
| GET | /api/transactions/status | حالة عملية |
| GET | /api/transactions/history | سجل العمليات |
| GET | /api/transactions/receipt | إيصال عملية |
| GET | /api/notifications | الإشعارات |

---

## 🌐 نشر السيرفر على Render.com (مجاني)

1. ارفع المستودع إلى GitHub
2. اذهب إلى [render.com](https://render.com) وأنشئ حساب
3. اضغط "New" → "Web Service"
4. اربط مستودع GitHub
5. الإعدادات:
   - **Root Directory**: `server`
   - **Build Command**: `npm install && npx prisma generate && npx prisma db push`
   - **Start Command**: `npm start`
   - **Environment Variables**:
     - `DATABASE_URL` = `file:./db/mahfaz.db`
     - `JWT_SECRET` = `your-secret-key-change-this`
     - `ENCRYPTION_KEY` = `your-32-char-encryption-key!`
     - `PORT` = `3001`
6. اضغط "Create Web Service"
7. بعد النشر، غيّر `baseUrl` في التطبيق إلى رابط Render

---

## 🔑 كيف يستفيد من توثيق المحافظ اليمنية

| الآلية | المصدر | التطبيق في مِحْفَظ |
|---|---|---|
| OTP للتأكيد | كاش + فلوسك + سبا كاش | كود تأكيد 4 أرقام |
| JWT مصادقة | فلوسك (RS256) | JWT (HS256) |
| دفع بخطوتين | الكل | init → confirm |
| استرجاع | سبا كاش + الكريمي | refund API |
| فحص حالة | كاش + سبا كاش | status API |
| تشفير AES | القطيبي + كاش | encryption.ts |
| MD5 Token | كاش + بنك عدن | merchantToken |
| كود تأكيد منفصل | جيب | يختلف عن كلمة المرور |
| 3 طرق دفع | جيب | QR + رقم + كود |
| إخفاء الهوية | جيب | خيار خصوصية |
| رموز الأخطاء | كاش (24 كود) | error codes 6000-9999 |

---

## 📄 الرخصة

هذا المشروع للاستخدام التعليمي والمحاكاة فقط.
