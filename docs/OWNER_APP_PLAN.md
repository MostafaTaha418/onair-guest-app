# OnAir Owner App — خطة التطبيق

> **التطبيق:** OnAir Owner & Office App (المالك الفردي + المكتب + المساعدين)  
> **المستودع:** `onair_parteners`  
> **المرجع الأعلى:** [OnAir Master Plan.md](OnAir%20Master%20Plan.md). أي تعارض بين الملف ده والـ Master Plan، الـ Master Plan هو اللي يمشي.  
> **الألوان والخط:** [UI_UX_DESIGN_SYSTEM.md](UI_UX_DESIGN_SYSTEM.md)  
> **الـ Backend (الجداول والصلاحيات والدوال والإشعارات):** [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md)  
> **تاريخ الإنشاء:** 27 أكتوبر 2026  
> **تعديل 28 أكتوبر 2026:** إلغاء SMS ودخول الهاتف (الدخول بالبريد + كلمة المرور، والتسجيل فيه رقم هاتف مصري + «عليه واتساب؟» أو رقم واتساب اختياري، وكل الأكواد على البريد)؛ ربط التطبيق بجداول Supabase الموحدة وصلاحياته (2.5)؛ الدوال بأسمائها النهائية والإشعارات اللي بتوصل التطبيق (7).

---

## 0. نطاق الملف

الملف ده خطة **تطبيق المالك/المكتب بس**. تطبيق المستأجر ولوحة الإدارة كل واحد ليه مستودع وخطة لوحده. الربط الوحيد بينّا هو الـ **Backend** وعقود الـ API اللي بينشرها (Master Plan 13.3).

**مش من نطاق التطبيق ده:**
- أي شاشة خاصة بالمستأجر (بحث، دفع Kashier، مفضلة، تقييم).
- أي شاشة إدارة داخلية (اعتماد الشركاء والعقارات، المحاسبة العامة، خدمة العملاء).
- **شات مباشر مع المستأجر.** ممنوع (القرار 102)، وكل التواصل بيعدّي على خدمة عملاء OnAir.

---

## 1. القرارات المثبتة للتطبيق

| البند | القرار | المصدر |
|---|---|---|
| التقنية | Flutter / Dart | Master Plan 13.1 |
| إدارة الحالة | **Cubit عبر `flutter_bloc`** (نفس تطبيق المستأجر) | قرار الفريق — 27 أكتوبر 2026 |
| اللغة | **العربي هو الافتراضي** + تغيير للإنجليزي من الإعدادات، والنصوص كلها في ملفات ARB | قرار الفريق — 27 أكتوبر 2026 |
| الاتجاه | RTL أساسي للعربي، و LTR للإنجليزي | Master Plan 12.2 |
| الخط | Cairo فقط | UI_UX_DESIGN_SYSTEM |
| الثيم | Light + Dark بالـ Tokens الموجودة في ملف الـ Design System | UI_UX_DESIGN_SYSTEM |
| التنقل | Bottom Navigation + «المزيد» | القرار 116 |
| المالك الفردي والمكتب | **نفس الواجهة ونفس الوظائف**؛ الفرق في نوع الكيان والمستندات بس | Master Plan 1.3 |
| المساعد | رئيسية مخصصة جوه نفس التطبيق، والقوائم بتظهر حسب صلاحياته | القرار 111 |
| البيئات | Staging + Production منفصلين (مفاتيح وروابط مختلفة) | Master Plan 13.1 |
| الأمان | **مفيش أي أسرار في التطبيق** (`service_role` أو مفاتيح Kashier أو غيرها) | Master Plan 13.4 |

---

## 2. الـ Backend المشترك [متفق عليه — 27 أكتوبر 2026]

### 2.1 الاتفاق

- **حساب Supabase واحد وداتابيز واحدة مشتركة** بين التلات تطبيقات. الحساب فيه **مشروعين**: `onair-staging` للتطوير والتجربة، و `onair-production` للتشغيل الحقيقي (Master Plan 13.1). الشغل اليومي كله على Staging.
- **المرجع الوحيد** للجداول والأعمدة والحالات والصلاحيات والدوال والإشعارات: [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md) [محسوم — 28 أكتوبر 2026]. أي اسم في الملف ده مختلف عنه، اسم الـ Backend Master Plan هو اللي يمشي.
- الـ Backend بيتنفذ في مستودع مشترك `onair-backend` (Supabase migrations + RLS + الدوال + خدمة Node `integrations-service` للتكاملات: Kashier، Resend، FCM/APNs، Cloudflare R2).

### 2.2 مين مسؤول عن إيه

1. التنفيذ الأساسي للـ Backend كله حسب الـ Backend Master Plan (القسم 13 فيه ترتيب الـ Migrations).
2. بعد كده الصيانة بالبادئات: **تطبيقنا بينادي `partner_*` و`common_*` بس** (Backend Master Plan 12). ممنوع ننادي `guest_*` أو `admin_*`.
3. **الجداول المشتركة** (`profiles`، `workspaces`، `workspace_members`، `properties`، `bookings`، `booking_events`، الجداول المالية، `notifications`) محدش يعدّل شكلها لوحده. أي تغيير لازم يوافق عليه التلاتة ويتسجل في الـ Backend Master Plan في نفس الـ PR.
4. **Contract-first:** العقد بيتكتب ويتنشر الأول، وكل تطبيق يولّد الـ Client/Types بتاعه منه.

### 2.3 قواعد الشغل على الداتابيز المشتركة [مهم]

> الخطر: 3 أشخاص، كل واحد معاه Claude، بيعدّلوا في نفس الداتابيز. من غير قواعد، ممكن واحد يمسح أو يغيّر حاجة شغّالة عند التاني من غير ما يعرف، ومحدش هيعرف مين غيّر إيه.

