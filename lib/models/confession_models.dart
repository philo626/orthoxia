import 'package:cloud_firestore/cloud_firestore.dart';

/// Official Coptic Orthodox Dioceses & Authentic Churches Directory (Egypt & Diaspora)
class CopticDiocesesCatalog {
  static const List<String> dioceses = [
    'القاهرة الكبرى',
    'مصر الجديدة وعين شمس والمطرية',
    'شبرا الشمالية',
    'شبرا الجنوبية',
    'شرق السكة الحديد',
    'المعادي والبساتين ودار السلام',
    'حلوان والمعصرة',
    'القاهرة الجديدة والتجمع والرحاب',
    'الجيزة',
    '٦ أكتوبر وأوسيم',
    'الإسكندرية',
    'شبرا الخيمة وتوابعها',
    'القليوبية وبنها وقويسنا',
    'الشرقية والزقازيق ومنيا القمح',
    'العاشر من رمضان',
    'الدقهلية والمنصورة',
    'دمياط وكفر الشيخ والبراري',
    'الغربية وطنطا والمحلة الكبرى',
    'المنوفية وشبين الكوم',
    'البحيرة ومطروح والخمس مدن الغربية',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف وببا والفشن',
    'المنيا وأبوقرقاص ومغاغة وسمالوط ومطاي وملوي وديرمواس',
    'أسيوط وديروط والقوصية ومنفلوط وأبوتيج وأبنوب',
    'سوهاج وأخميم والبلينا وطما وطهطا وجرجا',
    'قنا ونجع حمادي ودشنا ونقادة وقوص',
    'الأقصر وإسنا وأرمنت',
    'أسوان وكوم أمبو وإدفو',
    'البحر الأحمر والغردقة',
    'الوادي الجديد',
    'شمال وجنوب سيناء',
    'إيبارشيات المهجر (أوروبا / أمريكا / كندا / أستراليا / الخليج)',
  ];

