import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/database_provider.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../../shared/widgets/app_time_picker.dart';
import '../../../shared/widgets/notification_permission_prompt.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../reminders/application/local_notification_service.dart';
import '../../reminders/application/reminder_providers.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _libraryHeroEdgeCream = Color(0xFFF6F3EE);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _cardBackground = Color(0xFFFAFAF4);
const _primaryText = Color(0xFF123B2B);
const _secondaryText = Color(0xFF69766E);
const _gold = Color(0xFFD4BA75);
const _dividerColor = Color(0xFFDDE4D9);

const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 14.0;

const _statisticsHeroAsset = 'assets/images/istatistikler-hero.webp';
const _periods = ['Genel Bakış', 'Günlük', 'Aylık'];
const _statisticsPillLift = 56.0;
const _statisticsCardTitleFontSize = 17.0;
const _statisticsCardDescriptionFontSize = 12.2;
const _statisticsDailyTargetKey = 'statistics.target.daily';
const _statisticsMonthlyTargetKey = 'statistics.target.monthly';
const _statisticsYearlyTargetKey = 'statistics.target.yearly';
final _counterStatBucketsProvider = StreamProvider<List<CounterStatBucket>>((
  ref,
) {
  return ref.watch(appDatabaseProvider).watchCounterStatBuckets();
});

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedPeriod = _periods.first;
  late DateTime _selectedDailyDate = _dateOnly(DateTime.now());
  late DateTime _selectedMonthlyMonth = _monthOnly(DateTime.now());
  late int _selectedOverviewYear = DateTime.now().year;
  _StatisticsTargets _targets = const _StatisticsTargets();
  bool _targetsLoaded = false;

  @override
  void initState() {
    super.initState();
    _restoreTargets();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final safeBottom = media.padding.bottom;
    final bottomNavHeight = _bottomNavBaseHeight * scale;
    final bottomNavOffset = _bottomNavBottomOffset(safeBottom, scale);
    final bottomReservedHeight = bottomNavHeight + bottomNavOffset;
    final scrollBottomPadding = _scrollExtraBottomSpacing * scale;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.14).toDouble();
    final bucketsAsync = ref.watch(_counterStatBucketsProvider);
    final statistics = _StatisticsData.fromBuckets(
      bucketsAsync.value ?? const [],
    );
    final availableYears = statistics.availableYears(DateTime.now().year);

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
                child: CustomPaint(painter: _StatisticsWashPainter()),
              ),
              Positioned.fill(
                bottom: bottomReservedHeight,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: 0, bottom: scrollBottomPadding),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatisticsTopCluster(
                            scale: scale,
                            topInset: media.padding.top,
                            selectedPeriod: _selectedPeriod,
                            onSelected: (period) =>
                                setState(() => _selectedPeriod = period),
                          ),
                          SizedBox(height: 4 * scale),
                          _StatisticsTargetCard(
                            scale: scale,
                            targets: _targets,
                            loaded: _targetsLoaded,
                            statistics: statistics,
                            month: _selectedMonthlyMonth,
                            year: _selectedOverviewYear,
                            onEdit: () => _showTargetEditor(context, scale),
                          ),
                          SizedBox(height: 10 * scale),
                          if (_selectedPeriod == 'Günlük')
                            _DailyStatisticsSection(
                              scale: scale,
                              selectedDate: _selectedDailyDate,
                              statistics: statistics,
                              dailyTarget: _targets.daily,
                              onEditTargets: () =>
                                  _showTargetEditor(context, scale),
                              onPickDate: () => _pickDailyDate(context),
                              onPreviousDate: () => _changeDailyDate(-1),
                              onNextDate: () => _changeDailyDate(1),
                            )
                          else if (_selectedPeriod == 'Aylık')
                            _MonthlyStatisticsSection(
                              scale: scale,
                              selectedMonth: _selectedMonthlyMonth,
                              statistics: statistics,
                              monthlyTarget: _targets.monthlyTargetFor(
                                _selectedMonthlyMonth,
                              ),
                              monthlyTargetAutomatic: _targets
                                  .monthlyIsAutomatic(_selectedMonthlyMonth),
                              onEditTargets: () =>
                                  _showTargetEditor(context, scale),
                              onPreviousMonth: () => _changeMonthlyMonth(-1),
                              onNextMonth: () => _changeMonthlyMonth(1),
                            )
                          else ...[
                            _OverviewCard(
                              scale: scale,
                              selectedYear: _selectedOverviewYear,
                              statistics: statistics,
                              availableYears: availableYears,
                              yearToDateTarget: _targets.yearToDateTargetFor(
                                _selectedOverviewYear,
                              ),
                              yearlyTargetAutomatic: _targets.yearlyIsAutomatic(
                                _selectedOverviewYear,
                              ),
                              onEditTargets: () =>
                                  _showTargetEditor(context, scale),
                              onYearSelected: (year) =>
                                  setState(() => _selectedOverviewYear = year),
                            ),
                            SizedBox(height: 10 * scale),
                            _YearlyFocusCard(
                              scale: scale,
                              selectedYear: _selectedOverviewYear,
                              statistics: statistics,
                            ),
                            SizedBox(height: 10 * scale),
                            _RecordCard(
                              scale: scale,
                              selectedYear: _selectedOverviewYear,
                              statistics: statistics,
                            ),
                            SizedBox(height: 10 * scale),
                            _DayPartDistributionCard(
                              scale: scale,
                              selectedYear: _selectedOverviewYear,
                              statistics: statistics,
                            ),
                            SizedBox(height: 10 * scale),
                            _YearlyMonthlyOverviewCard(
                              scale: scale,
                              selectedYear: _selectedOverviewYear,
                              statistics: statistics,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.statistics,
                quickStartKey: const Key('statistics.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restoreTargets() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _targets = _StatisticsTargets(
        daily: _readTargetPreference(prefs, _statisticsDailyTargetKey),
        monthly: _readTargetPreference(prefs, _statisticsMonthlyTargetKey),
        yearly: _readTargetPreference(prefs, _statisticsYearlyTargetKey),
      );
      _targetsLoaded = true;
    });
  }

  Future<void> _persistTargets(_StatisticsTargets targets) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeTargetPreference(
      prefs,
      _statisticsDailyTargetKey,
      targets.daily,
    );
    await _writeTargetPreference(
      prefs,
      _statisticsMonthlyTargetKey,
      targets.monthly,
    );
    await _writeTargetPreference(
      prefs,
      _statisticsYearlyTargetKey,
      targets.yearly,
    );
  }

  Future<void> _showTargetEditor(BuildContext context, double scale) async {
    final previousDailyTarget = _targets.daily;
    final updatedTargets = await showModalBottomSheet<_StatisticsTargets>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TargetEditorSheet(scale: scale, targets: _targets),
    );

    if (updatedTargets == null || !mounted) {
      return;
    }

    setState(() {
      _targets = updatedTargets;
      _targetsLoaded = true;
    });
    await _persistTargets(updatedTargets);

    final dailyTarget = updatedTargets.daily;
    if (!mounted ||
        !context.mounted ||
        dailyTarget == null ||
        dailyTarget == previousDailyTarget) {
      return;
    }

    await _offerDailyTargetReminder(context, dailyTarget);
  }

  Future<void> _offerDailyTargetReminder(
    BuildContext context,
    int dailyTarget,
  ) async {
    final reminderTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) {
        var selectedTime = const TimeOfDay(
          hour: ReminderRepository.dailyTargetReminderHour,
          minute: ReminderRepository.dailyTargetReminderMinute,
        );

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final timeLabel = _formatReminderDialogTime(selectedTime);

            return AlertDialog(
              backgroundColor: _cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              icon: const Icon(
                Icons.notifications_active_rounded,
                color: _buttonGreen,
              ),
              title: const Text('Hedefini her gün yanında tutalım mı?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Günlük ${_formatWholeNumber(dailyTarget)} zikir hedefin güzel bir adım. '
                    'Sana uygun bir saatte küçük bir hatırlatma ekleyelim; '
                    'günün yoğunluğunda unutmaz, ilerlemeni düzenli takip edersin.',
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showAppTimePicker(
                        context: dialogContext,
                        initialTime: selectedTime,
                        helpText: 'Günlük hedef hatırlatma saati',
                      );
                      if (picked == null || !dialogContext.mounted) {
                        return;
                      }

                      setDialogState(() => selectedTime = picked);
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hatırlatma saati'),
                        Text(
                          timeLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryText,
                      side: BorderSide(
                        color: _buttonGreen.withValues(alpha: 0.22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Şimdi değil'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedTime),
                  icon: const Icon(Icons.add_alert_rounded, size: 18),
                  label: Text("$timeLabel'te ekle"),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (reminderTime == null || !mounted || !context.mounted) {
      return;
    }

    final notifications = ref.read(localNotificationServiceProvider);
    final notificationsAllowed = await ensureNotificationPermissionForReminder(
      context: context,
      areNotificationsAllowed: notifications.areNotificationsAllowed,
      requestPermission: notifications.requestNotificationPermission,
    );
    if (!notificationsAllowed || !mounted || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(reminderRepositoryProvider)
          .upsertDailyTargetReminder(
            target: dailyTarget,
            hour: reminderTime.hour,
            minute: reminderTime.minute,
          );
      if (!mounted || !context.mounted) {
        return;
      }

      final timeLabel = _formatReminderDialogTime(reminderTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Günlük hedef hatırlatıcısı her gün $timeLabel'te aktif.",
          ),
        ),
      );
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hatırlatıcı eklenemedi. Lütfen tekrar dene.'),
        ),
      );
    }
  }

  void _changeDailyDate(int dayDelta) {
    setState(() {
      _selectedDailyDate = _dateOnly(
        _selectedDailyDate.add(Duration(days: dayDelta)),
      );
    });
  }

  void _changeMonthlyMonth(int monthDelta) {
    setState(() {
      _selectedMonthlyMonth = DateTime(
        _selectedMonthlyMonth.year,
        _selectedMonthlyMonth.month + monthDelta,
      );
    });
  }

  Future<void> _pickDailyDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDailyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _buttonGreen,
              onPrimary: Colors.white,
              surface: _cardBackground,
              onSurface: _primaryText,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDailyDate = _dateOnly(pickedDate);
    });
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _monthOnly(DateTime date) => DateTime(date.year, date.month);

String _formatReminderDialogTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _StatEvent {
  const _StatEvent({
    required this.createdAt,
    required this.dhikrId,
    required this.dhikrName,
    required this.delta,
    required this.target,
  });

  final DateTime createdAt;
  final String dhikrId;
  final String dhikrName;
  final int delta;
  final int target;
}

class _StatisticsData {
  const _StatisticsData(this.events);

