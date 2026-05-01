class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultTarget,
    this.arabicText,
    this.meaning,
    this.longMeaning,
    this.isFavorite = false,
    this.isBuiltIn = true,
  });

  final String id;
  final String name;
  final String category;
  final int defaultTarget;
  final String? arabicText;
  final String? meaning;
  final String? longMeaning;
  final bool isFavorite;
  final bool isBuiltIn;

  DhikrItem copyWith({bool? isFavorite, int? defaultTarget}) {
    return DhikrItem(
      id: id,
      name: name,
      category: category,
      defaultTarget: defaultTarget ?? this.defaultTarget,
      arabicText: arabicText,
      meaning: meaning,
      longMeaning: longMeaning,
      isFavorite: isFavorite ?? this.isFavorite,
      isBuiltIn: isBuiltIn,
    );
  }
}
