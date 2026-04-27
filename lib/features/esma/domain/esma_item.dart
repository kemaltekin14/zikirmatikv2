import '../../dhikr_library/domain/dhikr_item.dart';

class EsmaItem {
  const EsmaItem({
    required this.number,
    required this.name,
    required this.arabicText,
    required this.meaning,
    required this.category,
    required this.categoryIcon,
  });

  final int number;
  final String name;
  final String arabicText;
  final String meaning;
  final String category;
  final EsmaCategoryIcon categoryIcon;

  DhikrItem toDhikr() {
    return DhikrItem(
      id: 'esma-$number',
      name: name,
      arabicText: arabicText,
      meaning: meaning,
      category: 'Esma-ül Hüsna',
      defaultTarget: 100,
    );
  }
}

enum EsmaCategoryIcon { heart, crown, starOutline, starFilled }
