import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/app_database.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../../shared/widgets/app_time_picker.dart';
import '../../../shared/widgets/notification_permission_prompt.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dhikr_library/application/dhikr_providers.dart';
import '../../dhikr_library/data/builtin_dhikrs.dart';
import '../../dhikr_library/domain/dhikr_item.dart';
import '../application/local_notification_service.dart';
import '../application/reminder_providers.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _mutedText = Color(0xFF69766E);
const _cardSurface = Color(0xFFFAFAF4);
const _paleSage = Color(0xFFE5ECE2);
const _gold = Color(0xFFCDAA3B);
const _softGold = Color(0xFFE9D798);
const _heroAsset = 'assets/images/hatirlaticilar-hero.webp';
const _heroSearchBackdropExtension = 20.0;
const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;
const _focusCardPalettes = [
  _FocusCardPalette(
    start: Color(0xFF0B3022),
    middle: Color(0xFF176040),
    end: Color(0xFF113B2B),
    accent: _softGold,
  ),
  _FocusCardPalette(
    start: Color(0xFF0B3436),
    middle: Color(0xFF23786D),
    end: Color(0xFF103E3A),
    accent: Color(0xFFBFE6D7),
  ),
  _FocusCardPalette(
    start: Color(0xFF243821),
    middle: Color(0xFF607C41),
    end: Color(0xFF1D3321),
    accent: Color(0xFFE4D98D),
  ),
  _FocusCardPalette(
    start: Color(0xFF17354A),
    middle: Color(0xFF2B7076),
    end: Color(0xFF123243),
    accent: Color(0xFFB9E0E6),
  ),
];
const _allReminderWeekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
};
const _weekdayReminderDays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};
const _weekendReminderDays = {DateTime.saturday, DateTime.sunday};

const _weekdayShortLabels = {
  DateTime.monday: 'Pzt',
  DateTime.tuesday: 'Sal',
  DateTime.wednesday: 'Çar',
  DateTime.thursday: 'Per',
  DateTime.friday: 'Cum',
  DateTime.saturday: 'Cmt',
  DateTime.sunday: 'Paz',
};

const _weekdayLongLabels = {
  DateTime.monday: 'Pazartesi',
  DateTime.tuesday: 'Salı',
  DateTime.wednesday: 'Çarşamba',
  DateTime.thursday: 'Perşembe',
  DateTime.friday: 'Cuma',
  DateTime.saturday: 'Cumartesi',
  DateTime.sunday: 'Pazar',
};

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

