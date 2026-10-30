# OnAir Admin Web — خطة الجزء الخاص بلوحة الإدارة

> **المرجع الأعلى:** `docs/OnAir Master Plan.md` (عند أي تعارض، الـ Master Plan هو الأصح).  
> **المرجع البصري:** `docs/UI_UX_DESIGN_SYSTEM.md`.  
> **الـ Backend الموحد:** [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md) — **المرجع الوحيد** لأسماء الجداول والأعمدة والحالات والصلاحيات والدوال والإشعارات (حل محل `docs/shared-backend/REGISTRY.md` و`SHARED_BACKEND_PLAN.md` و`NOTIFICATIONS.md`؛ أي اسم فيهم مختلف، اسم الـ Backend Master Plan هو اللي يمشي).  
> **الغرض:** تحديد نطاق لوحة الإدارة وترتيب العمل قبل البدء بـ GitHub Spec Kit، بحيث تصبح كل فقرة في القسم 7 مدخلًا جاهزًا لأمر `/speckit-specify`.  
> **تاريخ:** 26 أكتوبر 2026 — **آخر تحديث:** 28 أكتوبر 2026 (الـ Backend الموحد: جداول اللوحة وصلاحياتها في 5.4، الإشعارات الموحدة، إلغاء SMS نهائيًا، كود دخول الموظفين في `private.otp_challenges`)

---

## 1. نطاق الجزء الخاص بي

| البند | القيمة |
|---|---|
| المنتج | **OnAir Admin Web** (المنتج الثالث في 1.3 من الـ Master Plan) |
| التقنية المعتمدة | **Next.js + React + TypeScript** (القرار 117) |
| المستخدمون | Super Admin، Admin، Customer Support، Finance، Internal/Field Staff |
| مبدأ الواجهة | موقع واحد + Sidebar حسب الصلاحيات؛ لا تطبيق منفصل لكل دور (10.1) |
| الربط | Supabase واحد مشترك مع تطبيقَي Flutter؛ **الـ Backend هو نقطة الربط الوحيدة** ولا يوجد كود مشترك بين التطبيقات (13.3) |

### 1.1 ماذا يعني «ERP» في سياق OnAir؟

الكلمة واسعة؛ الـ Master Plan يحدد ما المقصود بها بالضبط ويحذّر من التعقيد غير اللازم (0.3، 1.2-6):

| ما طلبته | ما يقابله في الـ Master Plan | ملاحظة نطاق |
|---|---|---|
| **الموظفين** | حسابات الإدارة الداخلية + الصلاحيات والتفويض (2.5) + My Tasks (10.7) | **ليس** HR كامل: لا رواتب، لا حضور وانصراف، لا GPS، لا صور إثبات. إضافتها تحتاج قرار منتج جديد |
| **الإيرادات** | Finance & Accounting (8.5، 8.6) | الإيراد = **الهامش المكتسب بعد Check-out** من الدفتر المحاسبي، وليس مجموع المدفوعات (8.1، AC-052) |
| **العملاء** | Users & Partners ← تبويب Guests (10.5) + Customer Support (10.6) | لا محادثة مباشرة مستأجر ↔ مالك (4.6) |
| **أصحاب العقارات** | Users & Partners ← Individual Owners / Offices (10.5) + اعتماد الشركاء (2.3) + Owner Settlements (8.4) | موظفو المالك/المكتب يُدارون من تطبيق المالك، والإدارة تراهم للقراءة فقط |
| (ضمنيًا) | Bookings (10.3)، Properties (10.4)، Dashboard (10.2)، Settings (10.8) | هذه قلب التشغيل ولا تعمل الأقسام الأخرى بدونها |

---

## 2. ملاحظات حرجة قبل البدء

1. **المستودع الحالي Vite + JavaScript عادي، والمعتمد Next.js + TypeScript.** الـ starter الموجود (`src/main.js`, `counter.js`) لا يُبنى عليه؛ يُعاد إنشاء المشروع بـ Next.js في أول Spec (001). مجلدا `.specify/` و`docs/` يبقيان كما هما.
2. **الـ Backend مشترك (حُسم — القرار D2):** مستودع `onair-backend` واحد على حساب `MostafaTaha418`، وبيتنفذ بالكامل حسب [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md). اللوحة بتنادي `admin_*` و`common_*` بس. المستودع ده **مفيهوش أي SQL أو Migration**.
3. **ممنوع `service_role` في المستودع ده خالص** — لا في المتصفح ولا في سيرفر Next.js (13.4، Backend Master Plan B7). كل الطلبات بجلسة الموظف نفسه (JWT بتاعه). **مفيش كتابة مباشرة في أي جدول**: كل كتابة عن طريق دالة `admin_*` / `common_*` أو مسار في خدمة Node `integrations-service`. إخفاء الزر في الواجهة ليس حماية (AC-007).
4. **دخول الإدارة = كلمة مرور + كود 6 أرقام على الإيميل في كل دخول** (2.5، AC-006 — القرار D3). **مفيش SMS في المنصة كلها.** التنفيذ (Backend Master Plan 5.2 و12):
   - بعد `signInWithPassword` اللوحة بتنادي `admin_start_login_challenge()` ← `challenge_id` مربوط بجلسة Supabase الحالية (`session_id`) في `private.otp_challenges` (`purpose = staff_login`).
   - `POST /v1/otp/send {challenge_id}` في خدمة Node ← الكود بيتبعت بـ Resend (الكود hash بس، صلاحية 10 دقايق، 5 محاولات، إعادة إرسال كل 60 ثانية — قيم `otp_*` في `platform_settings`).
   - `common_verify_otp(challenge_id, code)` ← الجلسة تبقى متحقق منها.
   - `private.has_platform_permission` بتشترط `private.staff_session_verified()`؛ من غيرها أي دالة `admin_*` بترجع `STAFF_LOGIN_CODE_REQUIRED`. مفيش جدول `admin_sessions` ولا `staff_login_challenges`.
5. **التواريخ:** التخزين UTC والعرض بتوقيت `Africa/Cairo`، والانتباه لحساب الليالي عند منتصف الليل (14.6-7).
6. **المال:** لا حسابات مالية في الواجهة؛ كل الأرقام تأتي محسوبة من الخادم/الدفتر. الواجهة تعرض فقط، وتستخدم نوع Money موحد (قروش كأعداد صحيحة أو decimal من الخادم) — لا `float`.

