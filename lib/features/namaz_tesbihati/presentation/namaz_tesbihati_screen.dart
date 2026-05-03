import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _mutedText = Color(0xFF69766E);
const _cardSurface = Color(0xFFFAFAF4);
const _paleSage = Color(0xFFE5ECE2);
const _softGold = Color(0xFFE9D798);
const _deepGreen = Color(0xFF082D20);
const _gold = Color(0xFFD2B56D);
const _mutedGold = Color(0xFF9D7D36);
const _counterInterior = Color(0xFFECE5D4);
const _counterTargetPillSurface = Color(0xFFE7DFC8);
const _counterTextGreen = Color(0xFF123B2B);
const _referencePanelSurface = Color(0xFFF0EADD);
const _referenceControlSurface = Color(0xFFF0EBDE);
const _heroAsset = 'assets/images/namaztesbihatihero.webp';
const _counterRingAsset = 'assets/images/zikr_counter_ring.png';
const _tesbihAsset = 'assets/images/zikr_tesbih.png';
const _heroSearchBackdropExtension = 20.0;
const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;
const _tesbihatOverviewLift = 25.0;
const _completionDayStorageKey = 'namazTesbihati.completionDay';
const _completedPrayerTimesStorageKey = 'namazTesbihati.completedPrayerTimes';

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

const _prayerTimes = [
  _PrayerTimeData(label: 'Sabah', icon: Icons.wb_sunny_rounded),
  _PrayerTimeData(label: 'Öğle', icon: Icons.light_mode_outlined),
  _PrayerTimeData(label: 'İkindi', icon: Icons.wb_twilight_rounded),
  _PrayerTimeData(label: 'Akşam', icon: Icons.wb_twilight_outlined),
  _PrayerTimeData(label: 'Yatsı', icon: Icons.dark_mode_rounded),
];

const _tesbihatSteps = [
  _TesbihatStepData(title: 'Subhanallah', target: 33),
  _TesbihatStepData(title: 'Elhamdülillah', target: 33),
  _TesbihatStepData(title: 'Allahu Ekber', target: 34),
  _TesbihatStepData(title: 'Kelime-i\nTevhid', target: 1),
];

class NamazTesbihatiScreen extends ConsumerStatefulWidget {
  const NamazTesbihatiScreen({super.key});

  @override
  ConsumerState<NamazTesbihatiScreen> createState() =>
      _NamazTesbihatiScreenState();
}

class _NamazTesbihatiScreenState extends ConsumerState<NamazTesbihatiScreen> {
  int _selectedPrayerTimeIndex = 0;
  var _completionDayKey = _dayKey(DateTime.now());
  var _completedPrayerTimesChangedBeforeRestore = false;
  Set<int> _completedPrayerTimeIndexes = {};
  Timer? _dayRolloverTimer;

  late final List<List<int>> _countsByPrayerTime = List.generate(
    _prayerTimes.length,
    (_) => List<int>.filled(_tesbihatSteps.length, 0),
  );

  List<int> get _currentCounts => _countsByPrayerTime[_selectedPrayerTimeIndex];

  int get _currentStepIndex => _activeStepIndexFor(_currentCounts);

  bool get _isCurrentTesbihatComplete => _isTesbihatComplete(_currentCounts);

  @override
  void initState() {
    super.initState();
    unawaited(_restoreDailyCompletionState());
    _scheduleDayRolloverCheck();
  }

  @override
  void dispose() {
    _dayRolloverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    _syncCompletionDay();

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
                    _NamazTesbihatiHero(
                      scale: scale,
                      safeTop: media.padding.top,
                      contentWidth: contentWidth,
                      horizontalInset: horizontalInset,
                    ),
                    _TesbihatOverview(
                      scale: scale,
                      horizontalInset: horizontalInset,
                      selectedPrayerTimeIndex: _selectedPrayerTimeIndex,
                      counts: _currentCounts,
                      activeStepIndex: _currentStepIndex,
                      complete: _isCurrentTesbihatComplete,
                      completedPrayerTimeIndexes: _completedPrayerTimeIndexes,
                      onPrayerTimeSelected: (index) {
                        setState(() => _selectedPrayerTimeIndex = index);
                      },
                      onIncrement: _incrementTesbihat,
                      onDecrement: _decrementTesbihat,
                      onReset: _resetTesbihat,
                    ),
                  ],
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.none,
                quickStartKey: const Key('namazTesbihati.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _incrementTesbihat() {
    if (_isCurrentTesbihatComplete) return;

    var completedAfterIncrement = false;
    setState(() {
      final stepIndex = _activeStepIndexFor(_currentCounts);
      final step = _tesbihatSteps[stepIndex];
      if (_currentCounts[stepIndex] < step.target) {
        _currentCounts[stepIndex] += 1;
      }
      completedAfterIncrement = _isTesbihatComplete(_currentCounts);
      if (completedAfterIncrement) {
        _completedPrayerTimeIndexes = {
          ..._completedPrayerTimeIndexes,
          _selectedPrayerTimeIndex,
        };
        _completedPrayerTimesChangedBeforeRestore = true;
      }
    });
    if (completedAfterIncrement) {
      unawaited(_persistDailyCompletionState());
    }
    final feedback = ref.read(interactionFeedbackServiceProvider);
    if (completedAfterIncrement) {
      feedback.success();
    } else {
      feedback.counterTick();
    }
  }

