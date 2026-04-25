import '../../dhikr_library/domain/dhikr_item.dart';

class EsmaItem {
  const EsmaItem({
    required this.number,
    required this.name,
    required this.arabicText,
    required this.meaning,
  });

  final int number;
  final String name;
  final String arabicText;
  final String meaning;

  DhikrItem toDhikr() {
    return DhikrItem(
      id: 'esma-$number',
      name: name,
      arabicText: arabicText,
      meaning: meaning,
      category: 'Esmaül Hüsna',
      defaultTarget: 100,
    );
  }
}