1. **كل تعديل في الداتابيز يبقى Migration file**، مش من الـ Dashboard أو الـ SQL Editor مباشرة.
   - الملفات بتبقى في مستودع Git مشترك للـ Backend (`supabase/migrations/`).
   - كده يبقى عندنا تاريخ لكل تغيير، ونقدر نبني Production بنفس الشكل بالظبط.
2. **التجربة على Supabase محلي الأول** (`supabase start` على Docker)، وبعد ما الـ Migration تشتغل صح ترتفع على Staging.
3. **الرفع على Staging بعد Pull Request** يراجعه واحد تاني، وبعدين `supabase db push`. يفضل يبقى من CI أو من شخص واحد متفقين عليه.
4. **Production محدش يلمسه مباشرة.** الرفع عليه بقرار من التلاتة وبعد ما الشغل يتجرب على Staging.
5. **التعديلات تبقى إضافة مش تكسير:** ممنوع `DROP` لجدول أو عمود، أو تغيير اسم، أو تغيير نوع عمود مستخدم، من غير اتفاق. لو محتاج تغيّر حاجة، ضيف الجديد الأول، وانقل التطبيقات عليه، وبعدين امسح القديم.
6. **قبل ما تكتب Migration جديدة اعمل `git pull`**، عشان ملفاتك تبقى بعد ملفات زمايلك في الترتيب، ومتعملوش نفس التعديل مرتين.
7. **Claude والأدوات التانية:**
   - لو حد ربط Supabase MCP بالـ Claude بتاعه، يبقى **Read-only** على المشروع المشترك، والكتابة عن طريق ملفات Migration بس.
   - ممنوع تخلي Claude يشغّل SQL بيمسح أو بيعدّل بيانات على Staging أو Production من غير ما تراجع الأمر بنفسك.
   - مفتاح `service_role` ميتحطش في أي تطبيق، ولا في ملف بيترفع على Git.
8. **RLS على كل جدول من أول يوم.** الجدول الجديد ميترفعش من غير Policies، عشان كل تطبيق يشوف المسموح له بس.
9. **الأنواع (Types):** كل تطبيق بيولّد الأنواع بتاعته من الداتابيز أو من العقد (`supabase gen types` أو OpenAPI)، ومحدش يكتبها بإيده.
10. **Seed data:** فيه ملف `seed.sql` مشترك فيه بيانات تجربة (مستأجر، مالك، مكتب، موظف، شقق، حجوزات بحالات مختلفة)، عشان كل واحد يجرب على نفس البيانات.

### 2.4 لحد ما الجداول تجهز

- كل Feature في التطبيق ليها **Repository interface** وتنفيذين: `Remote` (الحقيقي) و`Mock` (بيانات وهمية).
- التبديل بينهم بـ flag في إعدادات البيئة، فنشتغل على الشاشات من غير ما نستنى الـ Backend.
- الـ Mock لازم يلتزم بنفس شكل العقد المتفق عليه، عشان التبديل يبقى من غير تعديل في الشاشات.

### 2.5 قاعدة البيانات في Supabase — جداول التطبيق وصلاحياته [معتمد — 28 أكتوبر 2026]

> المرجع التفصيلي للأعمدة والقيود: [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md) (الأقسام 2 و4–12).

#### 2.5.1 الفكرة
- المالك الفردي والمكتب والمساعد **مش ليهم جدول مستخدمين خاص**. كل واحد فيهم صف في جدول `profiles` الموحد (نفس الجدول اللي فيه المستأجرين وموظفي OnAir)، وعلاقته بجهة العمل صف في `workspace_members`.
- **جهة العمل** (مالك فردي أو مكتب) = صف في `workspaces` (`kind = individual_owner | office`). الشخص ممكن يبقى عضو في أكتر من جهة.
- **الصلاحيات** = قوالب `role_presets` (`partner_owner`، `partner_manager`، `partner_reception`، `partner_accountant`) + صلاحيات إضافية/مسحوبة على صف العضوية، وتخصيص شقق (`member_property_assignments`) لو `all_properties = false`. كل دالة `partner_*` بتفحص `private.has_permission(workspace_id, perm, property_id)` في السيرفر.
- **مفيش كتابة مباشرة في أي جدول.** القراءة تحت RLS أو من دوال `partner_*` اللي بترجع الحقول المسموحة بس، والكتابة كلها بدوال.
- مسموح للتطبيق: Supabase URL + **anon key** فقط.

#### 2.5.2 مفاتيح صلاحيات الشريك (Backend Master Plan 2.2)

| المفتاح | بيفتح إيه في التطبيق |
|---|---|
| `workspace.manage` | بيانات الجهة، مستندات الاعتماد، وسيلة استلام التسويات |
| `staff.manage` | الموظفين والدعوات وسجل النشاط |
| `properties.view` / `properties.manage` | عرض الشقق / إضافة وتعديل وإرسال للمراجعة وإيقاف مؤقت |
| `calendar.manage` | غلق وفتح الفترات وتعديل السعر الأساسي |
| `policies.manage` | تخصيص العربون والإلغاء في حدود المنصة |
| `bookings.view` / `bookings.respond` / `bookings.request_cancellation` | عرض الحجوزات / قبول ورفض / طلب إلغاء حجز مؤكد |
| `stays.handover` | «تم تسليم الشقة» و«استلمت الشقة والمفاتيح» |
| `cash.collect` | تسجيل تحصيل نقدي (لو الشقة مسموح فيها والشخص من المحصّلين المحددين من OnAir) |
| `damage.manage` | مطالبات الأضرار |
| `finance.view` | الـ Financial Hub والكشوف والتصدير |

#### 2.5.3 الجداول اللي التطبيق بيقرا منها أو بيأثر فيها