---

## 3. الحزمة التقنية المقترحة لـ Admin Web

> [تطبيق مقترح] — قابلة للتعديل في `/speckit-plan` دون إعادة فتح قرارات المنتج.

| الطبقة | الاختيار | السبب |
|---|---|---|
| Framework | Next.js (أحدث إصدار مستقر) — App Router، TypeScript `strict` | قرار 117 |
| Supabase | `@supabase/supabase-js` + `@supabase/ssr` | جلسة عبر cookies وحماية المسارات من الـ middleware |
| أنواع البيانات | `supabase gen types typescript` من مستودع الـ Backend | الكود المولّد لا يُعدَّل يدويًا (13.3) |
| جلب البيانات | TanStack Query | Cache، إعادة المحاولة، Optimistic حيث يصح، Realtime invalidation |
| الجداول | TanStack Table | كل الأقسام تقريبًا قوائم مع بحث وفلاتر وتبويبات |
| النماذج | React Hook Form + Zod | تحقق موحد ورسائل أخطاء عربية |
| UI | Tailwind CSS + مكونات shadcn/ui (Radix) | تحكم كامل في الـ tokens، و logical properties (`ms-*`/`me-*`) للـ RTL |
| الرسوم البيانية | Recharts أو Apache ECharts | Dashboard + Financial Overview |
| i18n / RTL | next-intl، العربية افتراضيًا و`dir="rtl"`، مع تجهيز الإنجليزية | 12.2 |
| التواريخ | date-fns + date-fns-tz | UTC ↔ Cairo |
| الاختبارات | Vitest + Testing Library، Playwright + axe للـ E2E والوصول، Mock repositories في الذاكرة | DoD في 20.5 |
| التصدير | توليد PDF/Excel في الخادم (Node service) | لا تُبنى التقارير المالية من بيانات المتصفح |
| الاستضافة | Vercel أو أي Managed Cloud — [يُحسم أثناء التنفيذ] | 13.1 |

### 3.1 هيكل المجلدات المقترح

```text
dashbord-onair/
├── docs/                      # Master Plan + Design System + هذه الخطة
├── specs/                     # مخرجات Spec Kit (001-…, 002-…)
├── src/
│   ├── app/
│   │   ├── (auth)/login, otp
│   │   └── (dashboard)/
│   │       ├── page.tsx                 # Dashboard
│   │       ├── bookings/  properties/  users/  support/  tasks/
│   │       ├── finance/   accounting/  reviews/  staff/  settings/  audit/
│   ├── features/<module>/     # api (queries/mutations) + components + schemas لكل قسم
│   ├── components/ui/         # Design System (Button, Badge, DataTable, StatusChip …)
│   ├── lib/supabase/          # clients (browser/server) + database.types.ts المولّد
│   ├── lib/auth/              # session, permissions, <Can/> guard
│   ├── lib/money.ts, dates.ts # تنسيق المال والتواريخ
│   ├── i18n/ar.json, en.json
│   └── styles/tokens.css      # ألوان UI_UX_DESIGN_SYSTEM كـ CSS variables (light/dark)
└── tests/ (unit, e2e)
```

---

## 4. هيكل اللوحة (Information Architecture)

### 4.1 الـ Sidebar

| القسم | الصفحات | مرجع |
|---|---|---|
| **Dashboard** | 6 KPIs تشغيلية + 6 مالية، رسوم، «تحتاج إجراء» | 10.2 |
| **Bookings** | قائمة بتبويبات حالة + تفاصيل 4 أقسام (Info / Payments / Timeline / Actions) | 10.3 |
| **Properties** | قائمة + تفاصيل + طابور المراجعة + Compare (Approved vs Proposed) | 10.4 |
| **Users & Partners** | Guests / Individual Owners / Offices + تفاصيل 5 تبويبات + اعتماد المستندات | 10.5، 2.3 |
| **Customer Support** | Inbox الحالات، صفحة الحالة، تسجيل قرار المالك الهاتفي، البدائل، النزاعات | 10.6، 7.5 |
| **My Tasks** | مهام الموظف الداخلي/الميداني | 10.7 |
| **Finance** | Overview، Collections & Payments (+ تبويب Kashier Settlements)، Cash Custody، Owner Settlements، Refund Management، Financial Transactions | 8.6 |
| **Accounting** | دليل الحسابات، القيود، دفتر الأستاذ، ميزان المراجعة، القوائم والتقارير، Exports | 8.5، 8.6 |
| **Reviews** | مراجعة تقييمات المستأجرين قبل النشر | 4.5 |
| **Internal Staff** | موظفو OnAir، الدعوات، الأدوار والصلاحيات، الإيقاف/التعطيل | 2.5 |
| **Settings** | مركز إعدادات حسب المجالات (الهامش، العربون، الإلغاء، المهلات، القنوات، الإشعارات…) | 10.8 |
| **Audit Log** | سجل who/when/what/before/after | 2.6، AC-051 |

### 4.2 مصفوفة الأدوار المبدئية

> مبدئية للعرض فقط. المصدر الحقيقي: مفاتيح الصلاحيات والقوالب في Backend Master Plan 2.2 و2.3 (`super_admin`، `admin`، `customer_support`، `finance`، `field_staff` — والموظف ممكن ياخد **أكتر من قالب** + `extra_permissions` / `revoked_permissions`). الصلاحيات الفعلية بتيجي من `common_get_my_context()` بعد الدخول، والواجهة **متحسبهاش**. فصل الأدوار بيتفحص في السيرفر، والواجهة بتعرض رسالة واضحة لـ `SEPARATION_OF_DUTIES` و`PERMISSION_DENIED`.

| القسم | Super Admin | Admin | Support | Finance | Field Staff |
|---|---|---|---|---|---|
| Dashboard | كامل | كامل | تشغيلي | مالي | — |
| Bookings | كامل | كامل | عرض + إجراءات دعم | عرض مالي | عرض محدود |
| Properties | كامل | اعتماد/رفض | عرض | — | عرض/مراجعة مسندة |
| Users & Partners | كامل | اعتماد | عرض محدود | ملخص مالي | — |
| Customer Support | كامل | كامل | كامل | عرض | — |
| My Tasks | ✓ | ✓ | ✓ | ✓ | ✓ |
| Finance / Accounting | كامل | عرض | — | كامل (مع فصل الأدوار) | — |
| Reviews | كامل | كامل | ✓ | — | — |
| Internal Staff | كامل | ضمن سقف التفويض | — | — | — |
| Settings | كامل | حسب المجال | — | المجال المالي | — |
| Audit Log | كامل | عرض | — | المالي | — |

