# إعداد واتساب بيزنس API + الأوثنتكيشن — دليل خطوة بخطوة

> مرجع تشغيلي لتجهيز الحسابات الخارجية لميزة «الدخول بـ Google/Apple + تأكيد الرقم بكود واتساب»
> (الإيشو `onair-backend#27`، العقد `specs/005-guest-social-sign-in/`).
> **الجزء ده كله إعداد حسابات على Meta/Firebase — مش كود.** ربط الكود (الباك اند + التطبيق) بعد ما تجمع القيم في آخر الملف.

**مهم:** للمرحلة الحالية (تطوير/Staging) **مش محتاج توثيق Business ولا مستندات ولا شركة مسجّلة**. رقم الاختبار المجاني كفاية لبناء واختبار كل حاجة. التوثيق للإنتاج بس.

---

## ✅ تم إنجازه (محدّث 24 نوفمبر 2026)

- **Business Portfolio:** OnAir (business_id `1120393297547563`) ✅
- **حساب المطوّر:** اتعمل وتأكّد الرقم بـ `01140024915` ✅
- **Meta App:** `OnAir API` — **App ID `1704524364580184`** ✅
- **Use case:** Connect with customers through WhatsApp ✅
- **بيئة WhatsApp التجريبية** اتجهّزت ✅:

| القيمة | القيمة الفعلية (Test/Staging) |
|---|---|
| رقم الاختبار | `+1 (555) 178-8373` |
| `WHATSAPP_PHONE_NUMBER_ID` | `1481681208356379` |
| `WHATSAPP_WABA_ID` | `1500161248643618` |

> ملاحظة: دي قيم **رقم الاختبار** المجاني (للتطوير). رقم الإنتاج الحقيقي ليه IDs مختلفة تتعمل في Step 2 بعد التوثيق.

- **تجربة الإرسال:** ✅ **ناجحة** — اتبعتت رسالة واتساب حقيقية من رقم الاختبار على `01014867684` ووصلت. (المستلم اتضاف لقايمة الـ 5 أرقام التجريبية.)

**الباقي:** توليد Access token (مؤقت 24 ساعة للتجربة، ودائم عبر System User للسيرفر)، إنشاء قالب Authentication (عربي/إنجليزي)، إعداد الـ Webhook، وFirebase App Check.

---

## القسم 0 — تجهيز حسابك الشخصي (مرة واحدة)

- [ ] فعّل **المصادقة الثنائية (2FA)** على حساب فيسبوك الشخصي (Meta بتطلبها من الأدمن وقت التوثيق لاحقًا).
- [ ] تأكد إن إيميلك الرئيسي على الحساب شغّال وتوصله رسايل.

---

## القسم 1 — إنشاء Page باسم المشروع (اختياري للـ API، مفيد للعلامة)

> Cloud API **مش محتاج** Page. اعملها بس لو عايز حضور للعلامة التجارية. تقدر تتخطى القسم ده.