| الجدول (Supabase) | التطبيق بيقرا إيه | إزاي | الكتابة | الصلاحية |
|---|---|---|---|---|
| `auth.users` | الجلسة | `supabase_flutter` | `signUp` / `signInWithPassword` / `verifyOtp` / `resetPasswordForEmail` | — |
| `profiles` | صفه بس (الاسم، البريد، الهاتف وحالته، الواتساب) | `common_get_my_context` | `common_update_profile`, `common_request_phone_change` | صاحب الصف |
| `workspaces` | الجهات اللي هو عضو فيها وحالة اعتمادها | `common_get_my_context` / select تحت RLS | `partner_create_workspace`, `partner_update_workspace`, `partner_submit_verification` | `workspace.manage` |
| `workspace_members`, `workspace_invites`, `member_property_assignments` | الفريق والدعوات والشقق المخصصة | `partner_list_members`, `partner_member_activity` | `partner_invite_member`, `partner_update_member`, `partner_set_member_status`, `partner_revoke_invite`, `common_accept_invite` | `staff.manage` |
| `verification_documents` | مستندات الجهة وحالتها | select تحت RLS | `partner_add_verification_document` (+ رفع R2 خاص) | `workspace.manage` |
| `workspace_payout_methods` | وسيلة استلام التسويات | select تحت RLS | `partner_set_payout_method` | `workspace.manage` |
| `role_presets`, `permissions` | القوالب والمفاتيح لشاشة الصلاحيات | select | — | `staff.manage` |
| `properties`, `property_versions`, `property_media` | الشقق والنسخة المنشورة والمعلقة | `partner_list_properties`, `partner_get_property` | `partner_create_property`, `partner_save_property_draft`, `partner_submit_property`, `partner_pause_property`, `partner_resume_property`, `partner_archive_property`, `partner_set_base_price` | `properties.view` / `properties.manage` / `calendar.manage` |
| `booking_policies` | السياسات الفعالة | `partner_get_booking_policies` | `partner_set_booking_policy` | `policies.manage` |
| `markup_policies` | **ممنوع** — المالك ميشوفش هامش OnAir | — | — | — |
| `property_cash_collectors` | مين مسموح له يحصّل في كل شقة (OnAir بتحدده) | select تحت RLS | — | `properties.view` |
| `property_calendar_locks` | التقويم: Hold / حجز / غلق يدوي (من غير بيانات المستأجر) | `partner_get_calendar` | `partner_block_dates`, `partner_unblock_dates` | `calendar.manage` |
| `bookings`, `booking_events` | حجوزات شقق الجهة: الحالة، التواريخ، **اسم المستأجر وعدد الضيوف بس**، لقطة السعر الأساسي والشروط، المهلة، الـ Timeline — **من غير الهامش ولا هاتف/بريد المستأجر** | `partner_list_bookings`, `partner_get_booking` (التحديث اللحظي عبر Realtime على `notifications`) | `partner_respond_booking`, `partner_request_booking_cancellation`, `partner_confirm_handover`, `partner_confirm_checkout` | `bookings.view` / `bookings.respond` / `bookings.request_cancellation` / `stays.handover` |
| `payments` | حالة الدفع المتحققة والمتبقي، والتحصيلات النقدية | ضمن `partner_get_booking` و`partner_my_custody` | `partner_record_cash_collection` | `cash.collect` |
| `cash_handovers` | عهدتي وتسليماتي | `partner_my_custody` | `partner_request_cash_handover`, `partner_confirm_cash_handover` | `cash.collect` |
| `damage_claims`, `attachments` | المطالبات والأدلة | ضمن `partner_get_booking` | `partner_open_damage_claim` + Node `uploads/sign` | `damage.manage` |
| `owner_payables`, `settlements`, `journal_lines` (بُعد الجهة) | المستحقات eligible / paid، التسويات، كشف الحساب | `partner_finance_summary`, `partner_list_payables`, `partner_list_settlements`, `partner_statement` | Node `POST /v1/exports` | `finance.view` |
| `support_cases`, `case_messages` | حالات الجهة مع OnAir (طلبات الإلغاء، الدعم) | `common_list_my_support_cases`, `common_get_support_case` | `common_create_support_case`, `common_reply_support_case` | عضو + `bookings.view` |
| `audit_log` | سجل نشاط موظفي الجهة **في سياقها بس** | `partner_member_activity` | — | `staff.manage` |
| `notifications`, `notification_preferences`, `device_tokens` | إشعاراته (`audience = partner`) لكل جهة | `common_list_notifications(workspace_id)` + Realtime | `common_mark_notifications_read`, `common_set_notification_preferences`, `common_register_device(app='partner')` | صاحب الصف |
| `app_config`, `faq_items` | الإصدار الأدنى للتطبيق، رقم الدعم، أسئلة الشركاء | select / `common_list_faq('partner')` | — | — |

**مش متاحة للتطبيق خالص:** `markup_policies`, `refunds` (المالك بيشوف أثرها على الحجز بس)، `kashier_payouts`, `ledger_accounts`, `journal_entries`, `staff_tasks`, `platform_settings`, `notification_deliveries`, `booking_quotes`, `favorites`, `property_reviews` غير المعتمدة، وكل جداول `private`.

#### 2.5.4 خدمة Node اللي التطبيق بيكلمها

| المسار | الاستخدام |
|---|---|
| `POST /v1/otp/send` | كود على البريد (تغيير الهاتف، تأكيد تسليم العهدة) |
| `POST /v1/uploads/sign` · `GET /v1/files/{id}/url` | رفع صور الشقق والمستندات والأدلة وعرضها |
| `POST /v1/exports` | تصدير PDF / Excel |

---

## 3. المستخدمين جوه التطبيق

| المستخدم | بيشوف إيه |
|---|---|
| **Individual Owner** | كل حاجة تخص شققه وفريقه وماليته |
| **Office Principal / Manager** | نفس اللي فوق بالظبط، بهوية مكتب |
| **Owner / Office Assistant** | رئيسية موظف + القوائم والإجراءات المسموحة له بس، وعلى الشقق المخصصة له بس |

