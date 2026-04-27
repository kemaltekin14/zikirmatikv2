import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../counter/application/counter_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../data/esma_data.dart';
import '../domain/esma_item.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _mutedText = Color(0xFF69766E);
const _cardSurface = Color(0xFFFAFAF4);
const _paleSage = Color(0xFFE5ECE2);
const _gold = Color(0xFFCDAA3B);
const _heroAsset = 'assets/images/esma-her2.webp';
const _heroSearchBackdropExtension = 20.0;
const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

class EsmaScreen extends ConsumerStatefulWidget {
  const EsmaScreen({super.key});

  @override
  ConsumerState<EsmaScreen> createState() => _EsmaScreenState();
}

class _EsmaScreenState extends ConsumerState<EsmaScreen> {
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

  List<EsmaItem> get _filteredItems {
    final normalizedQuery = _query.trim().toLowerCase();
    return esmaItems.where((item) {
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        item.name,
        item.meaning,
        item.category,
        item.arabicText,
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
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
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _pageBackground)),
              Positioned.fill(
                bottom: bottomReservedHeight,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: scrollBottomPadding),
                  children: [
                    _EsmaTopSection(
                      scale: scale,
                      safeTop: media.padding.top,
                      contentWidth: contentWidth,
                      horizontalInset: horizontalInset,
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    ..._filteredItems.map(
                      (item) => _EsmaCard(
                        item: item,
                        scale: scale,
                        horizontalInset: horizontalInset,
                        onTap: () => _startEsma(item),
                      ),
                    ),
                  ],
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.esma,
                quickStartKey: const Key('esma.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startEsma(EsmaItem item) {
    final feedback = ref.read(interactionFeedbackServiceProvider);
    ref.read(counterControllerProvider.notifier).startDhikr(item.toDhikr());
    context.go(AppRoutes.counter);
    feedback.primaryAction();
  }
}

class _EsmaTopSection extends StatelessWidget {
  const _EsmaTopSection({
    required this.scale,
    required this.safeTop,
    required this.contentWidth,
    required this.horizontalInset,
    required this.controller,
    required this.onChanged,
  });

  final double scale;
  final double safeTop;
  final double contentWidth;
  final double horizontalInset;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: _EsmaTopBackground()),
        Positioned(
          left: 0,
          top: safeTop + 104 * scale,
          width: horizontalInset + 210 * scale,
          height: 78 * scale,
          child: const _SearchLeftBlendPatch(),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EsmaHero(
              scale: scale,
              safeTop: safeTop,
              contentWidth: contentWidth,
              horizontalInset: horizontalInset,
            ),
            Transform.translate(
              offset: Offset(0, -(_heroSearchBackdropExtension - 5) * scale),
              child: _SearchAddRow(
                scale: scale,
                horizontalInset: horizontalInset,
                controller: controller,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              height: math.max(0, (27 - _heroSearchBackdropExtension) * scale),
            ),
            _SectionHeader(scale: scale, horizontalInset: horizontalInset),
            SizedBox(height: 10 * scale),
          ],
        ),
      ],
    );
  }
}

class _EsmaTopBackground extends StatelessWidget {
  const _EsmaTopBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFCF7).withValues(alpha: 0.24),
            _pageBackground.withValues(alpha: 0.18),
            _pageBackground.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.42, 0.76],
        ),
      ),
    );
  }
}

class _SearchLeftBlendPatch extends StatelessWidget {
  const _SearchLeftBlendPatch();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.centerLeft,
          radius: 1.05,
          colors: [
            const Color(0xFFFFFCF7).withValues(alpha: 0.16),
            _pageBackground.withValues(alpha: 0.10),
            _pageBackground.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.54, 1.0],
        ),
      ),
    );
  }
}

