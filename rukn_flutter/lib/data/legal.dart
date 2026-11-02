// GENERATED from rukn-site src/data/legal.ts by a one-off port script. Text is verbatim.
// Clause order is significant: the site numbers clauses by array order and support cites
// them by number, so append new clauses rather than inserting them mid-list.
// ignore_for_file: lines_longer_than_80_chars

/// Privacy policy and terms of use, served at `/privacy` and `/terms` on the website and
/// shown in-app by `LegalScreen`. Ported from the website's `src/data/legal.ts`.
library;

class Localized {
  const Localized({required this.en, required this.ar});

  final String en;
  final String ar;

  String pick(bool isAr) => isAr ? ar : en;
}

sealed class LegalBlock {
  const LegalBlock();
}

/// A paragraph of body text.
class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text);

  final Localized text;
}

/// A bulleted list.
class LegalList extends LegalBlock {
  const LegalList(this.items);

  final List<Localized> items;
}

class LegalClause {
  const LegalClause({required this.id, required this.heading, required this.blocks});

  /// Anchor id, so a clause can be linked to directly (`/privacy#rights`).
  final String id;
  final Localized heading;
  final List<LegalBlock> blocks;
}

class LegalDoc {
  const LegalDoc({
    required this.slug,
    required this.title,
    required this.summary,
    required this.updated,
    required this.clauses,
  });

  /// `privacy` or `terms`.
  final String slug;
  final Localized title;
  final Localized summary;

  /// ISO date (YYYY-MM-DD) the current text took effect.
  final String updated;
  final List<LegalClause> clauses;
}

class LegalCompany {
  const LegalCompany({
    required this.name,
    required this.commercialRegister,
    required this.vatNumber,
    required this.phone,
    required this.email,
  });

  final Localized name;
  final String commercialRegister;
  final String vatNumber;
  final String phone;
  final String email;
}

const legalCompany = LegalCompany(
  name: Localized(
    en: 'Al Rukn Al Thamin Gold & Jewelry',
    ar: 'الركن الثمين للذهب والمجوهرات',
  ),
  commercialRegister: '7041480281',
  vatNumber: '312482882500003',
  phone: '920017233',
  email: 'info@alruknalthamin.com',
);

const _contactLine = Localized(
  en: 'Email info@alruknalthamin.com, call 920017233, or message us on WhatsApp at +966573788758.',
  ar: 'راسلنا على info@alruknalthamin.com، أو اتصل على 920017233، أو تواصل معنا عبر واتساب على \u200E+966573788758.',
);