**فصل الأدوار المالي (7.4، AC-044):** من يطلب/يعتمد الاسترداد ≠ من ينفّذه ≠ من يتحقق؛ ومنشئ القيد اليدوي ≠ معتمده. الواجهة تعكس ذلك، والخادم يفرضه.

---

## 5. التنسيق مع مطوّرَي Flutter (العقد المشترك)

ثلاثة تطبيقات على Supabase واحد = أي اختلاف في الأسماء أو الحالات يكسر الجميع. **العقد المشترك كله في [OnAir Backend Master Plan.md](OnAir%20Backend%20Master%20Plan.md)** (28 أكتوبر 2026)، وأي اسم في القسم 14 القديم من الـ Master Plan أو في REGISTRY مختلف عنه، اسم الـ Backend Master Plan هو اللي يمشي:

| البند | المرجع |
|---|---|
| **Schema** | Backend Master Plan الأقسام 4–10، وجدول الأسماء القديمة ← البديل في القسم 16 |
| **حالات الحجز** | Backend Master Plan 7.3: `payment_pending`, `payment_verifying`, `awaiting_owner`, `payment_conflict`, `confirmed`, `checked_in`, `completed`, `rejected`, `expired`, `cancelled`, `no_show`, `abandoned` + حالات الاسترداد **منفصلة** في `refunds` (8.3) |
| **حالات العقار** | `properties.status`: `draft`, `in_review`, `published`, `rejected`, `paused`, `archived` (+ `paused_by_scope`) — ونسخ الشقة `property_versions.status`: `draft`, `submitted`, `approved`, `rejected`, `superseded` |
| **RPC / Commands** | Backend Master Plan 12: اللوحة بتستدعي `admin_*` و `common_*` بس، **وممنوع** `guest_*` و `partner_*`. أكواد الأخطاء في القسم 11 |
| **الصلاحيات** | Backend Master Plan 2.2 (`scope = platform`). ممنوع اختراع مفتاح |
| **الإشعارات** | Backend Master Plan 9 — اللوحة مبتبعتش إشعارات بنفسها؛ الخادم بيولّدها مع كل حدث |
| **RLS** | من يقرأ/يكتب ماذا؛ اختبار عزل Workspaces (AC-004) |
| **Storage** | Buckets عامة لصور الإعلانات وخاصة للمستندات + روابط موقعة مؤقتة (16.2) |
| **Realtime** | الجداول/القنوات التي تُبث (طلبات حجز جديدة، حالات دعم) |
| **Seed** | بيانات Staging موحدة (مستأجرين، ملاك، مكاتب، عقارات، حجوزات بكل الحالات) |
| **إدارة التغيير** | أي تغيير يؤثر على أكثر من تطبيق يُتفق عليه أولًا، مع توافق رجعي للإصدارات المنشورة |

### 5.1 ما تنتجه لوحة الإدارة ويعتمد عليه تطبيقا Flutter

- اعتماد حساب المالك/المكتب والعقار ← بدونه لا يظهر إعلان في تطبيق المستأجر (AC-002، AC-003).
- إعدادات الهامش والعربون والإلغاء والمهلات ← تدخل في حساب السعر واللقطات.
- مراجعة التقييمات ← بدونها لا يظهر تقييم.
- تسجيل قرار المالك الهاتفي ← يغيّر حالة الحجز في التطبيقين.

**النتيجة:** أقسام الاعتماد (Partners + Properties) لها أولوية مبكرة لأن فريق Flutter يحتاجها لاختبار رحلته كاملة.

### 5.2 قواعد الشغل على الداتابيز المشتركة [مهم]

**الخطر:** 3 أشخاص، كل واحد معاه Claude، بيعدّلوا في نفس الداتابيز. من غير قواعد، ممكن واحد يمسح أو يغيّر حاجة شغّالة عند التاني من غير ما يعرف، ومحدش هيعرف مين غيّر إيه.

> القواعد الملزمة للـ Backend في Backend Master Plan (القسم 1.1 المستودع، 3 القواعد العامة، 13 ترتيب الـ Migrations). الملخص تحت للتذكير بس؛ عند أي اختلاف، ملف الـ Backend هو اللي يمشي.

**مصدر التعديل والتاريخ**

- كل تعديل في الداتابيز يبقى **Migration file**، مش من الـ Dashboard أو الـ SQL Editor مباشرة.
- الملفات في مستودع الـ Backend المشترك `onair-backend` جوه `supabase/migrations/` (القرار D2).
- كده يبقى عندنا تاريخ لكل تغيير، ونقدر نبني Production بنفس الشكل بالظبط.
- لو حد عدّل حاجة من الـ Dashboard بالغلط: يتحول الفرق لـ Migration بـ `supabase db diff` قبل أي حاجة تانية.

**دورة الـ Migration**

1. `git pull` قبل ما تكتب Migration جديدة، عشان ملفك يبقى بعد ملفات زمايلك في الترتيب ومتعملوش نفس التعديل مرتين.
2. التجربة على **Supabase محلي** الأول (`supabase start` على Docker، و`supabase db reset` يطبّق كل الـ Migrations والـ seed من الأول).
3. Pull Request يراجعه **شخص تاني** غير اللي كتبه، والـ CI يشغّل الـ Migrations واختبارات الـ RLS على قاعدة نظيفة.
4. بعد الدمج: الرفع على **Staging** بـ `supabase db push` من **الـ CI فقط** (مش من جهاز حد)، عشان يبقى فيه طريق واحد للرفع.
5. **Production محدش يلمسه مباشرة.** الرفع عليه بقرار من التلاتة، وبعد ما الشغل يتجرب على Staging.

> لو زميلك دمج Migration تاريخها أحدث من ملفك اللي لسه في PR، غيّر اسم ملفك لتاريخ جديد قبل الدمج (`supabase migration new` ثم انقل المحتوى)، عشان الترتيب على Staging يفضل صحيح.