  factory _StatisticsData.fromBuckets(List<CounterStatBucket> buckets) {
    final positiveEvents = [
      for (final bucket in buckets)
        if (bucket.count > 0)
          _StatEvent(
            createdAt: bucket.bucketStart,
            dhikrId: bucket.dhikrId,
            dhikrName: bucket.dhikrName,
            delta: bucket.count,
            target: bucket.target,
          ),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return _StatisticsData(positiveEvents);
  }

  final List<_StatEvent> events;

  List<int> availableYears(int currentYear) {
    final years = <int>{currentYear};
    for (final event in events) {
      years.add(event.createdAt.year);
    }

    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  _DailyStats dailyStats(DateTime date) {
    final day = _dateOnly(date);
    final previousDay = day.subtract(const Duration(days: 1));
    final events = _eventsBetween(day, day.add(const Duration(days: 1)));
    final previousTotal = _totalBetween(
      previousDay,
      previousDay.add(const Duration(days: 1)),
    );
    final hourlyValues = List<int>.filled(24, 0);
    final totalsByDhikr = <String, int>{};
    final targetByDhikr = <String, int>{};

    for (final event in events) {
      hourlyValues[event.createdAt.hour] += event.delta;
      totalsByDhikr.update(
        event.dhikrName,
        (value) => value + event.delta,
        ifAbsent: () => event.delta,
      );
      if (event.target > 0) {
        targetByDhikr[event.dhikrName] = math.max(
          targetByDhikr[event.dhikrName] ?? 0,
          event.target,
        );
      }
    }

    final ranks = _dailyRanksFromTotals(totalsByDhikr, targetByDhikr);
    final topHourIndex = _indexOfHighest(hourlyValues);
    final lowHourIndex = _indexOfLowestPositive(hourlyValues);
    final total = hourlyValues.fold<int>(0, (sum, value) => sum + value);
    final completedDhikrs = ranks
        .where((rank) => rank.target > 0 && rank.value >= rank.target)
        .length;

    return _DailyStats(
      total: total,
      previousTotal: previousTotal,
      dhikrCount: totalsByDhikr.values.where((value) => value > 0).length,
      completedDhikrs: completedDhikrs,
      totalDhikrs: ranks.length,
      topHourLabel: topHourIndex == null ? '-' : _formatHour(topHourIndex),
      lowHourLabel: lowHourIndex == null ? '-' : _formatHour(lowHourIndex),
      hourlyValues: hourlyValues,
      dayParts: _dayPartSharesForEvents(events),
      dhikrRanks: ranks,
    );
  }

  List<int> dailyValuesForMonth(DateTime month) {
    final dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final values = List<int>.filled(dayCount, 0);
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    for (final event in _eventsBetween(start, end)) {
      values[event.createdAt.day - 1] += event.delta;
    }

    return values;
  }

  List<int> monthlyValuesForYear(int year) {
    final values = List<int>.filled(12, 0);
    final start = DateTime(year);
    final end = DateTime(year + 1);

    for (final event in _eventsBetween(start, end)) {
      values[event.createdAt.month - 1] += event.delta;
    }

    return values;
  }

  _YearStats yearStats(int year) {
    final monthlyValues = monthlyValuesForYear(year);
    final start = DateTime(year);
    final end = DateTime(year + 1);
    final events = _eventsBetween(start, end);
    final dailyTotals = <DateTime, int>{};

    for (final event in events) {
      final day = _dateOnly(event.createdAt);
      dailyTotals.update(
        day,
        (value) => value + event.delta,
        ifAbsent: () => event.delta,
      );
    }

    final activeDays = dailyTotals.values.where((value) => value > 0).length;
    final total = monthlyValues.fold<int>(0, (sum, value) => sum + value);
    final daysInPeriod = _overviewDaysInPeriod(year);
    final bestDayEntry = _bestDailyEntry(dailyTotals);
    final record = bestDayEntry == null
        ? const _RecordStats.empty()
        : _recordForDay(bestDayEntry.key, bestDayEntry.value);

    return _YearStats(
      year: year,
      total: total,
      monthlyValues: monthlyValues,
      activeDays: activeDays,
      streak: _longestPositiveStreak(_dailyValuesForYear(year, dailyTotals)),
      dailyAverage: daysInPeriod == 0
          ? 0
          : (total / math.max(1, daysInPeriod)).round(),
      bestDayTotal: bestDayEntry?.value ?? 0,
      dhikrShares: _shareRowsForEvents(events, yearly: true),
      dayParts: _dayPartSharesForEvents(events),
      record: record,
    );
  }

  List<_MonthlyShareData> dhikrSharesForMonth(DateTime month) {
    return _shareRowsForEvents(
      _eventsBetween(
        DateTime(month.year, month.month),
        DateTime(month.year, month.month + 1),
      ),
    );
  }

  List<_DayPartData> dayPartsForMonth(DateTime month) {
    return _dayPartSharesForEvents(
      _eventsBetween(
        DateTime(month.year, month.month),
        DateTime(month.year, month.month + 1),
      ),
    );
  }

  int totalBetween(DateTime start, DateTime end) => _totalBetween(start, end);

  List<_StatEvent> _eventsBetween(DateTime start, DateTime end) {
    return [
      for (final event in events)
        if (!event.createdAt.isBefore(start) && event.createdAt.isBefore(end))
          event,
    ];
  }

  int _totalBetween(DateTime start, DateTime end) {
    return _eventsBetween(
      start,
      end,
    ).fold<int>(0, (sum, event) => sum + event.delta);
  }

  List<int> _dailyValuesForYear(int year, Map<DateTime, int> dailyTotals) {
    final days = _overviewDaysInPeriod(year);
    return [
      for (var i = 0; i < days; i++)
        dailyTotals[DateTime(year).add(Duration(days: i))] ?? 0,
    ];
  }

  MapEntry<DateTime, int>? _bestDailyEntry(Map<DateTime, int> totals) {
    MapEntry<DateTime, int>? best;
    for (final entry in totals.entries) {
      if (entry.value <= 0) {
        continue;
      }
      if (best == null || entry.value > best.value) {
        best = entry;
      }
    }
    return best;
  }

  _RecordStats _recordForDay(DateTime date, int total) {
    final events = _eventsBetween(date, date.add(const Duration(days: 1)));
    final totalsByDhikr = <String, int>{};
    for (final event in events) {
      totalsByDhikr.update(
        event.dhikrName,
        (value) => value + event.delta,
        ifAbsent: () => event.delta,
      );
    }

    var dhikrName = 'Kayıt yok';
    var dhikrTotal = 0;
    for (final entry in totalsByDhikr.entries) {
      if (entry.value > dhikrTotal) {
        dhikrName = entry.key;
        dhikrTotal = entry.value;
      }
    }

    return _RecordStats(
      date: date,
      total: total,
      dhikrName: dhikrName,
      dhikrTotal: dhikrTotal,
    );
  }
}

class _DailyStats {
  const _DailyStats({
    required this.total,
    required this.previousTotal,
    required this.dhikrCount,
    required this.completedDhikrs,
    required this.totalDhikrs,
    required this.topHourLabel,
    required this.lowHourLabel,
    required this.hourlyValues,
    required this.dayParts,
    required this.dhikrRanks,
  });

  final int total;
  final int previousTotal;
  final int dhikrCount;
  final int completedDhikrs;
  final int totalDhikrs;
  final String topHourLabel;
  final String lowHourLabel;
  final List<int> hourlyValues;
  final List<_DayPartData> dayParts;
  final List<_DailyDhikrRank> dhikrRanks;

  String get changeLabel {
    if (previousTotal == 0 && total == 0) {
      return '0';
    }
    if (previousTotal == 0) {
      return 'Yeni';
    }

    final change = ((total - previousTotal) / previousTotal * 100).round();
    if (change == 0) {
      return '%0';
    }
    return change > 0 ? '+%$change' : '-%${change.abs()}';
  }
}

class _YearStats {
  const _YearStats({
    required this.year,
    required this.total,
    required this.monthlyValues,
    required this.activeDays,
    required this.streak,
    required this.dailyAverage,
    required this.bestDayTotal,
    required this.dhikrShares,
    required this.dayParts,
    required this.record,
  });

  final int year;
  final int total;
  final List<int> monthlyValues;
  final int activeDays;
  final int streak;
  final int dailyAverage;
  final int bestDayTotal;
  final List<_MonthlyShareData> dhikrShares;
  final List<_DayPartData> dayParts;
  final _RecordStats record;
}

class _RecordStats {
  const _RecordStats({
    required this.date,
    required this.total,
    required this.dhikrName,
    required this.dhikrTotal,
  });

  const _RecordStats.empty()
    : date = null,
      total = 0,
      dhikrName = 'Kayıt yok',
      dhikrTotal = 0;

  final DateTime? date;
  final int total;
  final String dhikrName;
  final int dhikrTotal;
}

class _TargetProgressData {
  const _TargetProgressData({required this.total, required this.target});

  final int total;
  final int? target;

  bool get hasTarget => target != null;

  bool get completed {
    final target = this.target;
    return target != null && total >= target;
  }

  double get progress {
    final target = this.target;
    if (target == null) return 0;
    return (total / math.max(1, target)).clamp(0.0, 1.0).toDouble();
  }
}

class _StatisticsTargetCard extends StatelessWidget {
  const _StatisticsTargetCard({
    required this.scale,
    required this.targets,
    required this.loaded,
    required this.statistics,
    required this.month,
    required this.year,
    required this.onEdit,
  });

  final double scale;
  final _StatisticsTargets targets;
  final bool loaded;
  final _StatisticsData statistics;
  final DateTime month;
  final int year;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final monthlyTarget = targets.monthlyTargetFor(month);
    final yearlyTarget = targets.yearlyTargetFor(year);
    final monthlyAutomatic = targets.monthlyIsAutomatic(month);
    final yearlyAutomatic = targets.yearlyIsAutomatic(year);
    final hasAnyTarget = loaded && targets.hasAny;
    final dailyProgress = _TargetProgressData(
      total: statistics.dailyStats(today).total,
      target: targets.daily,
    );
    final monthlyProgress = _TargetProgressData(
      total: statistics.totalBetween(
        DateTime(month.year, month.month),
        DateTime(month.year, month.month + 1),
      ),
      target: monthlyTarget,
    );
    final yearlyProgress = _TargetProgressData(
      total: statistics.yearStats(year).total,
      target: yearlyTarget,
    );

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        9 * scale,
        12 * scale,
        9 * scale,
      ),
      child: hasAnyTarget
          ? _TargetFilledCompactBar(
              scale: scale,
              targets: targets,
              loaded: loaded,
              dailyProgress: dailyProgress,
              monthlyProgress: monthlyProgress,
              yearlyProgress: yearlyProgress,
              monthlyAutomatic: monthlyAutomatic,
              yearlyAutomatic: yearlyAutomatic,
              onEdit: onEdit,
            )
          : _TargetEmptyCompactBar(
              scale: scale,
              loaded: loaded,
              onEdit: onEdit,
            ),
    );
  }
}

class _TargetEmptyCompactBar extends StatelessWidget {
  const _TargetEmptyCompactBar({
    required this.scale,
    required this.loaded,
    required this.onEdit,
  });

  final double scale;
  final bool loaded;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loaded ? onEdit : null,
        borderRadius: BorderRadius.circular(18 * scale),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2 * scale),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gold.withValues(alpha: 0.22),
                      _primaryGreen.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14 * scale),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.24),
                    width: 0.7 * scale,
                  ),
                ),
                child: SizedBox.square(
                  dimension: 38 * scale,
                  child: Icon(
                    Icons.flag_rounded,
                    color: _primaryGreen,
                    size: 18 * scale,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loaded ? 'Hedef yok' : 'Hedefler yükleniyor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 12.6 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      loaded
                          ? 'Tek hedef gir, kalanını sistem tamamlar'
                          : 'Birazdan hazır',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 9.8 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * scale),
              _TargetSetButton(scale: scale, onPressed: loaded ? onEdit : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetFilledCompactBar extends StatelessWidget {
  const _TargetFilledCompactBar({
    required this.scale,
    required this.targets,
    required this.loaded,
    required this.dailyProgress,
    required this.monthlyProgress,
    required this.yearlyProgress,
    required this.monthlyAutomatic,
    required this.yearlyAutomatic,
    required this.onEdit,
  });

  final double scale;
  final _StatisticsTargets targets;
  final bool loaded;
  final _TargetProgressData dailyProgress;
  final _TargetProgressData monthlyProgress;
  final _TargetProgressData yearlyProgress;
  final bool monthlyAutomatic;
  final bool yearlyAutomatic;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final completedLabels = [
      if (dailyProgress.completed) 'Günlük',
      if (monthlyProgress.completed) 'Aylık',
      if (yearlyProgress.completed) 'Yıllık',
    ];
    final subtitle = completedLabels.isNotEmpty
        ? '${completedLabels.join(', ')} hedef tamam'
        : targets.daily != null
        ? 'Günlükten aylık ve yıllık akış hazır'
        : 'Kayıtlı hedefler aktif';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryGreen.withValues(alpha: 0.18),
                    _gold.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14 * scale),
                border: Border.all(
                  color: _primaryGreen.withValues(alpha: 0.14),
                  width: 0.7 * scale,
                ),
              ),
              child: SizedBox.square(
                dimension: 38 * scale,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: _primaryGreen,
                  size: 18 * scale,
                ),
              ),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hedefler',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 12.8 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 9.6 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            _TargetEditButton(scale: scale, onPressed: onEdit),
          ],
        ),
        SizedBox(height: 8 * scale),
        Row(
          children: [
            Expanded(
              child: _TargetSummaryPill(
                scale: scale,
                icon: Icons.today_rounded,
                label: 'Günlük',
                value: loaded ? _formatTargetValue(targets.daily) : '...',
                badge: _targetSummaryBadge(
                  progress: dailyProgress,
                  fallback: targets.daily == null ? 'Belirle' : 'Girildi',
                ),
                active: targets.daily != null,
                completed: dailyProgress.completed,
                progress: dailyProgress.progress,
                color: _buttonGreen,
              ),
            ),
            SizedBox(width: 7 * scale),
            Expanded(
              child: _TargetSummaryPill(
                scale: scale,
                icon: Icons.calendar_month_rounded,
                label: 'Aylık',
                value: loaded
                    ? _formatTargetValue(monthlyProgress.target)
                    : '...',
                badge: _targetSummaryBadge(
                  progress: monthlyProgress,
                  fallback: monthlyAutomatic
                      ? 'Otomatik'
                      : targets.monthly == null
                      ? 'Belirle'
                      : 'Özel',
                ),
                active: monthlyProgress.hasTarget,
                completed: monthlyProgress.completed,
                progress: monthlyProgress.progress,
                color: _gold,
              ),
            ),
            SizedBox(width: 7 * scale),
            Expanded(
              child: _TargetSummaryPill(
                scale: scale,
                icon: Icons.flag_rounded,
                label: 'Yıllık',
                value: loaded
                    ? _formatTargetValue(yearlyProgress.target)
                    : '...',
                badge: _targetSummaryBadge(
                  progress: yearlyProgress,
                  fallback: yearlyAutomatic
                      ? 'Otomatik'
                      : targets.yearly == null
                      ? 'Belirle'
                      : 'Özel',
                ),
                active: yearlyProgress.hasTarget,
                completed: yearlyProgress.completed,
                progress: yearlyProgress.progress,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _targetSummaryBadge({
  required _TargetProgressData progress,
  required String fallback,
}) {
  if (!progress.hasTarget) return fallback;
  if (progress.completed) return 'Tamam';
  final percent = (progress.progress * 100).round();
  return percent == 0 ? fallback : '%$percent';
}

class _TargetSetButton extends StatelessWidget {
  const _TargetSetButton({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hedef belirle',
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.add_rounded, size: 15 * scale),
        label: Text('Belirle', maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryGreen.withValues(alpha: 0.32),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.76),
          minimumSize: Size(0, 34 * scale),
          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: TextStyle(
            fontSize: 10.5 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _TargetEditButton extends StatelessWidget {
  const _TargetEditButton({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hedefleri düzenle',
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(Icons.edit_rounded, size: 16 * scale),
        style: IconButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          fixedSize: Size.square(34 * scale),
          minimumSize: Size.square(34 * scale),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
      ),
    );
  }
}

class _TargetSummaryPill extends StatelessWidget {
  const _TargetSummaryPill({
    required this.scale,
    required this.icon,
    required this.label,
    required this.value,
    required this.badge,
    required this.active,
    required this.completed,
    required this.progress,
    required this.color,
  });

  final double scale;
  final IconData icon;
  final String label;
  final String value;
  final String badge;
  final bool active;
  final bool completed;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = completed
        ? _primaryGreen
        : active
        ? color
        : _secondaryText;
    final valueColor = completed
        ? _primaryGreen
        : active
        ? _primaryText
        : _secondaryText;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            foreground.withValues(
              alpha: completed
                  ? 0.17
                  : active
                  ? 0.115
                  : 0.055,
            ),
            Colors.white.withValues(
              alpha: completed
                  ? 0.50
                  : active
                  ? 0.42
                  : 0.30,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(
          color: completed
              ? _gold.withValues(alpha: 0.36)
              : foreground.withValues(alpha: active ? 0.22 : 0.10),
          width: 0.7 * scale,
        ),
        boxShadow: [
          if (active)
            BoxShadow(
              color: foreground.withValues(alpha: 0.07),
              blurRadius: 10 * scale,
              offset: Offset(0, 4 * scale),
            ),
        ],
      ),
      child: SizedBox(
        height: 62 * scale,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8 * scale,
            7 * scale,
            8 * scale,
            6 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    completed ? Icons.check_circle_rounded : icon,
                    color: foreground,
                    size: 12 * scale,
                  ),
                  SizedBox(width: 4 * scale),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 8.8 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 13.2 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 7.6 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5 * scale),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: active ? progress : 0,
                  minHeight: 3 * scale,
                  color: completed ? _gold : foreground,
                  backgroundColor: foreground.withValues(alpha: 0.11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetEditorSheet extends StatefulWidget {
  const _TargetEditorSheet({required this.scale, required this.targets});

  final double scale;
  final _StatisticsTargets targets;

  @override
  State<_TargetEditorSheet> createState() => _TargetEditorSheetState();
}

class _TargetEditorSheetState extends State<_TargetEditorSheet> {
  late final TextEditingController _dailyController;
  late final TextEditingController _monthlyController;
  late final TextEditingController _yearlyController;

  @override
  void initState() {
    super.initState();
    _dailyController = TextEditingController(
      text: _targetInputText(widget.targets.daily),
    );
    _monthlyController = TextEditingController(
      text: _targetInputText(widget.targets.monthly),
    );
    _yearlyController = TextEditingController(
      text: _targetInputText(widget.targets.yearly),
    );
    _dailyController.addListener(_refreshAutomaticTargets);
  }

  @override
  void dispose() {
    _dailyController.removeListener(_refreshAutomaticTargets);
    _dailyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final now = DateTime.now();
    final dailyDraft = _parseTargetInput(_dailyController.text);
    final automaticMonthly = dailyDraft == null
        ? null
        : dailyDraft * DateUtils.getDaysInMonth(now.year, now.month);
    final automaticYearly = dailyDraft == null
        ? null
        : dailyDraft * _daysInYear(now.year);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28 * scale)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24 * scale,
              offset: Offset(0, -8 * scale),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20 * scale,
                12 * scale,
                20 * scale,
                18 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: _dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hedefleri düzenle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 19 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, size: 20 * scale),
                        color: _secondaryText,
                        style: IconButton.styleFrom(
                          fixedSize: Size.square(36 * scale),
                          minimumSize: Size.square(36 * scale),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  _TargetInputField(
                    scale: scale,
                    controller: _dailyController,
                    icon: Icons.today_rounded,
                    label: 'Günlük hedef',
                    hint: '2500',
                  ),
                  SizedBox(height: 10 * scale),
                  _AutomaticTargetPreview(
                    scale: scale,
                    monthlyValue: automaticMonthly,
                    yearlyValue: automaticYearly,
                  ),
                  SizedBox(height: 10 * scale),
                  _TargetInputField(
                    scale: scale,
                    controller: _monthlyController,
                    icon: Icons.calendar_month_rounded,
                    label: 'Aylık özel hedef',
                    hint: automaticMonthly == null
                        ? 'Günlükten otomatik'
                        : 'Otomatik: ${_formatWholeNumber(automaticMonthly)}',
                  ),
                  SizedBox(height: 10 * scale),
                  _TargetInputField(
                    scale: scale,
                    controller: _yearlyController,
                    icon: Icons.flag_rounded,
                    label: 'Yıllık özel hedef',
                    hint: automaticYearly == null
                        ? 'Günlükten otomatik'
                        : 'Otomatik: ${_formatWholeNumber(automaticYearly)}',
                  ),
                  SizedBox(height: 14 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearInputs,
                          icon: Icon(Icons.backspace_rounded, size: 15 * scale),
                          label: const Text('Temizle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _secondaryText,
                            side: BorderSide(
                              color: _dividerColor,
                              width: 1 * scale,
                            ),
                            minimumSize: Size.fromHeight(46 * scale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: Icon(Icons.check_rounded, size: 16 * scale),
                          label: const Text('Kaydet'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(46 * scale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _refreshAutomaticTargets() {
    setState(() {});
  }

  void _clearInputs() {
    _dailyController.clear();
    _monthlyController.clear();
    _yearlyController.clear();
  }

  void _save() {
    Navigator.of(context).pop(
      _StatisticsTargets(
        daily: _parseTargetInput(_dailyController.text),
        monthly: _parseTargetInput(_monthlyController.text),
        yearly: _parseTargetInput(_yearlyController.text),
      ),
    );
  }
}

class _AutomaticTargetPreview extends StatelessWidget {
  const _AutomaticTargetPreview({
    required this.scale,
    required this.monthlyValue,
    required this.yearlyValue,
  });

  final double scale;
  final int? monthlyValue;
  final int? yearlyValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.12),
          width: 0.7 * scale,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          11 * scale,
          9 * scale,
          11 * scale,
          9 * scale,
        ),
        child: Row(
          children: [
            Expanded(
              child: _AutomaticTargetValue(
                scale: scale,
                label: 'Aylık otomatik',
                value: monthlyValue,
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: _AutomaticTargetValue(
                scale: scale,
                label: 'Yıllık otomatik',
                value: yearlyValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomaticTargetValue extends StatelessWidget {
  const _AutomaticTargetValue({
    required this.scale,
    required this.label,
    required this.value,
  });

  final double scale;
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 8.6 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          _formatTargetValue(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 12.2 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _TargetInputField extends StatelessWidget {
  const _TargetInputField({
    required this.scale,
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
  });

  final double scale;
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [const _TargetNumberInputFormatter()],
      style: TextStyle(
        color: _primaryText,
        fontSize: 15 * scale,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20 * scale),
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: _secondaryText.withValues(alpha: 0.52)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.62),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: _dividerColor, width: 1 * scale),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: _dividerColor, width: 1 * scale),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: _primaryGreen, width: 1.3 * scale),
        ),
      ),
    );
  }
}

class _TargetNumberInputFormatter extends TextInputFormatter {
  const _TargetNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(
      newValue.text,
    ).replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatDigitString(digits);
    final extentOffset = newValue.selection.extentOffset;
    final safeOffset = extentOffset < 0
        ? 0
        : math.min(extentOffset, newValue.text.length);
    final digitsBeforeCursor = _digitsOnly(
      newValue.text.substring(0, safeOffset),
    ).length;
    final selectionOffset = _offsetForDigitPosition(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }
}

class _StatisticsTopCluster extends StatelessWidget {
  const _StatisticsTopCluster({
    required this.scale,
    required this.topInset,
    required this.selectedPeriod,
    required this.onSelected,
  });

  final double scale;
  final double topInset;
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: -42 * scale,
          child: const _StatisticsTopClusterBackground(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatisticsHero(scale: scale, topInset: topInset),
            SizedBox(height: 16 * scale),
            _PeriodFilter(
              scale: scale,
              selectedPeriod: selectedPeriod,
              onSelected: onSelected,
            ),
            SizedBox(height: 4 * scale),
          ],
        ),
      ],
    );
  }
}

class _StatisticsTopClusterBackground extends StatelessWidget {
  const _StatisticsTopClusterBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF7), Color(0xFFFFFCF7), _pageBackground],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
    );
  }
}

class _StatisticsHeroAssetEdgeFill extends StatelessWidget {
  const _StatisticsHeroAssetEdgeFill();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _libraryHeroEdgeCream,
            Color(0xFFFCF5EC),
            Color(0xFFEEEDE4),
            Color(0xFFE7ECE3),
            Color(0x00E9EEE4),
          ],
          stops: [0.0, 0.36, 0.66, 0.86, 1.0],
        ),
      ),
    );
  }
}

