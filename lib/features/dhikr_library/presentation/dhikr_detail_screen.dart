import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../counter/application/counter_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../application/dhikr_providers.dart';
import '../domain/dhikr_item.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _deepGreen = Color(0xFF123B2B);
const _buttonGreen = Color(0xFF327653);
const _targetGreen = Color(0xFF16583B);
const _targetGreenTop = Color(0xFF1B6A47);
const _arabicHeroGreen = Color(0xFF064934);
const _transliterationGold = Color(0xFF9A7225);
const _mutedGreen = Color(0xFF69766E);
const _referenceSurface = Color(0xFFF8F2E8);
const _referenceSurfaceTop = Color(0xFFFFFCF6);
const _meaningCardSurface = Color(0xFFFBF8F1);
const _referenceBorder = Color(0xFFE0CF9B);
const _gold = Color(0xFFD4BA75);
const _goldText = Color(0xFF80652B);
const _fixedTargetOptions = [33, 99, 100];
const _detailTopBackgroundAsset = 'assets/images/zikir-arka2.webp';
const _meaningCardBackgroundAsset = 'assets/images/tablo-arka.webp';

class DhikrDetailScreen extends ConsumerStatefulWidget {
  const DhikrDetailScreen({super.key, required this.dhikrId});

  final String dhikrId;

  @override
  ConsumerState<DhikrDetailScreen> createState() => _DhikrDetailScreenState();
}