**التعديلات تبقى إضافة مش تكسير**

- ممنوع `DROP` لجدول أو عمود، أو تغيير اسم، أو تغيير نوع عمود مستخدم، **من غير اتفاق**.
- لو محتاج تغيّر حاجة: ضيف الجديد الأول ← انقل التطبيقات عليه ← وبعدين امسح القديم في Migration لاحقة (expand → migrate → contract)، لأن نسخ الموبايل القديمة بتفضل منشورة عند الناس.
- أي تغيير في الشكل يتسجل في `OnAir Backend Master Plan.md` (الجدول نفسه، والدالة في القسم 12) في نفس الـ PR.
- محتاج حاجة في جدول أو دالة مش بتاعتك أو مشتركة؟ **متعدلهاش لوحدك** — اتفق مع التلاتة الأول واشتغل بـ Mock لحد ما تتنفذ.

**Claude والأدوات التانية**

- لو حد ربط **Supabase MCP** بالـ Claude بتاعه: يبقى **Read-only** (`--read-only`) ومحصور على مشروع الـ Staging بس، والكتابة عن طريق ملفات Migration فقط.
- ممنوع تخلي Claude يشغّل SQL بيمسح أو بيعدّل بيانات على Staging أو Production من غير ما تراجع الأمر بنفسك.
- مفتاح `service_role` ميتحطش في أي تطبيق، ولا في ملف بيترفع على Git (القسم 2-3).

**الأمان والعقد**

- **RLS على كل جدول من أول يوم.** الجدول الجديد ميترفعش من غير Policies، عشان كل تطبيق يشوف المسموح له بس. الـ CI يرفض أي Migration بتسيب جدول في `public` من غير RLS.
- **الأنواع (Types):** كل تطبيق بيولّد الأنواع بتاعته من الداتابيز أو من العقد (`supabase gen types` للوحة الإدارة، والـ models في Flutter من `contracts/`)، ومحدش يكتبها بإيده.
- **Seed data:** ملف `supabase/seed.sql` مشترك فيه بيانات تجربة (مستأجر، مالك، مكتب، موظف، شقق، حجوزات بحالات مختلفة)، عشان كل واحد يجرب على نفس البيانات. كل واحد بيعدّل الجزء بتاعه بس (`-- [admin]` للوحة)، ومحتوى الـ seed في Backend Master Plan القسم 14.

### 5.3 شغل مطوّر الإدارة في مستودع الـ Backend

الـ Backend كله بيتنفذ حسب ترتيب Migrations القسم 13 في Backend Master Plan. اللي يخص اللوحة بشكل مباشر:

| المهمة | مرجع Backend Master Plan |
|---|---|
| مراجعة الجداول والحالات والإشعارات ومسارات فتح الإشعارات في اللوحة | 4–10، 9.7 |
| جزء `-- [admin]` في `seed.sql` (موظفين OnAir: Super / Admin / Support / Finance / Field) | 14 |
| **CI الـ Backend** (Migrations على قاعدة نظيفة + اختبارات pgTAP + رفض جدول من غير RLS) + الرفع على Staging + فحص الـ Drift | 15، 18 |
| `common_get_my_context` + `admin_invite_staff` + `common_accept_invite` (دالة قبول واحدة لدعوات الشركاء وموظفي OnAir) | 12.1، 12.4 |
| التحقق الثاني بكود الإيميل (القرار D3): `private.otp_challenges` (`staff_login`) + `private.staff_session_verified` + `admin_start_login_challenge` + Node `/v1/otp/send` | 2.4، 5.2، 12.6 |
| دوال `admin_*` كلها وخدمة Node مسار `POST /v1/admin/refunds/{id}/execute` | 12.4، 12.6 |

### 5.4 قاعدة البيانات في Supabase — جداول اللوحة وصلاحياتها [معتمد — 28 أكتوبر 2026]

#### 5.4.1 الفكرة
- اللوحة بتقرا من **نفس قاعدة البيانات** اللي بيستخدمها تطبيق المستأجر وتطبيق المالك. مفيش جداول موظفين أو مستخدمين خاصة بالإدارة:
  - موظف OnAir = صف في `profiles` (نفس جدول المستأجرين والملاك) + صف في `workspace_members` داخل **Workspace المنصة** (`workspaces.kind = 'platform'`).
  - صلاحياته = قوالب `role_presets` (`scope = platform`) + `extra_permissions` / `revoked_permissions` على صف العضوية.
- كل دالة `admin_*` بتفحص `private.has_platform_permission(perm)` (عضوية نشطة + الصلاحية + كود الدخول متحقق للجلسة). RLS على الجداول بيستخدم نفس الدالة للقراءة.
- **مفيش كتابة مباشرة**؛ القراءة تحت RLS (أو من دوال `admin_*` للقوائم المجمعة)، والكتابة دوال `admin_*` / `common_*` أو خدمة Node.

#### 5.4.2 الجداول والصلاحية المطلوبة

