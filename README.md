# CVGate | بوابة السيرة الذاتية

> منصة جوال لإدارة التوظيف الحر تربط العملاء بالمستقلين وتمنح المدير أدوات متابعة وإدارة متكاملة.

**CVGate** is a Flutter-based freelance recruitment and contract management application. It connects clients who publish jobs with freelancers who apply for them, while providing administrators with tools to manage users, certificates, contracts, payments, and disputes.

`Flutter` `Dart` `Firebase` `Cloud Firestore` `Firebase Authentication` `Firebase Storage`

## عن المشروع

يوفّر CVGate تجربة مخصصة لثلاثة أنواع من المستخدمين: العميل، المستقل، والمدير. يدعم التطبيق دورة العمل من نشر الوظيفة والتقديم عليها، إلى إنشاء العقد وتسليم العمل والدفع والتقييم.

## المزايا الرئيسية

### العميل (Client)

- إنشاء الحساب وتسجيل الدخول وإدارة الملف الشخصي.
- نشر الوظائف وتعديلها ومتابعة الطلبات المقدمة.
- قبول المستقلين وإنشاء العقود.
- مراجعة الأعمال المسلّمة، إتمام الدفع، وإضافة التقييمات.
- الاطلاع على الإشعارات والمدفوعات والعقود.

### المستقل (Freelancer)

- استكمال الملف المهني وإضافة المهارات والأعمال السابقة.
- تصفح الوظائف المفتوحة والتقدم عليها.
- متابعة الطلبات والعقود وتسليم الأعمال.
- رفع الشهادات وملفاتها للتحقق من قبل الإدارة.
- متابعة المدفوعات والتقييمات والإشعارات.

### المدير (Admin)

- لوحة تحكم تعرض إحصاءات المستخدمين والوظائف والعقود والمدفوعات والنزاعات.
- إدارة المستخدمين وتفعيل الحسابات أو إيقافها.
- مراجعة شهادات المستقلين واعتمادها أو رفضها مع ملاحظة.
- إدارة الوظائف والعقود والمدفوعات والنزاعات.
- عرض التقارير والإشعارات وإدارة نموذج العقد.

## التقنيات المستخدمة

| المجال | التقنية |
| --- | --- |
| تطوير التطبيق والواجهات | Flutter وDart |
| إدارة الحالة والتنقل | flutter_bloc (BLoC/Cubit) |
| المصادقة | Firebase Authentication |
| قاعدة البيانات السحابية | Cloud Firestore (NoSQL) |
| حفظ ملفات الشهادات | Firebase Storage |
| التخزين المحلي | SharedPreferences |
| اختيار الملفات وعرض PDF | File Picker وSyncfusion PDF Viewer |
| بيئة التطوير | Android Studio |

## كيف يعمل النظام

```text
العميل ينشر وظيفة
        ↓
المستقل يتصفح الوظائف ويتقدم عليها
        ↓
العميل يراجع الطلب ويختار المستقل
        ↓
إنشاء عقد وتفعيله
        ↓
المستقل يسلّم العمل
        ↓
العميل يراجع التسليم ويكمل الدفع والتقييم
```

## بنية البيانات

يستخدم التطبيق **Cloud Firestore** لتخزين البيانات في Collections وDocuments، ومن أهمها:

```text
users                     بيانات الحسابات وأدوار المستخدمين
jobs                      الوظائف المنشورة
applications              طلبات التقديم على الوظائف
contracts                 العقود بين العميل والمستقل
submissions               الأعمال المسلّمة
payments                  عمليات الدفع
reviews                   التقييمات
notifications             الإشعارات
disputes                  النزاعات
users/{uid}/profile       الملف المهني للمستقل
users/{uid}/certificates  شهادات المستقل
```

## التشغيل محليًا

### المتطلبات

- Flutter SDK متوافق مع Dart `^3.5.2`.
- Android Studio مع Android Emulator، أو هاتف Android فعلي.
- مشروع Firebase مهيأ لتطبيق Android.

### الخطوات

1. استنسخ المستودع:

   ```bash
   git clone https://github.com/ShaykhahM/cv_Gate.git
   cd cv_Gate
   ```

2. ثبّت الحزم:

   ```bash
   flutter pub get
   ```

3. تأكد من إعداد Firebase ووضع ملف `google-services.json` الصحيح داخل:

   ```text
   android/app/google-services.json
   ```

4. شغّل محاكي Android من Android Studio، ثم شغّل التطبيق:

   ```bash
   flutter run
   ```

## هيكلية المشروع

```text
lib/
├── bloc/                 # Cubit وحالات التطبيق لكل دور
├── core/                 # الألوان والأنماط المشتركة
├── screens/
│   ├── auth/             # تسجيل الدخول وإنشاء الحساب
│   ├── client/           # واجهات العميل
│   ├── freelancer/       # واجهات المستقل
│   ├── Admin/            # واجهات المدير
│   └── splash/           # شاشة البداية
├── shared/               # المكونات والخدمات والثوابت المشتركة
└── main.dart             # نقطة تشغيل التطبيق وإعداد Firebase
```

## أعضاء المشروع

- Reema Owaydhah Alharbi
- Masheal Jamal Al-Rawished
- Shaykhah Mohammed Al-Enezi
- Malak Manawar Al Rousan
- Taghreed Hamad Alrasheedi
- Shmokh Abdullah Al-Shammari
- Wafaa Khaled Al-Toumi
- Raghad Manaa Al-Shammari
- Aliyah Farhan Alshammari
- Raghad Mohammed Almurayghi
- Remas Saad Sweidan
- Maryam Shalwah Al-Shammari
- Aisha Hussein Al-Shammari

---

Developed as a graduation project at **Northern Border University**.