  void _resetTesbihat() {
    setState(() {
      _countsByPrayerTime[_selectedPrayerTimeIndex] = List<int>.filled(
        _tesbihatSteps.length,
        0,
      );
    });
  }

  void _decrementTesbihat() {
    final lastCountedStepIndex = _lastCountedStepIndexFor(_currentCounts);
    if (lastCountedStepIndex == null) return;

    setState(() {
      _currentCounts[lastCountedStepIndex] -= 1;
    });
  }

  int _activeStepIndexFor(List<int> counts) {
    for (var index = 0; index < _tesbihatSteps.length; index++) {
      if (counts[index] < _tesbihatSteps[index].target) return index;
    }
    return _tesbihatSteps.length - 1;
  }

  bool _isTesbihatComplete(List<int> counts) {
    for (var index = 0; index < _tesbihatSteps.length; index++) {
      if (counts[index] < _tesbihatSteps[index].target) return false;
    }
    return true;
  }

  int? _lastCountedStepIndexFor(List<int> counts) {
    for (var index = counts.length - 1; index >= 0; index--) {
      if (counts[index] > 0) return index;
    }
    return null;
  }

  Future<void> _restoreDailyCompletionState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dayKey(DateTime.now());
    final storedDayKey = prefs.getString(_completionDayStorageKey);

    if (storedDayKey != todayKey) {
      if (_completedPrayerTimesChangedBeforeRestore) return;
      await prefs.setString(_completionDayStorageKey, todayKey);
      await prefs.setStringList(_completedPrayerTimesStorageKey, const []);
      if (!mounted || _completedPrayerTimesChangedBeforeRestore) return;
      setState(() {
        _completionDayKey = todayKey;
        _completedPrayerTimeIndexes = {};
        _resetAllTesbihatCounts();
      });
      return;
    }

    final restoredIndexes = _completedPrayerTimeIndexesFromStrings(
      prefs.getStringList(_completedPrayerTimesStorageKey) ?? const [],
    );
    if (!mounted || _completedPrayerTimesChangedBeforeRestore) return;
    setState(() {
      _completionDayKey = todayKey;
      _completedPrayerTimeIndexes = restoredIndexes;
    });
  }

  Future<void> _persistDailyCompletionState() async {
    final prefs = await SharedPreferences.getInstance();
    final completedIndexes = _completedPrayerTimeIndexes.toList()..sort();
    await prefs.setString(_completionDayStorageKey, _completionDayKey);
    await prefs.setStringList(_completedPrayerTimesStorageKey, [
      for (final index in completedIndexes) index.toString(),
    ]);
  }

  void _syncCompletionDay() {
    final todayKey = _dayKey(DateTime.now());
    if (_completionDayKey == todayKey) return;
    _completionDayKey = todayKey;
    _completedPrayerTimeIndexes = {};
    _completedPrayerTimesChangedBeforeRestore = true;
    _resetAllTesbihatCounts();
    unawaited(_persistDailyCompletionState());
    _scheduleDayRolloverCheck();
  }

  void _scheduleDayRolloverCheck() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final delay = tomorrow.difference(now) + const Duration(seconds: 1);
    _dayRolloverTimer = Timer(delay, () {
      if (!mounted) return;
      setState(_syncCompletionDay);
    });
  }

  void _resetAllTesbihatCounts() {
    for (final counts in _countsByPrayerTime) {
      for (var index = 0; index < counts.length; index++) {
        counts[index] = 0;
      }
    }
  }
}

class _PrayerTimeData {
  const _PrayerTimeData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _TesbihatStepData {
  const _TesbihatStepData({required this.title, required this.target});

  final String title;
  final int target;

  String countLabel(int count) => '$count/$target';
}

class _TesbihatOverview extends StatelessWidget {
  const _TesbihatOverview({
    required this.scale,
    required this.horizontalInset,
    required this.selectedPrayerTimeIndex,
    required this.counts,
    required this.activeStepIndex,
    required this.complete,
    required this.completedPrayerTimeIndexes,
    required this.onPrayerTimeSelected,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
  });

