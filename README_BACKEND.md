# دوائي — ربط Backend وقاعدة البيانات

تمت إضافة Supabase إلى النسخة الحالية لعمل تسجيل دخول حقيقي وحسابات مستخدمين حقيقية.

## 1) إنشاء مشروع Supabase
أنشئ مشروعًا جديدًا من لوحة Supabase.

## 2) إنشاء الجداول والسياسات
افتح SQL Editor والصق كامل ملف `supabase_schema.sql` ثم Run.

الملف ينشئ:
- `profiles`: بيانات المستخدم.
- `medicines`: بيانات الأدوية المضافة.
- Row Level Security (RLS) وسياسات الوصول.
- Trigger لإنشاء profile تلقائيًا عند إنشاء مستخدم.

## 3) بيانات الاتصال
من Supabase > Connect انسخ:
- Project URL
- Publishable key

لا تضع Service Role key داخل تطبيق الهاتف.

## 4) تشغيل التطبيق
من مجلد المشروع:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## 5) إنشاء المستخدمين الحقيقيين
يمكن إنشاء أول مستخدمين من شاشة «إنشاء حساب» داخل التطبيق. بعد إنشاء الحساب، يمكنهما تسجيل الدخول من شاشة «تسجيل الدخول».

إذا كان Confirm email مفعّلًا في Supabase، يجب تأكيد البريد قبل أول دخول. يمكن تغيير إعداد Confirm email من Authentication في لوحة Supabase وفق طريقة الاختبار التي تريدها.

## 6) الخطوة التالية
بعد نجاح الدخول، نربط شاشة «إضافة دواء» بجدول `medicines` بدل البيانات التجريبية، ثم نربط البحث والطلبات والتبادل والمحادثات والإشعارات بقاعدة البيانات.

## ملاحظة أمنية
تطبيق الهاتف يستخدم Publishable key فقط، مع RLS. لا تستخدم Service Role key داخل التطبيق.