**Workspaces:**
- المستخدم ممكن يبقى عضو في أكتر من جهة عمل. مثلًا موظف عند مالكين، أو مالك وكمان موظف عند مكتب.
- فيه **Workspace Switcher** واضح، وبتغيير الجهة بتتمسح كل البيانات المحمّلة (Cache + Cubits) وتتحمل من جديد.
- التطبيق **مش بيثق** في الـ Workspace الحالي من نفسه. الـ Backend هو اللي بيتحقق من الانتساب في كل طلب (Master Plan 2.6).
- إخفاء الزرار حسب الصلاحية بيحسّن التجربة، لكنه **مش حماية**. التطبيق لازم يتعامل صح مع رفض السيرفر (403) ويعرض رسالة واضحة.

---

## 4. المعمارية

### 4.1 هيكل المجلدات المقترح

```text
lib/
├── main_staging.dart
├── main_production.dart
├── app/
│   ├── app.dart                  # MaterialApp.router + Theme + Locale
│   ├── router/                   # go_router + guards (auth / workspace / permission)
│   └── di/                       # RepositoryProvider + BlocProvider على مستوى التطبيق
├── core/
│   ├── config/                   # Env (staging/prod) عبر --dart-define-from-file
│   ├── network/                  # Dio client + interceptors (auth, request_id, errors)
│   ├── supabase/                 # تهيئة supabase_flutter (Auth + قراءات تحت RLS)
│   ├── session/                  # الجلسة، الـ Workspace النشط، تسجيل الخروج
│   ├── errors/                   # Failure + أكواد الأخطاء القادمة من العقود
│   ├── money/                    # Money بوحدة صغيرة (int)، تنسيق الجنيه
│   ├── dates/                    # UTC ↔ توقيت القاهرة، حساب الليالي
│   ├── permissions/              # مفاتيح الصلاحيات كما يعرّفها الـ Backend
│   └── l10n/                     # ARB عربي/إنجليزي
├── design_system/
│   ├── tokens/                   # colors, typography, spacing, radius, shadows
│   ├── theme/                    # ThemeData light/dark + ThemeExtensions
│   └── components/               # Buttons, Inputs, StatusChip, Cards, Empty/Error/Loading
├── generated/
│   └── api/                      # Client مولّد من عقود API — ممنوع التعديل اليدوي
└── features/
    ├── auth/
    ├── onboarding/               # نوع الحساب + مستندات التحقق + حالة الاعتماد
    ├── workspaces/               # Switcher + قبول الدعوات
    ├── dashboard/                # رئيسية المالك + رئيسية المساعد
    ├── properties/               # Wizard + المسودات + النسخ + الإيقاف المؤقت
    ├── calendar/                 # تقويم شامل + تقويم لكل شقة + الأسعار والتوافر
    ├── bookings/                 # القائمة + التفاصيل + قبول/رفض
    ├── stays/                    # Check-in/out + التحصيل النقدي + العهدة + الأضرار
    ├── staff/                    # الموظفين والدعوات والصلاحيات والنشاط
    ├── finance/                  # Financial Hub
    ├── notifications/            # مركز الإشعارات + FCM
    └── account/                  # الملف الشخصي + الإعدادات + اللغة + الثيم
```

كل Feature جواها:

```text
features/<name>/
├── data/          # remote + mock datasources, models (DTO), repository impl
├── domain/        # entities + repository interface
└── presentation/  # cubit/ (cubit + state), pages/, widgets/
```

### 4.2 الحزم المقترحة [تطبيق مقترح]

| الغرض | الحزمة |
|---|---|
| State | `flutter_bloc`, `bloc_test`, `equatable` أو `freezed` |
| Routing | `go_router` |
| Backend | `supabase_flutter` (Auth + قراءات RLS)، `dio` (خدمات Node) |
| Models | `freezed`, `json_serializable` |
| API Client | مولّد من OpenAPI (مثلًا `openapi-generator` بقالب `dart-dio`) |
| تخزين آمن | `flutter_secure_storage` |
| الترجمة | `flutter_localizations`, `intl` (gen-l10n) |
| الإشعارات | `firebase_messaging`, `flutter_local_notifications` |
| الصور | `image_picker`, `cached_network_image`, ضغط قبل الرفع |
| الرسوم البيانية | `fl_chart` |
| المراقبة | Crash reporting يتحدد مع الفريق |

### 4.3 قواعد الوصول للبيانات

- **القراءة** (قوائم الشقق، الحجوزات، الإشعارات): ينفع مباشرة من Supabase تحت RLS، أو من Node، حسب العقد.
- **الكتابة الحساسة** لازم تعدّي على أمر موثوق في السيرفر (Node / RPC): قبول ورفض الحجز، Check-in/out، التحصيل النقدي، تسليم العهدة، تعديل صلاحيات الموظفين، طلب إلغاء حجز مؤكد.
- **التطبيق عمره ما يحسب سعر أو مبلغ ويبعته كحقيقة.** المبالغ دايمًا جاية من السيرفر.
- كل أمر كتابة بيتبعت معاه **Idempotency key**، عشان الضغط مرتين أو إعادة المحاولة متعملش العملية مرتين.
- المبالغ بتتعامل كـ `int` بأصغر وحدة (قروش)، **مش `double`**.
- التواريخ بتتخزن UTC وتتعرض بتوقيت القاهرة. الليالي بتتحسب بالتاريخ مش بالساعات.

---

## 5. التنقل والشاشات

### 5.1 Bottom Navigation — المالك / المدير

| التبويب | المحتوى |
|---|---|
| **الرئيسية** | Dashboard (القرار 105) |
| **الحجوزات** | قائمة موحدة بتبويبات الحالة (القرار 108) |
| **الشقق** | قائمة الشقق + إضافة شقة |
| **التقويم** | تقويم شامل + الدخول لتقويم كل شقة (القرار 107) |
| **المزيد** | المالية، الموظفين، الإشعارات، الحساب والتحقق، الإعدادات (لغة/ثيم)، تبديل جهة العمل، تسجيل الخروج |

