# دليل تشغيل مشروع CVGate (نسخة Mac و Android المهيأة)

تم إنشاء وتجهيز نسخة طبق الأصل كاملة من المشروع متوافقة 100% مع أجهزة **macOS** و **Android**، وجاهزة للعمل المباشر على **Visual Studio Code** و **Android Studio**.

---

## 📁 المجلدات المتوفرة:

1. **المجلد النظيف والجاهز المباشر (موصى بفتحه فوراً):**
   ```text
   /Users/shikha/cvgate/CVGate_App
   ```
   > يحتوي المشروع بهيكل Flutter القياسي المباشر (ملف `pubspec.yaml` في المجلد الرئيسي مباشرة)، وهو الأنسب لفتحه في بيئات التطوير.

2. **المجلد الحالي مع التحديثات:**
   ```text
   /Users/shikha/cvgate/cv_Gate
   ```
   > تم تحديثه أيضاً وحل جميع مشاكل الإعدادات وإضافة ملفات الإطلاق المباشرة لـ VS Code و Android Studio.

---

## 🛠️ أهم التحسينات والإصلاحات المطبقة:

1. **دعم تشغيل الماك (macOS Desktop & iOS):**
   - إنشاء ملف الإعدادات الموحد `lib/firebase_options.dart` الذي يربط تطبيق الماك بنظام Firebase بنفس مفاتيح المشروع السحابي.
   - تفعيل صلاحيات اتصال الشبكة `com.apple.security.network.client` في `DebugProfile.entitlements` و `Release.entitlements` (للسماح لـ Firebase بالاتصال بالإنترنت على الماك).
   - تفعيل صلاحيات اختيار الملفات `com.apple.security.files.user-selected.read-write` لرفع الشهادات وملفات الـ PDF على الماك.
   - إضافة ملف `GoogleService-Info.plist` لأجهزة أبل.

2. **دعم تشغيل الأندرويد (Android):**
   - إضافة الصلاحيات الضرورية في `AndroidManifest.xml` (الإنترنت `INTERNET`، حالة الشبكة `ACCESS_NETWORK_STATE`، صلاحيات قراءة الملفات للـ PDF والصور).
   - إضافة نوافذ الاستعلام `<queries>` لتشغيل الروابط الخارجية وعرض الملفات مع `url_launcher`.
   - ضبط توافق Gradle و Java ومطابقة المتطلبات مع Android Studio الحديث.

3. **سلامة الشاشات والمكونات (طبق الأصل دون أي نقص):**
   - جميع شاشات المدير (Admin Screens - 18 شاشة).
   - جميع شاشات العميل (Client Screens - 18 شاشة).
   - جميع شاشات المستقل (Freelancer Screens - 17 شاشة).
   - شاشات المصادقة (Login & Create Account).
   - شاشة البداية (Splash Screen).
   - كافة الحالات وإدارة الحالة (Bloc & Cubits: Admin, Client, Freelancer).
   - كافة الخطوط (10 خطوط) والصور وأيقونات التطبيق.

4. **تنظيف ملف الاعتماديات (`pubspec.yaml`):**
   - إزالة الحزم القديمة غير المستخدمة في الكود والتي كانت تسبب تعارضات برمجية (مثل `flutter_gradient_button`).
   - تثبيت إصدارات الحزم المتوافقة مع أحدث نسخ Flutter و Dart.

---

## 🚀 طريقة التشغيل:

### 1. في Visual Studio Code:
1. افتح VS Code.
2. اختر **File** -> **Open Folder...** واختر:
   `/Users/shikha/cvgate/CVGate_App`
3. من شريط الحالة بالأسفل أو من قائمة الأجهزة (Devices)، اختر:
   - **macOS (desktop)** للتشغيل المباشر على جهاز الماك.
   - أو **Android Emulator** لتشغيله على محاكي الأندرويد.
4. اضغط على مفتاح **F5** أو اختر من القائمة: **Run -> Start Debugging**.

### 2. في Android Studio:
1. افتح Android Studio.
2. اضغط على **Open** واختر:
   `/Users/shikha/cvgate/CVGate_App`
3. انتظر ثوانٍ لاكتمال المزامنة، وستجد التكوين `main.dart` جاهزاً في الأعلى.
4. اختر جهاز التشغيل (Mac Desktop أو Android Emulator).
5. اضغط على زر التشغيل الأخضر ▶️ **Run**.

### 3. من سطر الأوامر (Terminal):
```bash
cd /Users/shikha/cvgate/CVGate_App

# لتحميل الحزم:
flutter pub get

# للتشغيل على الماك:
flutter run -d macos

# للتشغيل على الأندرويد:
flutter run -d android
```