class _StatisticsHeroLeftBlendPatch extends StatelessWidget {
  const _StatisticsHeroLeftBlendPatch();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.64, 1.0],
        ).createShader(bounds);
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F2ED),
              Color(0xFFFCF6ED),
              Color(0xFFEEEDE5),
              Color(0xFFE8EDE4),
              Color(0x00E9EEE4),
            ],
            stops: [0.0, 0.34, 0.58, 0.80, 1.0],
          ),
        ),
      ),
    );
  }
}

class _StatisticsHeroRightWash extends StatelessWidget {
  const _StatisticsHeroRightWash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _pageBackground.withValues(alpha: 0.30),
            _libraryHeroEdgeCream.withValues(alpha: 0.18),
            _libraryHeroEdgeCream.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.74, 1.0],
        ),
      ),
    );
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero({required this.scale, required this.topInset});

  final double scale;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    const heroAssetBaseWidth = appLayoutBaselineWidth;
    const heroAssetVisualScale = 0.90;
    final heroLayoutHeight = topInset + 150 * scale;
    final heroFlowHeight = heroLayoutHeight - _statisticsPillLift * scale;
    final heroImageLeftEdge =
        appLayoutBaselineWidth * (1 - heroAssetVisualScale) * scale;

    return SizedBox(
      height: heroFlowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: heroImageLeftEdge + 4 * scale,
            height: heroLayoutHeight + 46 * scale,
            child: const _StatisticsHeroAssetEdgeFill(),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Transform.scale(
                alignment: Alignment.topRight,
                scale: scale * heroAssetVisualScale,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.72, 1.0],
                    ).createShader(bounds);
                  },
                  child: Image.asset(
                    _statisticsHeroAsset,
                    width: heroAssetBaseWidth,
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: 140 * scale,
            height: heroLayoutHeight + 58 * scale,
            child: const IgnorePointer(child: _StatisticsHeroLeftBlendPatch()),
          ),
          Positioned(
            left: 112 * scale,
            right: 0,
            top: topInset + 32 * scale,
            height: 86 * scale,
            child: const IgnorePointer(child: _StatisticsHeroRightWash()),
          ),
          Positioned(
            left: 20 * scale,
            top: topInset + 4 * scale,
            child: _HeroMenuButton(scale: scale),
          ),
          Positioned(
            left: 64 * scale,
            top: topInset + 11 * scale,
            right: 70 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'İstatistikler',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 20.5 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Padding(
                  padding: EdgeInsets.only(right: 46 * scale),
                  child: Text(
                    'Zikir yolculuğunu takip et, istikrarını güçlendir.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText.withValues(alpha: 0.88),
                      fontSize: 11.6 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.38,
                      letterSpacing: 0,
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
          color: _cardBackground.withValues(alpha: 0.96),
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

class _PeriodFilter extends StatefulWidget {
  const _PeriodFilter({
    required this.scale,
    required this.selectedPeriod,
    required this.onSelected,
  });

  final double scale;
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  @override
  State<_PeriodFilter> createState() => _PeriodFilterState();
}

class _PeriodFilterState extends State<_PeriodFilter> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedIntoView(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant _PeriodFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.scale != widget.scale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedIntoView();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollSelectedIntoView({bool jump = false}) {
    if (!mounted || !_controller.hasClients) {
      return;
    }

    final index = _periods.indexOf(widget.selectedPeriod);
    if (index < 0) {
      return;
    }

    final maxOffset = _controller.position.maxScrollExtent;
    final estimatedOffset = math.max(
      0.0,
      index * 82 * widget.scale - 48 * widget.scale,
    );
    final targetOffset = index == _periods.length - 1
        ? maxOffset
        : math.min(maxOffset, estimatedOffset);

    if (jump) {
      _controller.jumpTo(targetOffset);
      return;
    }

    _controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48 * widget.scale,
      child: ListView.separated(
        controller: _controller,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18 * widget.scale),
        itemBuilder: (context, index) {
          final period = _periods[index];
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 38 * widget.scale,
              child: _PeriodPill(
                scale: widget.scale,
                label: period,
                selected: period == widget.selectedPeriod,
                onTap: () => widget.onSelected(period),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: 8 * widget.scale),
        itemCount: _periods.length,
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
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
    final foreground = selected ? Colors.white : _primaryText;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(20 * scale),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 9 * scale,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _buttonGreen
                : _cardBackground.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(
              color: selected
                  ? _gold.withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.66),
              width: 0.7 * scale,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _buttonGreen.withValues(alpha: 0.16),
                      blurRadius: 16 * scale,
                      offset: Offset(0, 7 * scale),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.3 * scale,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyStatisticsSection extends StatelessWidget {
  const _DailyStatisticsSection({
    required this.scale,
    required this.selectedDate,
    required this.statistics,
    required this.dailyTarget,
    required this.onEditTargets,
    required this.onPickDate,
    required this.onPreviousDate,
    required this.onNextDate,
  });

  final double scale;
  final DateTime selectedDate;
  final _StatisticsData statistics;
  final int? dailyTarget;
  final VoidCallback onEditTargets;
  final VoidCallback onPickDate;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;

  @override
  Widget build(BuildContext context) {
    final summary = statistics.dailyStats(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DailySummaryCard(
          scale: scale,
          selectedDate: selectedDate,
          summary: summary,
          dailyTarget: dailyTarget,
          onEditTargets: onEditTargets,
          onPickDate: onPickDate,
          onPreviousDate: onPreviousDate,
          onNextDate: onNextDate,
        ),
        SizedBox(height: 10 * scale),
        _DailyProgressCard(
          scale: scale,
          parts: summary.dayParts,
          total: summary.total,
        ),
        SizedBox(height: 10 * scale),
        _TopDailyDhikrsCard(scale: scale, items: summary.dhikrRanks),
        SizedBox(height: 10 * scale),
        _HourlyDistributionCard(
          scale: scale,
          hourlyValues: summary.hourlyValues,
          topHourLabel: summary.topHourLabel,
          lowHourLabel: summary.lowHourLabel,
        ),
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.scale,
    required this.selectedDate,
    required this.summary,
    required this.dailyTarget,
    required this.onEditTargets,
    required this.onPickDate,
    required this.onPreviousDate,
    required this.onNextDate,
  });

  final double scale;
  final DateTime selectedDate;
  final _DailyStats summary;
  final int? dailyTarget;
  final VoidCallback onEditTargets;
  final VoidCallback onPickDate;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    final target = dailyTarget;
    final hasTarget = target != null;
    final remaining = hasTarget ? math.max(0, target - total) : 0;
    final progress = hasTarget
        ? (total / math.max(1, target)).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final metrics = [
      _MetricData(
        icon: Icons.trending_up_rounded,
        value: summary.changeLabel,
        label: 'Düne Göre',
        color: _gold,
      ),
      _MetricData(
        icon: Icons.spa_rounded,
        value: '${summary.dhikrCount}',
        label: 'Zikir Türü',
        color: _buttonGreen,
      ),
      _MetricData(
        icon: Icons.bolt_rounded,
        value: summary.topHourLabel,
        label: 'Yoğun Saat',
        color: _primaryGreen,
      ),
      _MetricData(
        icon: Icons.check_circle_rounded,
        value: summary.totalDhikrs == 0
            ? '0'
            : '${summary.completedDhikrs}/${summary.totalDhikrs}',
        label: 'Tamamlanan',
        color: _buttonGreen,
      ),
    ];

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        13 * scale,
        14 * scale,
        13 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Özet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: _statisticsCardTitleFontSize * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.06,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onPickDate,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _primaryGreen.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.64),
                              width: 0.7 * scale,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 7 * scale,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: _primaryGreen,
                                  size: 14 * scale,
                                ),
                                SizedBox(width: 7 * scale),
                                Flexible(
                                  child: Text(
                                    _formatDailyDate(selectedDate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _primaryText,
                                      fontSize: 10.8 * scale,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2 * scale),
                                Icon(
                                  Icons.expand_more_rounded,
                                  color: _secondaryText,
                                  size: 15 * scale,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _DailyDateArrowButton(
                scale: scale,
                icon: Icons.chevron_left_rounded,
                onPressed: onPreviousDate,
              ),
              SizedBox(width: 7 * scale),
              _DailyDateArrowButton(
                scale: scale,
                icon: Icons.chevron_right_rounded,
                onPressed: onNextDate,
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF123B2B), Color(0xFF327653)],
              ),
              borderRadius: BorderRadius.circular(24 * scale),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.16),
                  blurRadius: 20 * scale,
                  offset: Offset(0, 9 * scale),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                15 * scale,
                15 * scale,
                14 * scale,
                14 * scale,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugün çekilen',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 11.2 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatWholeNumber(total),
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 35 * scale,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          hasTarget
                              ? remaining == 0
                                    ? 'Günlük hedef tamamlandı'
                                    : 'Günlük hedefe ${_formatWholeNumber(remaining)} zikir kaldı'
                              : 'Hedef yok; özet gösteriliyor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFF4E3A8),
                            fontSize: 10.8 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 11 * scale),
                  _OverviewTargetPanel(
                    scale: scale,
                    progress: progress,
                    target: target,
                    onTap: onEditTargets,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          _DailyInsetPanel(
            scale: scale,
            child: Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(
                    child: _OverviewMetricTile(
                      scale: scale,
                      metric: metrics[i],
                    ),
                  ),
                  if (i != metrics.length - 1)
                    _SubtleVerticalDivider(scale: scale),
                ],
              ],
            ),
          ),
          SizedBox(height: 11 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: _gold.withValues(alpha: 0.23),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 11 * scale,
                vertical: 10 * scale,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 15 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      total == 0
                          ? 'Bugün için henüz zikir kaydı yok.'
                          : hasTarget
                          ? remaining == 0
                                ? 'Günlük hedef tamamlandı; kayıtların dağılımı güncellendi.'
                                : 'Kalan hedef gerçek günlük toplamdan hesaplanıyor.'
                          : 'Hedef girmeden de toplam, vakit ve zikir dağılımı görünür.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 10.7 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyDateArrowButton extends StatelessWidget {
  const _DailyDateArrowButton({
    required this.scale,
    required this.icon,
    required this.onPressed,
  });

  final double scale;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 35 * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _pageBackground.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 0.7 * scale,
          ),
        ),
        child: IconButton(
          tooltip: 'Tarih değiştir',
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, color: _primaryGreen, size: 22 * scale),
        ),
      ),
    );
  }
}

