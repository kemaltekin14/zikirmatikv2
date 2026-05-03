import '../../dhikr_library/domain/dhikr_item.dart';

class EsmaItem {
  const EsmaItem({
    required this.number,
    required this.name,
    required this.arabicText,
    required this.dhikrName,
    required this.dhikrArabicText,
    required this.meaning,
    required this.category,
    required this.ebcedNumber,
    this.explanation,
  });

  final int number;
  final String name;
  final String arabicText;
  final String dhikrName;
  final String dhikrArabicText;
  final String meaning;
  final String category;
  final int ebcedNumber;
  final String? explanation;

  bool get hasDisplayNumber => number > 0;

  EsmaCategoryIcon get categoryIcon {
    return switch (category) {
      'Rahmet' => EsmaCategoryIcon.heart,
      'Rızık' => EsmaCategoryIcon.leaf,
      'Koruma' => EsmaCategoryIcon.shield,
      'Hikmet' => EsmaCategoryIcon.balance,
      'Celal' => EsmaCategoryIcon.crown,
      'Mülk' => EsmaCategoryIcon.crown,
      'Yaratılış' => EsmaCategoryIcon.spark,
      _ => EsmaCategoryIcon.star,
    };
  }

  DhikrItem toDhikr() {
    return DhikrItem(
      id: 'esma-$number',
      name: dhikrName,
      arabicText: dhikrArabicText,
      meaning: meaning,
      longMeaning: explanation,
      category: 'Esma-ül Hüsna',
      defaultTarget: ebcedNumber,
    );
  }
}

enum EsmaCategoryIcon { heart, crown, star, leaf, shield, balance, spark }