const legalPrivacy = LegalDoc(
  slug: 'privacy',
  title: Localized(
    en: 'Privacy Policy',
    ar: 'سياسة الخصوصية',
  ),
  summary: Localized(
    en: 'What we collect when you use our website and app, why we collect it, who we share it with, and the choices you have.',
    ar: 'ما نجمعه من بيانات عند استخدامك لموقعنا وتطبيقنا، ولماذا نجمعها، ومع من نشاركها، والخيارات المتاحة لك.',
  ),
  updated: '2026-10-15',
  clauses: [
  LegalClause(
    id: 'who-we-are',
    heading: Localized(
      en: 'Who we are',
      ar: 'من نحن',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Al Rukn Al Thamin Gold & Jewelry (Commercial Register 7041480281, VAT number 312482882500003) operates the rknthmin.com.sa website and the Al Rukn Al Thamin mobile app in the Kingdom of Saudi Arabia. We are the controller of the personal data described in this policy, and we process it in line with the Saudi Personal Data Protection Law (PDPL) and its implementing regulations.',
          ar: 'تدير الركن الثمين للذهب والمجوهرات (سجل تجاري رقم 7041480281، الرقم الضريبي 312482882500003) موقع rknthmin.com.sa وتطبيق الركن الثمين في المملكة العربية السعودية. نحن الجهة المسؤولة عن البيانات الشخصية الموضحة في هذه السياسة، ونعالجها وفق نظام حماية البيانات الشخصية ولوائحه التنفيذية.',
        )),
    ],
  ),
  LegalClause(
    id: 'data-we-collect',
    heading: Localized(
      en: 'Data we collect',
      ar: 'البيانات التي نجمعها',
    ),
    blocks: [
      LegalList([
        Localized(
            en: 'Account details: your name, mobile number (verified by a one-time SMS code) and, if you add one, your email address.',
            ar: 'بيانات الحساب: اسمك ورقم جوالك (يُتحقق منه برمز يُرسل في رسالة نصية) وبريدك الإلكتروني إن أضفته.',
          ),
        Localized(
            en: 'Orders and delivery: the items you buy, your saved addresses and Saudi National Address, the map location you pin for delivery, and whether you chose delivery, branch pickup or vault storage.',
            ar: 'الطلبات والتوصيل: القطع التي تشتريها، وعناوينك المحفوظة وعنوانك الوطني، والموقع الذي تحدده على الخريطة للتوصيل، واختيارك بين التوصيل أو الاستلام من الفرع أو الحفظ في الخزنة.',
          ),
        Localized(
            en: 'Payments: card payments are processed by our payment provider, Paymob. We never see or store your full card number. For bank transfers we keep the transfer receipt you upload.',
            ar: 'المدفوعات: تُعالج المدفوعات بالبطاقة لدى مزوّد الدفع Paymob، ولا نطّلع على رقم بطاقتك كاملاً ولا نحتفظ به. وفي التحويل البنكي نحتفظ بإيصال التحويل الذي ترفعه.',
          ),
        Localized(
            en: 'Investment tools: the holdings you record in your portfolio, the price alerts you set, consultation requests, market-trip bookings and your loyalty points.',
            ar: 'أدوات الاستثمار: الأصول التي تسجّلها في محفظتك، وتنبيهات الأسعار التي تضبطها، وطلبات الاستشارة، وحجوزات الرحلات السوقية، ونقاط الولاء.',
          ),
        Localized(
            en: 'Conversations: messages you send us by WhatsApp, email or phone.',
            ar: 'المراسلات: الرسائل التي ترسلها إلينا عبر واتساب أو البريد الإلكتروني أو الهاتف.',
          ),
        Localized(
            en: 'Device and usage: IP address, device and browser type, pages viewed, and the campaign or ad link that brought you to us.',
            ar: 'الجهاز والاستخدام: عنوان IP، ونوع الجهاز والمتصفح، والصفحات التي زرتها، والحملة أو الرابط الإعلاني الذي أوصلك إلينا.',
          ),
      ]),
    ],
  ),
  LegalClause(
    id: 'device-permissions',
    heading: Localized(
      en: 'Device permissions',
      ar: 'أذونات الجهاز',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'The app asks for a permission only when you use the feature that needs it, and works without it.',
          ar: 'لا يطلب التطبيق أي إذن إلا عند استخدامك للميزة التي تحتاجه، ويعمل بدونه.',
        )),
      LegalList([
        Localized(
            en: 'Location: to drop your delivery pin on the map. We save only the pin you confirm, not a location history.',
            ar: 'الموقع: لتحديد موقع التوصيل على الخريطة. نحفظ الموقع الذي تؤكده فقط، ولا نحتفظ بسجل لمواقعك.',
          ),
        Localized(
            en: 'Notifications: to tell you when gold reaches a price you set an alert for.',
            ar: 'الإشعارات: لإبلاغك عند وصول سعر الذهب إلى السعر الذي ضبطت عليه التنبيه.',
          ),
        Localized(
            en: 'Photos and files: to upload a bank transfer receipt.',
            ar: 'الصور والملفات: لرفع إيصال التحويل البنكي.',
          ),
      ]),
    ],
  ),
  LegalClause(
    id: 'how-we-use',
    heading: Localized(
      en: 'How we use your data',
      ar: 'كيف نستخدم بياناتك',
    ),
    blocks: [
      LegalList([
        Localized(
            en: 'To sign you in and keep your account secure.',
            ar: 'لتسجيل دخولك والحفاظ على أمان حسابك.',
          ),
        Localized(
            en: 'To process, deliver and store your orders, and to issue tax invoices.',
            ar: 'لتنفيذ طلباتك وتوصيلها وحفظها، وإصدار الفواتير الضريبية.',
          ),
        Localized(
            en: 'To meet our legal duties as a precious-metals dealer, including anti-money-laundering checks and record keeping.',
            ar: 'للوفاء بالتزاماتنا النظامية بصفتنا تاجراً للمعادن الثمينة، ومنها إجراءات مكافحة غسل الأموال وحفظ السجلات.',
          ),
        Localized(
            en: 'To answer your questions, send the price alerts you asked for, and tell you about your orders.',
            ar: 'للرد على استفساراتك، وإرسال تنبيهات الأسعار التي طلبتها، وإبلاغك بحالة طلباتك.',
          ),
        Localized(
            en: 'To measure which of our ads and campaigns work, and to improve the website and app.',
            ar: 'لقياس فاعلية إعلاناتنا وحملاتنا، وتحسين الموقع والتطبيق.',
          ),
      ]),
    ],
  ),
  LegalClause(
    id: 'sharing',
    heading: Localized(
      en: 'Who we share it with',
      ar: 'مع من نشاركها',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'We do not sell your personal data. We share only what each party needs to do its job:',
          ar: 'لا نبيع بياناتك الشخصية. ونشارك كل جهة بما تحتاجه فقط لأداء عملها:',
        )),
      LegalList([
        Localized(
            en: 'Paymob, to process card payments.',
            ar: 'Paymob لمعالجة المدفوعات بالبطاقة.',
          ),
        Localized(
            en: 'UPS and our delivery partners, to deliver your order.',
            ar: 'UPS وشركاء التوصيل لإيصال طلبك.',
          ),
        Localized(
            en: 'Our SMS provider, to send sign-in codes.',
            ar: 'مزوّد الرسائل النصية لإرسال رموز الدخول.',
          ),
        Localized(
            en: 'Our hosting and infrastructure providers, who store data on our behalf.',
            ar: 'مزوّدو الاستضافة والبنية التقنية الذين يحفظون البيانات نيابة عنا.',
          ),
        Localized(
            en: 'Google (Analytics, Tag Manager, Ads), Meta, Snapchat and TikTok, to measure visits and ad performance.',
            ar: 'Google (Analytics وTag Manager وAds) وMeta وSnapchat وTikTok لقياس الزيارات وأداء الإعلانات.',
          ),
        Localized(
            en: 'Government authorities, when the law requires it.',
            ar: 'الجهات الحكومية متى ما اقتضى النظام ذلك.',
          ),
      ]),
      LegalParagraph(Localized(
          en: 'Some of these providers process data outside the Kingdom. When that happens we rely on the safeguards the PDPL transfer regulations require.',
          ar: 'يعالج بعض هؤلاء المزوّدين البيانات خارج المملكة، وفي هذه الحالة نلتزم بالضمانات التي تشترطها لائحة نقل البيانات الشخصية خارج المملكة.',
        )),
    ],
  ),
  LegalClause(
    id: 'on-device-storage',
    heading: Localized(
      en: 'Cookies and on-device storage',
      ar: 'ملفات تعريف الارتباط والتخزين على الجهاز',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'We store a few things on your device so the service works: your sign-in session, your cart, checkout progress, your price alerts and the campaign that brought you to us. The analytics and advertising tools listed above may set their own cookies. You can clear them at any time from your browser or device settings.',
          ar: 'نحفظ على جهازك ما يلزم لعمل الخدمة: جلسة الدخول، وسلة المشتريات، وتقدّم عملية الشراء، وتنبيهات الأسعار، والحملة التي أوصلتك إلينا. وقد تضع أدوات التحليل والإعلان المذكورة أعلاه ملفات تعريف ارتباط خاصة بها، ويمكنك حذفها في أي وقت من إعدادات المتصفح أو الجهاز.',
        )),
    ],
  ),
  LegalClause(
    id: 'retention',
    heading: Localized(
      en: 'How long we keep it',
      ar: 'مدة الاحتفاظ بالبيانات',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'We keep your account data while your account is open. Tax invoices and transaction records are kept for as long as Saudi tax and anti-money-laundering laws require, which can be up to 10 years after the transaction, even if you delete your account. Everything else is deleted or anonymised when we no longer need it.',
          ar: 'نحتفظ ببيانات حسابك ما دام حسابك قائماً. أما الفواتير الضريبية وسجلات العمليات فنحتفظ بها المدة التي تفرضها أنظمة الضريبة ومكافحة غسل الأموال في المملكة، وقد تصل إلى ١٠ سنوات من تاريخ العملية، حتى بعد حذف حسابك. وما عدا ذلك يُحذف أو تُزال هويته متى انتفت حاجتنا إليه.',
        )),
    ],
  ),
  LegalClause(
    id: 'security',
    heading: Localized(
      en: 'Security',
      ar: 'أمن البيانات',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Data travels over encrypted connections (HTTPS), sign-in uses one-time codes, and access to customer data inside our team is limited to the staff who need it. No system is perfectly secure; if a breach affects you, we will notify you and the authorities as the law requires.',
          ar: 'تنتقل البيانات عبر اتصالات مشفّرة (HTTPS)، ويتم الدخول برموز تُستخدم مرة واحدة، ويقتصر الاطلاع على بيانات العملاء داخل فريقنا على من يحتاجها لأداء عمله. لا يوجد نظام آمن تماماً، وإن تعرّضت بياناتك لأي اختراق فسنبلغك ونبلغ الجهات المختصة وفق ما يقتضيه النظام.',
        )),
    ],
  ),
  LegalClause(
    id: 'rights',
    heading: Localized(
      en: 'Your rights',
      ar: 'حقوقك',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Under the PDPL you can ask us to:',
          ar: 'يحق لك بموجب نظام حماية البيانات الشخصية أن تطلب منا:',
        )),
      LegalList([
        Localized(
            en: 'Tell you what personal data we hold about you and give you a copy.',
            ar: 'إطلاعك على بياناتك الشخصية لدينا وتزويدك بنسخة منها.',
          ),
        Localized(
            en: 'Correct data that is wrong or incomplete.',
            ar: 'تصحيح البيانات غير الدقيقة أو غير المكتملة.',
          ),
        Localized(
            en: 'Delete your data and your account.',
            ar: 'حذف بياناتك وحسابك.',
          ),
        Localized(
            en: 'Stop using your data for marketing, or withdraw any consent you gave.',
            ar: 'التوقف عن استخدام بياناتك في التسويق، أو سحب أي موافقة سبق أن منحتها.',
          ),
      ]),
      LegalParagraph(Localized(
          en: 'You can edit your name, email and number yourself under My account. For anything else, contact us using the details below; we answer within 30 days. If you are not satisfied with our answer you can complain to the Saudi Data & AI Authority (SDAIA).',
          ar: 'يمكنك تعديل اسمك وبريدك ورقمك بنفسك من صفحة «حسابي». ولأي طلب آخر تواصل معنا عبر البيانات أدناه، ونرد خلال ٣٠ يوماً. وإن لم يرضك ردّنا فيحق لك تقديم شكوى إلى الهيئة السعودية للبيانات والذكاء الاصطناعي (سدايا).',
        )),
    ],
  ),
  LegalClause(
    id: 'account-deletion',
    heading: Localized(
      en: 'Deleting your account',
      ar: 'حذف حسابك',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'You can ask us to delete your account and its data at any time from the Delete account page, linked at the top of this page. It explains what is deleted, what the law requires us to keep, and how long it takes.',
          ar: 'يمكنك طلب حذف حسابك وبياناته في أي وقت من صفحة «حذف الحساب» الموجودة أعلى هذه الصفحة، وفيها توضيح لما يُحذف، وما يلزمنا النظام بالاحتفاظ به، والمدة التي يستغرقها الحذف.',
        )),
    ],
  ),
  LegalClause(
    id: 'children',
    heading: Localized(
      en: 'Children',
      ar: 'الأطفال',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Our service is for adults aged 18 and over. We do not knowingly collect data from anyone younger. If you believe a child has given us their data, contact us and we will delete it.',
          ar: 'خدماتنا موجّهة لمن بلغوا ١٨ عاماً فأكثر، ولا نجمع عن علمٍ بيانات من هم دون ذلك. وإن علمت أن طفلاً زوّدنا ببياناته فتواصل معنا وسنحذفها.',
        )),
    ],
  ),
  LegalClause(
    id: 'changes',
    heading: Localized(
      en: 'Changes to this policy',
      ar: 'التعديلات على هذه السياسة',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'When we change this policy we update the date at the top of the page. If a change affects how we use data you have already given us, we will tell you in the app or by message before it takes effect.',
          ar: 'عند تعديل هذه السياسة نحدّث التاريخ أعلى الصفحة. وإن أثّر التعديل في طريقة استخدامنا لبيانات سبق أن قدّمتها، فسنبلغك عبر التطبيق أو برسالة قبل سريانه.',
        )),
    ],
  ),
  LegalClause(
    id: 'contact',
    heading: Localized(
      en: 'Contact us',
      ar: 'تواصل معنا',
    ),
    blocks: [LegalParagraph(_contactLine)],
  ),
  ],
);