| القسم في اللوحة | الجداول اللي بيقرا منها | الكتابة (الدوال) | صلاحية القراءة / الكتابة |
|---|---|---|---|
| Dashboard | تجميعات من `bookings`, `properties`, `support_cases`, `payments`, `refunds`, `owner_payables`, `journal_lines` + `cash_custody_balances` | — | `admin_dashboard_kpis` / `admin_action_queue` حسب الصلاحيات |
| Bookings | `bookings`, `booking_events`, `payments`, `refunds`, `replacement_offers`, `damage_claims`, `property_calendar_locks` | `admin_record_owner_phone_decision`, `admin_cancel_booking`, `admin_record_stay_exception`, `admin_mark_no_show`, `admin_reopen_no_show`, `admin_create_replacement_offer` | `bookings.view_all` / `bookings.record_phone_decision`, `bookings.manage` |
| Properties | `properties`, `property_versions` (للـ Compare)، `property_media`, `property_cash_collectors`, `markup_policies`, `booking_policies` | `admin_review_property_version`, `admin_pause_property`, `admin_resume_property`, `admin_set_cash_collection` | `properties.review` / `properties.suspend` |
| Users & Partners | `profiles`, `workspaces`, `workspace_members` (للقراءة)، `verification_documents`, `workspace_payout_methods` | `admin_review_workspace`, `admin_review_document`, `admin_set_workspace_status` | `users.view`, `identity_documents.view` / `partners.review` |
| Customer Support | `support_cases`, `case_messages` (+ `internal`)، `attachments`, `damage_claims` | `admin_assign_case`, `admin_reply_case`, `admin_set_case_status`, `admin_resolve_damage_claim` | `support.handle` / `support.assign` |
| Refunds | `refunds`, `payments`, `attachments` | `admin_request_refund`, `admin_approve_refund`, Node `refunds/{id}/execute`, `admin_mark_refund_executed`, `admin_verify_refund` | `refunds.request` / `.approve` / `.execute` / `.verify` (فصل أدوار) |
| Collections & Cash | `payments`, `cash_handovers`, `kashier_payouts`, `cash_custody_balances`, `financial_transactions_v` | `admin_confirm_cash_handover`, `admin_verify_kashier_payout` | `kashier.reconcile`, `cash.receive_handover`, `accounting.view` |
| Owner Settlements | `owner_payables`, `settlements`, `workspace_payout_methods` | `admin_prepare_settlement`, `admin_approve_settlement`, `admin_mark_settlement_paid`, `admin_verify_settlement` | `settlements.prepare` / `.approve` / `.execute` / `.verify` |
| Accounting | `ledger_accounts`, `journal_entries`, `journal_lines`, `trial_balance_v`, `general_ledger_v` | `admin_create_manual_journal`, `admin_approve_journal`, `admin_reverse_journal` | `accounting.view` / `accounting.post_manual`, `accounting.approve` |
| Reviews | `property_reviews` | `admin_moderate_review` | `reviews.moderate` |
| Internal Staff | `workspace_members` + `workspace_invites` (workspace المنصة)، `role_presets`, `permissions`, `audit_log` | `admin_invite_staff`, `admin_update_staff`, `admin_set_staff_status` | `platform.staff.manage` |
| My Tasks | `staff_tasks`, `staff_task_updates` | `admin_create_task`, `admin_update_task` | المسند له / `tasks.assign` |
| Settings | `platform_settings`, `app_config`, `markup_policies`, `booking_policies`, `locations`, `amenities`, `property_types`, `faq_items`, `notification_types` | `admin_update_setting`, `admin_update_app_config`, `admin_set_markup_policy`, `admin_set_booking_policy`, `admin_upsert_*`, `admin_update_notification_type` | `settings.manage` / `settings.manage_finance` |
| Audit Log | `audit_log` | — | `audit.view` |
| Notifications | `notifications` (`audience = platform`)، `notification_preferences`, `device_tokens` | `common_mark_notifications_read`, `common_set_notification_preferences`, `common_register_device(app='admin_web')` | صاحب الصف |

**مش متاحة للوحة:** `booking_quotes`, `favorites`, `notification_deliveries` (للتشخيص بـ `settings.manage` بس)، وكل جداول `private` (`otp_challenges`, `provider_webhook_events`).

#### 5.4.3 الإشعارات اللي بتوصل اللوحة (`audience = platform`)

> نظام موحد مع التطبيقين (Backend Master Plan 9). الإشعار بيوصل **لكل موظف OnAir معاه الصلاحية المسؤولة** في مركز إشعارات اللوحة (+ Web Push و Toast/صوت للأولوية `high`/`critical`). لما موظف ينفذ الإجراء، الإشعار بيتقفل عند زمايله ويظهر «اتعامل معاه بواسطة فلان».

| الحدث | النوع | بيوصل لمين (الصلاحية) |
|---|---|---|
| مالك/مكتب أرسل مستندات الاعتماد | `partner.verification_submitted` | `partners.review` |
| إضافة شقة / نسخة معدلة للمراجعة | `property.submitted` / `property.revision_submitted` | `properties.review` |
| إيقاف طارئ من المالك / إعادة تفعيل | `property.paused_by_partner` / `property.resumed_by_partner` | `properties.review` + `bookings.monitor` |
| طلب حجز مدفوع جديد | `booking.request_received` | `bookings.monitor` |
| قرب انتهاء مهلة رد المالك | `booking.response_reminder` | `support.handle` (للمتابعة الهاتفية) |
| قبول الحجز | `booking.confirmed` | `bookings.monitor` |
| رفض / انتهاء مهلة / دفع متعارض | `booking.rejected` / `booking.expired` / `booking.payment_conflict` | `support.handle` + `refunds.approve` |
| إلغاء من المستأجر | `booking.cancelled_by_guest` | `bookings.monitor` |
| المالك طلب إلغاء حجز مؤكد | `booking.owner_cancellation_requested` | `support.handle` + `bookings.manage` |
| رد المستأجر على عرض بديل | `booking.replacement_answered` | منشئ العرض + `support.handle` |
| تعذر إقرار Check-in/out | `stay.exception_requested` | `bookings.manage` |
| مطالبة ضرر / اعتراض | `damage.claim_opened` / `damage.guest_disputed` | `support.handle` |
| مراحل الاسترداد | `refund.requested` → `refund.approved` → `refund.executed` | `refunds.approve` → `refunds.execute` → `refunds.verify` |
| فشل/تأخر استرداد | `refund.failed` / `refund.overdue` | `refunds.approve` + `support.handle` |
| تسليم عهدة لـ OnAir | `cash.handover_confirmed` | `cash.receive_handover` |
| تسوية جاهزة / مدفوعة | `settlement.approved` / `settlement.paid` | `settlements.execute` / `settlements.verify` |
| دفعة Kashier / فرق | `kashier.payout_synced` / `kashier.payout_discrepancy` | `kashier.reconcile` |
| قيد يدوي ينتظر اعتماد | `journal.pending_approval` | `accounting.approve` |
| حالة دعم جديدة / رد / تخطي SLA | `support.case_created` / `support.user_replied` / `support.sla_breached` | `support.handle` / المسند له / `support.assign` |
| تقييم جديد | `review.submitted` | `reviews.moderate` |
| مهمة مسندة / قربت / اتحدثت | `task.assigned` / `task.due_soon` / `task.updated` | المسند له / المنشئ |
| دعوة موظف اتقبلت | `invite.accepted` | `platform.staff.manage` |
| تعديل إعداد حساس | `settings.changed` | `audit.view` |