  static const Map<String, List<String>> churchesByDiocese = {
    'القاهرة الكبرى': [
      'الكاتدرائية المرقسية الكبرى بالعباسية',
      'كنيسة السيدة العذراء المعلقة بمصر القديمة',
      'كنيسة القديس أبي سرجة بمصر القديمة',
      'كنيسة الشهيد مارجرجس بمصر القديمة',
      'كنيسة السيدة العذراء بالزمالك',
      'كنيسة السيدة العذراء بالفجالة',
      'كنيسة الشهيد مارجرجس بالمنيل',
      'كنيسة رئيس الملائكة ميخائيل بالظاهر',
      'كنيسة السيدة العذراء بقصرية الريحان',
      'كنيسة القديس مارمرقس بكلوت بك',
      'كنيسة السيدة العذراء بالزيتون',
      'كنيسة القديس الأنبا رويس بالعباسية',
      'كنيسة السيدة العذراء بالمقطم (سمعان الخراز)',
      'كنيسة السيدة العذراء بمدينة نصر (أرض الجولف)',
      'كنيسة الشهيد مارجرجس بألماظة',
      'كنيسة القديسين بطرس وبولس (البطرسية)',
    ],
    'مصر الجديدة وعين شمس والمطرية': [
      'كنيسة القديس مارمرقس بمصر الجديدة',
      'كنيسة السيدة العذراء بأرض الجولف',
      'كنيسة الشهيد مارجرجس بهليوبوليس',
      'كنيسة السيدة العذراء بالنزهة الجديدة',
      'كنيسة الشهيد مارمينا بمصر الجديدة',
      'كنيسة السيدة العذراء والأنبا أثناسيوس بمدينة نصر',
      'كنيسة رئيس الملائكة ميخائيل بشيراتون',
      'كنيسة السيدة العذراء بعين شمس الشرقية',
      'كنيسة الشهيد مارجرجس بعين شمس',
      'كنيسة السيدة العذراء بالمطرية',
      'كنيسة الشهيد مارجرجس بالمطرية',
      'كنيسة السيدة العذراء بالحلمية',
    ],
    'شبرا الشمالية': [
      'كنيسة السيدة العذراء بالحافظية',
      'كنيسة القديس مارمرقس بشبرا',
      'كنيسة الشهيد مارجرجس بخمارويه',
      'كنيسة السيدة العذراء بعياد بك',
      'كنيسة رئيس الملائكة ميخائيل بطوسون',
      'كنيسة الشهيد أبوسيفين والأنبا مقار بحدائق شبرا',
      'كنيسة القديسة دميانة بأرض بابا دبلو',
      'كنيسة السيدة العذراء والملاك ميخائيل بالخلفاوي',
      'كنيسة الأنبا أنطونيوس بشبرا',
    ],
    'شبرا الجنوبية': [
      'كنيسة السيدة العذراء بمسرة',
      'كنيسة الشهيد مارجرجس بجزيرة بدران',
      'كنيسة السيدة العذراء بروض الفرج',
      'كنيسة القديس مارمرقس بروض الفرج',
      'كنيسة الشهيد مارمينا بالترعة البولاقية',
      'كنيسة السيدة العذراء بمهمشة',
      'كنيسة الشهيد مارجرجس بالجيوشي',
      'كنيسة السيدة العذراء بأرض شريف',
    ],
    'شرق السكة الحديد': [
      'كنيسة السيدة العذراء بالزيتون (التجلي)',
      'كنيسة القديس مارمرقس بحدائق القبة',
      'كنيسة الشهيد مارجرجس بحمامات القبة',
      'كنيسة السيدة العذراء بسراي القبة',
      'كنيسة رئيس الملائكة ميخائيل بحدائق القبة',
      'كنيسة السيدة العذراء بالوايلي الكبير',
      'كنيسة الشهيد مارجرجس بالزاوية الحمراء',
      'كنيسة القديس الأنبا بولا بأرض الجولف',
      'كنيسة الشهيد أبوسيفين بحدائق القبة',
    ],
    'المعادي والبساتين ودار السلام': [
      'كنيسة السيدة العذراء بالمعادي (العدوية)',
      'كنيسة القديس مارمرقس بالمعادي',
      'كنيسة رئيس الملائكة رافائيل بالمعادي الجديدة',
      'كنيسة الشهيد مارجرجس بكوتسيكا',
      'كنيسة السيدة العذراء بدار السلام',
      'كنيسة الشهيد مارجرجس بطرة',
      'كنيسة القديس الأنبا أرسانيوس بكوتسيكا',
      'كنيسة السيدة العذراء بالبساتين',
    ],
    'حلوان والمعصرة': [
      'كاتدرائية السيدة العذراء بحلوان',
      'كنيسة الشهيد مارجرجس بحلوان',
      'كنيسة القديس مارمرقس بحدائق حلوان',
      'كنيسة السيدة العذراء بالمعصرة',
      'كنيسة رئيس الملائكة ميخائيل بالمعصرة',
      'كنيسة الشهيد مارمينا بحلوان',
      'كنيسة السيدة العذراء بمدينة ١٥ مايو',
      'كنيسة الأنبا برسوم العريان بالمعصرة',
    ],
    'القاهرة الجديدة والتجمع والرحاب': [
      'كنيسة السيدة العذراء والقديس الأنبا بيشوي بالتجمع الخامس',
      'كنيسة السيدة العذراء بالتجمع الأول',
      'كنيسة الشهيد مارجرجس والأنبا أنطونيوس بالتجمع الثالث',
      'كنيسة القديس مارمرقس بمدينة الرحاب',
      'كنيسة السيدة العذراء بمدينتي',
      'كنيسة الشهيد مارجرجس بمدينة الشروق',
      'كنيسة السيدة العذراء والقديس أثناسيوس بمدينة بدر',
      'كاتدرائية ميلاد المسيح بالعاصمة الإدارية',
    ],
    'الجيزة': [
      'كاتدرائية الشهيد مارجرجس بالجيزة',
      'كنيسة السيدة العذراء بالدقي',
      'كنيسة القديس مارمرقس بالجيزة',
      'كنيسة السيدة العذراء بالمهندسين',
      'كنيسة الشهيد مارجرجس بالعجوزة',
      'كنيسة السيدة العذراء بالعمرانية',
      'كنيسة الشهيد مارمينا بالعمرانية',
      'كنيسة رئيس الملائكة ميخائيل بالصحفيين',
      'كنيسة السيدة العذراء بالهرم',
      'كنيسة القديسة دميانة بالهرم',
      'كنيسة السيدة العذراء بإمبابة',
      'كنيسة الشهيد مارجرجس بفيصل',
    ],
    '٦ أكتوبر وأوسيم': [
      'كنيسة السيدة العذراء بمدينة ٦ أكتوبر',
      'كنيسة القديس مارمرقس بمدينة ٦ أكتوبر',
      'كنيسة رئيس الملائكة ميخائيل بمدينة ٦ أكتوبر',
      'كنيسة السيدة العذراء بالشيخ زايد',
      'كنيسة الشهيد مارجرجس بحدائق أكتوبر',
      'كنيسة السيدة العذراء بأوسيم',
      'كنيسة الشهيد مارجرجس بالوراق',
    ],
    'الإسكندرية': [
      'الكاتدرائية المرقسية الكبرى بمحطة الرمل',
      'كنيسة الشهيد مارجرجس بسبورتنج',
      'كنيسة السيدة العذراء بمحرم بك',
      'كنيسة القديسين مارمرقس والبابا بطرس بسيدي بشر',
      'كنيسة السيدة العذراء بسموحة',
      'كنيسة الشهيد مارمينا بفلمنج',
      'كنيسة السيدة العذراء والقديس يوسف بسموحة',
      'كنيسة الشهيد مارجرجس بباكوس',
      'كنيسة السيدة العذراء بجناكليس',
      'كنيسة رئيس الملائكة ميخائيل بمصطفى كامل',
      'كنيسة السيدة العذراء بغبريال',
      'كنيسة الشهيد مارمينا بالمندرة',
      'كنيسة القديس الأنبا تكلا هيمانوت بالإبراهيمية',
      'كنيسة الشهيد مارجرجس بالحضرة',
      'كنيسة السيدة العذراء بالعجمي (البيطاش)',
    ],
    'شبرا الخيمة وتوابعها': [
      'كاتدرائية الشهيد مارجرجس بشبرا الخيمة',
      'كنيسة السيدة العذراء ببيجام',
      'كنيسة القديس مارمرقس بشبرا الخيمة',
      'كنيسة السيدة العذراء بمسترد',
      'كنيسة الشهيد أبوسيفين بشبرا الخيمة',
      'كنيسة رئيس الملائكة ميخائيل ببهتيم',
      'كنيسة السيدة العذراء بشبرا البلد',
      'كنيسة الشهيد مارجرجس بمدينة العبور',
    ],
    'القليوبية وبنها وقويسنا': [
      'مطرانية السيدة العذراء ببنها',
      'كنيسة القديس نيقولاوس ببنها',
      'كنيسة الشهيد مارجرجس بكفر شكر',
      'كنيسة السيدة العذراء بطوخ',
      'كنيسة الشهيد مارجرجس بقويسنا',
      'كنيسة السيدة العذراء بالقناطر الخيرية',
      'كنيسة السيدة العذراء بشبين القناطر',
    ],
    'الشرقية والزقازيق ومنيا القمح': [
      'مطرانية السيدة العذراء بالزقازيق',
      'كنيسة الشهيد مارجرجس بالزقازيق',
      'كنيسة القديس مارمرقس بالزقازيق',
      'كنيسة السيدة العذراء بمنيا القمح',
      'كنيسة الشهيد مارجرجس ببلبيس',
      'كنيسة السيدة العذراء بأبوحماد',
      'كنيسة الشهيد مارجرجس بفاقوس',
    ],
    'العاشر من رمضان': [
      'كاتدرائية القديس مارمرقس بالعاشر من رمضان',
      'كنيسة السيدة العذراء بالعاشر من رمضان',
      'كنيسة الشهيد مارجرجس بالعاشر من رمضان',
      'كنيسة رئيس الملائكة ميخائيل بالعاشر من رمضان',
    ],
    'الدقهلية والمنصورة': [
      'كاتدرائية السيدة العذراء والملاك ميخائيل بالمنصورة',
      'كنيسة الشهيد مارجرجس بالمنصورة',
      'كنيسة القديسة دميانة بالمنصورة',
      'كنيسة السيدة العذراء بطلخا',
      'كنيسة الشهيد مارجرجس بميت غمر',
      'كنيسة السيدة العذراء بالسنبلاوين',
      'كنيسة السيدة العذراء بدكرنس',
    ],
    'دمياط وكفر الشيخ والبراري': [
      'مطرانية السيدة العذراء بدمياط',
      'كنيسة الشهيد مارجرجس بدمياط الجديدة',
      'كنيسة القديسة دميانة ببراري بلقاس',
      'كنيسة السيدة العذراء بكفر الشيخ',
      'كنيسة الشهيد مارجرجس بدسوق',
      'كنيسة السيدة العذراء بسخا',
    ],
    'الغربية وطنطا والمحلة الكبرى': [
      'كاتدرائية الشهيد مارجرجس بطنطا',
      'كنيسة السيدة العذراء بالصاغة بطنطا',
      'كنيسة القديس ماربولس بطنطا',
      'كنيسة السيدة العذراء بالمحلة الكبرى',
      'كنيسة الشهيد مارجرجس بالمحلة الكبرى',
      'كنيسة الشهيد أبانوب بسمنود',
      'كنيسة السيدة العذراء بزفتى',
      'كنيسة السيدة العذراء بكفر الزيات',
    ],
    'المنوفية وشبين الكوم': [
      'مطرانية الشهيد مارجرجس بشبين الكوم',
      'كنيسة السيدة العذراء بشبين الكوم',
      'كنيسة الشهيد مارجرجس بمنوف',
      'كنيسة السيدة العذراء بأشمون',
      'كنيسة السيدة العذراء بالسادات',
      'كنيسة الشهيد مارجرجس بالباجور',
      'كنيسة السيدة العذراء ببركة السبع',
    ],
    'البحيرة ومطروح والخمس مدن الغربية': [
      'كاتدرائية السيدة العذراء بدمنهور',
      'كنيسة الشهيد مارجرجس بدمنهور',
      'كنيسة رئيس الملائكة ميخائيل بدمنهور',
      'كنيسة السيدة العذراء بكفر الدوار',
      'كنيسة السيدة العذراء بإيتاي البارود',
      'كنيسة السيدة العذراء بمرسى مطروح',
      'كنيسة السيدة العذراء بالساحل الشمالي',
    ],
    'بورسعيد': [
      'كاتدرائية السيدة العذراء ورئيس الملائكة ميخائيل ببورسعيد',
      'كنيسة الشهيد مارجرجس ببورسعيد',
      'كنيسة القديس مارمرقس ببورسعيد',
      'كنيسة القديس الأنبا بيشوي ببورسعيد',
      'كنيسة السيدة العذراء ببورفؤاد',
    ],
    'الإسماعيلية': [
      'مطرانية القديس الأنبا بولا بالإسماعيلية',
      'كنيسة الشهيد مارجرجس بالإسماعيلية',
      'كنيسة السيدة العذراء بالشيخ زايد بالإسماعيلية',
      'كنيسة رئيس الملائكة ميخائيل بالإسماعيلية',
      'كنيسة السيدة العذراء بالقنطرة غرب',
    ],
    'السويس': [
      'مطرانية السيدة العذراء بالسويس',
      'كنيسة الشهيد مارجرجس بالصباح بالسويس',
      'كنيسة القديس الأنبا أنطونيوس بالسويس',
      'كنيسة رئيس الملائكة ميخائيل بالسويس',
    ],
    'الفيوم': [
      'مطرانية الشهيد مارجرجس بالفيوم',
      'كنيسة السيدة العذراء بالفيوم',
      'كنيسة القديسة دميانة بالفيوم',
      'كنيسة الشهيد مارمينا بالفيوم',
      'كنيسة السيدة العذراء بسنورس',
      'كنيسة الشهيد مارجرجس بإطسا',
    ],
    'بني سويف وببا والفشن': [
      'مطرانية السيدة العذراء ببني سويف',
      'كنيسة الشهيد مارجرجس ببني سويف',
      'كنيسة القديس مارمرقس ببني سويف الجديدة',
      'كنيسة السيدة العذراء بببا',
      'كنيسة الشهيد مارجرجس بالفشن',
      'كنيسة السيدة العذراء بالواسطى',
    ],
    'المنيا وأبوقرقاص ومغاغة وسمالوط ومطاي وملوي وديرمواس': [
      'مطرانية القديس مارمرقس بالمنيا',
      'كنيسة السيدة العذراء بالمنيا',
      'كنيسة الأمير تادرس بالمنيا',
      'كنيسة السيدة العذراء بالمنيا الجديدة',
      'مطرانية الشهيد مارجرجس بأبوقرقاص',
      'مطرانية القديس مارمرقس بملوي',
      'كنيسة السيدة العذراء بسمالوط (جبل الطير)',
      'كنيسة شهداء الإيمان بسمالوط',
      'مطرانية الشهيد مارجرجس بمغاغة',
      'كنيسة السيدة العذراء بمطاي',
      'كنيسة السيدة العذراء ببني مزار',
      'كنيسة السيدة العذراء بديرمواس',
    ],
    'أسيوط وديروط والقوصية ومنفلوط وأبوتيج وأبنوب': [
      'كاتدرائية رئيس الملائكة ميخائيل بأسيوط',
      'كنيسة القديس مارمرقس بأسيوط',
      'كنيسة الشهيد مارجرجس بأسيوط',
      'كنيسة السيدة العذراء بدرنكة',
      'مطرانية السيدة العذراء بالقوصية',
      'مطرانية الشهيد مارجرجس بديروط',
      'مطرانية السيدة العذراء بمنفلوط',
      'مطرانية الشهيد مارجرجس بأبوتيج',
      'مطرانية الشهيد مارجرجس بأبنوب',
      'كنيسة السيدة العذراء بأسيوط الجديدة',
    ],
    'سوهاج وأخميم والبلينا وطما وطهطا وجرجا': [
      'مطرانية الشهيد مارجرجس بسوهاج',
      'كنيسة السيدة العذراء بسوهاج',
      'كنيسة القديس مارمرقس بسوهاج',
      'مطرانية السيدة العذراء بأخميم',
      'مطرانية رئيس الملائكة ميخائيل بجرجا',
      'مطرانية السيدة العذراء بطهطا',
      'مطرانية الشهيد أبوفام بطما',
      'مطرانية السيدة العذراء بالبلينا',
    ],
    'قنا ونجع حمادي ودشنا ونقادة وقوص': [
      'مطرانية القديس مارمرقس بقنا',
      'كنيسة السيدة العذراء بقنا',
      'مطرانية القديس يوحنا الحبيب بنجع حمادي',
      'مطرانية الشهيد مارجرجس بدشنا',
      'مطرانية رئيس الملائكة ميخائيل بنقادة',
      'مطرانية الشهيد إسطفانوس بقوص',
    ],
    'الأقصر وإسنا وأرمنت': [
      'كاتدرائية السيدة العذراء بالأقصر',
      'كنيسة الشهيد مارجرجس بالأقصر',
      'كنيسة رئيس الملائكة ميخائيل بالأقصر',
      'كنيسة السيدة العذراء بإسنا',
      'كنيسة الشهيد مارجرجس بأرمنت',
    ],
    'أسوان وكوم أمبو وإدفو': [
      'كاتدرائية رئيس الملائكة ميخائيل بأسوان',
      'كنيسة السيدة العذراء بأسوان',
      'كنيسة الشهيد مارجرجس بكوم أمبو',
      'كنيسة السيدة العذراء بإدفو',
      'كنيسة السيدة العذراء بدراو',
    ],
    'البحر الأحمر والغردقة': [
      'كاتدرائية القديس الأنبا شنودة بالغردقة',
      'كنيسة السيدة العذراء بالغردقة',
      'كنيسة الشهيد مارجرجس بسفاجا',
      'كنيسة السيدة العذراء بالقصير',
      'كنيسة السيدة العذراء برأس غارب',
    ],
    'الوادي الجديد': [
      'مطرانية السيدة العذراء بالخارجة',
      'كنيسة الشهيد مارجرجس بالداخلة',
      'كنيسة السيدة العذراء بالفرافرة',
    ],
    'شمال وجنوب سيناء': [
      'مطرانية الشهيد مارجرجس بالعريش',
      'كنيسة السيدة العذراء بالعريش',
      'كاتدرائية السمائيين بشرم الشيخ',
      'كنيسة القديس موسى الأسود بطور سيناء',
      'كنيسة السيدة العذراء بدهب',
    ],
    'إيبارشيات المهجر (أوروبا / أمريكا / كندا / أستراليا / الخليج)': [
      'كنيسة القديس مارمرقس – نيوجيرسي / نيويورك',
      'كنيسة السيدة العذراء – لوس أنجلوس / كاليفورنيا',
      'كنيسة القديس مارمرقس – تورونتو / ميسيساجا',
      'كنيسة السيدة العذراء – مونتريال',
      'كنيسة القديس مارمرقس – لندن',
      'كنيسة السيدة العذراء – باريس',
      'كنيسة القديس مارمرقس – فرانكفورت / ألمانيا',
      'كنيسة السيدة العذراء – ميلانو / روما',
      'كنيسة السيدة العذراء والقديس مارمينا – سيدني',
      'كنيسة القديس أثناسيوس – ملبورن',
      'كاتدرائية القديس مارمرقس – الكويت',
      'كنيسة القديس الأنبا أنطونيوس – أبوظبي',
      'كنيسة القديس مارمينا – دبي',
      'كنيسة السيدة العذراء – الدوحة / قطر',
      'كنيسة السيدة العذراء – مسقط / عُمان',
    ],
  };