const legalTerms = LegalDoc(
  slug: 'terms',
  title: Localized(
    en: 'Terms & Conditions',
    ar: 'الشروط والأحكام',
  ),
  summary: Localized(
    en: 'The agreement between you and us when you browse, buy or use the investment tools on our website and app.',
    ar: 'الاتفاقية بينك وبيننا عند تصفّحك أو شرائك أو استخدامك لأدوات الاستثمار في موقعنا وتطبيقنا.',
  ),
  updated: '2026-10-15',
  clauses: [
  LegalClause(
    id: 'agreement',
    heading: Localized(
      en: 'About these terms',
      ar: 'عن هذه الشروط',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'These terms apply to the rknthmin.com.sa website and the Al Rukn Al Thamin app, operated by Al Rukn Al Thamin Gold & Jewelry (Commercial Register 7041480281). By creating an account or placing an order you agree to them and to our Privacy Policy.',
          ar: 'تسري هذه الشروط على موقع rknthmin.com.sa وتطبيق الركن الثمين اللذين تديرهما الركن الثمين للذهب والمجوهرات (سجل تجاري رقم 7041480281). وبإنشائك حساباً أو تقديمك طلباً فإنك توافق عليها وعلى سياسة الخصوصية.',
        )),
    ],
  ),
  LegalClause(
    id: 'account',
    heading: Localized(
      en: 'Your account',
      ar: 'حسابك',
    ),
    blocks: [
      LegalList([
        Localized(
            en: 'You must be 18 or older to create an account or buy.',
            ar: 'يجب ألا يقل عمرك عن ١٨ عاماً لإنشاء حساب أو الشراء.',
          ),
        Localized(
            en: 'The details you give us must be accurate and your own. Orders are released only to the account holder or someone they authorise.',
            ar: 'يجب أن تكون البيانات التي تقدّمها صحيحة وخاصة بك، ولا تُسلَّم الطلبات إلا لصاحب الحساب أو من يفوّضه.',
          ),
        Localized(
            en: 'You sign in with a code sent to your mobile. Keep your phone secure: activity after a correct code is treated as yours.',
            ar: 'تسجّل دخولك برمز يُرسل إلى جوالك، فحافظ على أمان هاتفك؛ إذ يُعدّ أي نشاط يتم بعد إدخال الرمز الصحيح صادراً منك.',
          ),
      ]),
    ],
  ),
  LegalClause(
    id: 'prices',
    heading: Localized(
      en: 'Prices',
      ar: 'الأسعار',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Gold and silver prices follow the global market and change throughout the day. The price you pay is the one shown when you confirm payment. Prices are in Saudi riyals and include VAT where it applies, as shown on your invoice. If an item is listed at an obviously wrong price because of a technical error, we may cancel the order and refund you in full.',
          ar: 'تتبع أسعار الذهب والفضة السوق العالمية وتتغير على مدار اليوم، والسعر الذي تدفعه هو المعروض لحظة تأكيد الدفع. الأسعار بالريال السعودي وتشمل ضريبة القيمة المضافة حيثما تنطبق، كما تظهر في فاتورتك. وإن ظهرت قطعة بسعر خاطئ بشكل واضح بسبب خلل تقني، فيحق لنا إلغاء الطلب ورد المبلغ كاملاً.',
        )),
    ],
  ),
  LegalClause(
    id: 'orders-payment',
    heading: Localized(
      en: 'Orders and payment',
      ar: 'الطلبات والدفع',
    ),
    blocks: [
      LegalList([
        Localized(
            en: 'An order is confirmed once payment is received: immediately for card payments, and after we verify the transfer for bank transfers.',
            ar: 'يُعدّ الطلب مؤكداً عند استلام الدفع: فوراً في الدفع بالبطاقة، وبعد التحقق من التحويل في الدفع بالتحويل البنكي.',
          ),
        Localized(
            en: 'Bank transfers must arrive within the time shown at checkout, or the order may be cancelled.',
            ar: 'يجب أن يصل التحويل البنكي خلال المهلة الموضحة عند الدفع، وإلا جاز إلغاء الطلب.',
          ),
        Localized(
            en: 'As required of precious-metals dealers, we may ask for proof of identity or the source of funds before completing large orders, and we may decline any order we cannot verify.',
            ar: 'التزاماً بما يُفرض على تجار المعادن الثمينة، قد نطلب إثبات الهوية أو مصدر الأموال قبل إتمام الطلبات الكبيرة، ويحق لنا رفض أي طلب لا يمكننا التحقق منه.',
          ),
      ]),
    ],
  ),
  LegalClause(
    id: 'delivery',
    heading: Localized(
      en: 'Delivery, pickup and vault storage',
      ar: 'التوصيل والاستلام والحفظ في الخزنة',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'You can have your order delivered, collect it from a branch, or keep it in our vault and request release later. Delivery times are estimates. Risk passes to you when the order is handed to you or your authorised representative.',
          ar: 'يمكنك اختيار توصيل طلبك، أو استلامه من أحد الفروع، أو حفظه في خزنتنا وطلب استلامه لاحقاً. مواعيد التوصيل تقديرية، وتنتقل المسؤولية إليك عند تسليم الطلب لك أو لمن تفوّضه.',
        )),
    ],
  ),
  LegalClause(
    id: 'returns',
    heading: Localized(
      en: 'Exchanges and returns',
      ar: 'الاستبدال والاسترجاع',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Exchanges and returns follow our Exchange, Return & Delivery Policy, linked in the site footer. Because gold prices move daily, exchanges are valued at the market price on the day of exchange.',
          ar: 'يخضع الاستبدال والاسترجاع لسياسة الاستبدال والاسترجاع والتوصيل المتاحة في أسفل الموقع. ونظراً لتغيّر أسعار الذهب يومياً، تُقيَّم القطع عند الاستبدال بسعر السوق في يوم الاستبدال.',
        )),
    ],
  ),
  LegalClause(
    id: 'investment-tools',
    heading: Localized(
      en: 'Investment tools are not financial advice',
      ar: 'أدوات الاستثمار ليست استشارة مالية',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Live prices, charts, the portfolio tracker, price alerts and the zakat (nisab) reminder are for information only. Portfolio values are estimates based on the latest available price. Alerts can arrive late or not at all if your device is offline or notifications are switched off. Consultations offer general guidance, not personal investment advice. Decisions to buy, hold or sell are yours.',
          ar: 'الأسعار المباشرة والرسوم البيانية ومتابعة المحفظة وتنبيهات الأسعار وتذكير نصاب الزكاة هي لأغراض المعلومات فقط. قيم المحفظة تقديرية بناءً على آخر سعر متاح، وقد تتأخر التنبيهات أو لا تصل إن كان جهازك غير متصل أو الإشعارات معطّلة. والاستشارات توجيه عام وليست نصيحة استثمارية شخصية، وقرار الشراء أو الاحتفاظ أو البيع يعود إليك.',
        )),
    ],
  ),
  LegalClause(
    id: 'paid-services',
    heading: Localized(
      en: 'Paid services',
      ar: 'الخدمات المدفوعة',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Some services, such as portfolio plans and consultations, may be paid. The price and duration are shown before you pay. Plans do not renew automatically. Once a paid service has started it is not refundable, except where the law says otherwise.',
          ar: 'قد تكون بعض الخدمات مدفوعة، مثل خطط المحفظة والاستشارات، ويظهر السعر والمدة قبل الدفع. لا تتجدد الخطط تلقائياً، ولا يُسترد مقابل الخدمة المدفوعة بعد بدئها إلا فيما ينص عليه النظام.',
        )),
    ],
  ),
  LegalClause(
    id: 'loyalty',
    heading: Localized(
      en: 'Loyalty programme',
      ar: 'برنامج الولاء',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Loyalty points have no cash value, cannot be transferred, and are lost if your account is deleted. We may change the programme rules with notice in the app.',
          ar: 'نقاط الولاء ليس لها قيمة نقدية ولا يمكن تحويلها، وتسقط عند حذف الحساب. ويحق لنا تعديل قواعد البرنامج مع إشعارك عبر التطبيق.',
        )),
    ],
  ),
  LegalClause(
    id: 'acceptable-use',
    heading: Localized(
      en: 'Acceptable use',
      ar: 'الاستخدام المقبول',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Do not misuse the service: no fraudulent orders, no automated scraping of prices or content, no attempts to break into accounts or systems, and nothing unlawful. We may suspend or close accounts that do.',
          ar: 'يُمنع إساءة استخدام الخدمة، ومن ذلك: الطلبات الاحتيالية، والنسخ الآلي للأسعار أو المحتوى، ومحاولات اختراق الحسابات أو الأنظمة، وأي استخدام مخالف للنظام. ويحق لنا إيقاف أو إغلاق الحسابات المخالفة.',
        )),
    ],
  ),
  LegalClause(
    id: 'intellectual-property',
    heading: Localized(
      en: 'Intellectual property',
      ar: 'الملكية الفكرية',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'Our name, logo, product photos, designs and content belong to us or our licensors. Do not copy or reuse them without our written permission.',
          ar: 'اسمنا وشعارنا وصور منتجاتنا وتصاميمنا ومحتوانا مملوكة لنا أو للجهات المرخِّصة لنا، ولا يجوز نسخها أو إعادة استخدامها دون إذن كتابي منا.',
        )),
    ],
  ),
  LegalClause(
    id: 'liability',
    heading: Localized(
      en: 'Liability',
      ar: 'حدود المسؤولية',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'To the extent the law allows, we are not liable for losses caused by gold price movements, by decisions you make using our tools, or by outages beyond our reasonable control. Our total liability for any order is limited to the amount you paid for it. Nothing here limits rights you have under Saudi consumer protection law.',
          ar: 'في حدود ما يسمح به النظام، لا نتحمل مسؤولية الخسائر الناتجة عن تقلبات أسعار الذهب، أو عن قرارات تتخذها اعتماداً على أدواتنا، أو عن انقطاعات خارجة عن سيطرتنا المعقولة. وتقتصر مسؤوليتنا الإجمالية عن أي طلب على المبلغ الذي دفعته مقابله، ولا يحدّ شيء مما سبق من حقوقك المقررة في أنظمة حماية المستهلك في المملكة.',
        )),
    ],
  ),
  LegalClause(
    id: 'closing-account',
    heading: Localized(
      en: 'Closing your account',
      ar: 'إغلاق الحساب',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'You can ask us to delete your account at any time from the Delete account page. Open orders and items held in our vault must be settled or collected first.',
          ar: 'يمكنك طلب حذف حسابك في أي وقت من صفحة «حذف الحساب»، على أن تُستكمل الطلبات القائمة وتُستلم القطع المحفوظة في الخزنة أولاً.',
        )),
    ],
  ),
  LegalClause(
    id: 'law',
    heading: Localized(
      en: 'Governing law',
      ar: 'النظام الحاكم',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'These terms are governed by the laws of the Kingdom of Saudi Arabia, and disputes go to the competent courts in the Kingdom. If the Arabic and English versions differ, the Arabic version prevails.',
          ar: 'تخضع هذه الشروط لأنظمة المملكة العربية السعودية، وتختص المحاكم المختصة في المملكة بالفصل في أي نزاع. وفي حال الاختلاف بين النصين العربي والإنجليزي يُعتمد النص العربي.',
        )),
    ],
  ),
  LegalClause(
    id: 'changes',
    heading: Localized(
      en: 'Changes to these terms',
      ar: 'التعديلات على هذه الشروط',
    ),
    blocks: [
      LegalParagraph(Localized(
          en: 'We may update these terms and will change the date at the top of the page when we do. Orders already placed stay under the terms that applied when you placed them.',
          ar: 'قد نحدّث هذه الشروط، وسنغيّر التاريخ أعلى الصفحة عند ذلك. وتبقى الطلبات السابقة خاضعة للشروط السارية وقت تقديمها.',
        )),
    ],
  ),
  LegalClause(
    id: 'contact',
    heading: Localized(
      en: 'Contact us',
      ar: 'تواصل معنا',
    ),
    blocks: [LegalParagraph(_contactLine)],
  ),
  ],
);

/// Both documents keyed by slug.
const Map<String, LegalDoc> legalDocs = {
  'privacy': legalPrivacy,
  'terms': legalTerms,
};