class _DailySummaryMetricTile extends StatelessWidget {
  const _DailySummaryMetricTile({required this.scale, required this.metric});

  final double scale;
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MetricIconBubble(scale: scale, icon: metric.icon, color: metric.color),
        SizedBox(height: 9 * scale),
        SizedBox(
          width: 58 * scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: _primaryText,
                fontSize: 14.7 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: 5 * scale),
        SizedBox(
          width: 60 * scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 8.1 * scale,
                fontWeight: FontWeight.w700,
                height: 1.08,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.scale,
    required this.parts,
    required this.total,
  });

  final double scale;
  final List<_DayPartData> parts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final topPart = parts.reduce(
      (current, next) => current.percent >= next.percent ? current : next,
    );
    final tipText = total == 0
        ? 'Bugün için vakit dağılımı henüz oluşmadı.'
        : 'Bugün en yoğun vakit ${topPart.label}; dağılım gerçek kayıtlarından hesaplandı.';

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Vakit Dağılımı',
            description: 'Bugünkü zikirlerin vakitlere göre yüzdesi.',
          ),
          SizedBox(height: 14 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14 * scale,
              child: Row(
                children: [
                  for (final part in parts)
                    Expanded(
                      flex: math.max(1, part.percent),
                      child: ColoredBox(color: part.color),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          for (var i = 0; i < parts.length; i++) ...[
            _DailyTimeBlockRow(scale: scale, data: parts[i]),
            if (i != parts.length - 1) SizedBox(height: 9 * scale),
          ],
          SizedBox(height: 12 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.62),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                10 * scale,
                12 * scale,
                10 * scale,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: _gold,
                    size: 15 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      tipText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 10.5 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTimeBlockRow extends StatelessWidget {
  const _DailyTimeBlockRow({required this.scale, required this.data});

  final double scale;
  final _DayPartData data;

  @override
  Widget build(BuildContext context) {
    final labelColor = data.highlighted ? _primaryText : _secondaryText;

    return Row(
      children: [
        SizedBox.square(
          dimension: 30 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: data.color.withValues(
                alpha: data.highlighted ? 0.18 : 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 16 * scale),
          ),
        ),
        SizedBox(width: 10 * scale),
        SizedBox(
          width: 54 * scale,
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 11.5 * scale,
              fontWeight: data.highlighted ? FontWeight.w900 : FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7 * scale,
              value: (data.percent / 100).clamp(0.0, 1.0).toDouble(),
              color: data.color,
              backgroundColor: _dividerColor.withValues(alpha: 0.62),
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        SizedBox(
          width: 43 * scale,
          child: Text(
            '%${data.percent}',
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: data.highlighted ? _primaryText : _secondaryText,
              fontSize: 10.6 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _HourlyDistributionCard extends StatelessWidget {
  const _HourlyDistributionCard({
    required this.scale,
    required this.hourlyValues,
    required this.topHourLabel,
    required this.lowHourLabel,
  });

  final double scale;
  final List<int> hourlyValues;
  final String topHourLabel;
  final String lowHourLabel;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        14 * scale,
        15 * scale,
        12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Saat Dağılımı',
            description: 'Günün en yüksek ve en düşük saatlerini gösterir.',
          ),
          SizedBox(height: 14 * scale),
          SizedBox(
            height: 124 * scale,
            child: CustomPaint(
              painter: _HourlyDistributionPainter(
                scale: scale,
                values: hourlyValues,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(height: 12 * scale),
          Row(
            children: [
              _DailyFlowBadge(
                scale: scale,
                icon: Icons.bolt_rounded,
                label: 'En yüksek',
                value: topHourLabel,
                color: _gold,
              ),
              SizedBox(width: 8 * scale),
              _DailyFlowBadge(
                scale: scale,
                icon: Icons.self_improvement_rounded,
                label: 'En düşük',
                value: lowHourLabel,
                color: _buttonGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyFlowBadge extends StatelessWidget {
  const _DailyFlowBadge({
    required this.scale,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final double scale;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: 0.7 * scale,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10 * scale,
            9 * scale,
            10 * scale,
            9 * scale,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 15 * scale),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 9.5 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 10.7 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopDailyDhikrsCard extends StatelessWidget {
  const _TopDailyDhikrsCard({required this.scale, required this.items});

  final double scale;
  final List<_DailyDhikrRank> items;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        13 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Zikir Dağılımı',
            description: 'Bugünkü gerçek kayıtlara göre zikir sıralaması.',
          ),
          SizedBox(height: 12 * scale),
          if (items.isEmpty)
            _StatsEmptyMessage(
              scale: scale,
              icon: Icons.spa_rounded,
              text: 'Bugün için zikir kaydı yok.',
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _DailyDhikrRankRow(scale: scale, item: items[i]),
              if (i != items.length - 1) SizedBox(height: 11 * scale),
            ],
        ],
      ),
    );
  }
}

class _DailyDhikrRankRow extends StatelessWidget {
  const _DailyDhikrRankRow({required this.scale, required this.item});

  final double scale;
  final _DailyDhikrRank item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 30 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                item.rank.toString(),
                style: TextStyle(
                  color: item.color,
                  fontSize: 11.5 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
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
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 12.1 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.18),
                        width: 0.7 * scale,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 4.5 * scale,
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 8.8 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Text(
                    _formatWholeNumber(item.value),
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 12.1 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7 * scale),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5 * scale,
                  value: item.progress,
                  color: item.color,
                  backgroundColor: _dividerColor.withValues(alpha: 0.65),
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                '${_formatWholeNumber(item.value)} / ${_formatWholeNumber(item.target)} hedef',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 9.4 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _DailyMiniStatsGrid extends StatelessWidget {
  const _DailyMiniStatsGrid({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    const items = [
      _MetricData(
        icon: Icons.spa_rounded,
        value: '2 / 3',
        label: 'Tamamlanan Hedefler',
        color: _buttonGreen,
      ),
      _MetricData(
        icon: Icons.calendar_today_rounded,
        value: '12',
        label: 'Aktif Gün',
        color: _primaryGreen,
      ),
      _MetricData(
        icon: Icons.schedule_rounded,
        value: '1sa 48dk',
        label: 'Toplam Süre',
        color: _buttonGreen,
      ),
      _MetricData(
        icon: Icons.emoji_events_rounded,
        value: '8 gün',
        label: 'En Uzun Seri',
        color: _gold,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: _DailyMiniStatTile(scale: scale, item: items[i]),
            ),
            if (i != items.length - 1) SizedBox(width: 8 * scale),
          ],
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DailyMiniStatTile extends StatelessWidget {
  const _DailyMiniStatTile({required this.scale, required this.item});

  final double scale;
  final _MetricData item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
          width: 0.8 * scale,
        ),
        boxShadow: _softShadow(scale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 7 * scale,
          vertical: 12 * scale,
        ),
        child: Column(
          children: [
            _MetricIconBubble(scale: scale, icon: item.icon, color: item.color),
            SizedBox(height: 8 * scale),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 8.8 * scale,
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            SizedBox(height: 7 * scale),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryText,
                fontSize: 14.5 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyInsetPanel extends StatelessWidget {
  const _DailyInsetPanel({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 14 * scale,
        ),
        child: child,
      ),
    );
  }
}

class _MonthlyStatisticsSection extends StatelessWidget {
  const _MonthlyStatisticsSection({
    required this.scale,
    required this.selectedMonth,
    required this.statistics,
    required this.monthlyTarget,
    required this.monthlyTargetAutomatic,
    required this.onEditTargets,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final double scale;
  final DateTime selectedMonth;
  final _StatisticsData statistics;
  final int? monthlyTarget;
  final bool monthlyTargetAutomatic;
  final VoidCallback onEditTargets;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final dailyValues = statistics.dailyValuesForMonth(selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthlyOverviewCard(
          scale: scale,
          selectedMonth: selectedMonth,
          dailyValues: dailyValues,
          monthlyTarget: monthlyTarget,
          monthlyTargetAutomatic: monthlyTargetAutomatic,
          onEditTargets: onEditTargets,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
        ),
        SizedBox(height: 10 * scale),
        _MonthlyCalendarCard(
          scale: scale,
          selectedMonth: selectedMonth,
          dailyValues: dailyValues,
          monthlyTarget: monthlyTarget,
        ),
        SizedBox(height: 10 * scale),
        _MonthlyRhythmCard(
          scale: scale,
          selectedMonth: selectedMonth,
          dailyValues: dailyValues,
        ),
        SizedBox(height: 10 * scale),
        _MonthlyFocusCard(
          scale: scale,
          selectedMonth: selectedMonth,
          dailyValues: dailyValues,
          shares: statistics.dhikrSharesForMonth(selectedMonth),
          dayParts: statistics.dayPartsForMonth(selectedMonth),
        ),
        SizedBox(height: 10 * scale),
        _MonthlyInsightsCard(
          scale: scale,
          selectedMonth: selectedMonth,
          dailyValues: dailyValues,
          monthlyTarget: monthlyTarget,
        ),
      ],
    );
  }
}

class _MonthlyOverviewCard extends StatelessWidget {
  const _MonthlyOverviewCard({
    required this.scale,
    required this.selectedMonth,
    required this.dailyValues,
    required this.monthlyTarget,
    required this.monthlyTargetAutomatic,
    required this.onEditTargets,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final double scale;
  final DateTime selectedMonth;
  final List<int> dailyValues;
  final int? monthlyTarget;
  final bool monthlyTargetAutomatic;
  final VoidCallback onEditTargets;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final total = dailyValues.fold<int>(0, (sum, value) => sum + value);
    final target = monthlyTarget;
    final hasTarget = target != null;
    final progress = hasTarget
        ? (total / math.max(1, target)).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final activeDays = dailyValues.where((value) => value > 0).length;
    final average = activeDays == 0 ? 0 : (total / activeDays).round();
    final bestValue = dailyValues.reduce(math.max);
    final bestDay = dailyValues.indexOf(bestValue) + 1;
    final bestDayLabel = bestValue == 0 ? '-' : '$bestDay. gün';
    final streak = _longestPositiveStreak(dailyValues);
    final remaining = hasTarget ? math.max(0, target - total) : 0;
    final targetMode = monthlyTargetAutomatic ? 'otomatik' : 'özel';
    final metrics = [
      _MetricData(
        icon: Icons.calendar_month_rounded,
        value: '$activeDays/${dailyValues.length}',
        label: 'Aktif Gün',
        color: _primaryGreen,
      ),
      _MetricData(
        icon: Icons.show_chart_rounded,
        value: _formatWholeNumber(average),
        label: 'Gün Ort.',
        color: _buttonGreen,
      ),
      _MetricData(
        icon: Icons.emoji_events_rounded,
        value: bestDayLabel,
        label: 'En İyi Gün',
        color: _gold,
      ),
      _MetricData(
        icon: Icons.local_fire_department_rounded,
        value: '$streak gün',
        label: 'Seri',
        color: _buttonGreen,
      ),
    ];

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Aylık Özet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: _statisticsCardTitleFontSize * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.06,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      _formatMonthLabel(selectedMonth),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _DailyDateArrowButton(
                scale: scale,
                icon: Icons.chevron_left_rounded,
                onPressed: onPreviousMonth,
              ),
              SizedBox(width: 7 * scale),
              _DailyDateArrowButton(
                scale: scale,
                icon: Icons.chevron_right_rounded,
                onPressed: onNextMonth,
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5B3E), Color(0xFF347756)],
              ),
              borderRadius: BorderRadius.circular(22 * scale),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.13),
                  blurRadius: 18 * scale,
                  offset: Offset(0, 8 * scale),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                15 * scale,
                14 * scale,
                13 * scale,
                13 * scale,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bu ay toplam',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 11.2 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 7 * scale),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatWholeNumber(total),
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32 * scale,
                              fontWeight: FontWeight.w900,
                              height: 0.98,
                            ),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          hasTarget
                              ? remaining == 0
                                    ? 'Aylık hedef tamamlandı'
                                    : 'Aylık hedefe ${_formatWholeNumber(remaining)} zikir kaldı'
                              : 'Hedef yok; özet gösteriliyor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFF4E3A8),
                            fontSize: 10.7 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 13 * scale),
                  _OverviewTargetPanel(
                    scale: scale,
                    progress: progress,
                    target: target,
                    onTap: onEditTargets,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8 * scale,
              value: progress,
              color: _gold,
              backgroundColor: _dividerColor.withValues(alpha: 0.68),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            hasTarget
                ? '${_formatWholeNumber(total)} / ${_formatWholeNumber(target)} aylık hedef ($targetMode)'
                : 'Günlük hedef girilirse aylık hedef otomatik hesaplanır.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 10.8 * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(height: 13 * scale),
          _DailyInsetPanel(
            scale: scale,
            child: Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(
                    child: _OverviewMetricTile(
                      scale: scale,
                      metric: metrics[i],
                    ),
                  ),
                  if (i != metrics.length - 1)
                    _SubtleVerticalDivider(scale: scale),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyCalendarCard extends StatelessWidget {
  const _MonthlyCalendarCard({
    required this.scale,
    required this.selectedMonth,
    required this.dailyValues,
    required this.monthlyTarget,
  });

  final double scale;
  final DateTime selectedMonth;
  final List<int> dailyValues;
  final int? monthlyTarget;

  @override
  Widget build(BuildContext context) {
    final bestValue = dailyValues.reduce(math.max);
    final bestDay = bestValue == 0 ? null : dailyValues.indexOf(bestValue) + 1;
    final activeDays = dailyValues.where((value) => value > 0).length;
    final target = monthlyTarget;
    final dailyTarget = target == null
        ? null
        : (target / dailyValues.length).ceil();

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardHeader(
                  scale: scale,
                  title: 'Ay Takvimi',
                  description:
                      'Gün gün toplamı ve hedefe ulaşan günleri gösterir.',
                ),
              ),
              SizedBox(width: 9 * scale),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.25),
                    width: 0.7 * scale,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * scale,
                    vertical: 6 * scale,
                  ),
                  child: Text(
                    '$activeDays aktif gün',
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 10.2 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          _MonthlyCalendarGrid(
            scale: scale,
            selectedMonth: selectedMonth,
            dailyValues: dailyValues,
            dailyTarget: dailyTarget,
            bestDay: bestDay,
          ),
          SizedBox(height: 12 * scale),
          _MonthlyLegend(
            scale: scale,
            hasTarget: monthlyTarget != null,
            hasData: bestValue > 0,
          ),
        ],
      ),
    );
  }
}

class _MonthlyCalendarGrid extends StatelessWidget {
  const _MonthlyCalendarGrid({
    required this.scale,
    required this.selectedMonth,
    required this.dailyValues,
    required this.dailyTarget,
    required this.bestDay,
  });

  final double scale;
  final DateTime selectedMonth;
  final List<int> dailyValues;
  final int? dailyTarget;
  final int? bestDay;

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final leadingBlanks =
        DateTime(selectedMonth.year, selectedMonth.month).weekday - 1;
    final totalCells = leadingBlanks + dailyValues.length;
    final trailingBlanks = (7 - totalCells % 7) % 7;
    final maxValue = dailyValues.reduce(math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 5 * scale;
        final cellSize = (constraints.maxWidth - gap * 6) / 7;

        return Column(
          children: [
            Row(
              children: [
                for (final label in dayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 9.2 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < leadingBlanks; i++)
                  SizedBox(width: cellSize, height: cellSize),
                for (var i = 0; i < dailyValues.length; i++)
                  SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: _MonthlyDayCell(
                      scale: scale,
                      day: i + 1,
                      value: dailyValues[i],
                      maxValue: maxValue,
                      dailyTarget: dailyTarget,
                      highlighted: bestDay != null && i + 1 == bestDay,
                    ),
                  ),
                for (var i = 0; i < trailingBlanks; i++)
                  SizedBox(width: cellSize, height: cellSize),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MonthlyDayCell extends StatelessWidget {
  const _MonthlyDayCell({
    required this.scale,
    required this.day,
    required this.value,
    required this.maxValue,
    required this.dailyTarget,
    required this.highlighted,
  });

  final double scale;
  final int day;
  final int value;
  final int maxValue;
  final int? dailyTarget;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final active = value > 0;
    final target = dailyTarget;
    final intensity = maxValue == 0 ? 0.0 : value / maxValue;
    final warmth = math.max(0.0, (intensity - 0.56) / 0.44);
    final color = active
        ? Color.lerp(
            _buttonGreen,
            _gold,
            warmth,
          )!.withValues(alpha: 0.14 + intensity * 0.56)
        : Colors.white.withValues(alpha: 0.42);
    final textColor = active && intensity > 0.58 ? Colors.white : _primaryText;
    final mutedTextColor = active && intensity > 0.58
        ? Colors.white.withValues(alpha: 0.78)
        : _secondaryText;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(
          color: highlighted
              ? _gold
              : target != null && value >= target
              ? _gold.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.55),
          width: highlighted ? 1.2 * scale : 0.7 * scale,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.20),
                  blurRadius: 10 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(5 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontSize: 9.6 * scale,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                active ? _formatCompactCount(value) : '-',
                maxLines: 1,
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 8.2 * scale,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyLegend extends StatelessWidget {
  const _MonthlyLegend({
    required this.scale,
    required this.hasTarget,
    required this.hasData,
  });

  final double scale;
  final bool hasTarget;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MonthlyLegendItem(scale: scale, color: _dividerColor, label: 'Boş'),
        SizedBox(width: 10 * scale),
        _MonthlyLegendItem(
          scale: scale,
          color: _buttonGreen,
          label: 'Zikir var',
        ),
        SizedBox(width: 10 * scale),
        _MonthlyLegendItem(
          scale: scale,
          color: _gold,
          label: hasData
              ? (hasTarget ? 'Hedef üstü' : 'En yüksek')
              : 'Rekor yok',
        ),
      ],
    );
  }
}

class _MonthlyLegendItem extends StatelessWidget {
  const _MonthlyLegendItem({
    required this.scale,
    required this.color,
    required this.label,
  });

  final double scale;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(5 * scale),
            ),
            child: SizedBox.square(dimension: 10 * scale),
          ),
          SizedBox(width: 6 * scale),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 9.4 * scale,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyRhythmCard extends StatelessWidget {
  const _MonthlyRhythmCard({
    required this.scale,
    required this.selectedMonth,
    required this.dailyValues,
  });

  final double scale;
  final DateTime selectedMonth;
  final List<int> dailyValues;

  @override
  Widget build(BuildContext context) {
    final weeks = _monthlyWeekSummaries(selectedMonth, dailyValues);
    final hasMonthlyData = dailyValues.any((value) => value > 0);
    final maxWeekTotal = weeks.fold<int>(
      1,
      (highest, week) => math.max(highest, week.total),
    );
    final bestWeek = weeks.reduce((a, b) => a.total >= b.total ? a : b);
    final quietWeek = weeks.reduce((a, b) => a.total <= b.total ? a : b);

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Haftalık Dağılım',
            description: 'Haftalara göre toplam zikir ve aktif gün sayısı.',
          ),
          SizedBox(height: 15 * scale),
          SizedBox(
            height: 138 * scale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < weeks.length; i++) ...[
                  Expanded(
                    child: _MonthlyWeekColumn(
                      scale: scale,
                      week: weeks[i],
                      maxTotal: maxWeekTotal,
                      selected: hasMonthlyData && weeks[i] == bestWeek,
                    ),
                  ),
                  if (i != weeks.length - 1) SizedBox(width: 8 * scale),
                ],
              ],
            ),
          ),
          SizedBox(height: 13 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.58),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                11 * scale,
                12 * scale,
                11 * scale,
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: _primaryText,
                    fontFamily: 'Inter',
                    fontSize: 10.8 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  ),
                  text: hasMonthlyData
                      ? 'En yüksek hafta ${bestWeek.title}: ${_formatWholeNumber(bestWeek.total)} zikir. En düşük hafta ${quietWeek.title}; bu hafta günlük ortalama yükseltilebilir.'
                      : 'Bu ay haftalık dağılım henüz oluşmadı.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyWeekColumn extends StatelessWidget {
  const _MonthlyWeekColumn({
    required this.scale,
    required this.week,
    required this.maxTotal,
    required this.selected,
  });

  final double scale;
  final _MonthlyWeekSummary week;
  final int maxTotal;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final chartHeight = 78 * scale;
    final barHeight = math
        .max(10 * scale, chartHeight * week.total / maxTotal)
        .toDouble();

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: selected
                      ? [const Color(0xFFE7CA68), const Color(0xFFC7A44F)]
                      : [
                          _buttonGreen.withValues(alpha: 0.62),
                          _buttonGreen.withValues(alpha: 0.24),
                        ],
                ),
                borderRadius: BorderRadius.circular(12 * scale),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.18),
                          blurRadius: 12 * scale,
                          offset: Offset(0, 5 * scale),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(width: 27 * scale, height: barHeight),
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          week.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? _primaryText : _secondaryText,
            fontSize: 9.4 * scale,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 5 * scale),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatCompactCount(week.total),
            maxLines: 1,
            style: TextStyle(
              color: selected ? _gold : _primaryText,
              fontSize: 10.2 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          '${week.activeDays} gün',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 8.6 * scale,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MonthlyFocusCard extends StatelessWidget {
  const _MonthlyFocusCard({
    required this.scale,
    required this.selectedMonth,
    required this.dailyValues,
    required this.shares,
    required this.dayParts,
  });

  final double scale;
  final DateTime selectedMonth;
  final List<int> dailyValues;
  final List<_MonthlyShareData> shares;
  final List<_DayPartData> dayParts;

  @override
  Widget build(BuildContext context) {
    final total = dailyValues.fold<int>(0, (sum, value) => sum + value);

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Aylık Zikir Dağılımı',
            description:
                'Zikir türlerine ve vakitlere göre gerçek aylık yüzdeler.',
          ),
          SizedBox(height: 14 * scale),
          if (shares.isEmpty)
            _StatsEmptyMessage(
              scale: scale,
              icon: Icons.spa_rounded,
              text: 'Bu ay için zikir dağılımı henüz oluşmadı.',
            )
          else
            for (var i = 0; i < shares.length; i++) ...[
              _MonthlyShareRow(scale: scale, rank: i + 1, item: shares[i]),
              if (i != shares.length - 1) SizedBox(height: 10 * scale),
            ],
          SizedBox(height: 15 * scale),
          Container(height: 0.8 * scale, color: _dividerColor),
          SizedBox(height: 14 * scale),
          Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                color: _gold,
                size: 15 * scale,
              ),
              SizedBox(width: 7 * scale),
              Text(
                'Vakit Dağılımı',
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 13.3 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 11 * scale),
          _MonthlyDayPartBand(scale: scale, items: dayParts),
          SizedBox(height: 10 * scale),
          if (total == 0)
            _StatsEmptyMessage(
              scale: scale,
              icon: Icons.access_time_filled_rounded,
              text: 'Bu ay için vakit dağılımı henüz oluşmadı.',
            )
          else
            Wrap(
              spacing: 7 * scale,
              runSpacing: 7 * scale,
              children: [
                for (final part in dayParts)
                  _MonthlyPartChip(scale: scale, item: part),
              ],
            ),
        ],
      ),
    );
  }
}

class _MonthlyShareRow extends StatelessWidget {
  const _MonthlyShareRow({
    required this.scale,
    required this.rank,
    required this.item,
  });

  final double scale;
  final int rank;
  final _MonthlyShareData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 21 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.2 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 12.2 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  Text(
                    _formatWholeNumber(item.value),
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 11.8 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  SizedBox(
                    width: 31 * scale,
                    child: Text(
                      '%${item.percent}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 10.5 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4 * scale,
                  value: item.percent / 100,
                  color: item.color,
                  backgroundColor: _dividerColor.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyDayPartBand extends StatelessWidget {
  const _MonthlyDayPartBand({required this.scale, required this.items});

  final double scale;
  final List<_DayPartData> items;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 14 * scale,
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                flex: math.max(1, item.percent),
                child: ColoredBox(color: item.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyPartChip extends StatelessWidget {
  const _MonthlyPartChip({required this.scale, required this.item});

  final double scale;
  final _DayPartData item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 6 * scale,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 12 * scale),
            SizedBox(width: 5 * scale),
            Text(
              '${item.label} %${item.percent}',
              style: TextStyle(
                color: _primaryText,
                fontSize: 9.4 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyInsightsCard extends StatelessWidget {
  const _MonthlyInsightsCard({
    required this.scale,
    required this.selectedMonth,
    required this.dailyValues,
    required this.monthlyTarget,
  });

  final double scale;
  final DateTime selectedMonth;
  final List<int> dailyValues;
  final int? monthlyTarget;

  @override
  Widget build(BuildContext context) {
    final total = dailyValues.fold<int>(0, (sum, value) => sum + value);
    final target = monthlyTarget;
    final hasTarget = target != null;
    final remaining = hasTarget ? math.max(0, target - total) : 0;
    final emptyDays = math.max(
      1,
      dailyValues.where((value) => value == 0).length,
    );
    final bestValue = dailyValues.reduce(math.max);
    final bestDay = dailyValues.indexOf(bestValue) + 1;
    final bestWeek = _monthlyWeekSummaries(
      selectedMonth,
      dailyValues,
    ).reduce((a, b) => a.total >= b.total ? a : b);
    final hasMonthlyData = total > 0;
    final dailyCatchUp = hasTarget ? (remaining / emptyDays).ceil() : 0;
    final insights = [
      _MonthlyInsightData(
        icon: Icons.flag_rounded,
        title: hasTarget ? 'Kalan hedef' : 'Aylık hedef',
        value: hasTarget
            ? remaining == 0
                  ? 'Tamamlandı'
                  : '${_formatCompactCount(remaining)} kaldı'
            : 'Belirle',
        subtitle: hasTarget
            ? remaining == 0
                  ? 'Bu ay hedef tamamlandı; kalan günler seriyi güçlendirir.'
                  : 'Kalan günlerde ortalama ${_formatWholeNumber(dailyCatchUp)} zikir hedefi tamamlar.'
            : 'Hedef girilince gereken günlük ortalama hesaplanır.',
        color: _buttonGreen,
      ),
      _MonthlyInsightData(
        icon: Icons.auto_graph_rounded,
        title: 'En yüksek gün',
        value: hasMonthlyData ? '$bestDay. gün' : 'Kayıt yok',
        subtitle: hasMonthlyData
            ? '${_formatWholeNumber(bestValue)} zikirle ayın en yüksek günlük toplamı.'
            : 'Bu ay günlük rekor oluşmadı.',
        color: _gold,
      ),
      _MonthlyInsightData(
        icon: Icons.bolt_rounded,
        title: 'En iyi hafta',
        value: hasMonthlyData ? bestWeek.title : 'Kayıt yok',
        subtitle: hasMonthlyData
            ? '${_formatWholeNumber(bestWeek.total)} zikirle ayın en yüksek haftası.'
            : 'Bu ay haftalık toplam oluşmadı.',
        color: _primaryGreen,
      ),
    ];

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Aylık Hedef Özeti',
            description:
                'Hedefe ulaşmak için kalan günlerde gereken ortalamayı gösterir.',
          ),
          SizedBox(height: 13 * scale),
          for (var i = 0; i < insights.length; i++) ...[
            _MonthlyInsightTile(scale: scale, item: insights[i]),
            if (i != insights.length - 1) SizedBox(height: 8 * scale),
          ],
        ],
      ),
    );
  }
}

class _MonthlyInsightTile extends StatelessWidget {
  const _MonthlyInsightTile({required this.scale, required this.item});

  final double scale;
  final _MonthlyInsightData item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(17 * scale),
        border: Border.all(
          color: item.color.withValues(alpha: 0.16),
          width: 0.7 * scale,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          11 * scale,
          10 * scale,
          11 * scale,
          10 * scale,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 34 * scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 18 * scale),
              ),
            ),
            SizedBox(width: 11 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 10.4 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 5 * scale),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 9 * scale),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: item.color,
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearlyFocusCard extends StatelessWidget {
  const _YearlyFocusCard({
    required this.scale,
    required this.selectedYear,
    required this.statistics,
  });

  final double scale;
  final int selectedYear;
  final _StatisticsData statistics;

  @override
  Widget build(BuildContext context) {
    final yearStats = statistics.yearStats(selectedYear);
    final shares = yearStats.dhikrShares;
    final visibleShares = shares.take(5).toList(growable: false);
    final remainingShares = shares.skip(5).toList(growable: false);

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        14 * scale,
        14 * scale,
        12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Yıllık Zikir Dağılımı',
            description: 'Yıl içindeki zikir türlerinin toplam içindeki payı.',
          ),
          SizedBox(height: 13 * scale),
          if (visibleShares.isEmpty)
            _StatsEmptyMessage(
              scale: scale,
              icon: Icons.spa_rounded,
              text: 'Bu yıl için zikir dağılımı henüz oluşmadı.',
            )
          else
            for (var i = 0; i < visibleShares.length; i++) ...[
              _MonthlyShareRow(
                scale: scale,
                rank: i + 1,
                item: visibleShares[i],
              ),
              if (i != visibleShares.length - 1) SizedBox(height: 8 * scale),
            ],
          if (remainingShares.isNotEmpty) ...[
            SizedBox(height: 11 * scale),
            _YearlyDistributionMoreButton(
              scale: scale,
              count: remainingShares.length,
              onTap: () => _showYearlyDistributionSheet(
                context,
                scale,
                remainingShares,
                visibleShares.length + 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _YearlyDistributionMoreButton extends StatelessWidget {
  const _YearlyDistributionMoreButton({
    required this.scale,
    required this.count,
    required this.onTap,
  });

  final double scale;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.055),
            borderRadius: borderRadius,
            border: Border.all(
              color: _primaryGreen.withValues(alpha: 0.12),
              width: 0.7 * scale,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 11 * scale,
              vertical: 9 * scale,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: SizedBox.square(
                    dimension: 29 * scale,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _primaryGreen,
                      size: 20 * scale,
                    ),
                  ),
                ),
                SizedBox(width: 9 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Devamını gör',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 11.4 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        '$count zikir daha listede',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 9.2 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  color: _primaryGreen,
                  size: 15 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showYearlyDistributionSheet(
  BuildContext context,
  double scale,
  List<_MonthlyShareData> shares,
  int startRank,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _YearlyDistributionSheet(
      scale: scale,
      shares: shares,
      startRank: startRank,
    ),
  );
}

class _YearlyDistributionSheet extends StatelessWidget {
  const _YearlyDistributionSheet({
    required this.scale,
    required this.shares,
    required this.startRank,
  });

  final double scale;
  final List<_MonthlyShareData> shares;
  final int startRank;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28 * scale)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28 * scale,
              offset: Offset(0, -10 * scale),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18 * scale,
            10 * scale,
            18 * scale,
            math.max(bottomInset, 14 * scale),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.54,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: SizedBox(width: 48 * scale, height: 5 * scale),
                  ),
                ),
                SizedBox(height: 18 * scale),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dağılımın Devamı',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _primaryText,
                              fontSize: 19 * scale,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Text(
                            'Daha düşük paya sahip zikirler.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _secondaryText,
                              fontSize: 11.2 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, size: 22 * scale),
                      style: IconButton.styleFrom(
                        foregroundColor: _secondaryText,
                        fixedSize: Size.square(38 * scale),
                        minimumSize: Size.square(38 * scale),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * scale),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < shares.length; i++) ...[
                          _MonthlyShareRow(
                            scale: scale,
                            rank: startRank + i,
                            item: shares[i],
                          ),
                          if (i != shares.length - 1)
                            SizedBox(height: 12 * scale),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.scale,
    required this.selectedYear,
    required this.statistics,
    required this.availableYears,
    required this.yearToDateTarget,
    required this.yearlyTargetAutomatic,
    required this.onEditTargets,
    required this.onYearSelected,
  });

  final double scale;
  final int selectedYear;
  final _StatisticsData statistics;
  final List<int> availableYears;
  final int? yearToDateTarget;
  final bool yearlyTargetAutomatic;
  final VoidCallback onEditTargets;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final yearStats = statistics.yearStats(selectedYear);
    final total = yearStats.total;
    final target = yearToDateTarget;
    final hasTarget = target != null;
    final remaining = hasTarget ? math.max(0, target - total) : 0;
    final progress = hasTarget
        ? (total / math.max(1, target)).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final activeDays = yearStats.activeDays;
    final dailyAverage = yearStats.dailyAverage;
    final streak = yearStats.streak;
    final targetSource = yearlyTargetAutomatic
        ? 'Günlük hedeften bugüne kadarki yıllık ilerleme.'
        : 'Yıllık hedefin bugüne kadarki payı.';
    final metrics = [
      _MetricData(
        icon: Icons.calendar_today_rounded,
        value: '$activeDays',
        label: 'Aktif Gün',
        color: _primaryGreen,
      ),
      _MetricData(
        icon: Icons.local_fire_department_rounded,
        value: '$streak',
        label: 'Seri',
        color: _buttonGreen,
      ),
      _MetricData(
        icon: Icons.emoji_events_rounded,
        value: _formatWholeNumber(yearStats.bestDayTotal),
        label: 'En İyi Gün',
        color: _gold,
      ),
      _MetricData(
        icon: Icons.insights_rounded,
        value: _formatWholeNumber(dailyAverage),
        label: 'Günlük Ort.',
        color: _buttonGreen,
      ),
    ];

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        14 * scale,
        14 * scale,
        12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverviewHeader(
            scale: scale,
            selectedYear: selectedYear,
            availableYears: availableYears,
            onYearSelected: onYearSelected,
          ),
          SizedBox(height: 14 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF123B2B), Color(0xFF327653)],
              ),
              borderRadius: BorderRadius.circular(24 * scale),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.16),
                  blurRadius: 20 * scale,
                  offset: Offset(0, 9 * scale),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                15 * scale,
                15 * scale,
                14 * scale,
                14 * scale,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugüne kadar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 11.2 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatWholeNumber(total),
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 35 * scale,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          hasTarget
                              ? remaining == 0
                                    ? 'Bugüne kadarki hedef tamamlandı'
                                    : 'Bugüne kadarki hedefe ${_formatWholeNumber(remaining)} kaldı'
                              : 'Hedef yok; özet gösteriliyor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFF4E3A8),
                            fontSize: 10.8 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 11 * scale),
                  _OverviewTargetPanel(
                    scale: scale,
                    progress: progress,
                    target: target,
                    onTap: onEditTargets,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(
                  child: _DailySummaryMetricTile(
                    scale: scale,
                    metric: metrics[i],
                  ),
                ),
                if (i != metrics.length - 1)
                  _SubtleVerticalDivider(scale: scale),
              ],
            ],
          ),
          SizedBox(height: 11 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: _gold.withValues(alpha: 0.23),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 11 * scale,
                vertical: 10 * scale,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 15 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      hasTarget
                          ? targetSource
                          : 'Hedef girmeden de aktif gün, ortalama ve dağılım görünür.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 10.7 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTargetPanel extends StatelessWidget {
  const _OverviewTargetPanel({
    required this.scale,
    required this.progress,
    required this.target,
    required this.onTap,
  });

  final double scale;
  final double progress;
  final int? target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    final hasTarget = target != null;
    final completed = hasTarget && progress >= 1;
    final borderRadius = BorderRadius.circular(18 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: completed
                ? _gold.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.11),
            borderRadius: borderRadius,
            border: Border.all(
              color: completed
                  ? _gold.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.15),
              width: 0.7 * scale,
            ),
          ),
          child: SizedBox(
            width: 72 * scale,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 9 * scale,
                vertical: 11 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hedef',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 8.3 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 7 * scale),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: completed
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: const Color(0xFFF4E3A8),
                                size: 15 * scale,
                              ),
                              SizedBox(width: 3 * scale),
                              Text(
                                'Tamam',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w900,
                                  height: 0.95,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            hasTarget
                                ? '%${(progress * 100).round()}'
                                : 'Belirle',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: hasTarget ? 20 * scale : 13 * scale,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                          ),
                  ),
                  SizedBox(height: 9 * scale),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: hasTarget ? progress : 0,
                      minHeight: 5 * scale,
                      color: _gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  SizedBox(height: 7 * scale),
                  Text(
                    hasTarget ? _formatWholeNumber(target) : 'hedef yok',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 8.3 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
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

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.scale,
    required this.selectedYear,
    required this.availableYears,
    required this.onYearSelected,
  });

  final double scale;
  final int selectedYear;
  final List<int> availableYears;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Genel Bakış',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: _statisticsCardTitleFontSize * scale,
                  fontWeight: FontWeight.w900,
                  height: 1.06,
                ),
              ),
              SizedBox(height: 5 * scale),
              Text(
                '$selectedYear yılı özeti',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: _statisticsCardDescriptionFontSize * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
            ],
          ),
        ),
        _YearSelectorPill(
          scale: scale,
          selectedYear: selectedYear,
          years: availableYears,
          onYearSelected: onYearSelected,
        ),
      ],
    );
  }
}