  final double scale;
  final double horizontalInset;
  final int selectedPrayerTimeIndex;
  final List<int> counts;
  final int activeStepIndex;
  final bool complete;
  final Set<int> completedPrayerTimeIndexes;
  final ValueChanged<int> onPrayerTimeSelected;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final activeStep = _tesbihatSteps[activeStepIndex];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrayerTimeSelector(
            scale: scale,
            selectedIndex: selectedPrayerTimeIndex,
            completedIndexes: completedPrayerTimeIndexes,
            onSelected: onPrayerTimeSelected,
          ),
          SizedBox(height: 12 * scale),
          _TesbihatProgressCard(
            scale: scale,
            counts: counts,
            activeStepIndex: activeStepIndex,
          ),
          SizedBox(height: 13 * scale),
          _TesbihatCounterDialPanel(
            scale: scale,
            step: activeStep,
            count: counts[activeStepIndex],
            activeStepIndex: activeStepIndex,
            totalCount: _totalCount(counts),
            totalTarget: _totalTarget,
            complete: complete,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onReset: onReset,
          ),
        ],
      ),
    );
  }
}

int _totalCount(List<int> counts) {
  var total = 0;
  for (final count in counts) {
    total += count;
  }
  return total;
}

int get _totalTarget {
  var total = 0;
  for (final step in _tesbihatSteps) {
    total += step.target;
  }
  return total;
}

String _dayKey(DateTime date) {
  final localDate = date.toLocal();
  final year = localDate.year.toString().padLeft(4, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

Set<int> _completedPrayerTimeIndexesFromStrings(List<String> values) {
  final indexes = <int>{};
  for (final value in values) {
    final index = int.tryParse(value);
    if (index != null && index >= 0 && index < _prayerTimes.length) {
      indexes.add(index);
    }
  }
  return indexes;
}

class _PrayerTimeSelector extends StatelessWidget {
  const _PrayerTimeSelector({
    required this.scale,
    required this.selectedIndex,
    required this.completedIndexes,
    required this.onSelected,
  });

  final double scale;
  final int selectedIndex;
  final Set<int> completedIndexes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39 * scale,
      child: Row(
        children: [
          for (var index = 0; index < _prayerTimes.length; index++) ...[
            Expanded(
              child: _PrayerTimeChip(
                data: _prayerTimes[index],
                scale: scale,
                selected: index == selectedIndex,
                completed: completedIndexes.contains(index),
                onTap: () => onSelected(index),
              ),
            ),
            if (index != _prayerTimes.length - 1) SizedBox(width: 6 * scale),
          ],
        ],
      ),
    );
  }
}

class _PrayerTimeChip extends StatelessWidget {
  const _PrayerTimeChip({
    required this.data,
    required this.scale,
    required this.selected,
    required this.completed,
    required this.onTap,
  });

  final _PrayerTimeData data;
  final double scale;
  final bool selected;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emphasized = selected || completed;
    final foreground = emphasized ? _primaryGreen : _mutedText;
    final radius = BorderRadius.circular(17 * scale);