- اللوحة **مبتبعتش** إشعارات بنفسها؛ كل دالة `admin_*` بتولّد إشعارات الأطراف التانية (المستأجر والمالك) تلقائيًا. مثلًا `admin_review_property_version` بتبعت `property.approved` للمالك ومساعديه المسؤولين.
- عدادات «تحتاج إجراء» في الداش بورد بتتحسب من حالة البيانات (`admin_action_queue`) مش من الإشعارات.

---

## 6. لحد ما الجداول تجهز

- كل Feature في التطبيق ليها **Repository interface** وتنفيذين: **Remote** (الحقيقي، على Supabase) و**Mock** (بيانات وهمية).
- التبديل بينهم بـ **flag في إعدادات البيئة** (في لوحة الإدارة: `NEXT_PUBLIC_DATA_SOURCE`)، فنشتغل على الشاشات من غير ما نستنى الـ Backend.
- الـ Mock لازم يلتزم **بنفس شكل العقد المتفق عليه** (نفس الأنواع والحالات وأكواد الأخطاء)، عشان التبديل يبقى من غير تعديل في الشاشات.
- في لوحة الإدارة: الـ Mock بيانات في الذاكرة ببذرة ثابتة (بدون MSW)، والـ Remote بيتضاف من Spec 002 — التفاصيل في `specs/001-admin-foundation/contracts/data-access.md`.
- كل Spec في القسم 7 يذكر صراحة **ما يحتاجه من الـ Backend** بأسماء Backend Master Plan؛ لو لسه متنفذش في `onair-backend`، الشاشة على Mock لحد ما يجهز.

---

## 7. خارطة Specs لـ Spec Kit

> الترقيم تسلسلي كما في `.specify/init-options.json`. عمود «F» يربط بحزم 20.3 في الـ Master Plan.  
> كل سطر = وصف جاهز لـ `/speckit-specify`، ثم `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`.

### المرحلة 1 — Foundation

| # | Spec | F | المحتوى | يحتاج من الـ Backend | AC |
|---|---|---|---|---|---|
| 000 | **Constitution** | — | مبادئ المستودع (القسم 8) | — | — |
| 001 | `admin-foundation` | F17, F16 | Next.js + TS، tokens الألوان والخط Cairo، light/dark، RTL/i18n، App Shell (Sidebar/Topbar)، مكونات أساسية (DataTable، Filters، StatusChip، Empty/Loading/Error، ConfirmDialog)، طبقة Repository ببيانات Mock، CI | لا شيء (يعمل على بيانات تجريبية) | — |
| 002 | `admin-auth-rbac` | F01 | دخول بكلمة مرور + كود الإيميل في كل دخول، قبول دعوة الموظف وإنشاء الحساب بنفس الإيميل المدعو (مع الهاتف المصري و«عليه واتساب؟» أو رقم واتساب اختياري)، حماية المسارات، تحميل الصلاحيات من `common_get_my_context`، Sidebar حسب الصلاحية (مفاتيح Backend Master Plan 2.2)، `<Can>`، التعامل مع `PERMISSION_DENIED` و`STAFF_LOGIN_CODE_REQUIRED` وإلغاء الجلسة والإيقاف | `workspace_members` (workspace المنصة) + `role_presets` + `permissions` + `workspace_invites`، `common_get_my_context`، `common_accept_invite`، `admin_start_login_challenge` + Node `/v1/otp/send` + `common_verify_otp`، `private.otp_challenges` | AC-006, AC-007 |
| 003 | `internal-staff-management` | F01, F13 | **الموظفين**: قائمة، دعوة بالإيميل بقالب أو أكتر، تعديل القوالب والاستثناءات (محدش يدّي صلاحية مش معاه)، إيقاف/إنهاء/إعادة تفعيل، سجل نشاط | `admin_invite_staff`, `admin_update_staff` + إشعارات `invite.*` و `member.*` + `audit_log` | AC-005 (للداخليين) |

**معيار انتهاء المرحلة:** موظف إدارة يدخل بدوره الصحيح ويرى فقط أقسامه، وطلب API غير مخول يُرفض من الخادم.

### المرحلة 2 — Core

| # | Spec | F | المحتوى | AC |
|---|---|---|---|---|
| 004 | `partners-onboarding-approvals` | F02 | **العملاء وأصحاب العقارات**: تبويبات Guests/Owners/Offices، تفاصيل 5 تبويبات، مراجعة مستندات الهوية/الملكية بروابط موقعة، اعتماد/رفض بسبب | AC-002, AC-003 |
| 005 | `property-management` | F03, F04 | قائمة العقارات، التفاصيل، طابور المراجعة، Compare بين النسخة المعتمدة والمقترحة، اعتماد/رفض، إيقاف طارئ، عرض التسعير والتوافر (قراءة) | AC-008, AC-011 |
| 006 | `booking-management` | F06 | قائمة الحجوزات وتبويبات الحالات، صفحة 4 أقسام، Timeline، عدّاد مهلة 24 ساعة، لقطة السعر والشروط | AC-014 → AC-021 (عرض) |
| 007 | `customer-support-workspace` | F07, F09 | Inbox الحالات، صفحة الحالة، سجل الاتصالات، **تسجيل قرار المالك الهاتفي**، عرض البدائل، فتح طلب استرداد، SLA | AC-022, AC-047 |
| 008 | `refund-management` | F09 | قوائم الاستردادات، اعتماد → تنفيذ → تحقق مستقل، الأدلة، منع التكرار | AC-020, AC-021, AC-042, AC-046 |
| 009 | `stay-exceptions` | F08 | استثناءات Check-in/out، No-show وإعادة الفتح في نفس اليوم، مطالبات الأضرار والوساطة | AC-025 → AC-027, AC-033 → AC-036 |
| 010 | `collections-payments` | F11 | **الإيرادات (1)**: عمليات التحصيل أونلاين ونقدًا، حالات الدفع والإثبات، تبويب Kashier Settlements (Gross/Fees/Net + تأكيد الوصول) | AC-015, AC-023, AC-041 |

### المرحلة 3 — Pilot