  static List<String> churchesFor(String diocese) {
    return churchesByDiocese[diocese] ??
        const [
          'كنيسة السيدة العذراء مريم',
          'كنيسة الشهيد مارجرجس',
          'كنيسة القديس مارمرقس الرسول',
          'كنيسة رئيس الملائكة ميخائيل',
          'كنيسة الشهيد مارمينا العجايبي',
        ];
  }
}

enum PriestVerificationStatus { pending, approved, needsInfo }

class PriestProfile {
  final String priestUid;
  final String titlePrefix; // 'القس' | 'القمص'
  final String displayName;
  final String diocese;
  final String church;
  final PriestVerificationStatus verificationStatus;
  final String privateCode; // e.g. 'AB-4829' — fixed private code for Abona's own confession children
  final String vouchedByUid;
  final String vouchedByName;
  final String verificationNote;
  final String adminFeedback;
  final String phoneForVerification;
  final DateTime? updatedAt;

  const PriestProfile({
    required this.priestUid,
    required this.titlePrefix,
    required this.displayName,
    required this.diocese,
    required this.church,
    required this.verificationStatus,
    this.privateCode = '',
    this.vouchedByUid = '',
    this.vouchedByName = '',
    this.verificationNote = '',
    this.adminFeedback = '',
    this.phoneForVerification = '',
    this.updatedAt,
  });