### 5.2 Bottom Navigation — المساعد

| التبويب | المحتوى |
|---|---|
| **الرئيسية** | رئيسية موظف: المهام، حجوزات اليوم، وصول ومغادرة، عهدة نقدية، إشعارات |
| باقي التبويبات | تظهر **حسب الصلاحيات** بس (حجوزات، شقق، تقويم...) |
| **المزيد** | تبديل جهة العمل، الحساب، الإعدادات |

### 5.3 قائمة الشاشات

**Auth & Onboarding**
- Splash
- دخول **بالإيميل + كلمة السر** بس (مفيش دخول بالهاتف ولا SMS)
- تسجيل جديد: الاسم، الإيميل، كلمة السر، **رقم الهاتف (مصري)**، «الرقم ده عليه واتساب؟»، ولو لأ **رقم واتساب اختياري**
- تأكيد الإيميل والهاتف مع بعض **بكود 6 أرقام على الإيميل**
- نسيت كلمة السر (بكود 6 أرقام، **من غير روابط**)
- اختيار نوع الحساب: مالك فردي / مكتب
- رفع مستندات التحقق (هوية، إثبات ملكية أو تفويض، سجل تجاري للمكتب)
- حالة الاعتماد: Pending / Approved / Rejected للتصحيح
- قبول دعوة موظف
- Workspace Switcher

**Dashboard**
- رئيسية المالك: طلبات جديدة بعدّاد المهلة، حجوزات قادمة وجارية، حالة الشقق، ملخص مالي، روابط سريعة
- رئيسية المساعد

**Properties**
- قائمة الشقق بحالاتها: Draft / Submitted / Published / Rejected / Paused
- Wizard إضافة شقة في **6 خطوات** + Save Draft + Preview + Submit (القرار 106)
- تفاصيل شقة: النسخة المنشورة + النسخة المعدلة اللي مستنية المراجعة لو موجودة
- إيقاف مؤقت للطوارئ / إعادة تفعيل (بسبب)
- سياسات العربون والإلغاء على مستوى الشقة والمكتب، **في حدود الصلاحيات** (Master Plan 7.1)

**Calendar & Pricing**
- تقويم شامل لكل الشقق
- تقويم لكل شقة بحالاتها: متاح / مغلق يدويًا / مدفوع ومستني المالك (Hold) / مؤكد / إقامة جارية
- فتح وغلق فترات
- تعديل السعر الأساسي الثابت لليلة (بيتطبق فورًا)

**Bookings**
- قائمة بتبويبات: طلبات جديدة / مؤكدة / جارية / مكتملة / ملغاة ومرفوضة + بحث وفلاتر
- تفاصيل الحجز: المستأجر (في حدود المسموح)، التواريخ، لقطة السعر والشروط، حالة الدفع المتحققة، **الوقت المتبقي للرد**
- قبول / رفض الطلب (مع تأكيد)
- طلب إلغاء حجز مؤكد → **بيروح لـ OnAir للاعتماد**، المالك ميقدرش يلغي لوحده

**Stay Operations**
- «تم تسليم الشقة» (Check-in من جهة المالك)
- «استلمت الشقة والمفاتيح» (Check-out من جهة المالك) + حالة «المفتاح في مكان آمن»
- حالة الرصيد المتبقي بعد العربون (لازم يتسدد قبل الـ Check-in)
- التحصيل النقدي: لو مسموح للعقار وللشخص بس، والتأكيد بـ **كود بيوصل على بريد المستأجر** (المحصّل بيسجل ← المستأجر بيأكد من تطبيقه)
- عهدتي النقدية + تسليم العهدة (كامل أو جزئي) بإقرار مزدوج وكود على بريد المستلم
- مطالبة أضرار: وصف + أدلة اختيارية، ومتابعة رد المستأجر أو وساطة OnAir

**Staff** (للمالك والمدير)
- قائمة الموظفين: الحالة، آخر دخول، Online/Offline
- دعوة موظف **بالإيميل** (الموظف بيقبلها بحساب بنفس الإيميل)
- قوالب صلاحيات + تخصيص دقيق + كل الشقق أو شقق محددة
- سجل نشاط الموظف **في سياق جهة العمل دي بس**
- إيقاف مؤقت / إعادة تفعيل / إنهاء الانتساب
- **ممنوع GPS أو أي تتبع جغرافي**

**Finance — Financial Hub** (القرار 109)
- ملخص: إجمالي الحجوزات، المحصّل، المستحق المؤهل، المدفوع فعلًا، الصافي
- المستحقات والتسويات (الفرق واضح بين **eligible** و**paid**)
- الإيرادات والمصروفات + رسوم بيانية
- كشوف الحساب
- الفواتير والتقارير + تصدير PDF و Excel
- بيانات استلام التسويات (حساب بنكي / محفظة)، **لو العقد بيسمح**

**Notifications & Account**
- مركز الإشعارات داخل التطبيق
- Push عبر FCM/APNs (تسجيل وتحديث الـ device token)
- الملف الشخصي: الاسم، الإيميل، رقم الهاتف وحالة تأكيده، «عليه واتساب؟» ورقم الواتساب الاختياري؛ تغيير الرقم بكود على الإيميل
- قائمة أنواع الإشعارات اللي بتوصل التطبيق ومين بيستلمها في 7.2
- الإعدادات: **اللغة (عربي/English)**، الثيم (Light/Dark/System)، تفضيلات الإشعارات

---

## 6. قواعد العمل اللي التطبيق لازم يحترمها

> دي قواعد معتمدة من الـ Master Plan. التطبيق بيعرضها ويحترمها، لكن **التنفيذ الحقيقي في السيرفر**.

