import '../domain/dhikr_item.dart';

const builtinDhikrs = [
  DhikrItem(
    id: 'subhanallah',
    name: 'Subhanallah',
    arabicText: 'سبحان الله',
    meaning: 'Allah her türlü eksiklikten uzaktır.',
    category: 'Tesbih',
    defaultTarget: 33,
  ),
  DhikrItem(
    id: 'elhamdulillah',
    name: 'Elhamdulillah',
    arabicText: 'الحمد لله',
    meaning: 'Hamd Allah içindir.',
    category: 'Tesbih',
    defaultTarget: 33,
  ),
  DhikrItem(
    id: 'allahu-ekber',
    name: 'Allahu Ekber',
    arabicText: 'الله أكبر',
    meaning: 'Allah en büyüktür.',
    category: 'Tesbih',
    defaultTarget: 33,
  ),
  DhikrItem(
    id: 'estagfirullah',
    name: 'Estağfirullah',
    arabicText: 'أستغفر الله',
    meaning: 'Allah’tan bağışlanma dilerim.',
    category: 'İstiğfar',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'la-ilahe-illallah',
    name: 'La ilahe illallah',
    arabicText: 'لا إله إلا الله',
    meaning: 'Allah’tan başka ilah yoktur.',
    category: 'Tevhid',
    defaultTarget: 100,
  ),
];
