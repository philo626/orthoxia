import 'coptic_calendar_service.dart';

class CopticFastStatus {
  final bool isFastingToday;
  final String title;
  final String degree; // 'صوم من الدرجة الأولى', 'صوم من الدرجة الثانية', 'يوم فطر / فرح روحي'
  final bool fishAllowed;
  final String abstinenceGuide;
  final String nextFeastName;
  final int daysToNextFeast;
  final String spiritualMessage;

  const CopticFastStatus({
    required this.isFastingToday,
    required this.title,
    required this.degree,
    required this.fishAllowed,
    required this.abstinenceGuide,
    required this.nextFeastName,
    required this.daysToNextFeast,
    required this.spiritualMessage,
  });
}

class CopticFastService {
  static CopticFastStatus getTodayFastStatus([DateTime? date]) {
    final now = date ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final coptic = CopticCalendarService.fromGregorian(today);
    final easter = CopticCalendarService.computeOrthodoxEaster(today.year);

    final jonahStart = easter.subtract(const Duration(days: 69));
    final jonahEnd = easter.subtract(const Duration(days: 67));
    final greatLentStart = easter.subtract(const Duration(days: 55));
    final pentecostSunday = easter.add(const Duration(days: 49));
    final apostlesFastStart = easter.add(const Duration(days: 50));

    final isWedOrFri = today.weekday == DateTime.wednesday || today.weekday == DateTime.friday;

    // 1. Jonah's Fast (3 days)
    if (!today.isBefore(jonahStart) && !today.isAfter(jonahEnd)) {
      final rem = jonahEnd.difference(today).inDays + 1;
      return CopticFastStatus(
        isFastingToday: true,
        title: 'صوم نينوى (يونان النبي)',
        degree: 'صوم من الدرجة الأولى',
        fishAllowed: false,
        abstinenceGuide: 'انقطاع حتى الغروب أو الساعة الثالثة ظهراً • لا يُؤكل فيه السمك',
        nextFeastName: 'فصح يونان',
        daysToNextFeast: rem,
        spiritualMessage: 'أهل نينوى صاموا بتوبة صادقة فرفع الله عنهم الغضب وأحاطهم بمراحمه.',
      );
    }

    // 2. Great Lent & Holy Week (55 days before Easter)
    if (!today.isBefore(greatLentStart) && today.isBefore(easter)) {
      final rem = easter.difference(today).inDays;
      final isHolyWeek = rem <= 7;
      return CopticFastStatus(
        isFastingToday: true,
        title: isHolyWeek ? 'أسبوع البصخة المقدسة (أسبوع الآلام)' : 'الصوم الأربعيني المقدس (الصوم الكبير)',
        degree: 'صوم من الدرجة الأولى (أقدس أصوام الكنيسة)',
        fishAllowed: false,
        abstinenceGuide: 'صوم انقطاعي ونباتي كامل بدون سمك • تتلى فيه النبوات ومطانيات التوبة',
        nextFeastName: 'عيد القيامة المجيد',
        daysToNextFeast: rem,
        spiritualMessage: 'الصوم الكبير هو ربيع النفس ورحلة شركة حب نحو الصليب والقيامة.',
      );
    }

    // 3. Holy 50 Days (Pentecost Period - No fasting at all!)
    if (!today.isBefore(easter) && !today.isAfter(pentecostSunday)) {
      final rem = pentecostSunday.difference(today).inDays;
      return CopticFastStatus(
        isFastingToday: false,
        title: 'أيام الخماسين المقدسة المفرحة',
        degree: 'فترة فرح بالقيامة (لا صوم ولا مطانيات)',
        fishAllowed: true,
        abstinenceGuide: 'تُعامل الخماسين كأحد واحد متصل من الفرح بالقيامة، فلا يُصام فيها الأربعاء والجمعة.',
        nextFeastName: 'عيد العنصرة (حلول الروح القدس)',
        daysToNextFeast: rem,
        spiritualMessage: 'إخرستوس آنستي! افرحوا في الرب كل حين ببهجة القيامة.',
      );
    }

    // 4. Apostles' Fast (Starts Monday after Pentecost until 5 Abib)
    if (!today.isBefore(apostlesFastStart) &&
        (coptic.month < 11 || (coptic.month == 11 && coptic.day < 5))) {
      final fishToday = !isWedOrFri;
      return CopticFastStatus(
        isFastingToday: true,
        title: 'صوم الآباء الرسل الأطهار',
        degree: 'صوم من الدرجة الثانية (صوم الخدمة والكرازة)',
        fishAllowed: fishToday,
        abstinenceGuide: fishToday
            ? 'يُسمح اليوم بأكل السمك تخفيفاً على المؤمنين (ما عدا الأربعاء والجمعة)'
            : 'اليوم (${today.weekday == DateTime.wednesday ? "الأربعاء" : "الجمعة"}) يُصام بدون سمك',
        nextFeastName: 'عيد الآباء الرسل (٥ أبيب)',
        daysToNextFeast: (coptic.month == 11 ? (5 - coptic.day).clamp(1, 30) : (35 - coptic.day).clamp(1, 60)),
        spiritualMessage: 'صوم الآباء الرسل هو أول صوم صامته الكنيسة بعد حلول الروح القدس من أجل الخدمة.',
      );
    }

    // 5. Fast of the Virgin Mary (1 Mesra to 15 Mesra)
    if (coptic.month == 12 && coptic.day >= 1 && coptic.day < 16) {
      final rem = 16 - coptic.day;
      final fishToday = !isWedOrFri;
      return CopticFastStatus(
        isFastingToday: true,
        title: 'صوم السيدة العذراء مريم',
        degree: 'صوم من الدرجة الثانية (محبوب جداً لدى الشعب القبطي)',
        fishAllowed: fishToday,
        abstinenceGuide: fishToday
            ? 'يُسمح فيه بالسمك (ما عدا الأربعاء والجمعة)، وكثيرون يصومونه بنسك خاص محبةً في العذراء'
            : 'اليوم (${today.weekday == DateTime.wednesday ? "الأربعاء" : "الجمعة"}) يُصام بدون سمك',
        nextFeastName: 'عيد إظهار صعود جسد السيدة العذراء (١٦ مسرى)',
        daysToNextFeast: rem,
        spiritualMessage: 'طوباكِ يا مريم يا أم النور؛ صومك يملأ البيوت نهضات وتماجيد وبركة.',
      );
    }

    // 6. Nativity Fast (16 Hatour to 28 Kiahk)
    if ((coptic.month == 3 && coptic.day >= 16) || (coptic.month == 4 && coptic.day < 29)) {
      final isParamoun = coptic.month == 4 && coptic.day >= 26;
      final fishToday = !isWedOrFri && !isParamoun;
      final rem = coptic.month == 4 ? (29 - coptic.day) : (30 - coptic.day + 29);
      return CopticFastStatus(
        isFastingToday: true,
        title: isParamoun ? 'برامون عيد الميلاد المجيد' : 'صوم الميلاد المجيد (٤٣ يوماً)',
        degree: isParamoun ? 'صوم من الدرجة الأولى (البرامون)' : 'صوم من الدرجة الثانية',
        fishAllowed: fishToday,
        abstinenceGuide: fishToday
            ? 'يُسمح اليوم بأكل السمك (ما عدا الأربعاء والجمعة وأيام البرامون)'
            : 'اليوم يُصام بدون سمك استعداداً لاستقبال ميلاد مخلصنا الصالح',
        nextFeastName: 'عيد الميلاد المجيد (٢٩ كيهك)',
        daysToNextFeast: rem,
        spiritualMessage: 'استعد بقلب متضع كالمذود ليولد فيه ملك السلام.',
      );
    }

    // 7. Weekly Wednesday & Friday Fast
    if (isWedOrFri) {
      final dayName = today.weekday == DateTime.wednesday ? 'الأربعاء' : 'الجمعة';
      return CopticFastStatus(
        isFastingToday: true,
        title: 'صوم يوم $dayName الأسبوعي',
        degree: 'صوم من الدرجة الأولى',
        fishAllowed: false,
        abstinenceGuide: 'انقطاع حتى الساعة التاسعة قبطية (٣ عصراً) أو حسب إرشاد أب الاعتراف • بدون سمك',
        nextFeastName: 'قداس الأحد القادم',
        daysToNextFeast: (DateTime.sunday - today.weekday) % 7,
        spiritualMessage: today.weekday == DateTime.wednesday
            ? 'نصوم الأربعاء تذكاراً للتآمر على السيد المسيح، طالبين الأمانة له.'
            : 'نصوم الجمعة تذكاراً لصلب وفداء ربنا يسوع المسيح على عود الصليب.',
      );
    }

    // 8. Regular Non-Fasting Day
    return const CopticFastStatus(
      isFastingToday: false,
      title: 'يوم سنوي مبارك (غير صيامي)',
      degree: 'يوم فطر وشكر لله',
      fishAllowed: true,
      abstinenceGuide: 'لا يوجد صوم انقطاعي اليوم (إلا للمتقدمين للتناول في القداس الإلهي)',
      nextFeastName: 'صوم الأربعاء والجمعة الأسبوعي',
      daysToNextFeast: 2,
      spiritualMessage: 'كلوا واشربوا بشكر لمجد الله، واجعلوا يومكم مملوءاً بالصلاة والمحبة.',
    );
  }
}