class _YearSelectorPill extends StatelessWidget {
  const _YearSelectorPill({
    required this.scale,
    required this.selectedYear,
    required this.years,
    required this.onYearSelected,
  });

  final double scale;
  final int selectedYear;
  final List<int> years;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final menuYears = {...years, selectedYear}.toList()
      ..sort((a, b) => b.compareTo(a));

    return PopupMenuButton<int>(
      tooltip: 'Yıl seç',
      color: _cardBackground,
      initialValue: selectedYear,
      onSelected: onYearSelected,
      itemBuilder: (context) => [
        for (final year in menuYears)
          PopupMenuItem<int>(value: year, child: Text('$year yılı')),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _buttonGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 7 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedYear',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 10.7 * scale,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(width: 3 * scale),
              Icon(
                Icons.expand_more_rounded,
                color: _primaryGreen,
                size: 15 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewMetricTile extends StatelessWidget {
  const _OverviewMetricTile({required this.scale, required this.metric});

  final double scale;
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: metric.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 29 * scale,
            child: Icon(metric.icon, color: metric.color, size: 15 * scale),
          ),
        ),
        SizedBox(height: 9 * scale),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 14.7 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          metric.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 8.5 * scale,
            fontWeight: FontWeight.w700,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _MetricIconBubble extends StatelessWidget {
  const _MetricIconBubble({
    required this.scale,
    required this.icon,
    required this.color,
  });

  final double scale;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 29 * scale,
        child: Icon(icon, color: color, size: 15 * scale),
      ),
    );
  }
}