| # | القاعدة | المرجع |
|---|---|---|
| R1 | حساب لسه Pending يقدر يعمل ملفه ومسودات شقق، لكن **ميقدرش ينشر ولا يستقبل حجوزات** | 2.3, AC-002 |
| R2 | الشقة متتنشرش غير بعد اعتماد الحساب **واعتماد الشقة نفسها** | 3.1, AC-003 |
| R3 | تعديل جوهري (وصف/صور/موقع/مواصفات) بيعمل نسخة جديدة للمراجعة، والنسخة القديمة تفضل منشورة | 3.1, AC-008 |
| R4 | السعر الأساسي والتوافر بيتطبقوا **فورًا**، ومش بيغيّروا الحجوزات القائمة | 3.1, AC-009 |
| R5 | سعر ثابت لليلة، **من غير** أسعار حسب اليوم أو الموسم | 3.4 |
| R6 | المالك **مبيشوفش ولا بيعدّل** هامش OnAir، بيدير سعره الأساسي بس | 3.4 |
| R7 | ميقدرش يفتح فترة متعارضة مع حجز مؤكد أو Hold نشط | 3.5 |
| R8 | الإيقاف الطارئ **مبيلغيش** الحجوزات المؤكدة | 3.1, AC-011 |
| R9 | الرد على الطلب في **24 ساعة** من تأكيد الدفع، و**مفيش قبول بعد انتهاء المهلة** | 5.2 |
| R10 | المالك **ميقدرش يلغي حجز مؤكد لوحده**، بيطلب من OnAir | 7.2, AC-035 |
| R11 | Check-in محتاج تأكيد الطرفين + سداد الباقي، **من غير OTP وصور إلزامية** | 6.1, AC-025/026 |
| R12 | استحقاق المالك بيبدأ بعد **Check-in موثق** | 6.1, AC-028 |
| R13 | التحصيل النقدي للعقار والشخص المخوّل بس، وبكود على بريد المستأجر | 8.3, AC-037 |
| R14 | تسليم العهدة ممكن يبقى جزئي، وكل عملية متسجلة | 8.3, AC-039 |
| R15 | **مفيش خصم تلقائي** للأضرار من غير اتفاق أو قرار OnAir | 6.4 |
| R16 | عزل كامل بين جهات العمل، وموظف مكتب A ميشوفش أي حاجة من مكتب B | 2.2, AC-004 |
| R17 | إيقاف الموظف بيوقّف صلاحياته **فورًا**، ومبيأثرش على شغله مع جهات تانية | 2.4, AC-005 |
| R18 | **مفيش GPS** ولا تتبع موقع للموظفين | 1.2, 2.4 |
| R19 | **مفيش شات مباشر** مع المستأجر | 4.6, AC-047 |
| R20 | الدخول بالإيميل + كلمة السر، أرقام مصرية بس (+20) للهاتف والواتساب، **مفيش SMS**، والجلسة بتخلص بعد **30 يوم** من غير استخدام | 2.3, 16.1 |

---

## 7. العقود المطلوبة من الـ Backend لتطبيقنا [معدّل — 28 أكتوبر 2026]

> الأسماء النهائية من Backend Master Plan القسم 12. الجداول والصلاحيات في 2.5.

### 7.1 الدوال

| المجال | قراءة | أوامر (كتابة) |
|---|---|---|
| Auth | الجلسة، `common_get_my_context` | `auth.signUp` (بالبريد + كلمة المرور + الهاتف + الواتساب)، `verifyOtp` (كود البريد)، `signInWithPassword`، `resetPasswordForEmail`، `signOut`، `common_request_phone_change` + `common_verify_otp` |
| Workspaces | `common_get_my_context` (جهاتي وصلاحياتي في كل جهة) | `partner_create_workspace`, `partner_update_workspace`, `common_accept_invite` |
| Verification | حالة الاعتماد، المستندات | `partner_add_verification_document` (رفع خاص)، `partner_submit_verification`، `partner_set_payout_method` |
| Properties | `partner_list_properties`, `partner_get_property` | `partner_create_property`, `partner_save_property_draft`, `partner_submit_property`, `partner_pause_property`, `partner_resume_property`, `partner_archive_property` |
| Policies | `partner_get_booking_policies` | `partner_set_booking_policy` |
| Availability | `partner_get_calendar` | `partner_block_dates`, `partner_unblock_dates`, `partner_set_base_price` |
| Bookings | `partner_list_bookings`, `partner_get_booking` (+ Timeline) | `partner_respond_booking`, `partner_request_booking_cancellation` |
| Stays | ضمن `partner_get_booking` | `partner_confirm_handover`, `partner_confirm_checkout` |
| Cash | `partner_my_custody` | `partner_record_cash_collection`, `partner_request_cash_handover`, `partner_confirm_cash_handover` |
| Damage | ضمن `partner_get_booking` | `partner_open_damage_claim` |
| Staff | `partner_list_members`, `partner_member_activity` | `partner_invite_member`, `partner_update_member`, `partner_set_member_status`, `partner_revoke_invite` |
| Dashboard | `partner_dashboard` | — |
| Finance | `partner_finance_summary`, `partner_list_payables`, `partner_list_settlements`, `partner_statement` | Node `POST /v1/exports` |
| Support | `common_list_my_support_cases`, `common_get_support_case` | `common_create_support_case`, `common_reply_support_case` |
| Notifications | `common_list_notifications(workspace_id)`, `common_unread_count` | `common_mark_notifications_read`, `common_register_device(app='partner')`, `common_set_notification_preferences` |

**متفق عليه في الـ Backend Master Plan:**
- حالات الحجز (7.3) وحالات العقار (6.1) ونسخه (6.2).
- أكواد الأخطاء (القسم 11)، مثلًا `BOOKING_RESPONSE_EXPIRED`، `PERMISSION_DENIED`، `DATES_LOCKED`، `COLLECTOR_NOT_AUTHORIZED`، `WORKSPACE_NOT_APPROVED`.
- مفاتيح الصلاحيات وقوالبها (2.2 و2.3).
- المبالغ `bigint` بالقرش + `currency`، والتواريخ UTC ISO-8601، وتواريخ الإقامة `date` بنطاق `[check_in, check_out)`.