String _timeLabel(ReminderRecord reminder) {
  final hour = reminder.hour.toString().padLeft(2, '0');
  final minute = reminder.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _timePartsLabel(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const _reminderPresets = [
  _ReminderPreset(
    title: 'Sabah bereketi',
    body: 'Güne zikirle yumuşak bir başlangıç yap.',
    hour: 7,
    minute: 15,
    note: 'Gün açılırken',
    icon: Icons.wb_sunny_rounded,
    accent: Color(0xFFD4A93F),
  ),
  _ReminderPreset(
    title: 'Öğle nefesi',
    body: 'Kısa bir duraklama, derin bir zikir.',
    hour: 13,
    minute: 10,
    note: 'Günün ortası',
    icon: Icons.light_mode_rounded,
    accent: Color(0xFF4E9671),
  ),
  _ReminderPreset(
    title: 'Akşam huzuru',
    body: 'Günü şükürle kapat; gönlün huzurla dolsun.',
    hour: 20,
    minute: 45,
    note: 'Akşam kapanışı',
    icon: Icons.nights_stay_rounded,
    accent: Color(0xFF2F6E58),
  ),
  _ReminderPreset(
    title: 'Günlük hedef',
    body: 'Bugünkü zikir hedefin seni bekliyor.',
    hour: 21,
    minute: 15,
    note: 'Hedef takibi',
    icon: Icons.flag_rounded,
    accent: Color(0xFFC69A35),
  ),
  _ReminderPreset(
    title: 'Gece sükuneti',
    body: 'Uyku öncesi gönlüne zikirle huzur bırak.',
    hour: 22,
    minute: 30,
    note: 'Sessiz vakit',
    icon: Icons.bedtime_rounded,
    accent: Color(0xFF7D8D72),
  ),
];

const _rhythmWindows = [
  _RhythmWindow(
    label: 'Sabah',
    startHour: 4,
    endHour: 11,
    icon: Icons.wb_sunny_rounded,
  ),
  _RhythmWindow(
    label: 'Öğle',
    startHour: 11,
    endHour: 17,
    icon: Icons.light_mode_rounded,
  ),
  _RhythmWindow(
    label: 'Akşam',
    startHour: 17,
    endHour: 21,
    icon: Icons.wb_twilight_rounded,
  ),
  _RhythmWindow(
    label: 'Gece',
    startHour: 21,
    endHour: 4,
    icon: Icons.dark_mode_rounded,
  ),
];

class _ReminderPreset {
  const _ReminderPreset({
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.note,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final int hour;
  final int minute;
  final String note;
  final IconData icon;
  final Color accent;
}

class _FocusCardPalette {
  const _FocusCardPalette({
    required this.start,
    required this.middle,
    required this.end,
    required this.accent,
  });

  final Color start;
  final Color middle;
  final Color end;
  final Color accent;
}

class _RhythmWindow {
  const _RhythmWindow({
    required this.label,
    required this.startHour,
    required this.endHour,
    required this.icon,
  });

  final String label;
  final int startHour;
  final int endHour;
  final IconData icon;
}

List<ReminderRecord> _upcomingEnabledReminders(
  List<ReminderRecord> reminders, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  return reminders.where((reminder) => reminder.enabled).toList()..sort((a, b) {
    final nextA = _nextOccurrence(a, reference);
    final nextB = _nextOccurrence(b, reference);
    final occurrenceCompare = nextA.compareTo(nextB);
    if (occurrenceCompare != 0) return occurrenceCompare;
    final hourCompare = a.hour.compareTo(b.hour);
    if (hourCompare != 0) return hourCompare;
    return a.minute.compareTo(b.minute);
  });
}

Duration _delayUntil(ReminderRecord reminder, DateTime now) {
  return _nextOccurrence(reminder, now).difference(now);
}

DateTime _nextOccurrence(ReminderRecord reminder, DateTime now) {
  final repeatDays = _repeatDaysFor(reminder);
  var scheduled = DateTime(
    now.year,
    now.month,
    now.day,
    reminder.hour,
    reminder.minute,
  );
  while (!repeatDays.contains(scheduled.weekday) || !scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

String _delayLabel(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes <= 1) return 'birazdan';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes dk sonra';
  if (minutes == 0) return '$hours saat sonra';
  return '$hours s $minutes dk sonra';
}

bool _hasPresetReminder(
  List<ReminderRecord> reminders,
  _ReminderPreset preset,
) {
  return reminders.any(
    (reminder) =>
        reminder.hour == preset.hour &&
        reminder.minute == preset.minute &&
        _repeatDaysFor(reminder).containsAll(_allReminderWeekdays),
  );
}

DhikrItem? _dhikrForReminder(ReminderRecord reminder, List<DhikrItem> dhikrs) {
  final targetId = reminder.targetDhikrId;
  if (targetId == null) return null;
  for (final dhikr in dhikrs) {
    if (dhikr.id == targetId) return dhikr;
  }
  return null;
}

Set<int> _repeatDaysFor(ReminderRecord reminder) {
  return _repeatDaysFromValue(reminder.repeatDays);
}

Set<int> _repeatDaysFromValue(String value) {
  final days = value
      .split(',')
      .map((part) => int.tryParse(part.trim()))
      .whereType<int>()
      .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
      .toSet();
  return days.isEmpty ? _allReminderWeekdays : days;
}

String _repeatDaysLabel(Set<int> repeatDays) {
  if (repeatDays.length == _allReminderWeekdays.length &&
      repeatDays.containsAll(_allReminderWeekdays)) {
    return 'Her gün';
  }
  if (repeatDays.length == 5 && repeatDays.containsAll(_weekdayReminderDays)) {
    return 'Hafta içi';
  }
  if (repeatDays.length == 2 && repeatDays.containsAll(_weekendReminderDays)) {
    return 'Hafta sonu';
  }
  if (repeatDays.length == 1) {
    return 'Sadece ${_weekdayLongLabels[repeatDays.first]}';
  }
  final sorted = repeatDays.toList()..sort();
  return sorted.map((day) => _weekdayShortLabels[day]).join(', ');
}

bool _hourInWindow(int hour, _RhythmWindow window) {
  if (window.startHour < window.endHour) {
    return hour >= window.startHour && hour < window.endHour;
  }
  return hour >= window.startHour || hour < window.endHour;
}

int _enabledCountInWindow(
  List<ReminderRecord> reminders,
  _RhythmWindow window,
) {
  return reminders
      .where(
        (reminder) => reminder.enabled && _hourInWindow(reminder.hour, window),
      )
      .length;
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final horizontalInset = (screenWidth - contentWidth) / 2;
    final safeBottom = media.padding.bottom;
    final bottomNavHeight = _bottomNavBaseHeight * scale;
    final bottomNavOffset = _bottomNavBottomOffset(safeBottom, scale);
    final bottomReservedHeight = bottomNavHeight + bottomNavOffset;
    final scrollBottomPadding =
        bottomReservedHeight + _scrollExtraBottomSpacing * scale;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.12).toDouble();
    final reminders = ref.watch(remindersProvider);
    final dhikrs = ref
        .watch(dhikrItemsProvider)
        .maybeWhen(data: (items) => items, orElse: () => builtinDhikrs);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _pageBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: _pageBackground,
          extendBody: true,
          drawer: const AppMenuDrawer(),
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _pageBackground)),
              Positioned.fill(
                bottom: bottomReservedHeight,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: scrollBottomPadding),
                  children: [
                    _RemindersHero(
                      scale: scale,
                      safeTop: media.padding.top,
                      contentWidth: contentWidth,
                      horizontalInset: horizontalInset,
                    ),
                    SizedBox(height: 2 * scale),
                    reminders.when(
                      data: (items) => _RemindersContent(
                        reminders: items,
                        dhikrs: dhikrs,
                        scale: scale,
                        horizontalInset: horizontalInset,
                        onAdd: () =>
                            _showAddReminderDialog(context, ref, dhikrs),
                        onPresetAdd: (preset) async {
                          final notifications = ref.read(
                            localNotificationServiceProvider,
                          );
                          final notificationsAllowed =
                              await ensureNotificationPermissionForReminder(
                                context: context,
                                areNotificationsAllowed:
                                    notifications.areNotificationsAllowed,
                                requestPermission:
                                    notifications.requestNotificationPermission,
                              );
                          if (!notificationsAllowed || !context.mounted) {
                            return;
                          }

                          await ref
                              .read(reminderRepositoryProvider)
                              .addReminder(
                                title: preset.title,
                                body: preset.body,
                                hour: preset.hour,
                                minute: preset.minute,
                                repeatDays: _allReminderWeekdays,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${preset.title} her gün ${_timePartsLabel(preset.hour, preset.minute)} için eklendi.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onToggle: (reminder, value) => ref
                            .read(reminderRepositoryProvider)
                            .setEnabled(reminder, value),
                        onDelete: (reminder) => ref
                            .read(reminderRepositoryProvider)
                            .delete(reminder),
                      ),
                      error: (error, stackTrace) => _ReminderLoadState(
                        scale: scale,
                        horizontalInset: horizontalInset,
                        icon: Icons.error_outline_rounded,
                        title: 'Hatırlatıcılar yüklenemedi',
                        message: '$error',
                      ),
                      loading: () => _ReminderLoadState(
                        scale: scale,
                        horizontalInset: horizontalInset,
                        icon: Icons.notifications_active_rounded,
                        title: 'Hatırlatıcılar hazırlanıyor',
                        message: 'Kayıtlar birazdan açılacak.',
                        loading: true,
                      ),
                    ),
                  ],
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.none,
                quickStartKey: const Key('reminders.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemindersHero extends StatelessWidget {
  const _RemindersHero({
    required this.scale,
    required this.safeTop,
    required this.contentWidth,
    required this.horizontalInset,
  });

  final double scale;
  final double safeTop;
  final double contentWidth;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    const heroAssetVisualScale = 0.83;
    const heroAssetBaseWidth = appLayoutBaselineWidth;
    final heroHeight = (88 + _heroSearchBackdropExtension) * scale + safeTop;
    final heroAssetTop = contentWidth < appLayoutBaselineWidth
        ? -12 * scale
        : 0.0;
    final titleLeft = horizontalInset + 64 * scale;
    final titleTop = safeTop + 10 * scale;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFCF7),
                          Color(0xFFFFFCF7),
                          _pageBackground,
                        ],
                        stops: [0.0, 0.58, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: heroAssetTop,
                  right: 0,
                  child: IgnorePointer(
                    child: Transform.scale(
                      alignment: Alignment.topRight,
                      scale: scale * heroAssetVisualScale,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xFFFFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.28, 1.0],
                          ).createShader(bounds);
                        },
                        child: Image.asset(
                          _heroAsset,
                          width: heroAssetBaseWidth,
                          fit: BoxFit.contain,
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFFFFCF7).withValues(alpha: 0.48),
                          const Color(0xFFFFFCF7).withValues(alpha: 0.22),
                          const Color(0xFFFFFCF7).withValues(alpha: 0.00),
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.00),
                          _pageBackground.withValues(alpha: 0.34),
                        ],
                        stops: const [0.0, 0.66, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: horizontalInset + 20 * scale,
            top: safeTop + 4 * scale,
            child: _HeroMenuButton(scale: scale),
          ),
          Positioned(
            left: titleLeft,
            right: horizontalInset + 18 * scale,
            top: titleTop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hatırlatıcılar',
                    maxLines: 1,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 21.5 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
                SizedBox(
                  width: contentWidth * 0.62,
                  child: Text(
                    'Zikir vakitlerini gün gün planla,\nhuzur akışını koru.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryGreen.withValues(alpha: 0.86),
                      fontSize: 12.2 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.34,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMenuButton extends StatelessWidget {
  const _HeroMenuButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 35 * scale;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardSurface.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          enableFeedback: false,
          tooltip: 'Menü',
          onPressed: () => openAppMenu(context),
          icon: Icon(
            Icons.menu_rounded,
            color: _primaryGreen,
            size: 20 * scale,
          ),
        ),
      ),
    );
  }
}

class _RemindersContent extends StatelessWidget {
  const _RemindersContent({
    required this.reminders,
    required this.dhikrs,
    required this.scale,
    required this.horizontalInset,
    required this.onAdd,
    required this.onPresetAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<ReminderRecord> reminders;
  final List<DhikrItem> dhikrs;
  final double scale;
  final double horizontalInset;
  final VoidCallback onAdd;
  final ValueChanged<_ReminderPreset> onPresetAdd;
  final void Function(ReminderRecord reminder, bool value) onToggle;
  final ValueChanged<ReminderRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final sortedReminders = [...reminders]
      ..sort((a, b) {
        final hourCompare = a.hour.compareTo(b.hour);
        if (hourCompare != 0) return hourCompare;
        return a.minute.compareTo(b.minute);
      });
    final enabledCount = sortedReminders.where((item) => item.enabled).length;
    final upcomingReminders = _upcomingEnabledReminders(sortedReminders);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReminderFocusCarousel(
            scale: scale,
            reminderCount: sortedReminders.length,
            enabledCount: enabledCount,
            reminders: upcomingReminders,
            onAdd: onAdd,
          ),
          SizedBox(height: 12 * scale),
          _PresetRhythmRail(
            scale: scale,
            reminders: sortedReminders,
            onPresetAdd: onPresetAdd,
          ),
          SizedBox(height: 14 * scale),
          _DayRhythmCard(scale: scale, reminders: sortedReminders),
          SizedBox(height: 16 * scale),
          if (sortedReminders.isEmpty)
            _EmptyRemindersState(scale: scale, onAdd: onAdd)
          else ...[
            _RemindersSectionHeader(
              scale: scale,
              count: sortedReminders.length,
              onAdd: onAdd,
            ),
            SizedBox(height: 10 * scale),
            for (var index = 0; index < sortedReminders.length; index++) ...[
              _ReminderCard(
                reminder: sortedReminders[index],
                dhikrs: dhikrs,
                scale: scale,
                onToggle: (value) => onToggle(sortedReminders[index], value),
                onDelete: () => onDelete(sortedReminders[index]),
              ),
              if (index != sortedReminders.length - 1)
                SizedBox(height: 10 * scale),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReminderFocusCarousel extends StatefulWidget {
  const _ReminderFocusCarousel({
    required this.scale,
    required this.reminderCount,
    required this.enabledCount,
    required this.reminders,
    required this.onAdd,
  });

  final double scale;
  final int reminderCount;
  final int enabledCount;
  final List<ReminderRecord> reminders;
  final VoidCallback onAdd;

  @override
  State<_ReminderFocusCarousel> createState() => _ReminderFocusCarouselState();
}

class _ReminderFocusCarouselState extends State<_ReminderFocusCarousel> {
  late final PageController _controller;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant _ReminderFocusCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders.isEmpty) {
      _pageIndex = 0;
      return;
    }
    if (_pageIndex >= widget.reminders.length) {
      _pageIndex = widget.reminders.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpToPage(_pageIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = widget.reminders;
    final hasPages = reminders.isNotEmpty;
    final pageCount = hasPages ? reminders.length : 1;
    final carouselHeight = (184 + (pageCount > 1 ? 15 : 0)) * widget.scale;

    return SizedBox(
      height: carouselHeight,
      child: hasPages
          ? PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: reminders.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) {
                final palette =
                    _focusCardPalettes[index % _focusCardPalettes.length];
                return _ReminderFocusCard(
                  scale: widget.scale,
                  reminderCount: widget.reminderCount,
                  enabledCount: widget.enabledCount,
                  nextReminder: reminders[index],
                  onAdd: widget.onAdd,
                  palette: palette,
                  heading: index == 0
                      ? 'Sıradaki • 1/$pageCount'
                      : 'Yaklaşan • ${index + 1}/$pageCount',
                  pageIndex: _pageIndex,
                  pageCount: pageCount,
                );
              },
            )
          : _ReminderFocusCard(
              scale: widget.scale,
              reminderCount: widget.reminderCount,
              enabledCount: widget.enabledCount,
              nextReminder: null,
              onAdd: widget.onAdd,
              palette: _focusCardPalettes.first,
              heading: widget.reminderCount == 0
                  ? 'Planını Kur'
                  : 'Aktif Plan Yok',
              pageIndex: 0,
              pageCount: 1,
            ),
    );
  }
}

class _ReminderFocusCard extends StatelessWidget {
  const _ReminderFocusCard({
    required this.scale,
    required this.reminderCount,
    required this.enabledCount,
    required this.nextReminder,
    required this.onAdd,
    required this.palette,
    required this.heading,
    required this.pageIndex,
    required this.pageCount,
  });

  final double scale;
  final int reminderCount;
  final int enabledCount;
  final ReminderRecord? nextReminder;
  final VoidCallback onAdd;
  final _FocusCardPalette palette;
  final String heading;
  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final next = nextReminder;
    final hasNext = next != null;
    final repeatDays = hasNext ? _repeatDaysFor(next) : _allReminderWeekdays;
    final timeLabel = hasNext ? _timeLabel(next) : 'Seç';
    final statusLabel = hasNext
        ? '${_delayLabel(_delayUntil(next, now))} • ${_repeatDaysLabel(repeatDays)}'
        : enabledCount == 0 && reminderCount > 0
        ? 'aktif değil'
        : 'plan yok';
    final title = hasNext
        ? next.title
        : enabledCount == 0 && reminderCount > 0
        ? 'Aktif hatırlatıcı yok'
        : 'Hatırlatma planı';
    final body = hasNext
        ? next.body
        : enabledCount == 0 && reminderCount > 0
        ? 'Bir hatırlatıcıyı aç veya yeni bir vakit ekle.'
        : 'Her gün ya da belirli günlerde çalışacak vakitler oluştur.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(30 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.start, palette.middle, palette.end],
            stops: const [0.0, 0.56, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.18),
              blurRadius: 30 * scale,
              offset: Offset(0, 15 * scale),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -42 * scale,
              top: -38 * scale,
              child: _FocusHalo(size: 154 * scale, opacity: 0.16),
            ),
            Positioned(
              right: 38 * scale,
              bottom: -54 * scale,
              child: _FocusHalo(size: 116 * scale, opacity: 0.10),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                17 * scale,
                16 * scale,
                14 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _GlassIcon(
                        scale: scale,
                        icon: hasNext
                            ? Icons.notifications_active_rounded
                            : Icons.auto_awesome_rounded,
                        color: palette.accent,
                      ),
                      SizedBox(width: 11 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    heading,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 11.8 * scale,
                                      fontWeight: FontWeight.w800,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                _FocusStatusPill(
                                  scale: scale,
                                  label: statusLabel,
                                ),
                              ],
                            ),
                            SizedBox(height: 3 * scale),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.2 * scale,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeLabel,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 42 * scale,
                          fontWeight: FontWeight.w900,
                          height: 0.92,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(width: 13 * scale),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 3 * scale),
                          child: Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12.4 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Row(
                    children: [
                      _FocusMetric(
                        scale: scale,
                        value: '$enabledCount',
                        label: 'aktif',
                        accent: palette.accent,
                      ),
                      SizedBox(width: 8 * scale),
                      _FocusMetric(
                        scale: scale,
                        value: '$reminderCount',
                        label: 'toplam',
                        accent: palette.accent,
                      ),
                      const Spacer(),
                      _FocusAddButton(
                        scale: scale,
                        color: palette.accent,
                        onPressed: onAdd,
                      ),
                    ],
                  ),
                  if (pageCount > 1) ...[
                    SizedBox(height: 8 * scale),
                    Center(
                      child: _FocusPageDots(
                        scale: scale,
                        count: pageCount,
                        activeIndex: pageIndex,
                        accent: palette.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusHalo extends StatelessWidget {
  const _FocusHalo({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.2,
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({
    required this.scale,
    required this.icon,
    required this.color,
  });

  final double scale;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42 * scale,
      height: 42 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Icon(icon, color: color, size: 22 * scale),
    );
  }
}

class _FocusStatusPill extends StatelessWidget {
  const _FocusStatusPill({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.4 * scale,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _FocusMetric extends StatelessWidget {
  const _FocusMetric({
    required this.scale,
    required this.value,
    required this.label,
    required this.accent,
  });

  final double scale;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 11 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 14.2 * scale,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.4 * scale,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusPageDots extends StatelessWidget {
  const _FocusPageDots({
    required this.scale,
    required this.count,
    required this.activeIndex,
    required this.accent,
  });

  final double scale;
  final int count;
  final int activeIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final visibleCount = math.min(count, 5);
    final visibleActiveIndex = math.min(activeIndex, visibleCount - 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < visibleCount; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: index == visibleActiveIndex ? 14 * scale : 5.5 * scale,
            height: 5.5 * scale,
            decoration: BoxDecoration(
              color: index == visibleActiveIndex
                  ? accent
                  : Colors.white.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (index != visibleCount - 1) SizedBox(width: 4 * scale),
        ],
      ],
    );
  }
}

class _FocusAddButton extends StatelessWidget {
  const _FocusAddButton({
    required this.scale,
    required this.color,
    required this.onPressed,
  });

  final double scale;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 13 * scale,
            vertical: 9 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: _primaryGreen, size: 18 * scale),
              SizedBox(width: 5 * scale),
              Text(
                'Ekle',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 12.8 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetRhythmRail extends StatelessWidget {
  const _PresetRhythmRail({
    required this.scale,
    required this.reminders,
    required this.onPresetAdd,
  });

  final double scale;
  final List<ReminderRecord> reminders;
  final ValueChanged<_ReminderPreset> onPresetAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumSectionLabel(
          scale: scale,
          icon: Icons.auto_awesome_rounded,
          title: 'Hazır Hatırlatıcılar',
          trailing: 'her gün önerileri',
        ),
        SizedBox(height: 9 * scale),
        SizedBox(
          height: 138 * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _reminderPresets.length,
            separatorBuilder: (_, _) => SizedBox(width: 10 * scale),
            itemBuilder: (context, index) {
              final preset = _reminderPresets[index];
              final added = _hasPresetReminder(reminders, preset);
              return _PresetCard(
                scale: scale,
                preset: preset,
                added: added,
                onTap: added ? null : () => onPresetAdd(preset),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PremiumSectionLabel extends StatelessWidget {
  const _PremiumSectionLabel({
    required this.scale,
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _gold, size: 17 * scale),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 16.2 * scale,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        Text(
          trailing,
          style: TextStyle(
            color: _mutedText,
            fontSize: 11.8 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.scale,
    required this.preset,
    required this.added,
    required this.onTap,
  });

  final double scale;
  final _ReminderPreset preset;
  final bool added;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154 * scale,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22 * scale),
        child: InkWell(
          borderRadius: BorderRadius.circular(22 * scale),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: _cardSurface.withValues(alpha: added ? 0.72 : 0.96),
              borderRadius: BorderRadius.circular(22 * scale),
              border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
            ),
            child: Padding(
              padding: EdgeInsets.all(13 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36 * scale,
                        height: 36 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: preset.accent.withValues(alpha: 0.16),
                        ),
                        child: Icon(
                          preset.icon,
                          color: preset.accent,
                          size: 20 * scale,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        added ? Icons.check_circle_rounded : Icons.add_circle,
                        color: added ? _buttonGreen : _primaryGreen,
                        size: 22 * scale,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _timePartsLabel(preset.hour, preset.minute),
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 20.5 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    preset.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 13.3 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    added ? 'Her gün eklendi' : 'Her gün • ${preset.note}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 11.2 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayRhythmCard extends StatelessWidget {
  const _DayRhythmCard({required this.scale, required this.reminders});

  final double scale;
  final List<ReminderRecord> reminders;

  @override
  Widget build(BuildContext context) {
    final activeCount = reminders.where((reminder) => reminder.enabled).length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.055),
            blurRadius: 20 * scale,
            offset: Offset(0, 9 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14 * scale,
          14 * scale,
          14 * scale,
          13 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: _gold, size: 18 * scale),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    'Gün Dağılımı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 15.8 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
                _TimePill(
                  scale: scale,
                  label: '$activeCount aktif',
                  enabled: activeCount > 0,
                ),
              ],
            ),
            SizedBox(height: 13 * scale),
            Row(
              children: [
                for (var index = 0; index < _rhythmWindows.length; index++) ...[
                  Expanded(
                    child: _RhythmStep(
                      scale: scale,
                      window: _rhythmWindows[index],
                      count: _enabledCountInWindow(
                        reminders,
                        _rhythmWindows[index],
                      ),
                    ),
                  ),
                  if (index != _rhythmWindows.length - 1)
                    SizedBox(width: 7 * scale),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RhythmStep extends StatelessWidget {
  const _RhythmStep({
    required this.scale,
    required this.window,
    required this.count,
  });

  final double scale;
  final _RhythmWindow window;
  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        vertical: 10 * scale,
        horizontal: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: active
            ? _buttonGreen.withValues(alpha: 0.12)
            : _paleSage.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(17 * scale),
        border: Border.all(
          color: active
              ? _buttonGreen.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        children: [
          Icon(
            window.icon,
            color: active ? _buttonGreen : _mutedText,
            size: 20 * scale,
          ),
          SizedBox(height: 7 * scale),
          Text(
            window.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? _primaryGreen : _mutedText,
              fontSize: 11.2 * scale,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            count == 0 ? 'boş' : '$count vakit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active
                  ? _primaryGreen.withValues(alpha: 0.72)
                  : _mutedText.withValues(alpha: 0.70),
              fontSize: 10.2 * scale,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersSectionHeader extends StatelessWidget {
  const _RemindersSectionHeader({
    required this.scale,
    required this.count,
    required this.onAdd,
  });

  final double scale;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.notifications_active_rounded,
          color: _gold,
          size: 18 * scale,
        ),
        SizedBox(width: 9 * scale),
        Expanded(
          child: Text(
            'Hatırlatma Planı',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 18.6 * scale,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        _RoundIconButton(
          scale: scale,
          tooltip: 'Hatırlatıcı ekle',
          icon: Icons.add_rounded,
          onPressed: onAdd,
        ),
        SizedBox(width: 8 * scale),
        Text(
          '$count kayıt',
          style: TextStyle(
            color: _mutedText.withValues(alpha: 0.92),
            fontSize: 13.4 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.dhikrs,
    required this.scale,
    required this.onToggle,
    required this.onDelete,
  });

  final ReminderRecord reminder;
  final List<DhikrItem> dhikrs;
  final double scale;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final enabled = reminder.enabled;
    final textOpacity = enabled ? 1.0 : 0.56;
    final repeatLabel = _repeatDaysLabel(_repeatDaysFor(reminder));
    final linkedDhikr = _dhikrForReminder(reminder, dhikrs);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.07),
            blurRadius: 22 * scale,
            offset: Offset(0, 10 * scale),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.72),
            blurRadius: 12 * scale,
            offset: Offset(0, -2 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14 * scale,
          12 * scale,
          10 * scale,
          12 * scale,
        ),
        child: Row(
          children: [
            Container(
              width: 58 * scale,
              height: 58 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? const [Color(0xFF1F5F42), Color(0xFF3B8760)]
                      : [
                          _paleSage.withValues(alpha: 0.92),
                          _paleSage.withValues(alpha: 0.70),
                        ],
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: _buttonGreen.withValues(alpha: 0.16),
                          blurRadius: 18 * scale,
                          offset: Offset(0, 8 * scale),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: enabled ? Colors.white : _primaryGreen,
                size: 27 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          reminder.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryGreen.withValues(alpha: textOpacity),
                            fontSize: 15.8 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      _TimePill(
                        scale: scale,
                        label: _timeLabel(reminder),
                        enabled: enabled,
                      ),
                    ],
                  ),
                  SizedBox(height: 7 * scale),
                  Text(
                    reminder.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedText.withValues(
                        alpha: enabled ? 0.92 : 0.58,
                      ),
                      fontSize: 12.3 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  _RepeatDaysPill(
                    scale: scale,
                    label: repeatLabel,
                    enabled: enabled,
                  ),
                  if (linkedDhikr != null) ...[
                    SizedBox(height: 7 * scale),
                    _LinkedDhikrPill(
                      scale: scale,
                      dhikr: linkedDhikr,
                      enabled: enabled,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.82 * scale.clamp(0.92, 1.12),
                  child: Switch.adaptive(
                    value: enabled,
                    activeThumbColor: _buttonGreen,
                    activeTrackColor: _buttonGreen.withValues(alpha: 0.32),
                    onChanged: onToggle,
                  ),
                ),
                SizedBox(height: 2 * scale),
                _RoundIconButton(
                  scale: scale,
                  tooltip: 'Hatırlatıcıyı sil',
                  icon: Icons.delete_outline_rounded,
                  onPressed: onDelete,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatDaysPill extends StatelessWidget {
  const _RepeatDaysPill({
    required this.scale,
    required this.label,
    required this.enabled,
  });

  final double scale;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 188 * scale),
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 5 * scale,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? _paleSage.withValues(alpha: 0.76)
              : _paleSage.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 13 * scale,
              color: _primaryGreen.withValues(alpha: enabled ? 0.78 : 0.48),
            ),
            SizedBox(width: 5 * scale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryGreen.withValues(alpha: enabled ? 0.82 : 0.50),
                  fontSize: 10.8 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedDhikrPill extends StatelessWidget {
  const _LinkedDhikrPill({
    required this.scale,
    required this.dhikr,
    required this.enabled,
  });

  final double scale;
  final DhikrItem dhikr;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 216 * scale),
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 5 * scale,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? _softGold.withValues(alpha: 0.34)
              : _paleSage.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _gold.withValues(alpha: enabled ? 0.22 : 0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 13 * scale,
              color: _gold.withValues(alpha: enabled ? 1 : 0.55),
            ),
            SizedBox(width: 5 * scale),
            Flexible(
              child: Text(
                'Zikir: ${dhikr.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryGreen.withValues(alpha: enabled ? 0.84 : 0.52),
                  fontSize: 10.8 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.scale,
    required this.label,
    required this.enabled,
  });

  final double scale;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: enabled
            ? _softGold.withValues(alpha: 0.72)
            : _paleSage.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: _primaryGreen.withValues(alpha: enabled ? 0.92 : 0.58),
          fontSize: 12 * scale,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.scale,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final double scale;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = (compact ? 32.0 : 36.0) * scale;

    return SizedBox.square(
      dimension: size,
      child: Material(
        color: _cardSurface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: compact ? _mutedText : _primaryGreen,
              size: (compact ? 18.0 : 20.0) * scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRemindersState extends StatelessWidget {
  const _EmptyRemindersState({required this.scale, required this.onAdd});

  final double scale;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.06),
            blurRadius: 24 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22 * scale,
          24 * scale,
          22 * scale,
          24 * scale,
        ),
        child: Column(
          children: [
            Container(
              width: 72 * scale,
              height: 72 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _paleSage.withValues(alpha: 0.84),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: _primaryGreen,
                size: 34 * scale,
              ),
            ),
            SizedBox(height: 15 * scale),
            Text(
              'Hatırlatma yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryGreen,
                fontSize: 18 * scale,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              'Hazır bir her gün önerisi seçebilir ya da belirli günlerde çalışacak özel bir vakit ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mutedText,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
                height: 1.32,
              ),
            ),
            SizedBox(height: 18 * scale),
            FilledButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_rounded, size: 19 * scale),
              label: const Text('Özel Vakit Ekle'),
              style: FilledButton.styleFrom(
                backgroundColor: _buttonGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * scale,
                  vertical: 11 * scale,
                ),
                textStyle: TextStyle(
                  fontSize: 13.6 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderLoadState extends StatelessWidget {
  const _ReminderLoadState({
    required this.scale,
    required this.horizontalInset,
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final double scale;
  final double horizontalInset;
  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardSurface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
        ),
        child: Padding(
          padding: EdgeInsets.all(22 * scale),
          child: Column(
            children: [
              if (loading)
                SizedBox.square(
                  dimension: 30 * scale,
                  child: const CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Icon(icon, color: _primaryGreen, size: 32 * scale),
              SizedBox(height: 12 * scale),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 12.6 * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddReminderDialog(
  BuildContext context,
  WidgetRef ref,
  List<DhikrItem> dhikrs,
) async {
  final draft = await showModalBottomSheet<_ReminderDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    requestFocus: false,
    builder: (context) => _AddReminderSheet(dhikrs: dhikrs),
  );

  if (draft == null || !context.mounted) return;

  final selectedDhikr = draft.dhikr;
  final normalizedTitle = draft.title.trim().isEmpty
      ? selectedDhikr?.name ?? 'Zikir zamanı'
      : draft.title.trim();
  final body = selectedDhikr == null
      ? 'Zikrini tamamlamayı unutma.'
      : '${selectedDhikr.name} zikrini ${selectedDhikr.defaultTarget} hedefiyle tamamlamayı unutma.';

  final notifications = ref.read(localNotificationServiceProvider);
  final notificationsAllowed = await ensureNotificationPermissionForReminder(
    context: context,
    areNotificationsAllowed: notifications.areNotificationsAllowed,
    requestPermission: notifications.requestNotificationPermission,
  );
  if (!notificationsAllowed || !context.mounted) return;

  await ref
      .read(reminderRepositoryProvider)
      .addReminder(
        title: normalizedTitle,
        body: body,
        hour: draft.time.hour,
        minute: draft.time.minute,
        repeatDays: draft.repeatDays,
        targetDhikrId: selectedDhikr?.id,
      );

  if (!context.mounted) return;
  final dhikrSuffix = selectedDhikr == null ? '' : ' • ${selectedDhikr.name}';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$normalizedTitle ${_repeatDaysLabel(draft.repeatDays).toLowerCase()} ${draft.time.format(context)} için eklendi$dhikrSuffix.',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ReminderDraft {
  const _ReminderDraft({
    required this.title,
    required this.time,
    required this.repeatDays,
    required this.dhikr,
  });

  final String title;
  final TimeOfDay time;
  final Set<int> repeatDays;
  final DhikrItem? dhikr;
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.dhikrs});

  final List<DhikrItem> dhikrs;

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  late final TextEditingController _titleController;
  TimeOfDay _selectedTime = TimeOfDay.now();
  Set<int> _selectedDays = {..._allReminderWeekdays};
  DhikrItem? _selectedDhikr;
  bool _titleTouched = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Zikir zamanı');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _setRepeatDays(Set<int> days) {
    setState(() => _selectedDays = {...days});
  }

  void _toggleDay(int day) {
    setState(() {
      final next = {..._selectedDays};
      if (next.contains(day)) {
        if (next.length == 1) return;
        next.remove(day);
      } else {
        next.add(day);
      }
      _selectedDays = next;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  Future<void> _pickDhikr() async {
    final picked = await _showDhikrPicker(
      context: context,
      dhikrs: widget.dhikrs,
      selected: _selectedDhikr,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDhikr = picked;
      final title = _titleController.text.trim();
      if (!_titleTouched || title.isEmpty || title == 'Zikir zamanı') {
        _titleController.text = picked.name;
        _titleTouched = false;
      }
    });
  }

  void _clearDhikr() {
    setState(() => _selectedDhikr = null);
  }

  void _save() {
    Navigator.of(context).pop(
      _ReminderDraft(
        title: _titleController.text,
        time: _selectedTime,
        repeatDays: {..._selectedDays},
        dhikr: _selectedDhikr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = proportionalLayoutScaleFor(media.size.width);
    final maxWidth = math.min(media.size.width, appLayoutBaselineWidth * scale);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: maxWidth,
          height: media.size.height * 0.92,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _pageBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(34 * scale),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 34 * scale,
                  offset: Offset(0, -12 * scale),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 9 * scale, bottom: 7 * scale),
                    child: Container(
                      width: 44 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  _AddSheetHeader(
                    scale: scale,
                    timeLabel: _selectedTime.format(context),
                    repeatLabel: _repeatDaysLabel(_selectedDays),
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        19 * scale,
                        16 * scale,
                        19 * scale,
                        96 * scale,
                      ),
                      children: [
                        _AddSheetSection(
                          scale: scale,
                          icon: Icons.edit_notifications_rounded,
                          title: 'Hatırlatma',
                          subtitle: 'Başlık ve saat',
                          child: Column(
                            children: [
                              TextField(
                                controller: _titleController,
                                autofocus: false,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => _titleTouched = true,
                                decoration: InputDecoration(
                                  labelText: 'Başlık',
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.68,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      18 * scale,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.notifications_none_rounded,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10 * scale),
                              _SheetActionTile(
                                scale: scale,
                                icon: Icons.schedule_rounded,
                                title: 'Saat',
                                value: _selectedTime.format(context),
                                onTap: _pickTime,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        _AddSheetSection(
                          scale: scale,
                          icon: Icons.calendar_month_rounded,
                          title: 'Tekrar',
                          subtitle: 'Her gün ya da belirli günler',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8 * scale,
                                runSpacing: 8 * scale,
                                children: [
                                  _QuickRepeatChip(
                                    scale: scale,
                                    label: 'Her gün',
                                    selected:
                                        _selectedDays.containsAll(
                                          _allReminderWeekdays,
                                        ) &&
                                        _selectedDays.length ==
                                            _allReminderWeekdays.length,
                                    onTap: () =>
                                        _setRepeatDays(_allReminderWeekdays),
                                  ),
                                  _QuickRepeatChip(
                                    scale: scale,
                                    label: 'Hafta içi',
                                    selected:
                                        _selectedDays.containsAll(
                                          _weekdayReminderDays,
                                        ) &&
                                        _selectedDays.length ==
                                            _weekdayReminderDays.length,
                                    onTap: () =>
                                        _setRepeatDays(_weekdayReminderDays),
                                  ),
                                  _QuickRepeatChip(
                                    scale: scale,
                                    label: 'Hafta sonu',
                                    selected:
                                        _selectedDays.containsAll(
                                          _weekendReminderDays,
                                        ) &&
                                        _selectedDays.length ==
                                            _weekendReminderDays.length,
                                    onTap: () =>
                                        _setRepeatDays(_weekendReminderDays),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12 * scale),
                              Wrap(
                                spacing: 7 * scale,
                                runSpacing: 7 * scale,
                                children: [
                                  for (final day in _allReminderWeekdays)
                                    _DaySelectorChip(
                                      scale: scale,
                                      label: _weekdayShortLabels[day]!,
                                      selected: _selectedDays.contains(day),
                                      onTap: () => _toggleDay(day),
                                    ),
                                ],
                              ),
                              SizedBox(height: 11 * scale),
                              _SheetNote(
                                scale: scale,
                                text:
                                    '${_repeatDaysLabel(_selectedDays)} seçili. En az bir gün açık kalır.',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        _AddSheetSection(
                          scale: scale,
                          icon: Icons.auto_awesome_rounded,
                          title: 'Zikir bağlantısı',
                          subtitle: 'İsteğe bağlı',
                          child: _DhikrLinkControl(
                            scale: scale,
                            selectedDhikr: _selectedDhikr,
                            onPick: _pickDhikr,
                            onClear: _clearDhikr,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      19 * scale,
                      8 * scale,
                      19 * scale,
                      14 * scale,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryGreen,
                              side: BorderSide(
                                color: _primaryGreen.withValues(alpha: 0.18),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 14 * scale,
                              ),
                              textStyle: TextStyle(
                                fontSize: 13.2 * scale,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('Vazgeç'),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _save,
                            icon: Icon(
                              Icons.notifications_active_rounded,
                              size: 18 * scale,
                            ),
                            label: const Text('Hatırlatıcıyı Kaydet'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _buttonGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: 14 * scale,
                              ),
                              textStyle: TextStyle(
                                fontSize: 13.2 * scale,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddSheetHeader extends StatelessWidget {
  const _AddSheetHeader({
    required this.scale,
    required this.timeLabel,
    required this.repeatLabel,
    required this.onClose,
  });

  final double scale;
  final String timeLabel;
  final String repeatLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 19 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3324), Color(0xFF1F6C48)],
          ),
          borderRadius: BorderRadius.circular(28 * scale),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            15 * scale,
            12 * scale,
            15 * scale,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _GlassIcon(
                    scale: scale,
                    icon: Icons.add_alert_rounded,
                    color: _softGold,
                  ),
                  SizedBox(width: 11 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hatırlatma Tasarla',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          'Saat, gün ve isterse özel zikir seç.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11.8 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 14 * scale),
              Row(
                children: [
                  Expanded(
                    child: _HeaderSummaryPill(
                      scale: scale,
                      icon: Icons.schedule_rounded,
                      label: timeLabel,
                    ),
                  ),
                  SizedBox(width: 9 * scale),
                  Expanded(
                    child: _HeaderSummaryPill(
                      scale: scale,
                      icon: Icons.event_repeat_rounded,
                      label: repeatLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSummaryPill extends StatelessWidget {
  const _HeaderSummaryPill({
    required this.scale,
    required this.icon,
    required this.label,
  });

  final double scale;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 9 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _softGold, size: 17 * scale),
          SizedBox(width: 7 * scale),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.8 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSheetSection extends StatelessWidget {
  const _AddSheetSection({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.055),
            blurRadius: 18 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _paleSage.withValues(alpha: 0.74),
                  ),
                  child: Icon(icon, color: _primaryGreen, size: 19 * scale),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 15.4 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedText,
                          fontSize: 11.3 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 13 * scale),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.scale,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(18 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 11 * scale,
          ),
          child: Row(
            children: [
              Icon(icon, color: _buttonGreen, size: 22 * scale),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 11.2 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 0),
                    Text(
                      value,
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 16.5 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _mutedText,
                size: 22 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRepeatChip extends StatelessWidget {
  const _QuickRepeatChip({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _buttonGreen : _paleSage.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 13 * scale,
            vertical: 9 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15 * scale,
                ),
                SizedBox(width: 5 * scale),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _primaryGreen,
                  fontSize: 12.2 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySelectorChip extends StatelessWidget {
  const _DaySelectorChip({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 47 * scale,
      child: Material(
        color: selected ? _softGold.withValues(alpha: 0.72) : Colors.white,
        borderRadius: BorderRadius.circular(15 * scale),
        child: InkWell(
          borderRadius: BorderRadius.circular(15 * scale),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10 * scale),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryGreen.withValues(alpha: selected ? 0.94 : 0.66),
                fontSize: 11.8 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetNote extends StatelessWidget {
  const _SheetNote({required this.scale, required this.text});

  final double scale;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, color: _mutedText, size: 16 * scale),
        SizedBox(width: 7 * scale),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _mutedText,
              fontSize: 11.7 * scale,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),
        ),
      ],
    );
  }
}

class _DhikrLinkControl extends StatelessWidget {
  const _DhikrLinkControl({
    required this.scale,
    required this.selectedDhikr,
    required this.onPick,
    required this.onClear,
  });

  final double scale;
  final DhikrItem? selectedDhikr;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final dhikr = selectedDhikr;
    if (dhikr == null) {
      return _SheetActionTile(
        scale: scale,
        icon: Icons.search_rounded,
        title: 'Zikir seçmeden de kaydedebilirsin',
        value: 'Zikir Kütüphanesi’nden seç',
        onTap: onPick,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _softGold.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: _gold.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12 * scale),
        child: Row(
          children: [
            Container(
              width: 42 * scale,
              height: 42 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryGreen,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: _softGold,
                size: 20 * scale,
              ),
            ),
            SizedBox(width: 11 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dhikr.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 14.2 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    '${dhikr.category} • hedef ${dhikr.defaultTarget}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 11.4 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Başka zikir seç',
              onPressed: onPick,
              icon: const Icon(Icons.swap_horiz_rounded),
              color: _primaryGreen,
            ),
            IconButton(
              tooltip: 'Zikir bağlantısını kaldır',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              color: _mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

Future<DhikrItem?> _showDhikrPicker({
  required BuildContext context,
  required List<DhikrItem> dhikrs,
  required DhikrItem? selected,
}) {
  return showModalBottomSheet<DhikrItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    requestFocus: false,
    builder: (context) => _DhikrPickerSheet(dhikrs: dhikrs, selected: selected),
  );
}

class _DhikrPickerSheet extends StatefulWidget {
  const _DhikrPickerSheet({required this.dhikrs, required this.selected});

  final List<DhikrItem> dhikrs;
  final DhikrItem? selected;

  @override
  State<_DhikrPickerSheet> createState() => _DhikrPickerSheetState();
}

class _DhikrPickerSheetState extends State<_DhikrPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DhikrItem> get _filteredDhikrs {
    final query = _query.trim().toLowerCase();
    final sorted = [...widget.dhikrs]
      ..sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    if (query.isEmpty) return sorted;
    return sorted.where((dhikr) {
      final haystack = [
        dhikr.name,
        dhikr.category,
        dhikr.meaning,
        dhikr.arabicText,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = proportionalLayoutScaleFor(media.size.width);
    final maxWidth = math.min(media.size.width, appLayoutBaselineWidth * scale);
    final items = _filteredDhikrs;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: maxWidth,
          height: media.size.height * 0.82,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30 * scale),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      19 * scale,
                      14 * scale,
                      9 * scale,
                      8 * scale,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zikir Seç',
                                style: TextStyle(
                                  color: _primaryGreen,
                                  fontSize: 21 * scale,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                'Hatırlatıcıyı kütüphanedeki bir zikre bağla.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _mutedText,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 19 * scale),
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Zikir, kategori veya anlam ara',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: _paleSage.withValues(alpha: 0.70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20 * scale),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(
                                color: _mutedText,
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              19 * scale,
                              0,
                              19 * scale,
                              16 * scale,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 8 * scale),
                            itemBuilder: (context, index) {
                              final dhikr = items[index];
                              return _DhikrResultTile(
                                scale: scale,
                                dhikr: dhikr,
                                selected: widget.selected?.id == dhikr.id,
                                onTap: () => Navigator.of(context).pop(dhikr),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DhikrResultTile extends StatelessWidget {
  const _DhikrResultTile({
    required this.scale,
    required this.dhikr,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final DhikrItem dhikr;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _softGold.withValues(alpha: 0.34) : _pageBackground,
      borderRadius: BorderRadius.circular(20 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(20 * scale),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Row(
            children: [
              Container(
                width: 42 * scale,
                height: 42 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _buttonGreen
                      : _paleSage.withValues(alpha: 0.86),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.auto_awesome_rounded,
                  color: selected ? Colors.white : _primaryGreen,
                  size: 20 * scale,
                ),
              ),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dhikr.arabicText != null) ...[
                      Text(
                        dhikr.arabicText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryGreen.withValues(alpha: 0.68),
                          fontSize: 14.5 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                    ],
                    Text(
                      dhikr.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 14.4 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      '${dhikr.category} • hedef ${dhikr.defaultTarget}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 11.5 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _mutedText,
                size: 22 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