class _DayPartDistributionCard extends StatelessWidget {
  const _DayPartDistributionCard({
    required this.scale,
    required this.selectedYear,
    required this.statistics,
  });

  final double scale;
  final int selectedYear;
  final _StatisticsData statistics;

  @override
  Widget build(BuildContext context) {
    final yearStats = statistics.yearStats(selectedYear);
    final rows = yearStats.dayParts;
    final hasData = yearStats.total > 0;
    final topPart = rows.reduce(
      (current, next) => current.percent >= next.percent ? current : next,
    );

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vakit Dağılımı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: _statisticsCardTitleFontSize * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      'Zikirlerin vakitlere göre yıllık yüzdesi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: _statisticsCardDescriptionFontSize * scale,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * scale),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.60),
                    width: 0.7 * scale,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * scale,
                    vertical: 5.5 * scale,
                  ),
                  child: Text(
                    '$selectedYear yılı',
                    style: TextStyle(
                      color: _primaryText.withValues(alpha: 0.78),
                      fontSize: 10.2 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.58),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                12 * scale,
                12 * scale,
                11 * scale,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _DayPartRow(scale: scale, data: rows[i]),
                    if (i != rows.length - 1) SizedBox(height: 9 * scale),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14 * scale),
              border: Border.all(
                color: _gold.withValues(alpha: 0.22),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 11 * scale,
                vertical: 9 * scale,
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: _gold, size: 14 * scale),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: hasData
                            ? 'Zikirlerinin %${topPart.percent}ini ${topPart.label} vaktinde çekiyorsun.'
                            : 'Bu yıl için vakit dağılımı henüz oluşmadı.',
                        style: TextStyle(
                          color: _primaryText,
                          fontFamily: 'Inter',
                          fontSize: 10.7 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPartRow extends StatelessWidget {
  const _DayPartRow({required this.scale, required this.data});

  final double scale;
  final _DayPartData data;

  @override
  Widget build(BuildContext context) {
    final labelColor = data.highlighted ? _primaryText : _primaryText;
    final valueColor = data.highlighted ? _primaryText : _secondaryText;

    return Row(
      children: [
        SizedBox.square(
          dimension: 22 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: data.color.withValues(
                alpha: data.highlighted ? 0.18 : 0.13,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 13 * scale),
          ),
        ),
        SizedBox(width: 9 * scale),
        SizedBox(
          width: 47 * scale,
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 11.3 * scale,
              fontWeight: data.highlighted ? FontWeight.w800 : FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 9 * scale),
        Expanded(
          child: SizedBox(
            height: 7 * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: _primaryGreen.withValues(alpha: 0.075)),
                  FractionallySizedBox(
                    widthFactor: data.percent / 100,
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            data.color.withValues(alpha: 0.48),
                            data.color,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        SizedBox(
          width: 43 * scale,
          child: Text(
            '%${data.percent}',
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: valueColor,
              fontSize: 10.6 * scale,
              fontWeight: data.highlighted ? FontWeight.w900 : FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.scale,
    required this.selectedYear,
    required this.statistics,
  });

  final double scale;
  final int selectedYear;
  final _StatisticsData statistics;

  @override
  Widget build(BuildContext context) {
    final yearStats = statistics.yearStats(selectedYear);
    final record = yearStats.record;
    final hasRecord = record.total > 0;
    final dailyAverage = math.max(1, yearStats.dailyAverage);
    final ratio = hasRecord
        ? (record.total / dailyAverage).toStringAsFixed(1)
        : '-';
    final recordDhikrName = hasRecord ? record.dhikrName : 'Kayıt yok';
    final topDhikr = hasRecord ? _formatWholeNumber(record.dhikrTotal) : '0';
    final dateLabel = record.date == null
        ? '$selectedYear yılı için kayıt yok'
        : '${_formatDailyDate(record.date!)} · en yüksek gün';

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        13 * scale,
        14 * scale,
        13 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 38 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.25),
                      width: 0.7 * scale,
                    ),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: _gold,
                    size: 20 * scale,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rekorun',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 13.6 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 10.1 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _RecordTotalBadge(
                scale: scale,
                value: hasRecord ? _formatCompactCount(record.total) : '0',
              ),
            ],
          ),
          SizedBox(height: 11 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryGreen.withValues(alpha: 0.105),
                  _gold.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(
                color: _primaryGreen.withValues(alpha: 0.13),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                11 * scale,
                12 * scale,
                11 * scale,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rekor zikir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 9.4 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 5 * scale),
                        Text(
                          recordDhikrName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 18.2 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  topDhikr,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: _primaryGreen,
                                    fontSize: 24 * scale,
                                    fontWeight: FontWeight.w900,
                                    height: 0.92,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 5 * scale),
                            Padding(
                              padding: EdgeInsets.only(bottom: 2 * scale),
                              child: Text(
                                'zikir',
                                style: TextStyle(
                                  color: _secondaryText,
                                  fontSize: 9.6 * scale,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  SizedBox.square(
                    dimension: 50 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.78),
                          width: 0.8 * scale,
                        ),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: _primaryGreen,
                        size: 25 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 9 * scale),
          Wrap(
            spacing: 6 * scale,
            runSpacing: 6 * scale,
            children: [
              _RecordChip(
                scale: scale,
                icon: Icons.trending_up_rounded,
                text: hasRecord
                    ? 'Günlük ort. ${ratio.replaceAll('.', ',')}x'
                    : 'Kayıt bekliyor',
                color: _buttonGreen,
              ),
              _RecordChip(
                scale: scale,
                icon: Icons.auto_awesome_rounded,
                text: hasRecord ? 'Yılın zirvesi' : 'Gerçek veriden hesaplanır',
                color: _gold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordTotalBadge extends StatelessWidget {
  const _RecordTotalBadge({required this.scale, required this.value});

  final double scale;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 0.7 * scale,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 9 * scale,
          vertical: 7 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: _primaryText,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              'gün toplamı',
              maxLines: 1,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 7.7 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  const _RecordChip({
    required this.scale,
    required this.icon,
    required this.text,
    required this.color,
  });

  final double scale;
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 7 * scale,
          vertical: 5 * scale,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11.5 * scale),
            SizedBox(width: 4 * scale),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText,
                fontSize: 9.2 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearlyMonthlyOverviewCard extends StatelessWidget {
  const _YearlyMonthlyOverviewCard({
    required this.scale,
    required this.selectedYear,
    required this.statistics,
  });

  final double scale;
  final int selectedYear;
  final _StatisticsData statistics;

  @override
  Widget build(BuildContext context) {
    final yearStats = statistics.yearStats(selectedYear);
    final selectedMonthIndex = _overviewSelectedMonthIndex(selectedYear);
    final values = yearStats.monthlyValues;
    final selectedValue = values[selectedMonthIndex];
    final previousValue = selectedMonthIndex > 0
        ? values[selectedMonthIndex - 1]
        : selectedValue;
    final monthlyTotal = yearStats.total;
    final periodShare = monthlyTotal == 0
        ? 0
        : ((selectedValue / monthlyTotal) * 100).round();
    final difference = (previousValue - selectedValue).abs();
    final comparisonMonth = selectedMonthIndex > 0
        ? _monthAbbreviations[selectedMonthIndex - 1]
        : _monthAbbreviations[selectedMonthIndex];
    final comparisonText = monthlyTotal == 0
        ? 'Bu yıl için aylık görünüm henüz oluşmadı.'
        : previousValue >= selectedValue
        ? '$comparisonMonth aralığına göre $difference daha az zikir var.'
        : '$comparisonMonth aralığına göre $difference daha fazla zikir var.';

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$selectedYear yılı Aylık Görünüm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: _statisticsCardTitleFontSize * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatWholeNumber(monthlyTotal),
                    style: TextStyle(
                      color: _gold,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    'Aylık Toplam',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 9.4 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 15 * scale),
          SizedBox(
            height: 126 * scale,
            child: CustomPaint(
              painter: _YearlyMonthlyBarsPainter(
                scale: scale,
                values: values,
                selectedMonthIndex: selectedMonthIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(height: 12 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(14 * scale),
              border: Border.all(
                color: _primaryGreen.withValues(alpha: 0.08),
                width: 0.8 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                12 * scale,
                12 * scale,
                12 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _monthAbbreviations[selectedMonthIndex],
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 12.3 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        '$selectedValue zikir',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12.3 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 9 * scale),
                  Text(
                    comparisonText,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 10.2 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 7 * scale),
                  Text(
                    'Dönem toplamının %$periodShare’i bu aralıkta.',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 8.8 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _MonthlyProgressCard extends StatefulWidget {
  const _MonthlyProgressCard({
    required this.scale,
    required this.months,
    required this.values,
  });

  final double scale;
  final List<String> months;
  final List<int> values;

  @override
  State<_MonthlyProgressCard> createState() => _MonthlyProgressCardState();
}

class _MonthlyProgressCardState extends State<_MonthlyProgressCard> {
  int? _selectedMonthIndex;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    if (widget.values.isEmpty || widget.months.length != widget.values.length) {
      return _StatsCard(
        scale: scale,
        margin: EdgeInsets.symmetric(horizontal: 18 * scale),
        padding: EdgeInsets.all(15 * scale),
        child: _StatsEmptyMessage(
          scale: scale,
          icon: Icons.show_chart_rounded,
          text: 'Aylık ilerleme için kayıt bekleniyor.',
        ),
      );
    }

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        16 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Aylık İlerleme',
            description: 'Son 6 ayda okuduğun zikir sayıları',
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            height: 162 * scale,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = Size(constraints.maxWidth, 162 * scale);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    setState(() {
                      _selectedMonthIndex = _nearestMonthlyChartPoint(
                        details.localPosition,
                        chartSize,
                        scale,
                      );
                    });
                  },
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      months: widget.months,
                      values: widget.values,
                      scale: scale,
                      selectedPointIndex: _selectedMonthIndex,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int? _nearestMonthlyChartPoint(Offset tapPosition, Size size, double scale) {
    final points = _monthlyChartPoints(
      size: size,
      scale: scale,
      values: widget.values,
    );
    final hitRadius = 22 * scale;

    for (var i = 0; i < points.length; i++) {
      if ((tapPosition - points[i]).distance <= hitRadius) {
        return i;
      }
    }

    return null;
  }
}

Rect _monthlyChartRect(Size size, double scale) {
  final leftPadding = 36 * scale;
  final bottomPadding = 26 * scale;
  final topPadding = 28 * scale;
  final rightPadding = 4 * scale;

  return Rect.fromLTRB(
    leftPadding,
    topPadding,
    size.width - rightPadding,
    size.height - bottomPadding,
  );
}

List<Offset> _monthlyChartPoints({
  required Size size,
  required double scale,
  required List<int> values,
}) {
  final chartRect = _monthlyChartRect(size, scale);

  return [
    for (var i = 0; i < values.length; i++)
      Offset(
        chartRect.left + (chartRect.width * i / math.max(1, values.length - 1)),
        _monthlyValueToY(values[i].toDouble(), chartRect),
      ),
  ];
}

double _monthlyValueToY(double value, Rect rect) {
  final normalized = (value / 20000).clamp(0.0, 1.0);
  return rect.bottom - rect.height * normalized;
}

String _formatMonthlyValue(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

class _LineChartTooltipPainter {
  const _LineChartTooltipPainter({
    required this.scale,
    required this.month,
    required this.value,
    required this.anchor,
  });

  final double scale;
  final String month;
  final int value;
  final Offset anchor;

  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$month  ${_formatMonthlyValue(value)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.6 * scale,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final horizontalPadding = 9 * scale;
    final verticalPadding = 7 * scale;
    final tooltipSize = Size(
      textPainter.width + horizontalPadding * 2,
      textPainter.height + verticalPadding * 2,
    );
    final tooltipLeft = (anchor.dx - tooltipSize.width / 2).clamp(
      0.0,
      size.width - tooltipSize.width,
    );
    final tooltipTop = math.max(
      0.0,
      anchor.dy - tooltipSize.height - 10 * scale,
    );
    final tooltipRect = Offset(tooltipLeft, tooltipTop) & tooltipSize;
    final tooltipPath = Path()
      ..addRRect(RRect.fromRectAndRadius(tooltipRect, Radius.circular(999)));

    canvas.drawShadow(
      tooltipPath,
      Colors.black.withValues(alpha: 0.22),
      7 * scale,
      true,
    );
    canvas.drawPath(
      tooltipPath,
      Paint()..color = _primaryGreen.withValues(alpha: 0.95),
    );
    textPainter.paint(
      canvas,
      tooltipRect.topLeft + Offset(horizontalPadding, verticalPadding),
    );

    final pointerPath = Path()
      ..moveTo(anchor.dx - 5 * scale, tooltipRect.bottom - 1 * scale)
      ..lineTo(anchor.dx + 5 * scale, tooltipRect.bottom - 1 * scale)
      ..lineTo(anchor.dx, tooltipRect.bottom + 7 * scale)
      ..close();
    canvas.drawPath(
      pointerPath,
      Paint()..color = _primaryGreen.withValues(alpha: 0.95),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.scale,
    required this.title,
    required this.description,
  });

  final double scale;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: _statisticsCardTitleFontSize * scale,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText,
            fontSize: _statisticsCardDescriptionFontSize * scale,
            fontWeight: FontWeight.w600,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _StatsEmptyMessage extends StatelessWidget {
  const _StatsEmptyMessage({
    required this.scale,
    required this.icon,
    required this.text,
  });

  final double scale;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.08),
          width: 0.7 * scale,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 11 * scale,
          vertical: 10 * scale,
        ),
        child: Row(
          children: [
            Icon(icon, color: _buttonGreen, size: 15 * scale),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 10.2 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.scale,
    required this.margin,
    required this.padding,
    required this.child,
  });

  final double scale;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(24 * scale);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: _softShadow(scale),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _cardBackground.withValues(alpha: 0.92),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.68),
              width: 0.8 * scale,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _SubtleVerticalDivider extends StatelessWidget {
  const _SubtleVerticalDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8 * scale,
      height: 62 * scale,
      margin: EdgeInsets.symmetric(horizontal: 6 * scale),
      color: _dividerColor.withValues(alpha: 0.72),
    );
  }
}

class _YearlyMonthlyBarsPainter extends CustomPainter {
  const _YearlyMonthlyBarsPainter({
    required this.scale,
    required this.values,
    required this.selectedMonthIndex,
  });

  final double scale;
  final List<int> values;
  final int selectedMonthIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final chartRect = Rect.fromLTRB(
      0,
      10 * scale,
      size.width,
      size.height - 22 * scale,
    );
    final maxValue = math.max(1, values.reduce(math.max));
    final slotWidth = chartRect.width / values.length;
    final barWidth = math.min(24 * scale, slotWidth * 0.56);

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final normalized = value / maxValue;
      final height = math
          .max(value == 0 ? 0 : 4 * scale, chartRect.height * normalized)
          .toDouble();
      final centerX = chartRect.left + slotWidth * i + slotWidth / 2;
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        chartRect.bottom - height,
        barWidth,
        height,
      );
      final selected = i == selectedMonthIndex;
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: selected
              ? [const Color(0xFFE7CA68), const Color(0xFFC7A44F)]
              : [
                  _buttonGreen.withValues(alpha: value == 0 ? 0.10 : 0.34),
                  _buttonGreen.withValues(alpha: value == 0 ? 0.04 : 0.18),
                ],
        ).createShader(rect);

      if (value > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(5 * scale)),
          fillPaint,
        );
      }

      if (selected) {
        _drawMonthValueBubble(
          canvas: canvas,
          size: size,
          centerX: centerX,
          topY: rect.top,
          value: value,
        );
      } else if (value > 0) {
        _drawMonthValueBubble(
          canvas: canvas,
          size: size,
          centerX: centerX,
          topY: rect.top,
          value: value,
        );
      }

      textPainter.text = TextSpan(
        text: _monthAbbreviations[i],
        style: TextStyle(
          color: selected ? _gold : _secondaryText,
          fontSize: 8.6 * scale,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: slotWidth);
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, chartRect.bottom + 8 * scale),
      );
    }
  }

  void _drawMonthValueBubble({
    required Canvas canvas,
    required Size size,
    required double centerX,
    required double topY,
    required int value,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _formatWholeNumber(value),
        style: TextStyle(
          color: const Color(0xFFF7DE7A),
          fontSize: 8.8 * scale,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final bubbleSize = Size(textPainter.width + 10 * scale, 18 * scale);
    final left = (centerX - bubbleSize.width / 2).clamp(
      0.0,
      size.width - bubbleSize.width,
    );
    final top = math.max(0.0, topY - bubbleSize.height - 6 * scale);
    final rect = Offset(left, top) & bubbleSize;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(6 * scale)));

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.20),
      6 * scale,
      true,
    );
    canvas.drawPath(path, Paint()..color = _primaryGreen);
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _YearlyMonthlyBarsPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.values != values ||
        oldDelegate.selectedMonthIndex != selectedMonthIndex;
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.months,
    required this.values,
    required this.scale,
    this.selectedPointIndex,
  });

  final List<String> months;
  final List<int> values;
  final double scale;
  final int? selectedPointIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    final leftPadding = 36 * scale;
    final chartRect = _monthlyChartRect(size, scale);

    final gridPaint = Paint()
      ..color = _dividerColor.withValues(alpha: 0.62)
      ..strokeWidth = 0.7 * scale;
    final axisLabels = [
      ('20K', 20000.0),
      ('15K', 15000.0),
      ('10K', 10000.0),
      ('5K', 5000.0),
      ('0', 0.0),
    ];

    for (final (label, value) in axisLabels) {
      final y = _monthlyValueToY(value, chartRect);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: _secondaryText.withValues(alpha: 0.86),
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: leftPadding - 7 * scale);
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    final points = _monthlyChartPoints(
      size: size,
      scale: scale,
      values: values,
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _buttonGreen.withValues(alpha: 0.18),
          _buttonGreen.withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = _buttonGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final pointFill = Paint()..color = _buttonGreen;
    final pointStroke = Paint()
      ..color = _cardBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale;
    for (final point in points) {
      canvas.drawCircle(point, 4 * scale, pointFill);
      canvas.drawCircle(point, 4 * scale, pointStroke);
    }

    final selectedIndex = selectedPointIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < points.length) {
      final selectedPoint = points[selectedIndex];
      canvas.drawCircle(
        selectedPoint,
        7 * scale,
        Paint()..color = _buttonGreen.withValues(alpha: 0.18),
      );
      canvas.drawCircle(selectedPoint, 4.8 * scale, pointFill);
      canvas.drawCircle(selectedPoint, 4.8 * scale, pointStroke);
      _LineChartTooltipPainter(
        scale: scale,
        month: months[selectedIndex],
        value: values[selectedIndex],
        anchor: selectedPoint,
      ).paint(canvas, size);
    }

    for (var i = 0; i < months.length; i++) {
      textPainter.text = TextSpan(
        text: months[i],
        style: TextStyle(
          color: _secondaryText,
          fontSize: 10.4 * scale,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      final x =
          chartRect.left +
          (chartRect.width * i / math.max(1, months.length - 1)) -
          textPainter.width / 2;
      textPainter.paint(canvas, Offset(x, chartRect.bottom + 10 * scale));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.months != months ||
        oldDelegate.values != values ||
        oldDelegate.scale != scale ||
        oldDelegate.selectedPointIndex != selectedPointIndex;
  }
}

class _StatisticsWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lowerPaint = Paint()
      ..color = _gold.withValues(alpha: 0.030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    final lowerPath = Path()
      ..moveTo(size.width * 1.12, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.58,
        size.width * -0.12,
        size.height * 0.86,
      );
    canvas.drawPath(lowerPath, lowerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HourlyDistributionPainter extends CustomPainter {
  const _HourlyDistributionPainter({required this.scale, required this.values});

  final double scale;
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final leftPadding = 0.0;
    final bottomPadding = 23 * scale;
    final topPadding = 8 * scale;
    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width,
      size.height - bottomPadding,
    );
    final baselineY = chartRect.bottom;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          chartRect.left,
          baselineY - 1 * scale,
          chartRect.width,
          2 * scale,
        ),
        Radius.circular(999),
      ),
      Paint()..color = _dividerColor.withValues(alpha: 0.55),
    );

    final gap = 4.5 * scale;
    final maxValue = values.fold<int>(0, math.max);
    final barCount = math.max(1, values.length);
    final barWidth = (chartRect.width - gap * (barCount - 1)) / barCount;
    final radius = Radius.circular(999);
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final normalized = maxValue == 0
          ? 0.0
          : (value / maxValue).clamp(0.0, 1.0);
      final left = chartRect.left + i * (barWidth + gap);
      final height = maxValue == 0
          ? 5 * scale
          : math.max(7 * scale, chartRect.height * normalized);
      final rect = Rect.fromLTWH(
        left,
        chartRect.bottom - height,
        barWidth,
        height,
      );
      final highlighted = maxValue > 0 && value == maxValue;
      final glowPaint = Paint()
        ..color = (highlighted ? _gold : _buttonGreen).withValues(
          alpha: highlighted ? 0.15 : 0.05,
        );
      canvas.drawCircle(
        Offset(rect.center.dx, rect.top + 5 * scale),
        (barWidth * (highlighted ? 2.2 : 1.45)).clamp(3.0, 13 * scale),
        glowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: highlighted
                ? [const Color(0xFFE7CA68), const Color(0xFFC7A44F)]
                : [
                    _buttonGreen.withValues(alpha: 0.72),
                    _buttonGreen.withValues(alpha: 0.25),
                  ],
          ).createShader(rect),
      );
    }