class _EsmaHero extends StatelessWidget {
  const _EsmaHero({
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
    final heroHeight = (112 + _heroSearchBackdropExtension) * scale + safeTop;
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
                    'Esma-ül Hüsna',
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
                    "Allah'ın en güzel isimlerini öğren,\nanlamlarını kavra, zikret.",
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
          tooltip: 'Menü',
          onPressed: () {},
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

class _SearchAddRow extends StatelessWidget {
  const _SearchAddRow({
    required this.scale,
    required this.horizontalInset,
    required this.controller,
    required this.onChanged,
  });

  final double scale;
  final double horizontalInset;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40 * scale,
              decoration: BoxDecoration(
                color: _cardSurface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(31 * scale),
                border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.05),
                    blurRadius: 20 * scale,
                    offset: Offset(0, 8 * scale),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.70),
                    blurRadius: 10 * scale,
                    offset: Offset(0, -2 * scale),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                cursorColor: _primaryGreen,
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 14.2 * scale,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Ara…',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8C9690),
                    fontSize: 15.5 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      left: 14 * scale,
                      right: 7 * scale,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: _primaryGreen,
                      size: 21 * scale,
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 47 * scale,
                    minHeight: 40 * scale,
                  ),
                  contentPadding: EdgeInsets.only(
                    top: 12 * scale,
                    right: 18 * scale,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.scale, required this.horizontalInset});

  final double scale;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 24 * scale),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: _gold, size: 17 * scale),
          SizedBox(width: 9 * scale),
          Expanded(
            child: Text(
              'Esma-ül Hüsna',
              style: TextStyle(
                color: _primaryGreen,
                fontSize: 18.6 * scale,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          Text(
            '99 isim',
            style: TextStyle(
              color: _mutedText.withValues(alpha: 0.92),
              fontSize: 13.4 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EsmaCard extends StatelessWidget {
  const _EsmaCard({
    required this.item,
    required this.scale,
    required this.horizontalInset,
    required this.onTap,
  });

  final EsmaItem item;
  final double scale;
  final double horizontalInset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(27 * scale);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset + 19 * scale,
        0,
        horizontalInset + 19 * scale,
        10 * scale,
      ),
      child: _PressedScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: _cardSurface.withValues(alpha: 0.96),
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.055),
                    blurRadius: 23 * scale,
                    offset: Offset(0, 11 * scale),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.62),
                    blurRadius: 9 * scale,
                    offset: Offset(0, -2 * scale),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10 * scale,
                  9 * scale,
                  9 * scale,
                  9 * scale,
                ),
                child: Row(
                  children: [
                    _NumberBadge(number: item.number, scale: scale),
                    SizedBox(width: 11 * scale),
                    Expanded(
                      child: _EsmaTextBlock(item: item, scale: scale),
                    ),
                    SizedBox(width: 7 * scale),
                    SizedBox(
                      width: 84 * scale,
                      child: Text(
                        item.arabicText,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: _primaryGreen,
                          fontFamily: 'Amiri Quran',
                          fontSize: 22.8 * scale,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    ),
                    SizedBox(width: 7 * scale),
                    _ChevronButton(scale: scale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.scale});

  final int number;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33 * scale,
      height: 33 * scale,
      decoration: const BoxDecoration(color: _paleSage, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: _primaryGreen,
          fontSize: 12.7 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EsmaTextBlock extends StatelessWidget {
  const _EsmaTextBlock({required this.item, required this.scale});

  final EsmaItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryGreen,
            fontSize: 14.3 * scale,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          item.meaning,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _mutedText,
            fontSize: 10.2 * scale,
            fontWeight: FontWeight.w600,
            height: 1.12,
          ),
        ),
        SizedBox(height: 6 * scale),
        _CategoryPill(item: item, scale: scale),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.item, required this.scale});

  final EsmaItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.5 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      decoration: BoxDecoration(
        color: _paleSage.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(item.categoryIcon),
            color: _primaryGreen,
            size: 10.5 * scale,
          ),
          SizedBox(width: 4 * scale),
          Text(
            item.category,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 9.2 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(EsmaCategoryIcon icon) {
    return switch (icon) {
      EsmaCategoryIcon.heart => Icons.favorite_rounded,
      EsmaCategoryIcon.crown => Icons.workspace_premium_rounded,
      EsmaCategoryIcon.starOutline => Icons.star_outline_rounded,
      EsmaCategoryIcon.starFilled => Icons.star_rounded,
    };
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      decoration: BoxDecoration(
        color: _paleSage.withValues(alpha: 0.78),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: _primaryGreen,
        size: 20 * scale,
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