| # | Spec | F | المحتوى | AC |
|---|---|---|---|---|
| 011 | `operations-dashboard` | F13 | 6 KPIs تشغيلية + 6 مالية، رسوم الاتجاه وتوزيع الحالات، فلاتر زمنية ومقارنة، قوائم «تحتاج إجراء» | AC-052 |
| 012 | `cash-custody` | F11 | المحصّلون، الأرصدة، التسليم الجزئي، السجل | AC-037 → AC-039 |
| 013 | `owner-settlements` | F11 | **أصحاب العقارات (مالي)**: المستحقات eligible مقابل paid، جدول الشركاء، صفحة شريك، تنفيذ تسوية وإثباتها | AC-040 |
| 014 | `accounting-core` | F12 | **الإيرادات (2)**: دليل الحسابات، القيود (الآلية للعرض، اليدوية مع اعتماد مستقل)، دفتر الأستاذ، ميزان المراجعة | AC-043 → AC-045 |
| 015 | `settings-audit` | F13 | مركز الإعدادات حسب المجالات، تأكيد التغييرات الحساسة، سجل الإصدارات، صفحة Audit Log | AC-051 |
| 016 | `reviews-moderation` | F15 | طابور التقييمات، قبول/رفض بسبب | AC-048, AC-049 |
| 017 | `staff-tasks` | F13 | My Tasks: إسناد، أولوية، موعد، حالة، ملاحظة مختصرة | AC-050 |

### المرحلة 4 — Scale

| # | Spec | F | المحتوى |
|---|---|---|---|
| 018 | `financial-overview-reports` | F12 | Financial Overview بالرسوم الثلاث، القوائم المالية، Drilldown |
| 019 | `invoices-exports` | F12 | فواتير وكشوف وتصدير PDF/Excel (توليد في الخادم) |
| 020 | `admin-notifications` | F14 | صندوق الإشعارات (`common_list_notifications` بفلاتر الفئة والحالة)، العداد، مقروء، التفضيلات، Realtime على `notifications` + Toast وصوت لـ `high`/`critical`، «اتعامل معاه بواسطة فلان» (`resolved_by`)، مفاتيح `notif_<type>_title/body` ونص عام للنوع المجهول، الفتح حسب `entity_type`، Web Push (P1)، شاشة إدارة قنوات الأنواع (`admin_update_notification_type`) — Backend Master Plan 9 |
| 021 | `analytics` | F12 | مؤشرات الإيرادات والتكاليف والمخاطر والتسويات |

> **ملاحظة ترتيب:** يمكن تقديم 004 و005 قبل اكتمال 003 إذا احتاج فريق Flutter الاعتمادات مبكرًا؛ 003 لا يمنعهما طالما 002 جاهز.

---

## 8. مسودة مبادئ الـ Constitution لهذا المستودع

> تُمرَّر كمدخل لـ `/speckit-constitution`. مأخوذة من 20.2 في الـ Master Plan ومكيّفة للويب.

1. **Master Plan First:** لا سياسة حجز/دفع/استرداد/صلاحيات تُخترع في الواجهة؛ عند الغموض يُسجَّل `[NEEDS CLARIFICATION]` ولا يُفترض.
2. **Server Authority:** الواجهة لا تحسب مالًا ولا تمنح صلاحية ولا تغيّر حالة حساسة مباشرة؛ كل فعل حساس عبر RPC/خدمة موثوقة. لا `service_role` في أي كود يصل للمتصفح.
3. **Permission-Aware UI:** كل صفحة وزر يقرأ صلاحيات الخادم؛ الإخفاء تجربة مستخدم وليس أمانًا.
4. **Contract-Driven:** الأنواع مولّدة من الـ Backend ولا تُعدَّل يدويًا؛ أي حالة أو enum تأتي من العقد.
5. **Auditable Actions:** كل فعل حساس يطلب سببًا عند اللزوم، ويُظهر من نفّذه ومتى، ويؤكَّد قبل التنفيذ.
6. **Financial Display Integrity:** فصل واضح بين التحصيل والعهدة والذمم والهامش المكتسب والاسترداد؛ لا أرقام مالية محسوبة في المتصفح.
7. **Arabic-First RTL & Accessible:** العربية و RTL أصليان، i18n جاهز للإنجليزية، تباين جيد، دعم لوحة المفاتيح وقارئ الشاشة، حالات Loading/Empty/Error لكل شاشة.
8. **Design System Consistency:** الألوان والخط من `UI_UX_DESIGN_SYSTEM.md` كـ tokens، بكثافة معلومات مناسبة للويب، light/dark.
9. **Testable Delivery:** كل Spec مربوط بـ AC من الـ Master Plan، مع Unit لمنطق العرض و E2E للمسارات الحرجة واختبارات صلاحيات.
10. **Simplicity:** لا شاشات مكررة ولا نسخ لواجهات Kashier ولا HR غير معتمد.

---

## 9. سجل القرارات

### 9.1 قرارات محسومة (26 أكتوبر 2026)

| # | القرار | المحسوم |
|---|---|---|
| D1 | هيكل المستودعات | *(اتعدّل 28 أكتوبر 2026)* مفيش Organization. كل تطبيق في ريبو على حساب صاحبه (اللوحة: `MohamedHelmyAmara/dashboard-onair`)، و`onair-backend` هو الريبو المشترك الوحيد: `MostafaTaha418/onair-backend` (Private) والاتنين التانيين Collaborators. الـ clone بتاعه جنب ريبو اللوحة (`../onair-backend`) |
| D2 | ملكية الـ Backend | *(اتعدّل 28 أكتوبر 2026)* التلاتة بيكتبوا في `onair-backend`، كل واحد في الدومين بتاعه (اللوحة: `admin_` وجداول `owner=admin` — القسم 5.3). `core` = موافقة التلاتة. الرفع على Staging من الـ CI بس، والمرجع Backend Master Plan |
| D3 | التحقق الثاني لدخول الإدارة | **كود 6 أرقام على الإيميل** عبر Resend في أول دخول وفي كل دخول. بيتسجل على جلسة Supabase Auth في `private.otp_challenges` (`staff_login`)، و`private.has_platform_permission` بتفحصه (القسم 2-4). **مفيش SMS في المنصة كلها** — *(اتأكد واتوافق عليه من الفريق 28 أكتوبر 2026)* |
| D4 | مكان منطق العمليات الحساسة | التطبيقات تتصل بـ Supabase مباشرة تحت RLS؛ الأوامر الذرية (الحجز، الـ Hold، الصلاحيات، الاعتمادات، المال) **دوال Postgres RPC**؛ و**Node.js للتكاملات فقط** (Kashier، Resend، FCM/APNs، Cloudflare R2، عمّال الإرسال والمطابقة) — مفيش SMS |
| D5 | لغة اللوحة | العربية + RTL، وكل النصوص في ملفات ترجمة جاهزة لإضافة الإنجليزية لاحقًا |
| D6 | نطاق «الموظفين» | حسابات موظفي OnAir وأدوارهم وصلاحياتهم وإيقافهم وسجل نشاطهم ومهامهم (2.5، 10.7). **لا HR** (رواتب، حضور، إجازات) |
| D7 | الإطار | Next.js + TypeScript بدل Vite الحالي (القرار 117) |
| D8 | ضم موظفي OnAir *(28 أكتوبر 2026)* | الموظف بيتضاف بدعوة على الإيميل من شاشة الموظفين (`admin_invite_staff`) بقالب أو أكتر. الإيميل بيبعته الـ backend (إشعار `invite.received`)، مش اللوحة. الموظف بيفتح الرابط ويعمل حساب **بنفس الإيميل المدعو** وكلمة سر، وبعدها بيبقى عضو في workspace المنصة بالصلاحيات اللي اتحددت |
| D9 | فروع Git *(28 أكتوبر 2026)* | `main` ← `develop` ← `feature/NNN-<وصف>`، والـ PR على `develop` (`AGENTS.md`). فرع `develop` لسه متعملش في ريبو اللوحة |