    const labels = ['00', '06', '12', '18', '24'];
    for (var i = 0; i < labels.length; i++) {
      final hourIndex = i * 6;
      final x = i == labels.length - 1
          ? chartRect.right
          : chartRect.left + hourIndex * (barWidth + gap) + barWidth / 2;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: _secondaryText,
          fontSize: 9.6 * scale,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      final labelX = (x - textPainter.width / 2).clamp(
        0.0,
        size.width - textPainter.width,
      );
      textPainter.paint(canvas, Offset(labelX, chartRect.bottom + 9 * scale));
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyDistributionPainter oldDelegate) {
    if (oldDelegate.scale != scale ||
        oldDelegate.values.length != values.length) {
      return true;
    }

    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) {
        return true;
      }
    }

    return false;
  }
}

List<BoxShadow> _softShadow(double scale) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.045),
      blurRadius: 18 * scale,
      offset: Offset(0, 8 * scale),
    ),
  ];
}

const _monthAbbreviations = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

int _overviewSelectedMonthIndex(int selectedYear) {
  final now = DateTime.now();
  return selectedYear == now.year ? now.month - 1 : 11;
}

int _overviewDaysInPeriod(int selectedYear) {
  final now = DateTime.now();
  if (selectedYear == now.year) {
    return now.difference(DateTime(selectedYear)).inDays + 1;
  }

  return DateTime(selectedYear + 1).difference(DateTime(selectedYear)).inDays;
}