- [ ] افتح [facebook.com](https://facebook.com) من حسابك الشخصي.
- [ ] القايمة (☰) → **Pages** → **Create new Page**.
- [ ] اكتب اسم الصفحة = **OnAir**، واختَر Category مناسبة (مثلاً Travel Company / Vacation Rental)، واكتب نبذة.
- [ ] **Create Page** → الصفحة بقت مربوطة بحسابك الشخصي كأدمن.

---

## القسم 2 — إنشاء Business Portfolio (Business Manager) باسم OnAir

> ده الكيان اللي هيشيل كل أصول الخدمة. حسابك الشخصي أدمن عليه، بس الأصول منفصلة عنه.

- [ ] افتح [business.facebook.com](https://business.facebook.com).
- [ ] لو أول مرة: **Create account** → اكتب **Business name = OnAir**، اسمك، وإيميل الشركة/الرسمي.
- [ ] أكّد الإيميل من الرسالة اللي هتوصلك.
- [ ] **Business Settings → Business Info** → كمّل بيانات النشاط (العنوان، الموقع، التليفون).
- [ ] **(موصى به)** Business Settings → **Users → People → Add** → ضيف **أدمن احتياطي** تاني موثوق، عشان ما تخسرش الوصول لو حسابك اتقفل.
- [ ] **(لو عملت Page في القسم 1)** Business Settings → **Accounts → Pages → Add → Add a Page** → اختَر **OnAir** عشان تبقى تحت الـ Portfolio.

---

## القسم 3 — إنشاء Meta App وإضافة منتج WhatsApp

- [ ] افتح [developers.facebook.com](https://developers.facebook.com) → **My Apps → Create App**.
- [ ] النوع = **Business** → اربط الـ App بالـ Business Portfolio بتاع OnAir → سمّيه مثلاً `OnAir API`.
- [ ] من داخل الـ App: **Add Product → WhatsApp → Set up**.
- [ ] ده بيعمل تلقائيًا:
  - **WABA** (WhatsApp Business Account) تجريبي.
  - **رقم اختبار مجاني** (test number).
- [ ] روح صفحة **WhatsApp → API Setup**، هتلاقي:
  - **Temporary access token** (مؤقت 24 ساعة — للتجربة السريعة بس).
  - 📌 **Phone number ID** → سجّله.
  - 📌 **WhatsApp Business Account ID (WABA ID)** → سجّله.

---

## القسم 4 — تجربة الإرسال على رقم الاختبار

- [ ] في **API Setup → To**، ضيف رقم موبايلك (ولحد 5 أرقام للفريق) → هيوصلك كود تأكيد على واتساب → أكّده.
- [ ] اضغط **Send message** (برسالة الـ Hello World الجاهزة) → اتأكد إن الرسالة وصلت على واتساب.
- ✅ كده أثبتنا إن الإرسال شغّال من غير أي توثيق ولا فلوس.

---

## القسم 5 — إنشاء قالب الأوثنتكيشن (Authentication Template)

> ده القالب اللي الكود هيتبعت فيه. لازم عربي + إنجليزي.

- [ ] افتح **WhatsApp Manager → Message Templates → Create Template**.
- [ ] **Category = Authentication** (مش Marketing/Utility — مهم للسعر وللموافقة).
- [ ] فعّل زر **Copy code**، وتوصية الأمان، وانتهاء الصلاحية **10 دقايق**.
- [ ] أنشئ نسخة **Arabic (`ar`)** ونسخة **English (`en`)**.
- [ ] استنى موافقة Meta (دقايق لساعات).
- [ ] 📌 سجّل **اسم القالب** المعتمد.

---

## القسم 6 — System User + توكن دائم (للسيرفر)

> ده اللي الـ Worker هيستخدمه للإرسال. دائم ومش متوقّف على جلستك الشخصية.

- [ ] **Business Settings → Users → System Users → Add** → اسم مثلاً `onair-api-system` → دور **Admin**.
- [ ] **Add Assets** → اربطه بـ **الـ App** و**الـ WABA** بصلاحية **Full control / Manage**.
- [ ] **Generate New Token** → اختَر الـ App → فعّل صلاحيتَي:
  - `whatsapp_business_messaging`
  - `whatsapp_business_management`
- [ ] اختَر **Token expiration = Never**.
- [ ] 📌 انسخ التوكن واحفظه فورًا في مكان آمن (مش هيتعرض تاني) → ده **`WHATSAPP_ACCESS_TOKEN`** (سر).

---

## القسم 7 — بيانات الـ Webhook (للسيرفر)

> هنكمّل ربطه فعليًا بعد ما كود الباك اند (A9) ينزل، بس جهّز القيم دلوقتي.

- [ ] **App → Settings → Basic** → انسخ **App Secret** → 📌 **`WHATSAPP_APP_SECRET`** (سر).
- [ ] اخترع string عشوائي طويل → 📌 **`WHATSAPP_WEBHOOK_VERIFY_TOKEN`** (سر، نفسه هيتكتب في Meta).
- [ ] 📌 اعرف نسخة Graph API المستخدمة (مثلاً `v21.0`) → **`WHATSAPP_GRAPH_VERSION`**.
- [ ] *(لاحقًا، بعد نزول الكود)* **App → WhatsApp → Configuration** → حط:
  - **Callback URL** = `https://api.on-air.website/v1/webhooks/whatsapp`
  - **Verify token** = القيمة اللي فوق
  - اشترك في حدث **messages**.

---

## القسم 8 — Firebase + App Check (مجاني، بدون مستندات)

> العقد بيفرض App Check على كل إرسال. التطبيقين (guest + partner) لازم **نفس مشروع Firebase**.

- [ ] اعمل مشروع على [console.firebase.google.com](https://console.firebase.google.com) باسم **OnAir**.
- [ ] ضيف تطبيق **Android** بمعرّفات: `com.onair.guest` و `com.onair.guest.staging` (وبعدين الشركاء: `com.onair.partners` / `.stg`).
- [ ] ضيف تطبيق **iOS** بنفس الـ bundle IDs.
- [ ] فعّل **App Check**: **Play Integrity** (أندرويد) و**App Attest** (iOS).
- [ ] 📌 من إعدادات المشروع، سجّل **Project Number** → **`FIREBASE_PROJECT_NUMBER`** (لكل بيئة).
- [ ] نزّل `google-services.json` (أندرويد) و `GoogleService-Info.plist` (iOS) — هنحطهم في التطبيق وقت الربط.

---

## القسم 9 — Supabase Auth: تفعيل Google و Apple

> ده بيتعمل في لوحة Supabase لكل بيئة (Staging + Production).

- [ ] **Google provider:** فعّله، وحط **Web Client ID** كـ audience، وضيف Android/iOS Client IDs في "Authorized Client IDs".
- [ ] **Apple provider:** فعّله بـ Services ID / Team ID / Key ID / ملف `.p8`.
  - ⚠️ سر Apple **بينتهي كل 6 شهور** → حط تذكير تقويم بالتجديد.
- [ ] تأكد إن **Phone provider مقفول** (إحنا بنبعت واتساب بنفسنا).

---

## 📋 القيم اللي تجمّعها وتبعتهالي (عشان أربط الباك اند + التطبيق)

| القيمة | من فين | نوعها | المكان |
|---|---|---|---|
| `WHATSAPP_ACCESS_TOKEN` | القسم 6 | 🔒 سر | Worker |
| `WHATSAPP_APP_SECRET` | القسم 7 | 🔒 سر | Worker |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | القسم 7 | 🔒 سر | Worker |
| `WHATSAPP_PHONE_NUMBER_ID` | القسم 3 | var | Worker |
| `WHATSAPP_WABA_ID` | القسم 3 | var | Worker |
| `WHATSAPP_OTP_TEMPLATE` | القسم 5 | var | Worker |
| `WHATSAPP_GRAPH_VERSION` | القسم 7 | var | Worker |
| `FIREBASE_PROJECT_NUMBER` | القسم 8 | var | Worker (لكل بيئة) |
| `OTP_HASH_KEY` | **أنا بولّده** (عشوائي ≥32 بايت) | 🔒 سر | Worker |
| `GOOGLE_SERVER_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` | Google Cloud / Firebase | var | التطبيق `env/staging.json` |
| ملفات `google-services.json` / `GoogleService-Info.plist` | القسم 8 | ملفات | التطبيق |

> 🔒 **الأسرار متتكتبش في Git.** تتحط كـ Worker secrets في `onair-backend`. ابعتهالي بأمان وقت الربط.

---

## 🔀 تقسيم المسؤولية

**عليك (إعداد خارجي):** الأقسام 0–9 فوق، وجمع القيم.
**عليّ (كود):**
- **الباك اند (`onair-backend`):** تنفيذ A1–A9 (migrations حالة `incomplete` و `otp_send_limits` وأعمدة الواتساب، RPCs، تعديل الـ Worker للإرسال على واتساب + الـ webhook + App Check)، وإضافة متغيرات الـ env، والاختبارات.
- **التطبيق (البرانش ده):** ربط الـ env الحقيقي، تحويل `BACKEND_MODE` من `mock` لـ `live`، إضافة ملفات Firebase، واختبار التدفّق على Staging.

**قبل ما الباك اند يبدأ:** لازم تحسم الـ **6 قرارات** في الإيشو #27 (مكان العقد، توقيت `common_verify_otp`، شكل `common_update_profile`، ملكية Firebase، مين يعمل/يدفع واتساب، تسجيل موظفي OnAir مع محمد).

---

## 🗺️ الترتيب المقترح

1. **دلوقتي:** الأقسام 0 → 6 (للوصول لرقم اختبار + قالب + توكن) + القسم 8 (Firebase).
2. **بالتوازي:** حسم الـ 6 قرارات في الإيشو.
3. **بعد كده:** أبدأ كود الباك اند (A1–A9) على Staging، نربطه بالتطبيق ونختبر على رقم الاختبار.
4. **قبل الإطلاق:** تسجيل الشركة → Business Verification → رقم حقيقي → رفع الحدود → الإنتاج.