### 9.2 قرارات تقنية مفتوحة (تُحسم في `/speckit-plan` بدون انتظار أحد)

| # | القرار | التوصية |
|---|---|---|
| T1 | مكتبة الواجهة | **حُسم في Spec 001:** Tailwind CSS 4 + shadcn/ui (Radix) — `specs/001-admin-foundation/research.md` R4 |
| T2 | استضافة اللوحة | Vercel للـ Staging مبدئيًا — يُحسم في Spec 002 |
| T3 | تصميم Figma للوحة | **حُسم في Spec 001:** نبني من tokens الـ Design System حتى يتوفر تصميم ويب |

### 9.3 مفتوحة — تحتاج صاحب المشروع

| # | القرار | لماذا يهم | يوقف |
|---|---|---|---|
| O1 | خطة Supabase المدفوعة (Pro) | انتهاء الجلسة بعد 30 يومًا دون استخدام (2.3) يحتاج إعداد inactivity timeout المتاح في Pro فقط؛ والـ Production عمومًا لا يصح على الخطة المجانية | Backend F01 |
| ~~O2~~ | ~~مزود SMS~~ | **اتلغى (28 أكتوبر 2026):** مفيش SMS في المنصة كلها؛ تأكيد الهاتف وكل الأكواد على البريد عبر Resend (Backend Master Plan B3). | — |
| ~~O3~~ | ~~مصفوفة صلاحيات الأدمن التفصيلية~~ | **اتحسم:** Backend Master Plan 2.2 و2.3 (المفاتيح والقوالب، معتمدة 28 أكتوبر 2026) | — |
| O4 | القيم الافتراضية للسياسات | الهامش، نسبة العربون، مهلة الإلغاء المجاني — لا أرقام في الـ Master Plan | 015، الـ seed |
| O5 | قدرات حساب Kashier الفعلية | تحدد شاشات التحصيل والاسترداد والتسويات | 008، 010 |
| O6 | محاسب يراجع دليل الحسابات | شرط في 8.5 | 014 |

### 9.4 مفتوحة — تحتاج اتفاق مع فريق Flutter

| # | القرار | يوقف |
|---|---|---|
| ~~C1~~ | ~~تثبيت حالات الحجز والعقار~~ | **اتحسم:** Backend Master Plan 6.1 و6.2 و7.3 (بما فيها `payment_conflict` و`abandoned`)، وأنواع العقار جدول `property_types` |
| ~~C2~~ | ~~شكل أكواد الأخطاء~~ | **اتحسم:** `raise exception '<CODE>' using errcode = 'P0001'` + القائمة في Backend Master Plan القسم 11 |
| ~~C3~~ | ~~البيئات~~ | **اتحسم:** Supabase local (Docker) لكل مطور + Staging مشترك `popadthwlumlkizmauak`. Production لسه متعملش (Backend Master Plan B1) |
| ~~C4~~ | ~~ترتيب تسليم الـ backend~~ | **اتحسم:** ترتيب الـ Migrations في Backend Master Plan القسم 13 |

### 9.5 مهام تجهيز قبل أول Spec

- [x] ~~إنشاء GitHub Organization~~ — اتلغى (القرار D1). ريبو اللوحة على حسابك.
- [ ] قبول دعوة `MostafaTaha418/onair-backend` وعمل clone في `F:\onair-backend` (بدل الريبو المحلي اللي اتعمل قبل كده من غير remote).
- [ ] عمل فرع `develop` في ريبو اللوحة (القرار D9).
- [ ] إضافة `.gitattributes` (`* text=auto eol=lf`) في المستودعين لتوحيد نهايات السطور بين Windows وMac.
- [ ] تثبيت Docker Desktop (لازم لـ `supabase start` واختبارات الـ RLS).
- [ ] التأكد من اسم وبريد Git في إعدادات الجهاز قبل الرفع.
- [x] مشروع Supabase Staging موجود (`popadthwlumlkizmauak`، Frankfurt). Production مشروع منفصل قبل الإطلاق.
- [ ] ملاحظة لـ Spec 001: `create-next-app` يرفض فولدرًا فيه `.claude` و`.specify` وملفات Vite؛ يُنشأ المشروع في فولدر مؤقت ثم يُنقل، وتُحذف ملفات Vite.

---

## 10. أول خطوات عملية

1. إنهاء مهام 9.5، وإرسال 9.3 لصاحب المشروع.
2. `/speckit-constitution` بمبادئ القسم 8 (لا يتوقف على 9.3).
3. اجتماع قصير مع زميلَي Flutter لتثبيت عقد القسم 5 (حتى لو مبدئيًا).
4. `/speckit-specify` لـ **001 admin-foundation** ← clarify ← plan ← tasks ← implement.
5. بالتوازي: المرحلة صفر في `onair-backend` (القسم 5.3) — خصوصًا 0.6 (CI) و 0.8 (`common_get_my_context` + `admin_invite_staff`) وكود الإيميل، لأن 002 يعتمد عليهم.