int _daysInYear(int year) {
  return DateTime(year + 1).difference(DateTime(year)).inDays;
}

List<_DailyDhikrRank> _dailyRanksFromTotals(
  Map<String, int> totalsByDhikr,
  Map<String, int> targetByDhikr,
) {
  final entries =
      totalsByDhikr.entries.where((entry) => entry.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  return [
    for (var i = 0; i < math.min(entries.length, 5); i++)
      _DailyDhikrRank(
        i + 1,
        entries[i].key,
        entries[i].value,
        math.max(targetByDhikr[entries[i].key] ?? entries[i].value, 1),
        (entries[i].value /
                math.max(targetByDhikr[entries[i].key] ?? entries[i].value, 1))
            .clamp(0.0, 1.0)
            .toDouble(),
        _rankStatus(
          entries[i].value,
          targetByDhikr[entries[i].key] ?? entries[i].value,
        ),
        _shareColorForRank(i),
      ),
  ];
}

String _rankStatus(int value, int target) {
  if (target <= 0) {
    return 'Kayıt';
  }
  if (value >= target) {
    return 'Tamamlandı';
  }
  if (value / target >= 0.75) {
    return 'Kalan az';
  }
  return 'Devam';
}

List<_MonthlyShareData> _shareRowsForEvents(
  List<_StatEvent> events, {
  bool yearly = false,
}) {
  final totalsByDhikr = <String, int>{};
  for (final event in events) {
    totalsByDhikr.update(
      event.dhikrName,
      (value) => value + event.delta,
      ifAbsent: () => event.delta,
    );
  }

  final total = totalsByDhikr.values.fold<int>(0, (sum, value) => sum + value);
  final entries =
      totalsByDhikr.entries.where((entry) => entry.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  return [
    for (var i = 0; i < entries.length; i++)
      _MonthlyShareData(
        label: entries[i].key,
        value: entries[i].value,
        percent: total == 0 ? 0 : (entries[i].value / total * 100).round(),
        color: _shareColorForRank(i, yearly: yearly),
      ),
  ];
}

List<_DayPartData> _dayPartSharesForEvents(List<_StatEvent> events) {
  final totals = List<int>.filled(5, 0);
  for (final event in events) {
    totals[_dayPartIndexForHour(event.createdAt.hour)] += event.delta;
  }

  final total = totals.fold<int>(0, (sum, value) => sum + value);
  final highlightedIndex = _indexOfHighest(totals);

  return [
    _DayPartData(
      icon: Icons.wb_sunny_rounded,
      label: 'Sabah',
      percent: total == 0 ? 0 : (totals[0] / total * 100).round(),
      color: const Color(0xFFE9A84B),
      highlighted: highlightedIndex == 0 && total > 0,
    ),
    _DayPartData(
      icon: Icons.light_mode_rounded,
      label: 'Öğle',
      percent: total == 0 ? 0 : (totals[1] / total * 100).round(),
      color: const Color(0xFFD8BA65),
      highlighted: highlightedIndex == 1 && total > 0,
    ),
    _DayPartData(
      icon: Icons.wb_twilight_rounded,
      label: 'İkindi',
      percent: total == 0 ? 0 : (totals[2] / total * 100).round(),
      color: const Color(0xFFC9A554),
      highlighted: highlightedIndex == 2 && total > 0,
    ),
    _DayPartData(
      icon: Icons.apartment_rounded,
      label: 'Akşam',
      percent: total == 0 ? 0 : (totals[3] / total * 100).round(),
      color: _buttonGreen,
      highlighted: highlightedIndex == 3 && total > 0,
    ),
    _DayPartData(
      icon: Icons.nightlight_round,
      label: 'Yatsı',
      percent: total == 0 ? 0 : (totals[4] / total * 100).round(),
      color: _primaryGreen,
      highlighted: highlightedIndex == 4 && total > 0,
    ),
  ];
}

int _dayPartIndexForHour(int hour) {
  if (hour >= 5 && hour < 11) {
    return 0;
  }
  if (hour >= 11 && hour < 14) {
    return 1;
  }
  if (hour >= 14 && hour < 17) {
    return 2;
  }
  if (hour >= 17 && hour < 21) {
    return 3;
  }
  return 4;
}

int? _indexOfHighest(List<int> values) {
  var bestIndex = -1;
  var bestValue = 0;
  for (var i = 0; i < values.length; i++) {
    if (values[i] > bestValue) {
      bestValue = values[i];
      bestIndex = i;
    }
  }
  return bestIndex == -1 ? null : bestIndex;
}

int? _indexOfLowestPositive(List<int> values) {
  var bestIndex = -1;
  var bestValue = 1 << 30;
  for (var i = 0; i < values.length; i++) {
    final value = values[i];
    if (value > 0 && value < bestValue) {
      bestValue = value;
      bestIndex = i;
    }
  }
  return bestIndex == -1 ? null : bestIndex;
}

String _formatHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

Color _shareColorForRank(int rank, {bool yearly = false}) {
  const colors = [
    Color(0xFF1D6B49),
    Color(0xFF5D9B78),
    Color(0xFFC9A554),
    Color(0xFF8DBA9E),
    Color(0xFF2F805B),
    Color(0xFF7BAB8E),
    Color(0xFFD7BE6A),
    Color(0xFF9BC8AE),
  ];
  return colors[rank % colors.length];
}

String _formatWholeNumber(int value) {
  return _formatDigitString(value.toString());
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String _formatDigitString(String digits) {
  final raw = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

int _offsetForDigitPosition(String formatted, int digitPosition) {
  if (digitPosition <= 0) {
    return 0;
  }

  var seenDigits = 0;
  for (var i = 0; i < formatted.length; i++) {
    if (RegExp(r'\d').hasMatch(formatted[i])) {
      seenDigits++;
    }
    if (seenDigits >= digitPosition) {
      return i + 1;
    }
  }

  return formatted.length;
}

int _longestPositiveStreak(List<int> values) {
  var best = 0;
  var current = 0;

  for (final value in values) {
    if (value > 0) {
      current++;
      best = math.max(best, current);
    } else {
      current = 0;
    }
  }

  return best;
}

List<_MonthlyWeekSummary> _monthlyWeekSummaries(
  DateTime month,
  List<int> dailyValues,
) {
  final summaries = <_MonthlyWeekSummary>[];

  for (var start = 0; start < dailyValues.length; start += 7) {
    final end = math.min(start + 7, dailyValues.length);
    final values = dailyValues.sublist(start, end);
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final activeDays = values.where((value) => value > 0).length;
    summaries.add(
      _MonthlyWeekSummary(
        title: '${summaries.length + 1}. hafta',
        range: '${start + 1}-$end ${_monthAbbreviations[month.month - 1]}',
        total: total,
        activeDays: activeDays,
      ),
    );
  }

  return summaries;
}

String _formatMonthLabel(DateTime month) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  return '${months[month.month - 1]} ${month.year}';
}

String _formatCompactCount(int value) {
  if (value < 1000) {
    return '$value';
  }

  final compact = value / 1000;
  final digits = value % 1000 == 0 ? 0 : 1;
  return '${compact.toStringAsFixed(digits).replaceAll('.', ',')}b';
}

String _formatTargetValue(int? value) {
  if (value == null) {
    return 'Belirle';
  }

  return _formatWholeNumber(value);
}

String _targetInputText(int? value) =>
    value == null ? '' : _formatWholeNumber(value);

int? _parseTargetInput(String raw) {
  final value = int.tryParse(_digitsOnly(raw));
  if (value == null || value <= 0) {
    return null;
  }

  return value;
}

int? _readTargetPreference(SharedPreferences prefs, String key) {
  final value = prefs.getInt(key);
  if (value == null || value <= 0) {
    return null;
  }

  return value;
}

Future<void> _writeTargetPreference(
  SharedPreferences prefs,
  String key,
  int? value,
) {
  if (value == null || value <= 0) {
    return prefs.remove(key);
  }

  return prefs.setInt(key, value);
}

class _StatisticsTargets {
  const _StatisticsTargets({this.daily, this.monthly, this.yearly});

  final int? daily;
  final int? monthly;
  final int? yearly;

  bool get hasAny => daily != null || monthly != null || yearly != null;

  bool monthlyIsAutomatic(DateTime month) => monthly == null && daily != null;

  bool yearlyIsAutomatic(int year) => yearly == null && daily != null;

  int? monthlyTargetFor(DateTime month) {
    final customTarget = monthly;
    if (customTarget != null) {
      return customTarget;
    }

    final dailyTarget = daily;
    if (dailyTarget == null) {
      return null;
    }

    return dailyTarget * DateUtils.getDaysInMonth(month.year, month.month);
  }

  int? yearlyTargetFor(int year) {
    final customTarget = yearly;
    if (customTarget != null) {
      return customTarget;
    }

    final dailyTarget = daily;
    if (dailyTarget == null) {
      return null;
    }

    return dailyTarget * _daysInYear(year);
  }

  int? yearToDateTargetFor(int year) {
    final dailyTarget = daily;
    if (dailyTarget != null) {
      return dailyTarget * _overviewDaysInPeriod(year);
    }

    final yearlyTarget = yearly;
    if (yearlyTarget == null) {
      return null;
    }

    return (yearlyTarget * _overviewDaysInPeriod(year) / _daysInYear(year))
        .round();
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

String _formatDailyDate(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _DailyDhikrRank {
  const _DailyDhikrRank(
    this.rank,
    this.label,
    this.value,
    this.target,
    this.progress,
    this.status,
    this.color,
  );

  final int rank;
  final String label;
  final int value;
  final int target;
  final double progress;
  final String status;
  final Color color;
}

class _DayPartData {
  const _DayPartData({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final int percent;
  final Color color;
  final bool highlighted;
}

class _MonthlyWeekSummary {
  const _MonthlyWeekSummary({
    required this.title,
    required this.range,
    required this.total,
    required this.activeDays,
  });

  final String title;
  final String range;
  final int total;
  final int activeDays;
}

class _MonthlyShareData {
  const _MonthlyShareData({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final int value;
  final int percent;
  final Color color;
}

class _MonthlyInsightData {
  const _MonthlyInsightData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
}
