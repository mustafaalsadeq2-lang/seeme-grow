class AgeResult {
  final int years;
  final int months;
  final int days;

  const AgeResult({
    required this.years,
    required this.months,
    required this.days,
  });

  @override
  String toString() {
    final parts = <String>[];
    if (years > 0) parts.add('$years years');
    if (months > 0) parts.add('$months months');
    if (days > 0) parts.add('$days days');
    return parts.isEmpty ? 'Newborn' : parts.join(' · ');
  }
}

class AgeCalculator {
  /// العمر الحالي (يتحدّث تلقائيًا يوميًا)
  static AgeResult currentAge(DateTime birthDate) {
    return _calculate(birthDate, DateTime.now());
  }

  /// العمر عند سنة معيّنة (Birth / Year N)
  static AgeResult ageAtYear(DateTime birthDate, int year) {
    final targetDate = DateTime(
      birthDate.year + year,
      birthDate.month,
      birthDate.day,
    );
    return _calculate(birthDate, targetDate);
  }

  static AgeResult _calculate(DateTime birth, DateTime target) {
    int years = target.year - birth.year;
    int months = target.month - birth.month;
    int days = target.day - birth.day;

    if (days < 0) {
      months--;
      final prevMonth =
          DateTime(target.year, target.month, 0).day;
      days += prevMonth;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    return AgeResult(
      years: years < 0 ? 0 : years,
      months: months < 0 ? 0 : months,
      days: days < 0 ? 0 : days,
    );
  }
}