### 7.2 الإشعارات اللي بتوصل تطبيقنا (`audience = partner`)

> نظام موحد مع تطبيق المستأجر ولوحة الإدارة (Backend Master Plan 9). الإشعار بيوصل **لأعضاء الجهة اللي معاهم الصلاحية المكتوبة والشقة مخصصة لهم** (والـ Principal دايمًا)، والتطبيق بيعرضه في سياق الجهة بتاعته (`workspace_id`). **IA** = مركز الإشعارات، **PU** = Push، **EM** = بريد. **مفيش SMS.**

| النوع | الحدث | بيوصل لمين (الصلاحية) | القنوات |
|---|---|---|---|
| `booking.request_received` | طلب حجز مدفوع ينتظر الرد | `bookings.respond` | IA + PU + EM (critical) |
| `booking.response_reminder` | قرب انتهاء مهلة الـ 24 ساعة | `bookings.respond` | IA + PU + EM |
| `booking.confirmed` / `booking.rejected` | تم القبول/الرفض (من التطبيق أو هاتفيًا عبر الدعم) | `bookings.view` | IA + PU (القبول) / IA (الرفض) |
| `booking.expired` | انتهت المهلة بدون رد | `bookings.respond` | IA + PU |
| `booking.cancelled_by_guest` / `booking.cancelled_by_platform` | إلغاء الحجز | `bookings.view` | IA + PU |
| `booking.no_show_recorded` / `booking.reopened` | عدم حضور / إعادة فتح | `bookings.view` | IA + PU |
| `property.submitted` / `property.revision_submitted` | زميل أرسل شقة/نسخة للمراجعة | `properties.manage` | IA |
| `property.approved` / `property.rejected` | قرار OnAir على الشقة | `properties.manage` | IA + PU + EM |
| `property.revision_approved` / `property.revision_rejected` | قرار النسخة المعدلة | `properties.manage` | IA + PU |
| `property.paused_by_platform` / `property.resumed_by_platform` | إيقاف/تفعيل إداري | `properties.manage` | IA + PU + EM |
| `property.cash_collectors_changed` | تغيير المحصّلين | `workspace.manage` + الأشخاص المعنيين | IA (+ PU) |
| `partner.verification_approved` / `partner.verification_rejected` | قرار اعتماد الجهة | `workspace.manage` | IA + PU + EM |
| `partner.suspended` / `partner.reactivated` | إيقاف/تفعيل الجهة | كل الأعضاء | IA + PU + EM |
| `invite.received` / `invite.accepted` | دعوة / قبولها | المدعو / `staff.manage` | EM (+IA+PU) / IA |
| `member.permissions_changed`, `member.suspended`, `member.reactivated`, `member.ended` | تغييرات على الموظف | الموظف نفسه | IA + PU (+ EM للإيقاف/الإنهاء) |
| `payment.remaining_paid` | المستأجر سدد المتبقي | `stays.handover` | IA + PU |
| `cash.payment_confirmed` | المستأجر أكد التحصيل النقدي | المحصّل + `finance.view` | IA + PU / IA |
| `cash.handover_requested` / `cash.handover_confirmed` | طلب/تأكيد تسليم عهدة | المستلم / المسلِّم | IA + PU |
| `stay.checkin_reminder` / `stay.checkout_reminder` | تذكير بالوصول/المغادرة | `stays.handover` | IA + PU |
| `stay.guest_checkin_confirmed` / `stay.guest_checkout_confirmed` | المستأجر أكد الاستلام/المغادرة | `stays.handover` | IA + PU |
| `stay.checked_in` / `stay.completed` | بدأت/اكتملت الإقامة | `bookings.view` | IA |
| `damage.guest_accepted` / `damage.guest_disputed` / `damage.resolved` | رد المستأجر / قرار الوساطة | `damage.manage` | IA + PU |
| `settlement.paid` / `settlement.verified` | تسوية مدفوعة / متأكدة | `finance.view` | IA + PU + EM / IA |
| `review.approved` | تقييم جديد منشور على شقة | `properties.manage` | IA |
| `support.staff_replied` / `support.case_resolved` | رد OnAir على حالة الجهة | فاتح الحالة | IA + PU |
| `account.phone_changed` / `account.password_changed` | تغيير بيانات الأمان | المستخدم | IA + EM |

- لما المستخدم يبدّل جهة العمل، العداد والقائمة بيتفلتروا بالجهة النشطة، مع مؤشر لإشعارات الجهات التانية.
- الأنواع الخاصة بالحجز والفلوس **إلزامية** (الـ Push بتاعها مبيتقفلش).

## 8. مراحل التنفيذ

> متوافقة مع مراحل الـ Master Plan (17): Foundation ← Core ← Pilot ← Scale.

### M0 — تجهيز المشروع (Foundation)
- هيكل المجلدات والحزم والـ Lints
- Flavors: Staging / Production
- **Design System:** الـ Tokens (ألوان، خط Cairo، مسافات) + Light/Dark Theme + المكونات الأساسية
- الترجمة: عربي افتراضي + إنجليزي + RTL/LTR + تغيير اللغة من الإعدادات
- `core/`: الشبكة، الجلسة، الأخطاء، Money، التواريخ
- Router + Guards
- طبقة الـ Mock
- CI: `flutter analyze` + `flutter test`

**تخلص لما:** التطبيق يفتح بالثيمين واللغتين، والمكونات الأساسية جاهزة، والـ CI شغال.

### M1 — الدخول وجهات العمل (Foundation · P0)
- Auth كامل (إيميل + كلمة سر، تسجيل بالهاتف والواتساب، كود 6 أرقام على الإيميل للتأكيد والاستعادة وتغيير الرقم)
- اختيار نوع الحساب + رفع مستندات التحقق + شاشة حالة الاعتماد
- قبول دعوة موظف + Workspace Switcher
- Shell التنقل للمالك وللمساعد حسب الصلاحيات