    return _PressedScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 39 * scale,
            padding: EdgeInsets.symmetric(horizontal: 5 * scale),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected
                  ? _cardSurface.withValues(alpha: 0.96)
                  : completed
                  ? const Color(0xFFEAF3E8).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.58),
              border: Border.all(
                color: emphasized
                    ? _primaryGreen.withValues(alpha: 0.62)
                    : Colors.white.withValues(alpha: 0.76),
                width: emphasized ? 1.15 * scale : 0.8 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: emphasized
                      ? _primaryGreen.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.035),
                  blurRadius: emphasized ? 18 * scale : 12 * scale,
                  offset: Offset(0, emphasized ? 7 * scale : 5 * scale),
                ),
                if (selected)
                  BoxShadow(
                    color: _softGold.withValues(alpha: 0.18),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 3 * scale),
                  ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.icon, color: foreground, size: 15 * scale),
                  SizedBox(width: 4.5 * scale),
                  Text(
                    data.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12.2 * scale,
                      fontWeight: emphasized
                          ? FontWeight.w800
                          : FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  if (completed) ...[
                    SizedBox(width: 3.5 * scale),
                    Icon(
                      Icons.check_circle_rounded,
                      color: _primaryGreen,
                      size: 13.2 * scale,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TesbihatProgressCard extends StatelessWidget {
  const _TesbihatProgressCard({
    required this.scale,
    required this.counts,
    required this.activeStepIndex,
  });

  final double scale;
  final List<int> counts;
  final int activeStepIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            14 * scale,
            16 * scale,
            14 * scale,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * scale),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.84),
                _cardSurface.withValues(alpha: 0.72),
                _paleSage.withValues(alpha: 0.34),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.78),
              width: 0.8 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.08),
                blurRadius: 24 * scale,
                offset: Offset(0, 11 * scale),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.55),
                blurRadius: 12 * scale,
                offset: Offset(0, -3 * scale),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 37 * scale,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 16 * scale,
                      child: _AnimatedTesbihatConnector(
                        scale: scale,
                        counts: counts,
                      ),
                    ),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < _tesbihatSteps.length;
                          index++
                        )
                          Expanded(
                            child: Center(
                              child: _TesbihatStepBadge(
                                number: index + 1,
                                active: index == activeStepIndex,
                                completed:
                                    counts[index] >=
                                    _tesbihatSteps[index].target,
                                scale: scale,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < _tesbihatSteps.length; index++)
                    Expanded(
                      child: _TesbihatStepLabel(
                        data: _tesbihatSteps[index],
                        count: counts[index],
                        active: index == activeStepIndex,
                        completed:
                            counts[index] >= _tesbihatSteps[index].target,
                        scale: scale,
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

class _TesbihatStepBadge extends StatelessWidget {
  const _TesbihatStepBadge({
    required this.number,
    required this.active,
    required this.completed,
    required this.scale,
  });

  final int number;
  final bool active;
  final bool completed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isActive = active && !completed;
    final emphasized = isActive || completed;
    const activeStepGreen = _counterTextGreen;
    final size = emphasized ? 37 * scale : 34 * scale;
    final fillColor = completed
        ? null
        : isActive
        ? _cardSurface.withValues(alpha: 0.70)
        : _paleSage.withValues(alpha: 0.78);
    final borderColor = completed
        ? _softGold.withValues(alpha: 0.70)
        : isActive
        ? activeStepGreen
        : Colors.white.withValues(alpha: 0.82);
    final shadowColor = completed
        ? _primaryGreen.withValues(alpha: 0.18)
        : isActive
        ? activeStepGreen.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.035);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        end: completed
            ? 1
            : isActive
            ? 0.55
            : 0,
      ),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, emphasis, child) {
        final lift = emphasized ? -1.5 * scale * emphasis.clamp(0.0, 1.0) : 0.0;

        return Transform.translate(
          offset: Offset(0, lift),
          child: AnimatedScale(
            scale: completed
                ? 1.04
                : isActive
                ? 1.06
                : 1,
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: completed
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3F8A63), _primaryGreen],
                      )
                    : null,
                color: fillColor,
                border: Border.all(
                  color: borderColor,
                  width: isActive
                      ? 2.1 * scale
                      : completed
                      ? 1.2 * scale
                      : 0.9 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: emphasized ? 15 * scale : 9 * scale,
                    offset: Offset(0, emphasized ? 6 * scale : 4 * scale),
                  ),
                  if (isActive)
                    BoxShadow(
                      color: activeStepGreen.withValues(alpha: 0.10),
                      blurRadius: 4 * scale,
                      spreadRadius: 1.2 * scale,
                    ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                reverseDuration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  final scale = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                    reverseCurve: Curves.easeInCubic,
                  );

                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.72, end: 1).animate(scale),
                      child: child,
                    ),
                  );
                },
                child: completed
                    ? Icon(
                        Icons.check_rounded,
                        key: ValueKey('step-$number-complete'),
                        color: const Color(0xFFF7EDC2),
                        size: 19 * scale,
                      )
                    : Text(
                        '$number',
                        key: ValueKey(
                          'step-$number-${isActive ? 'active' : 'idle'}',
                        ),
                        style: TextStyle(
                          color: isActive ? activeStepGreen : _mutedText,
                          fontSize: 13.2 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TesbihatStepLabel extends StatelessWidget {
  const _TesbihatStepLabel({
    required this.data,
    required this.count,
    required this.active,
    required this.completed,
    required this.scale,
  });

  final _TesbihatStepData data;
  final int count;
  final bool active;
  final bool completed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final color = active || completed ? _primaryGreen : _mutedText;
    final multiline = data.title.contains('\n');
    final titleStyle = TextStyle(
      color: color,
      fontSize: multiline ? 10.5 * scale : 10.8 * scale,
      fontWeight: FontWeight.w800,
      height: multiline ? 1.05 : 1,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3 * scale),
      child: Column(
        children: [
          SizedBox(
            height: 27 * scale,
            child: Center(
              child: multiline
                  ? AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      style: titleStyle,
                      child: Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        style: titleStyle,
                        child: Text(
                          data.title,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2 * scale),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: color.withValues(alpha: active || completed ? 0.92 : 0.78),
              fontSize: 11.7 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            child: Text(
              data.countLabel(count),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTesbihatConnector extends StatelessWidget {
  const _AnimatedTesbihatConnector({required this.scale, required this.counts});

  final double scale;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _connectorFillProgressFor(counts)),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: SizedBox(height: 3 * scale),
      builder: (context, fillProgress, child) {
        return CustomPaint(
          painter: _TesbihatConnectorPainter(
            scale: scale,
            fillProgress: fillProgress,
          ),
          child: child,
        );
      },
    );
  }
}

double _connectorFillProgressFor(List<int> counts) {
  final segmentCount = _tesbihatSteps.length - 1;
  var progress = 0.0;

  for (var index = 0; index < segmentCount; index++) {
    final step = _tesbihatSteps[index];
    final stepProgress = (counts[index] / step.target)
        .clamp(0.0, 1.0)
        .toDouble();
    progress += stepProgress;
    if (stepProgress < 1) break;
  }

  return progress.clamp(0.0, segmentCount.toDouble()).toDouble();
}

class _TesbihatConnectorPainter extends CustomPainter {
  const _TesbihatConnectorPainter({
    required this.scale,
    required this.fillProgress,
  });

  final double scale;
  final double fillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final stepWidth = size.width / _tesbihatSteps.length;
    final y = size.height / 2;
    final inactivePaint = Paint()
      ..color = _paleSage.withValues(alpha: 0.80)
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = _primaryGreen.withValues(alpha: 0.78)
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < _tesbihatSteps.length - 1; index++) {
      final start = Offset((index + 0.5) * stepWidth + 24 * scale, y);
      final end = Offset((index + 1.5) * stepWidth - 24 * scale, y);
      canvas.drawLine(start, end, inactivePaint);

      final segmentProgress = (fillProgress - index).clamp(0.0, 1.0).toDouble();
      if (segmentProgress > 0) {
        final activeEnd = Offset(
          start.dx + (end.dx - start.dx) * segmentProgress,
          y,
        );
        canvas.drawLine(start, activeEnd, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TesbihatConnectorPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.fillProgress != fillProgress;
  }
}

class _TesbihatCounterDialPanel extends StatelessWidget {
  const _TesbihatCounterDialPanel({
    required this.scale,
    required this.step,
    required this.count,
    required this.activeStepIndex,
    required this.totalCount,
    required this.totalTarget,
    required this.complete,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
  });

  final double scale;
  final _TesbihatStepData step;
  final int count;
  final int activeStepIndex;
  final int totalCount;
  final int totalTarget;
  final bool complete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final totalProgress = totalTarget == 0
        ? 0.0
        : (totalCount / totalTarget).clamp(0.0, 1.0).toDouble();
    final remaining = math.max(totalTarget - totalCount, 0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialSize = (screenWidth * 0.57 * 1.20).clamp(257.0, 293.0).toDouble();
    final lowerControlsLift = 22 * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActiveTesbihatHeader(
          scale: scale,
          activeStepIndex: activeStepIndex,
          stepTitle: step.title.replaceAll('\n', ' '),
          complete: complete,
        ),
        SizedBox(height: 4.5 * scale),
        _NamazCounterDial(
          scale: scale,
          size: dialSize,
          count: count,
          target: step.target,
          complete: complete,
          onIncrement: onIncrement,
        ),
        Transform.translate(
          offset: Offset(0, -lowerControlsLift),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NamazCounterProgressCard(
                scale: scale,
                height: 76 * scale,
                totalCount: totalCount,
                totalTarget: totalTarget,
                progress: totalProgress,
                remaining: remaining,
              ),
              SizedBox(height: 8 * scale),
              _NamazCounterActionsBar(
                scale: scale,
                canUndo: totalCount > 0,
                canReset: totalCount > 0,
                onReset: onReset,
                onDecrement: onDecrement,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveTesbihatHeader extends StatelessWidget {
  const _ActiveTesbihatHeader({
    required this.scale,
    required this.activeStepIndex,
    required this.stepTitle,
    required this.complete,
  });

  final double scale;
  final int activeStepIndex;
  final String stepTitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final label = complete
        ? 'Tesbihat tamamlandı'
        : '${activeStepIndex + 1}. zikir';
    final title = complete ? 'Allah kabul etsin' : stepTitle;

    return Container(
      constraints: BoxConstraints(minHeight: 43 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        8 * scale,
        14 * scale,
        8 * scale,
      ),
      decoration: BoxDecoration(
        color: _referencePanelSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(
          color: _mutedGold.withValues(alpha: 0.30),
          width: 0.9 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withValues(alpha: 0.07),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
          BoxShadow(
            color: _gold.withValues(alpha: 0.06),
            blurRadius: 12 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28 * scale,
            height: 28 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F8A63), _primaryGreen],
              ),
              border: Border.all(color: _softGold.withValues(alpha: 0.55)),
            ),
            child: Icon(
              complete ? Icons.check_rounded : Icons.auto_awesome_rounded,
              color: const Color(0xFFFFF5D4),
              size: 15 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 10.8 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 15.2 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1,
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

class _NamazCounterDial extends StatefulWidget {
  const _NamazCounterDial({
    required this.scale,
    required this.size,
    required this.count,
    required this.target,
    required this.complete,
    required this.onIncrement,
  });

  final double scale;
  final double size;
  final int count;
  final int target;
  final bool complete;
  final VoidCallback onIncrement;

  @override
  State<_NamazCounterDial> createState() => _NamazCounterDialState();
}

class _NamazCounterDialState extends State<_NamazCounterDial>
    with TickerProviderStateMixin {
  static const _pressSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 28,
  );

  late final AnimationController _pressController;
  late final AnimationController _countPopController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      lowerBound: -0.08,
      upperBound: 1,
    );
    _countPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _NamazCounterDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _countPopController.forward(from: 0);
    }
    if (widget.complete && !oldWidget.complete) {
      _releasePress();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _countPopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interiorSize = widget.size * 0.735;
    final counterNumberWidth = widget.size * 0.48;
    final targetPillWidth = (widget.size * 0.32).clamp(76.0, 92.0).toDouble();
    final targetPillHeight = (25 * widget.scale).clamp(23.0, 28.0).toDouble();
    final targetPillTop = widget.size * 0.705;
    final tesbihHeight = widget.size * 1.40;
    final tesbihWidth = tesbihHeight * 2 / 3;

    return Semantics(
      button: !widget.complete,
      label: 'Namaz tesbihatı sayacı',
      value: '${widget.count} / ${widget.target}',
      child: GestureDetector(
        key: const Key('namazTesbihati.counterDial'),
        behavior: HitTestBehavior.translucent,
        onTapDown: widget.complete ? null : _handleTapDown,
        onTapUp: widget.complete ? null : _handleTapUp,
        onTapCancel: widget.complete ? null : _handleTapCancel,
        onTap: widget.complete ? null : _handleTap,
        child: SizedBox.square(
          dimension: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 0.82,
                height: widget.size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _deepGreen.withValues(alpha: 0.12),
                      blurRadius: 28 * widget.scale,
                      offset: Offset(0, 13 * widget.scale),
                    ),
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.10),
                      blurRadius: 18 * widget.scale,
                      offset: Offset(0, 4 * widget.scale),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pressController,
                builder: (context, child) {
                  final pressState = _currentPressState;
                  final innerTravel = (4.2 * widget.scale)
                      .clamp(3.2, 5.1)
                      .toDouble();
                  final reboundLift = (1.0 * widget.scale)
                      .clamp(0.7, 1.3)
                      .toDouble();
                  final innerOffset =
                      pressState.easedPress * innerTravel -
                      pressState.rebound * reboundLift;
                  final innerScale =
                      1 -
                      pressState.easedPress * 0.010 +
                      pressState.rebound * 0.004;

                  return Transform.translate(
                    offset: Offset(0, innerOffset),
                    child: Transform.scale(
                      scale: innerScale,
                      child: Container(
                        width: interiorSize,
                        height: interiorSize,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            _counterInterior,
                            const Color(0xFFE0D0B2),
                            pressState.easedPress * 0.88,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: -widget.size * 0.04,
                top: -widget.size * 0.055,
                width: tesbihWidth,
                height: tesbihHeight,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.94,
                    child: Image.asset(_tesbihAsset, fit: BoxFit.contain),
                  ),
                ),
              ),
              Image.asset(
                _counterRingAsset,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
              AnimatedBuilder(
                animation: _pressController,
                builder: (context, child) {
                  final pressState = _currentPressState;
                  final numberTravel = (2.7 * widget.scale)
                      .clamp(2.0, 3.4)
                      .toDouble();
                  final numberLift = (0.9 * widget.scale)
                      .clamp(0.6, 1.2)
                      .toDouble();
                  final numberOffset =
                      -widget.size * 0.025 +
                      pressState.easedPress * numberTravel -
                      pressState.rebound * numberLift;
                  final numberScale =
                      1 -
                      pressState.easedPress * 0.012 +
                      pressState.rebound * 0.005;

                  return Transform.translate(
                    offset: Offset(0, numberOffset),
                    child: Transform.scale(scale: numberScale, child: child),
                  );
                },
                child: SizedBox(
                  width: counterNumberWidth,
                  height: (widget.size * 0.23).clamp(66.0, 92.0).toDouble(),
                  child: AnimatedBuilder(
                    animation: _countPopController,
                    builder: (context, child) {
                      final progress = _countPopController.value
                          .clamp(0.0, 1.0)
                          .toDouble();
                      final pop = Curves.easeOutBack
                          .transform(progress)
                          .clamp(0.0, 1.12)
                          .toDouble();
                      final settle = Curves.easeOutCubic.transform(progress);
                      final scale = 0.92 + pop * 0.08;
                      final lift = (1 - settle) * widget.size * 0.014;

                      return Transform.translate(
                        offset: Offset(0, lift),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.count}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _counterTextGreen,
                          fontSize: 90 * widget.scale,
                          fontWeight: FontWeight.w900,
                          height: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _pressController,
                builder: (context, child) {
                  final pressState = _currentPressState;
                  final pillTravel = (2.2 * widget.scale)
                      .clamp(1.6, 2.8)
                      .toDouble();
                  final pillLift = (0.7 * widget.scale)
                      .clamp(0.5, 1.0)
                      .toDouble();

                  return Positioned(
                    top:
                        targetPillTop +
                        pressState.easedPress * pillTravel -
                        pressState.rebound * pillLift,
                    left: 0,
                    right: 0,
                    child: child!,
                  );
                },
                child: Center(
                  child: Container(
                    width: targetPillWidth,
                    height: targetPillHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _counterTargetPillSurface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _mutedGold.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9 * widget.scale,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.complete ? 'TAMAM' : 'HEDEF ${widget.target}',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _counterTextGreen.withValues(alpha: 0.86),
                            fontSize: 11.8 * widget.scale,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CounterPressState get _currentPressState {
    final rawPress = _pressController.value;
    final press = rawPress.clamp(0.0, 1.0).toDouble();
    final rebound = ((-rawPress).clamp(0.0, 0.08) / 0.08).toDouble();
    return _CounterPressState(
      easedPress: Curves.easeOutCubic.transform(press),
      rebound: rebound,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.stop();
    _pressController.animateTo(
      1,
      duration: const Duration(milliseconds: 72),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTapUp(TapUpDetails details) {
    _releasePress();
  }

  void _handleTapCancel() {
    _releasePress();
  }

  void _handleTap() {
    _playAcceptedTapPulse();
    widget.onIncrement();
  }

  void _playAcceptedTapPulse() {
    _pressController.stop();
    final visiblePress = math
        .max(_pressController.value.clamp(0.0, 1.0).toDouble(), 0.72)
        .toDouble();
    _pressController
        .animateTo(
          visiblePress,
          duration: const Duration(milliseconds: 48),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted && !widget.complete) {
            _releasePress();
          }
        });
  }

  void _releasePress() {
    _pressController.stop();
    _pressController.animateWith(
      SpringSimulation(_pressSpring, _pressController.value, 0, -4.4),
    );
  }
}

class _CounterPressState {
  const _CounterPressState({required this.easedPress, required this.rebound});

  final double easedPress;
  final double rebound;
}

class _NamazCounterProgressCard extends StatelessWidget {
  const _NamazCounterProgressCard({
    required this.scale,
    required this.height,
    required this.totalCount,
    required this.totalTarget,
    required this.progress,
    required this.remaining,
  });

  final double scale;
  final double height;
  final int totalCount;
  final int totalTarget;
  final double progress;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        (20 * scale).clamp(17.0, 22.0).toDouble(),
        (9 * scale).clamp(8.0, 11.0).toDouble(),
        (20 * scale).clamp(17.0, 22.0).toDouble(),
        (8 * scale).clamp(6.0, 9.0).toDouble(),
      ),
      decoration: BoxDecoration(
        color: _referencePanelSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(
          color: _mutedGold.withValues(alpha: 0.34),
          width: 0.9 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withValues(alpha: 0.08),
            blurRadius: 22 * scale,
            offset: Offset(0, 9 * scale),
          ),
          BoxShadow(
            color: _gold.withValues(alpha: 0.07),
            blurRadius: 16 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOPLAM İLERLEMEN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 12.2 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Text(
                '$totalCount / $totalTarget',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: (7 * scale).clamp(6.0, 8.0).toDouble()),
          _NamazPremiumProgressBar(scale: scale, progress: progress),
          SizedBox(height: (7 * scale).clamp(5.0, 8.0).toDouble()),
          Text(
            remaining == 0 ? 'Tesbihat tamamlandı' : '$remaining zikir kaldı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 12.5 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NamazPremiumProgressBar extends StatelessWidget {
  const _NamazPremiumProgressBar({required this.scale, required this.progress});

  final double scale;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final trackHeight = (9 * scale).clamp(8.0, 10.5).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          height: trackHeight + 6 * scale,
          child: CustomPaint(
            painter: _NamazProgressBarPainter(
              progress: value,
              trackHeight: trackHeight,
              scale: scale,
            ),
          ),
        );
      },
    );
  }
}

class _NamazProgressBarPainter extends CustomPainter {
  const _NamazProgressBarPainter({
    required this.progress,
    required this.trackHeight,
    required this.scale,
  });

  final double progress;
  final double trackHeight;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final value = progress.clamp(0.0, 1.0).toDouble();
    final centerY = size.height / 2;
    final trackRect = Rect.fromLTWH(
      0,
      centerY - trackHeight / 2,
      size.width,
      trackHeight,
    );
    final trackRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(999),
    );

    canvas.drawRRect(
      trackRRect,
      Paint()..color = const Color(0xFFD6D4C6).withValues(alpha: 0.86),
    );

    if (value <= 0.001) return;

    final fillWidth = (size.width * value).clamp(0.0, size.width).toDouble();
    final fillRect = Rect.fromLTWH(0, trackRect.top, fillWidth, trackHeight);
    final fillRRect = RRect.fromRectAndRadius(
      fillRect,
      const Radius.circular(999),
    );

    canvas.drawRRect(
      fillRRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _primaryGreen,
            const Color(0xFF1C6B4B),
            _gold.withValues(alpha: 0.86),
          ],
          stops: const [0, 0.70, 1],
        ).createShader(trackRect),
    );

    final headX = fillWidth.clamp(0.0, size.width).toDouble();
    final glowWidth = (24 * scale).clamp(19.0, 28.0).toDouble();
    final glowRect = Rect.fromLTRB(
      (headX - glowWidth).clamp(0.0, size.width).toDouble(),
      trackRect.top - trackHeight * 0.35,
      (headX + trackHeight * 0.25).clamp(0.0, size.width).toDouble(),
      trackRect.bottom + trackHeight * 0.35,
    );
    if (glowRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(glowRect, Radius.circular(glowWidth)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              _gold.withValues(alpha: 0),
              _gold.withValues(alpha: 0.36),
              const Color(0xFFFFE01B).withValues(alpha: 0.58),
            ],
          ).createShader(glowRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NamazProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.scale != scale;
  }
}

class _NamazCounterActionsBar extends StatelessWidget {
  const _NamazCounterActionsBar({
    required this.scale,
    required this.canUndo,
    required this.canReset,
    required this.onReset,
    required this.onDecrement,
  });

  final double scale;
  final bool canUndo;
  final bool canReset;
  final VoidCallback onReset;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: _referenceControlSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: _mutedGold.withValues(alpha: 0.34),
          width: 0.9 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withValues(alpha: 0.08),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
          BoxShadow(
            color: _gold.withValues(alpha: 0.07),
            blurRadius: 12 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NamazCounterToolbarButton(
              scale: scale,
              icon: Icons.refresh_rounded,
              label: 'SIFIRLA',
              onTap: canReset ? onReset : null,
            ),
          ),
          Container(
            width: 1,
            height: 30 * scale,
            margin: EdgeInsets.symmetric(horizontal: 9 * scale),
            color: _mutedGold.withValues(alpha: 0.16),
          ),
          Expanded(
            child: _NamazCounterToolbarButton(
              scale: scale,
              icon: Icons.undo_rounded,
              label: 'GERİ AL',
              onTap: canUndo ? onDecrement : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NamazCounterToolbarButton extends StatelessWidget {
  const _NamazCounterToolbarButton({
    required this.scale,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = enabled
        ? _primaryGreen
        : _primaryGreen.withValues(alpha: 0.36);
    final borderRadius = BorderRadius.circular(16 * scale);

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          splashColor: _gold.withValues(alpha: 0.12),
          highlightColor: _gold.withValues(alpha: 0.06),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 19 * scale),
              SizedBox(width: 7 * scale),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressedScale extends StatefulWidget {
  const _PressedScale({required this.child});

  final Widget child;

  @override
  State<_PressedScale> createState() => _PressedScaleState();
}

class _PressedScaleState extends State<_PressedScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }
}

class _NamazTesbihatiHero extends StatelessWidget {
  const _NamazTesbihatiHero({
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
    final heroVisualHeight =
        (112 + _heroSearchBackdropExtension) * scale + safeTop;
    final heroLayoutHeight = math.max(
      safeTop + 96 * scale,
      heroVisualHeight - _tesbihatOverviewLift * scale,
    );
    final heroAssetTop = contentWidth < appLayoutBaselineWidth
        ? -12 * scale
        : 0.0;
    final titleLeft = horizontalInset + 64 * scale;
    final titleTop = safeTop + 10 * scale;

    return SizedBox(
      height: heroLayoutHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: heroVisualHeight,
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
                    'Namaz Tesbihatı',
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
                    'Namaz sonrası tesbihatı huzurla,\nadım adım tamamla.',
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