  String get fullDisplayName {
    final name = displayName.trim();
    if (name.startsWith('أبونا') || name.startsWith('القس') || name.startsWith('القمص')) {
      return name;
    }
    return '${titlePrefix.isNotEmpty ? titlePrefix : 'القس'} $name';
  }

  bool get isVerifiedPublic => verificationStatus == PriestVerificationStatus.approved;

  static PriestVerificationStatus parseStatus(String? raw) {
    switch (raw) {
      case 'approved':
        return PriestVerificationStatus.approved;
      case 'needs_info':
        return PriestVerificationStatus.needsInfo;
      default:
        return PriestVerificationStatus.pending;
    }
  }

  static String statusToString(PriestVerificationStatus status) {
    switch (status) {
      case PriestVerificationStatus.approved:
        return 'approved';
      case PriestVerificationStatus.needsInfo:
        return 'needs_info';
      case PriestVerificationStatus.pending:
        return 'pending';
    }
  }

  factory PriestProfile.fromMap(String uid, Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    return PriestProfile(
      priestUid: uid,
      titlePrefix: '${data['titlePrefix'] ?? 'القس'}',
      displayName: '${data['displayName'] ?? ''}',
      diocese: '${data['diocese'] ?? ''}',
      church: '${data['church'] ?? ''}',
      verificationStatus: parseStatus(data['verificationStatus']?.toString()),
      privateCode: '${data['privateCode'] ?? ''}',
      vouchedByUid: '${data['vouchedByUid'] ?? ''}',
      vouchedByName: '${data['vouchedByName'] ?? ''}',
      verificationNote: '${data['verificationNote'] ?? ''}',
      adminFeedback: '${data['adminFeedback'] ?? ''}',
      phoneForVerification: '${data['phoneForVerification'] ?? ''}',
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Single-use peer-priest vouch invite code (e.g. KN-7391) issued by an approved priest
class PriestVouchInvite {
  final String code;
  final String issuerUid;
  final String issuerName;
  final String issuerChurch;
  final bool used;
  final String usedByUid;
  final String usedByName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const PriestVouchInvite({
    required this.code,
    required this.issuerUid,
    required this.issuerName,
    required this.issuerChurch,
    required this.used,
    this.usedByUid = '',
    this.usedByName = '',
    this.createdAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory PriestVouchInvite.fromMap(String code, Map<String, dynamic> data) {
    final cTs = data['createdAt'];
    final eTs = data['expiresAt'];
    return PriestVouchInvite(
      code: code,
      issuerUid: '${data['issuerUid'] ?? ''}',
      issuerName: '${data['issuerName'] ?? ''}',
      issuerChurch: '${data['issuerChurch'] ?? ''}',
      used: data['used'] == true,
      usedByUid: '${data['usedByUid'] ?? ''}',
      usedByName: '${data['usedByName'] ?? ''}',
      createdAt: cTs is Timestamp ? cTs.toDate() : null,
      expiresAt: eTs is Timestamp ? eTs.toDate() : null,
    );
  }
}

class ConfessionSession {
  final String id;
  final String priestUid;
  final String priestName;
  final String church;
  final String diocese;
  final String dateIso; // yyyy-MM-dd
  final String dayLabelAr; // e.g. 'الجمعة ٢٧ نوفمبر'
  final String startTimeAr; // e.g. '٥:٠٠ مساءً'
  final String locationNote; // optional e.g. 'مكتب الاعتراف بالكنيسة'
  final int? maxAttendees; // null = عدد مفتوح
  final bool isOpen; // false = أبونا قفل التسجيل
  final int confirmedCount;
  final int waitlistCount;
  final DateTime? createdAt;

  const ConfessionSession({
    required this.id,
    required this.priestUid,
    required this.priestName,
    required this.church,
    required this.diocese,
    required this.dateIso,
    required this.dayLabelAr,
    required this.startTimeAr,
    this.locationNote = '',
    this.maxAttendees,
    required this.isOpen,
    required this.confirmedCount,
    required this.waitlistCount,
    this.createdAt,
  });

  bool get isUnlimited => maxAttendees == null || maxAttendees! <= 0;
  bool get isFull => !isUnlimited && confirmedCount >= maxAttendees!;

  factory ConfessionSession.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final rawMax = data['maxAttendees'];
    return ConfessionSession(
      id: id,
      priestUid: '${data['priestUid'] ?? ''}',
      priestName: '${data['priestName'] ?? ''}',
      church: '${data['church'] ?? ''}',
      diocese: '${data['diocese'] ?? ''}',
      dateIso: '${data['dateIso'] ?? ''}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
      locationNote: '${data['locationNote'] ?? ''}',
      maxAttendees: rawMax is num && rawMax.toInt() > 0 ? rawMax.toInt() : null,
      isOpen: data['isOpen'] != false,
      confirmedCount: (data['confirmedCount'] as num?)?.toInt() ?? 0,
      waitlistCount: (data['waitlistCount'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class ConfessionAttendee {
  final String attendeeUid;
  final String sessionId;
  final String attendeeName;
  final String status; // 'confirmed' | 'waitlist' | 'cancelled'
  final String dayLabelAr;
  final String startTimeAr;
  final DateTime? updatedAt;

  const ConfessionAttendee({
    required this.attendeeUid,
    required this.sessionId,
    required this.attendeeName,
    required this.status,
    required this.dayLabelAr,
    required this.startTimeAr,
    this.updatedAt,
  });

  factory ConfessionAttendee.fromMap(String uid, Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    return ConfessionAttendee(
      attendeeUid: uid,
      sessionId: '${data['sessionId'] ?? ''}',
      attendeeName: '${data['attendeeName'] ?? ''}',
      status: '${data['status'] ?? 'confirmed'}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class PriestNotificationItem {
  final String id;
  final String type; // 'registered' | 'waitlist' | 'cancelled'
  final String attendeeUid;
  final String attendeeName;
  final String sessionId;
  final String dayLabelAr;
  final String startTimeAr;
  final bool read;
  final DateTime? createdAt;

  const PriestNotificationItem({
    required this.id,
    required this.type,
    required this.attendeeUid,
    required this.attendeeName,
    required this.sessionId,
    required this.dayLabelAr,
    required this.startTimeAr,
    required this.read,
    this.createdAt,
  });

  String get indoorDetailedMessage {
    if (type == 'cancelled') {
      return '$attendeeName اعتذر(ت) عن موعد الاعتراف يوم $dayLabelAr.';
    }
    if (type == 'waitlist') {
      return '$attendeeName انضمّ لقائمة الانتظار للاعتراف عند قدسك يوم $dayLabelAr.';
    }
    return '$attendeeName سجّل(ت) حضور للاعتراف عند قدسك يوم $dayLabelAr (ابتداءً من $startTimeAr).';
  }

  factory PriestNotificationItem.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return PriestNotificationItem(
      id: id,
      type: '${data['type'] ?? 'registered'}',
      attendeeUid: '${data['attendeeUid'] ?? ''}',
      attendeeName: '${data['attendeeName'] ?? ''}',
      sessionId: '${data['sessionId'] ?? ''}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
      read: data['read'] == true,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

enum AttendanceActionStatus {
  confirmed,
  alreadyConfirmed,
  waitlisted,
  alreadyWaitlisted,
  sessionClosed,
  sessionFull,
  cancelled,
  notSignedIn,
  offlineError,
}

class AttendanceActionResult {
  final AttendanceActionStatus status;
  final String message;

  const AttendanceActionResult({required this.status, required this.message});
}

// =============================================================================
// PRIEST PRIVATE ON-DEVICE PASTORAL CARE MODELS (100% AES-256 LOCAL ONLY)
// =============================================================================

/// Altar Litany Commemoration Name (المرضى • الراقدين • المسافرين • ضيقات • شكر)
class AltarNameItem {
  final String id;
  final String name;
  final String category; // 'sick' | 'departed' | 'travelers' | 'distressed' | 'thanksgiving'
  final String note;
  final String createdAtIso;

  const AltarNameItem({
    required this.id,
    required this.name,
    required this.category,
    this.note = '',
    required this.createdAtIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'note': note,
        'createdAtIso': createdAtIso,
      };

  factory AltarNameItem.fromJson(Map<String, dynamic> j) => AltarNameItem(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        category: '${j['category'] ?? 'sick'}',
        note: '${j['note'] ?? ''}',
        createdAtIso: '${j['createdAtIso'] ?? ''}',
      );
}

/// Private Pastoral Visitation Entry (دفتر الافتقاد — محلي مشفر 100%)
class VisitationEntry {
  final String id;
  final String personName;
  final String area;
  final String phone;
  final String tag; // 'مريض' | 'أسرة' | 'مسن' | 'شاب' | 'ضيقة'
  final String note;
  final bool visited;
  final bool plannedByMe; // «أنا هروح أفتقده» (في خطتي للافتقاد)
  final String updatedAtIso;

  const VisitationEntry({
    required this.id,
    required this.personName,
    this.area = '',
    this.phone = '',
    this.tag = 'أسرة',
    this.note = '',
    this.visited = false,
    this.plannedByMe = false,
    required this.updatedAtIso,
  });

  VisitationEntry copyWith({
    String? personName,
    String? area,
    String? phone,
    String? tag,
    String? note,
    bool? visited,
    bool? plannedByMe,
    String? updatedAtIso,
  }) =>
      VisitationEntry(
        id: id,
        personName: personName ?? this.personName,
        area: area ?? this.area,
        phone: phone ?? this.phone,
        tag: tag ?? this.tag,
        note: note ?? this.note,
        visited: visited ?? this.visited,
        plannedByMe: plannedByMe ?? this.plannedByMe,
        updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'area': area,
        'phone': phone,
        'tag': tag,
        'note': note,
        'visited': visited,
        'plannedByMe': plannedByMe,
        'updatedAtIso': updatedAtIso,
      };

  factory VisitationEntry.fromJson(Map<String, dynamic> j) => VisitationEntry(
        id: '${j['id'] ?? ''}',
        personName: '${j['personName'] ?? ''}',
        area: '${j['area'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        tag: '${j['tag'] ?? 'أسرة'}',
        note: '${j['note'] ?? ''}',
        visited: j['visited'] == true,
        plannedByMe: j['plannedByMe'] == true,
        updatedAtIso: '${j['updatedAtIso'] ?? ''}',
      );
}

/// Priest Sermon Preparation Note (تحضير العظات — محلي 100%)
class SermonNote {
  final String id;
  final String title;
  final String occasion;
  final String scriptureRef;
  final String points;
  final String patristicQuote;
  final String updatedAtIso;

  const SermonNote({
    required this.id,
    required this.title,
    this.occasion = '',
    this.scriptureRef = '',
    this.points = '',
    this.patristicQuote = '',
    required this.updatedAtIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'occasion': occasion,
        'scriptureRef': scriptureRef,
        'points': points,
        'patristicQuote': patristicQuote,
        'updatedAtIso': updatedAtIso,
      };

  factory SermonNote.fromJson(Map<String, dynamic> j) => SermonNote(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        occasion: '${j['occasion'] ?? ''}',
        scriptureRef: '${j['scriptureRef'] ?? ''}',
        points: '${j['points'] ?? ''}',
        patristicQuote: '${j['patristicQuote'] ?? ''}',
        updatedAtIso: '${j['updatedAtIso'] ?? ''}',
      );
}