**تخلص لما:** مالك ومكتب وموظف يدخلوا كل واحد بدوره الصح، وتغيير جهة العمل بيعزل البيانات (AC-002، AC-004).

### M2 — العقارات (Core · P0)
- قائمة الشقق + Wizard الـ 6 خطوات + Draft + Preview + Submit
- رفع الصور (ضغط + Signed upload)
- النسخ المعدلة + الإيقاف الطارئ
- سياسات العربون والإلغاء

**تخلص لما:** AC-003، AC-008، AC-011.

### M3 — الأسعار والتقويم (Core · P0)
- تقويم كل شقة بالحالات + فتح وغلق الفترات + السعر الأساسي
- التقويم الشامل

**تخلص لما:** AC-009 + منع فتح فترة متعارضة مع Hold أو حجز مؤكد.

### M4 — الحجوزات ورد المالك (Core · P0)
- قائمة الحجوزات + التفاصيل + عدّاد الـ 24 ساعة
- قبول / رفض + التعامل مع انتهاء المهلة
- FCM/APNs + مركز الإشعارات
- طلب إلغاء حجز مؤكد

**تخلص لما:** AC-019، AC-020، AC-021، AC-024 (من جهة المالك)، AC-035.

### M5 — عمليات الإقامة (Core · P0 قبل أول إقامة)
- Check-in / Check-out من جهة المالك + حالة الرصيد المتبقي
- التحصيل النقدي + عهدتي + تسليم العهدة
- مطالبات الأضرار

**تخلص لما:** AC-025، AC-026، AC-027، AC-036، AC-037، AC-038، AC-039.

### M6 — الرئيسية والموظفين (Core / P1)
- Dashboard المالك الكامل + رئيسية المساعد
- مركز الموظفين: دعوات، قوالب صلاحيات، شقق مخصصة، نشاط، إيقاف/تفعيل/إنهاء

**تخلص لما:** AC-005، AC-007 (التطبيق بيتعامل صح مع رفض السيرفر).

### M7 — Financial Hub (P1 → P2)
- الملخص + المستحقات (eligible / paid) + التسويات + الكشوف
- الرسوم البيانية
- التصدير PDF / Excel

**تخلص لما:** AC-040 من جهة المالك + الأرقام بتطابق ردود السيرفر.

### M8 — التجهيز للـ Pilot
- حالات Loading / Empty / Error / Offline في كل الشاشات
- Accessibility: تباين، أحجام خط متغيرة، أهداف لمس، Screen reader
- اختبارات Integration للسيناريوهات الأساسية
- تجهيز النشر على المتاجر (أيقونات، Splash، صلاحيات، Privacy)

---

## 9. الاختبارات

| النوع | التغطية |
|---|---|
| **Unit** | كل Cubit بـ `bloc_test`، الـ Repositories، Money والتواريخ وحساب الليالي |
| **Widget** | مكونات الـ Design System، الشاشات الأساسية بالحالات (Loading/Error/Empty/Success)، RTL و LTR |
| **Integration** | الدخول ← تغيير جهة العمل ← إضافة شقة ← قبول طلب ← Check-in ← Check-out |
| **Permissions** | المساعد مبيشوفش غير المسموح له، والتطبيق بيعرض رسالة صح لما السيرفر يرجّع 403 |
| **Contract** | الـ Mock والـ Remote بيرجعوا نفس الشكل (اختبار على عينات العقد) |

**Definition of Done لكل Feature** (من Master Plan 20.5):
- مطابقة للقرارات وقواعد العزل
- حالات Loading / Error / Empty / Success
- RTL + الترجمتين
- Light + Dark
- اختبارات Unit/Widget ناجحة
- مفيش أسرار في الكود
- تحديث الملف ده لو اتحسم أي تفصيل أثناء التنفيذ

---

## 10. التنسيق مع باقي الفريق

- **Design System واحد بالمواصفات، مش بالكود:** تطبيق المستأجر وتطبيقنا بيطبقوا نفس [UI_UX_DESIGN_SYSTEM.md](UI_UX_DESIGN_SYSTEM.md). أي تعديل في الـ Tokens يتعمل في الملف ده الأول ويتبلّغ للفريق.
- **العقود أولًا:** أي Feature محتاجة Endpoint جديد، العقد بتاعه يتكتب ويتراجع قبل الشاشة.
- **أسماء الحالات وأكواد الأخطاء** جاية من الـ Backend، وممنوع نخترع أسماء محلية مختلفة.
- **التوافق مع الإصدارات القديمة:** أي تغيير في عقد لازم ميكسرش نسخة التطبيق المنشورة.
- **مزامنة دورية** بين التلاتة لمراجعة العقود والـ Migrations الجديدة.

---

## 11. نقاط مفتوحة

| # | النقطة | مين يحسمها |
|---|---|---|
| O1 | ~~Backend واحد مشترك~~ **اتحسم:** حساب Supabase واحد وداتابيز مشتركة (القسم 2). والجداول والصلاحيات والدوال اتحسمت في [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md) (28 أكتوبر 2026). الباقي: الموافقة على قواعد 2.3 | الفريق كله |
| O2 | قناة تواصل المالك مع دعم OnAir من جوه التطبيق (زرار اتصال / تذكرة / مفيش) | صاحب المنتج |
| O3 | العهدة النقدية لموظف المكتب بتتسلم لمين: المدير، OnAir، أو الاتنين حسب الحالة | صاحب المنتج + Admin |
| O4 | القائمة النهائية لمفاتيح الصلاحيات وقوالبها الجاهزة | الفريق (في المرحلة صفر) |
| O5 | تفاصيل الشاشات من Figma | التصميم (الوظائف مش مستنياها) |
| O6 | أداة الـ Crash reporting والـ Analytics | الفريق |
| O7 | مولّد الـ API Client النهائي | الفريق (مع اختيار شكل العقود) |