class _DhikrDetailScreenState extends ConsumerState<DhikrDetailScreen> {
  int _selectedTarget = 33;
  int? _customTarget;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.12).toDouble();
    final stickyPanelBottomOffset = media.padding.bottom + 10 * scale;
    final pinnedFooterHeight = 150 * scale + stickyPanelBottomOffset;
    final items = ref.watch(dhikrItemsProvider);

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
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _pageBackground)),
              Positioned.fill(
                child: CustomPaint(painter: _DetailWashPainter()),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: media.padding.top + 310 * scale,
                child: const _DetailTopBackground(),
              ),
              items.when(
                data: (dhikrs) {
                  final item = dhikrs.firstWhere(
                    (dhikr) => dhikr.id == widget.dhikrId,
                    orElse: () => dhikrs.first,
                  );
                  final detail = _DhikrDetailContent.forItem(item);
                  if (_selectedTarget != 0 &&
                      _selectedTarget != _customTarget &&
                      !_fixedTargetOptions.contains(_selectedTarget)) {
                    _selectedTarget = _fixedTargetOptions.first;
                  }

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                14 * scale,
                                media.padding.top + 6 * scale,
                                14 * scale,
                                pinnedFooterHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _TopBar(scale: scale, item: item),
                                  SizedBox(height: 7 * scale),
                                  _HeroPanel(
                                    scale: scale,
                                    item: item,
                                    detail: detail,
                                  ),
                                  SizedBox(height: 7 * scale),
                                  _InfoCard(
                                    scale: scale,
                                    title: 'Anlamı',
                                    body: detail.longMeaning,
                                  ),
                                  SizedBox(height: 6 * scale),
                                  _VirtueCard(scale: scale, detail: detail),
                                  SizedBox(height: 6 * scale),
                                  _TimingCard(scale: scale, detail: detail),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14 * scale,
                            right: 14 * scale,
                            bottom: stickyPanelBottomOffset,
                            child: _StickyActionPanel(
                              scale: scale,
                              selectedTarget: _selectedTarget,
                              customTarget: _customTarget,
                              onTargetChanged: _selectTarget,
                              onCustomTarget: _showCustomTargetDialog,
                              target: _selectedTarget,
                              onPressed: () => _startDhikr(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                error: (error, stackTrace) => _LoadState(
                  scale: scale,
                  title: 'Zikir açılamadı',
                  message: '$error',
                ),
                loading: () => _LoadState(
                  scale: scale,
                  title: 'Zikir hazırlanıyor',
                  message: 'Detaylar birazdan açılacak.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startDhikr(DhikrItem item) {
    ref
        .read(counterControllerProvider.notifier)
        .startDhikr(item, target: _selectedTarget);
    ref.read(interactionFeedbackServiceProvider).primaryAction();
    context.push(AppRoutes.counter);
  }

  void _selectTarget(int target) {
    setState(() => _selectedTarget = target);
    ref.read(interactionFeedbackServiceProvider).selection();
  }

  Future<void> _showCustomTargetDialog() async {
    final controller = TextEditingController(
      text: _customTarget == null ? '' : '$_customTarget',
    );

    final target = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Özel hedef'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Hedef sayısı',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 1) return;
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Uygula'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (target == null || !mounted) return;

    setState(() {
      _customTarget = target;
      _selectedTarget = target;
    });
    ref.read(interactionFeedbackServiceProvider).selection();
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.scale, required this.item});

  final double scale;
  final DhikrItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = item.isFavorite;

    return Row(
      children: [
        _CircleIconButton(
          scale: scale,
          tooltip: 'Geri dön',
          icon: Icons.chevron_left_rounded,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dhikrLibrary);
            }
          },
        ),
        const Spacer(),
        _CircleIconButton(
          scale: scale,
          tooltip: isFavorite ? 'Favoriden çıkar' : 'Favoriye ekle',
          icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          color: isFavorite ? const Color(0xFFC39B32) : _primaryGreen,
          background: isFavorite
              ? _gold.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.58),
          onTap: () {
            ref
                .read(settingsControllerProvider.notifier)
                .toggleFavorite(item.id);
            ref.read(interactionFeedbackServiceProvider).selection();
          },
        ),
        SizedBox(width: 7 * scale),
        _CircleIconButton(
          scale: scale,
          tooltip: 'Metni kopyala',
          icon: Icons.ios_share_rounded,
          onTap: () {
            Clipboard.setData(
              ClipboardData(
                text:
                    '${item.name}\n${item.arabicText ?? ''}\n${item.meaning ?? ''}',
              ),
            );
            ref.read(interactionFeedbackServiceProvider).selection();
          },
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.scale,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color = _primaryGreen,
    this.background,
  });

  final double scale;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 30 * scale,
        child: Material(
          color: background ?? Colors.white.withValues(alpha: 0.58),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(icon, color: color, size: 18 * scale),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.scale,
    required this.item,
    required this.detail,
  });

  final double scale;
  final DhikrItem item;
  final _DhikrDetailContent detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8 * scale,
        12 * scale,
        8 * scale,
        12 * scale,
      ),
      child: Column(
        children: [
          Text(
            detail.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _arabicHeroGreen,
              fontFamily: 'Amiri',
              fontSize: 34 * scale,
              fontWeight: FontWeight.w700,
              height: 1.18,
              shadows: [
                Shadow(
                  color: _arabicHeroGreen.withValues(alpha: 0.20),
                  blurRadius: 4 * scale,
                  offset: Offset(0, 1.5 * scale),
                ),
              ],
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            detail.transliteration,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _transliterationGold,
              fontFamily: 'EB Garamond',
              fontSize: 24 * scale,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              height: 1.1,
              shadows: [
                Shadow(
                  color: _deepGreen.withValues(alpha: 0.12),
                  blurRadius: 3 * scale,
                  offset: Offset(0, 1 * scale),
                ),
              ],
            ),
          ),
          SizedBox(height: 8 * scale),
          _HeroDivider(scale: scale),
          SizedBox(height: 8 * scale),
          Text(
            item.meaning ?? detail.shortMeaning,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedGreen,
              fontSize: 10.8 * scale,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36 * scale,
          height: 1,
          color: _goldText.withValues(alpha: 0.22),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 7 * scale),
          child: Icon(
            Icons.diamond_outlined,
            color: _goldText.withValues(alpha: 0.72),
            size: 11 * scale,
          ),
        ),
        Container(
          width: 36 * scale,
          height: 1,
          color: _goldText.withValues(alpha: 0.22),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.scale,
    required this.title,
    required this.body,
  });

  final double scale;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _ReferenceCard(
      scale: scale,
      backgroundAsset: _meaningCardBackgroundAsset,
      backgroundOpacity: 0.94,
      backgroundBaseColor: _meaningCardSurface,
      backgroundFit: BoxFit.fitWidth,
      backgroundAlignment: Alignment.bottomRight,
      backgroundOverflowBottom: 15 * scale,
      backgroundOverflowRight: 1 * scale,
      borderOpacity: 1,
      borderWidth: 1.5 * scale,
      emphasizedBorder: true,
      shadowStrength: 1.55,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 118 * scale),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final doorReserve = (constraints.maxWidth * 0.18).clamp(
              48 * scale,
              66 * scale,
            );

            return Padding(
              padding: EdgeInsets.only(right: doorReserve),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(scale: scale, title: title),
                  SizedBox(height: 7 * scale),
                  Text(
                    body,
                    style: TextStyle(
                      color: const Color(0xFF293934),
                      fontSize: 11.15 * scale,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  const _VirtueCard({required this.scale, required this.detail});

  final double scale;
  final _DhikrDetailContent detail;

  @override
  Widget build(BuildContext context) {
    return _ReferenceCard(
      scale: scale,
      ornateBorder: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6 * scale,
          vertical: 1 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(scale: scale, title: 'Fazileti'),
            SizedBox(height: 11 * scale),
            Text(
              detail.virtueArabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: _primaryGreen,
                fontFamily: 'Amiri',
                fontSize: 15.2 * scale,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 9 * scale),
            Text(
              detail.virtueText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF34413A),
                fontFamily: 'EB Garamond',
                fontSize: 12.6 * scale,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.34,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              detail.source,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _goldText,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  const _TimingCard({required this.scale, required this.detail});

  final double scale;
  final _DhikrDetailContent detail;

  @override
  Widget build(BuildContext context) {
    return _ReferenceCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(scale: scale, title: 'Ne zaman çekilir'),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              for (final timing in detail.timings) ...[
                Expanded(
                  child: _TimingTile(scale: scale, timing: timing),
                ),
                if (timing != detail.timings.last) SizedBox(width: 5 * scale),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimingTile extends StatelessWidget {
  const _TimingTile({required this.scale, required this.timing});

  final double scale;
  final _TimingInfo timing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 55 * scale),
      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: _referenceSurfaceTop.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(11 * scale),
        border: Border.all(color: _referenceBorder.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withValues(alpha: 0.045),
            blurRadius: 10 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(timing.icon, color: _primaryGreen, size: 13 * scale),
          SizedBox(height: 3 * scale),
          Text(
            timing.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            timing.amount,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mutedGreen,
              fontSize: 8.8 * scale,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.scale,
    required this.selectedTarget,
    required this.customTarget,
    required this.onChanged,
    required this.onCustomTarget,
  });

  final double scale;
  final int selectedTarget;
  final int? customTarget;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustomTarget;

  @override
  Widget build(BuildContext context) {
    final customSelected =
        customTarget != null &&
        customTarget == selectedTarget &&
        !_fixedTargetOptions.contains(selectedTarget);

    return Container(
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        11 * scale,
        12 * scale,
        10 * scale,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(scale: scale, title: 'Hedef belirle'),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              for (final target in _fixedTargetOptions) ...[
                SizedBox(
                  width: 50 * scale,
                  child: _TargetChip(
                    scale: scale,
                    label: '$target',
                    selected: target == selectedTarget,
                    onTap: () => onChanged(target),
                  ),
                ),
                SizedBox(width: 5 * scale),
              ],
              Expanded(
                child: _TargetChip(
                  scale: scale,
                  label: customTarget == null ? 'Özel' : '$customTarget',
                  icon: Icons.edit_rounded,
                  selected: customSelected,
                  onTap: onCustomTarget,
                ),
              ),
              SizedBox(width: 5 * scale),
              Expanded(
                child: _TargetChip(
                  scale: scale,
                  label: 'Sonsuz',
                  icon: Icons.all_inclusive_rounded,
                  selected: selectedTarget == 0,
                  onTap: () => onChanged(0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final double scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = 17 * scale;
    final selectedOutlineWidth = 1.05 * scale;
    final innerRadius = selected ? radius - selectedOutlineWidth : radius;

    return SizedBox(
      height: 34 * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: (selected ? _deepGreen : Colors.black).withValues(
                alpha: selected ? 0.16 : 0.045,
              ),
              blurRadius: selected ? 12 * scale : 9 * scale,
              offset: Offset(0, selected ? 5 * scale : 3 * scale),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gold.withValues(alpha: 0.92),
                      _goldText.withValues(alpha: 0.70),
                    ],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.94),
            border: selected
                ? null
                : Border.all(color: _primaryGreen.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: EdgeInsets.all(selected ? selectedOutlineWidth : 0),
            child: Material(
              clipBehavior: Clip.antiAlias,
              color: selected ? _deepGreen : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(innerRadius),
                onTap: onTap,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3 * scale),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: selected ? Colors.white : _primaryGreen,
                              size: 13.5 * scale,
                            ),
                            SizedBox(width: 2.5 * scale),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: selected ? Colors.white : _primaryGreen,
                              fontSize: 11.6 * scale,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyActionPanel extends StatelessWidget {
  const _StickyActionPanel({
    required this.scale,
    required this.selectedTarget,
    required this.customTarget,
    required this.onTargetChanged,
    required this.onCustomTarget,
    required this.target,
    required this.onPressed,
  });

  final double scale;
  final int selectedTarget;
  final int? customTarget;
  final ValueChanged<int> onTargetChanged;
  final VoidCallback onCustomTarget;
  final int target;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [
          BoxShadow(
            color: _buttonGreen.withValues(alpha: 0.16),
            blurRadius: 22 * scale,
            offset: Offset(0, 9 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _meaningCardSurface,
            border: Border.all(color: _referenceBorder.withValues(alpha: 0.32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TargetCard(
                scale: scale,
                selectedTarget: selectedTarget,
                customTarget: customTarget,
                onChanged: onTargetChanged,
                onCustomTarget: onCustomTarget,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12 * scale,
                  0,
                  12 * scale,
                  10 * scale,
                ),
                child: _AnimatedStartButton(
                  scale: scale,
                  target: target,
                  onPressed: onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStartButton extends StatefulWidget {
  const _AnimatedStartButton({
    required this.scale,
    required this.target,
    required this.onPressed,
  });

  final double scale;
  final int target;
  final VoidCallback onPressed;

  @override
  State<_AnimatedStartButton> createState() => _AnimatedStartButtonState();
}

class _AnimatedStartButtonState extends State<_AnimatedStartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return AnimatedScale(
      scale: _pressed ? 0.982 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = (math.sin(_controller.value * math.pi * 2) + 1) / 2;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _targetGreen.withValues(alpha: 0.22 + pulse * 0.12),
                  blurRadius: 13 * scale + pulse * 8 * scale,
                  spreadRadius: pulse * 1.6 * scale,
                  offset: Offset(0, 6 * scale),
                ),
              ],
            ),
            child: child,
          );
        },
        child: SizedBox(
          height: 52 * scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Material(
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_targetGreenTop, _targetGreen],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final shimmerWidth = constraints.maxWidth * 0.24;
                          final x =
                              -shimmerWidth +
                              (constraints.maxWidth + shimmerWidth * 2) *
                                  _controller.value;

                          return Transform.translate(
                            offset: Offset(x, 0),
                            child: child,
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.rotate(
                            angle: -0.28,
                            child: Container(
                              width: constraints.maxWidth * 0.24,
                              height: 74 * scale,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                  stops: const [0, 0.5, 1],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        key: const Key('dhikr.detail.start'),
                        borderRadius: BorderRadius.circular(999),
                        onTap: widget.onPressed,
                        onHighlightChanged: (pressed) {
                          setState(() => _pressed = pressed);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30 * scale,
                              height: 30 * scale,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 21 * scale,
                              ),
                            ),
                            SizedBox(width: 9 * scale),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.target == 0
                                      ? 'Sonsuz zikre başla'
                                      : '${widget.target} hedefle zikre başla',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({
    required this.scale,
    required this.child,
    this.backgroundAsset,
    this.backgroundOpacity = 0,
    this.backgroundBaseColor,
    this.backgroundFit = BoxFit.cover,
    this.backgroundAlignment = Alignment.centerRight,
    this.backgroundOverflowBottom = 0,
    this.backgroundOverflowRight = 0,
    this.ornateBorder = false,
    this.emphasizedBorder = false,
    this.borderOpacity = 0.28,
    this.borderWidth,
    this.shadowStrength = 1,
  });

  final double scale;
  final Widget child;
  final String? backgroundAsset;
  final double backgroundOpacity;
  final Color? backgroundBaseColor;
  final BoxFit backgroundFit;
  final Alignment backgroundAlignment;
  final double backgroundOverflowBottom;
  final double backgroundOverflowRight;
  final bool ornateBorder;
  final bool emphasizedBorder;
  final double borderOpacity;
  final double? borderWidth;
  final double shadowStrength;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17 * scale),
        boxShadow: _referenceCardShadow(scale, strength: shadowStrength),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundBaseColor,
            gradient: backgroundBaseColor == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _referenceSurfaceTop.withValues(alpha: 0.96),
                      _referenceSurface.withValues(alpha: 0.94),
                    ],
                  )
                : null,
            border: Border.all(
              color: _referenceBorder.withValues(alpha: borderOpacity),
              width: borderWidth ?? 1,
            ),
          ),
          child: Stack(
            children: [
              if (backgroundAsset != null)
                Positioned(
                  left: 0,
                  top: 0,
                  right: -backgroundOverflowRight,
                  bottom: -backgroundOverflowBottom,
                  child: Image.asset(
                    backgroundAsset!,
                    fit: backgroundFit,
                    alignment: backgroundAlignment,
                    opacity: AlwaysStoppedAnimation(backgroundOpacity),
                  ),
                ),
              Positioned.fill(
                child: CustomPaint(painter: _ReferenceCardTexturePainter()),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  15 * scale,
                  15 * scale,
                  15 * scale,
                  15 * scale,
                ),
                child: child,
              ),
              if (emphasizedBorder)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EmphasizedCardBorderPainter(scale),
                  ),
                ),
              if (ornateBorder)
                Positioned.fill(
                  child: CustomPaint(painter: _OrnateGoldBorderPainter(scale)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.scale, required this.title});

  final double scale;
  final String title;

  @override
  Widget build(BuildContext context) {
    final icon = _sectionIcon(title);

    return Row(
      children: [
        Container(
          width: 23 * scale,
          height: 23 * scale,
          decoration: BoxDecoration(
            color: _referenceSurfaceTop.withValues(alpha: 0.86),
            shape: BoxShape.circle,
            border: Border.all(color: _referenceBorder.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _goldText.withValues(alpha: 0.08),
                blurRadius: 7 * scale,
                offset: Offset(0, 2 * scale),
              ),
            ],
          ),
          child: Icon(icon, color: _primaryGreen, size: 13 * scale),
        ),
        SizedBox(width: 8 * scale),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: _primaryGreen,
            fontSize: 10 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

List<BoxShadow> _referenceCardShadow(double scale, {double strength = 1}) {
  return [
    BoxShadow(
      color: _deepGreen.withValues(alpha: 0.055 * strength),
      blurRadius: 20 * scale * strength,
      offset: Offset(0, 9 * scale),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.60),
      blurRadius: 1 * scale,
      offset: Offset(0, -0.5 * scale),
    ),
  ];
}

IconData _sectionIcon(String title) {
  final normalized = title.toLowerCase();
  if (normalized.contains('anlam')) return Icons.menu_book_rounded;
  if (normalized.contains('fazilet')) return Icons.auto_awesome_rounded;
  if (normalized.contains('zaman')) return Icons.schedule_rounded;
  if (normalized.contains('hedef')) return Icons.track_changes_rounded;
  return Icons.spa_rounded;
}

class _ReferenceCardTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _gold.withValues(alpha: 0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final spacing = size.width / 9;
    for (var i = -4; i < 13; i++) {
      final x = i * spacing;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.75, size.height),
        linePaint,
      );
    }

    final cornerPaint = Paint()
      ..color = _primaryGreen.withValues(alpha: 0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = Rect.fromLTWH(
      size.width * 0.73,
      size.height * -0.12,
      size.width * 0.34,
      size.height * 0.54,
    );
    canvas.drawArc(rect, math.pi * 0.08, math.pi * 0.84, false, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmphasizedCardBorderPainter extends CustomPainter {
  const _EmphasizedCardBorderPainter(this.scale);

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0.9 * scale,
      0.9 * scale,
      size.width - 1.8 * scale,
      size.height - 1.8 * scale,
    );
    final radius = Radius.circular(17 * scale);
    final outerPaint = Paint()
      ..color = _goldText.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), outerPaint);

    final innerRect = rect.deflate(2.0 * scale);
    final innerPaint = Paint()
      ..color = _referenceBorder.withValues(alpha: 0.46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(15 * scale)),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmphasizedCardBorderPainter oldDelegate) =>
      oldDelegate.scale != scale;
}

class _OrnateGoldBorderPainter extends CustomPainter {
  const _OrnateGoldBorderPainter(this.scale);

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      7 * scale,
      7 * scale,
      size.width - 14 * scale,
      size.height - 14 * scale,
    );
    final radius = Radius.circular(13 * scale);
    final borderPaint = Paint()
      ..color = _goldText.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), borderPaint);

    final motifPaint = Paint()
      ..color = _goldText.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * scale
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset origin, double sx, double sy) {
      final p = Path()
        ..moveTo(origin.dx, origin.dy + sy * 9 * scale)
        ..quadraticBezierTo(
          origin.dx + sx * 5 * scale,
          origin.dy + sy * 5 * scale,
          origin.dx + sx * 10 * scale,
          origin.dy,
        )
        ..moveTo(origin.dx + sx * 3 * scale, origin.dy + sy * 13 * scale)
        ..lineTo(origin.dx + sx * 13 * scale, origin.dy + sy * 3 * scale);
      canvas.drawPath(p, motifPaint);
      canvas.drawCircle(
        Offset(origin.dx + sx * 10 * scale, origin.dy + sy * 10 * scale),
        1.2 * scale,
        motifPaint,
      );
    }

    drawCorner(Offset(12 * scale, 12 * scale), 1, 1);
    drawCorner(Offset(size.width - 12 * scale, 12 * scale), -1, 1);
    drawCorner(Offset(12 * scale, size.height - 12 * scale), 1, -1);
    drawCorner(
      Offset(size.width - 12 * scale, size.height - 12 * scale),
      -1,
      -1,
    );

    final dividerPaint = Paint()
      ..color = _goldText.withValues(alpha: 0.16)
      ..strokeWidth = 0.75 * scale;
    canvas.drawLine(
      Offset(size.width * 0.10, 8 * scale),
      Offset(size.width * 0.90, 8 * scale),
      dividerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.10, size.height - 8 * scale),
      Offset(size.width * 0.90, size.height - 8 * scale),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrnateGoldBorderPainter oldDelegate) =>
      oldDelegate.scale != scale;
}

class _DetailTopBackground extends StatelessWidget {
  const _DetailTopBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _detailTopBackgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _pageBackground.withValues(alpha: 0),
                  _pageBackground.withValues(alpha: 0.02),
                  _pageBackground.withValues(alpha: 0.38),
                  _pageBackground,
                ],
                stops: const [0, 0.64, 0.88, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadState extends StatelessWidget {
  const _LoadState({
    required this.scale,
    required this.title,
    required this.message,
  });

  final double scale;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _buttonGreen),
            SizedBox(height: 18 * scale),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _deepGreen,
                fontSize: 18 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mutedGreen,
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topWash = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFFCF6).withValues(alpha: 0.94),
              const Color(0xFFE9EEE4).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.20, size.height * 0.02),
              radius: size.width * 0.86,
            ),
          );
    canvas.drawRect(Offset.zero & size, topWash);

    final greenWash = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _buttonGreen.withValues(alpha: 0.12),
              _buttonGreen.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.85, size.height * 0.72),
              radius: size.width * 0.72,
            ),
          );
    canvas.drawRect(Offset.zero & size, greenWash);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DhikrDetailContent {
  const _DhikrDetailContent({
    required this.arabic,
    required this.transliteration,
    required this.shortMeaning,
    required this.longMeaning,
    required this.virtueArabic,
    required this.virtueText,
    required this.source,
    required this.timings,
  });

  final String arabic;
  final String transliteration;
  final String shortMeaning;
  final String longMeaning;
  final String virtueArabic;
  final String virtueText;
  final String source;
  final List<_TimingInfo> timings;

  factory _DhikrDetailContent.forItem(DhikrItem item) {
    if (item.id == 'subhanallah') {
      return const _DhikrDetailContent(
        arabic: 'سُبْحَانَ اللّٰه',
        transliteration: 'Sübhânallâh',
        shortMeaning: 'Allah’ı her türlü noksanlıktan tenzih ederim.',
        longMeaning:
            'Kalbin Rabbine duyduğu hayretin ilk sözüdür. Mümin, kainatın her zerresinde O’nun kudretini görür ve “Rabbim her türlü eksiklikten münezzehtir” der. Dile hafif, mizanda ağır olan bu kelime, gönüldeki tevhid nuruna tercüman olur.',
        virtueArabic:
            'مَنْ قَالَ سُبْحَانَ اللَّهِ وَبِحَمْدِهِ فِي يَوْمٍ مِائَةَ مَرَّةٍ حُطَّتْ خَطَايَاهُ',
        virtueText:
            'Kim günde yüz defa “Sübhânallâhi ve bi-hamdihî” derse, günahları deniz köpüğü kadar bile olsa bağışlanır.',
        source: 'Buhârî, Daavât 65 · Müslim, Zikir 28',
        timings: [
          _TimingInfo(
            icon: Icons.wb_sunny_rounded,
            label: 'Sabah-akşam',
            amount: '100 defa',
          ),
          _TimingInfo(
            icon: Icons.trip_origin_rounded,
            label: 'Namaz sonrası',
            amount: '33 defa',
          ),
          _TimingInfo(
            icon: Icons.nights_stay_rounded,
            label: 'Yatmadan',
            amount: '33 defa',
          ),
        ],
      );
    }

    return _DhikrDetailContent(
      arabic: item.arabicText ?? item.name,
      transliteration: item.name,
      shortMeaning: item.meaning ?? '',
      longMeaning: item.meaning ?? 'Bu zikir için detay metni hazırlanıyor.',
      virtueArabic: item.arabicText ?? '',
      virtueText: 'Bu zikir için fazilet bilgileri hazırlanıyor.',
      source: 'Kaynak bilgisi eklenecek',
      timings: [
        _TimingInfo(
          icon: Icons.trip_origin_rounded,
          label: 'Önerilen',
          amount: '${item.defaultTarget} defa',
        ),
        const _TimingInfo(
          icon: Icons.schedule_rounded,
          label: 'Gün içinde',
          amount: 'Uygun vakit',
        ),
        const _TimingInfo(
          icon: Icons.flag_rounded,
          label: 'Hedefli',
          amount: 'Niyetle',
        ),
      ],
    );
  }
}

class _TimingInfo {
  const _TimingInfo({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final String amount;
}
