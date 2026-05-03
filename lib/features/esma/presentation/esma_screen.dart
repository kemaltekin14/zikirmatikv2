import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/services/app_services.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../counter/application/counter_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../application/esma_audio_service.dart';
import '../data/esma_data.dart';
import '../domain/esma_item.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _mutedText = Color(0xFF69766E);
const _cardSurface = Color(0xFFFAFAF4);
const _paleSage = Color(0xFFE5ECE2);
const _gold = Color(0xFFCDAA3B);
const _softGold = Color(0xFFE9D798);
const _heroAsset = 'assets/images/esma-her2.webp';
const _heroSearchBackdropExtension = 20.0;
const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;
const _esmaCompactCardHeight = 198.0;
const _esmaExpandedCardHeight = 366.0;
const _esmaCardMotionDuration = Duration(milliseconds: 560);
const _esmaCardRevealDuration = Duration(milliseconds: 460);

const _categoryFilters = [
  'Rahmet',
  'Kudret',
  'Huzur',
  'Rızık',
  'Koruma',
  'Hikmet',
  'Celal',
  'Mülk',
  'Yaratılış',
];

String _analyticsText(String value) {
  return value.length > 100 ? value.substring(0, 100) : value;
}

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

String _normalizeSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll('á', 'a')
      .replaceAll('í', 'i')
      .replaceAll('ú', 'u')
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

class EsmaScreen extends ConsumerStatefulWidget {
  const EsmaScreen({super.key, this.initialExpandedNumber});

  final int? initialExpandedNumber;

  @override
  ConsumerState<EsmaScreen> createState() => _EsmaScreenState();
}

class _EsmaScreenState extends ConsumerState<EsmaScreen> {
  late final TextEditingController _searchController;
  late final EsmaAudioService _audioService;
  String _query = '';
  String? _selectedCategory;
  late int _expandedNumber;
  final Set<int> _favoriteNumbers = {};
  final Map<int, GlobalKey> _cardKeys = {};
  Timer? _searchAnalyticsDebounce;
  String? _lastLoggedSearchQuery;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _audioService = EsmaAudioService();
    _expandedNumber = _validInitialExpandedNumber(widget.initialExpandedNumber);
    if (widget.initialExpandedNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollExpandedCardIntoView(
          duration: const Duration(milliseconds: 520),
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant EsmaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialExpandedNumber != widget.initialExpandedNumber) {
      _expandedNumber = _validInitialExpandedNumber(
        widget.initialExpandedNumber,
      );
      if (widget.initialExpandedNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollExpandedCardIntoView(
            duration: const Duration(milliseconds: 520),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _searchAnalyticsDebounce?.cancel();
    unawaited(_audioService.dispose());
    _searchController.dispose();
    super.dispose();
  }

  List<EsmaItem> get _filteredItems {
    final normalizedQuery = _normalizeSearch(_query);
    return esmaItems.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        if (item.hasDisplayNumber) item.number.toString(),
        item.name,
        item.meaning,
        item.category,
        item.arabicText,
      ].map(_normalizeSearch).join(' ');
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  int _validInitialExpandedNumber(int? number) {
    final requested = number;
    if (requested != null &&
        esmaItems.any((item) => item.number == requested)) {
      return requested;
    }
    return esmaItems.first.number;
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
                    _EsmaTopSection(
                      scale: scale,
                      safeTop: media.padding.top,
                      contentWidth: contentWidth,
                      horizontalInset: horizontalInset,
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                          final visibleItems = _filteredItems;
                          if (visibleItems.isNotEmpty &&
                              !visibleItems.any(
                                (item) => item.number == _expandedNumber,
                              )) {
                            _expandedNumber = visibleItems.first.number;
                          }
                        });
                      },
                    ),
                    _EsmaMosaic(
                      items: _filteredItems,
                      scale: scale,
                      horizontalInset: horizontalInset,
                      expandedNumber: _expandedNumber,
                      favoriteNumbers: _favoriteNumbers,
                      cardKeys: _cardKeys,
                      onExpand: _expandEsma,
                      onFavorite: _toggleEsmaFavorite,
                      onListen: _listenEsma,
                      onStart: _startEsma,
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

  void _handleSearchChanged(String value) {
    setState(() {
      _query = value;
      final visibleItems = _filteredItems;
      if (visibleItems.isNotEmpty &&
          !visibleItems.any((item) => item.number == _expandedNumber)) {
        _expandedNumber = visibleItems.first.number;
      }
    });

    _searchAnalyticsDebounce?.cancel();
    final normalizedQuery = _normalizeSearch(value);
    if (normalizedQuery.length < 2) {
      return;
    }

    _searchAnalyticsDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _lastLoggedSearchQuery == normalizedQuery) return;
      final resultCount = _filteredItems.length;
      _lastLoggedSearchQuery = normalizedQuery;

      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logEvent(
              'search_used',
              parameters: {
                'source': 'esma',
                'query_length': value.trim().length,
                'has_results': resultCount > 0,
                'result_count': resultCount,
                'category': _analyticsText(_selectedCategory ?? 'all'),
              },
            ),
      );
    });
  }

  void _toggleEsmaFavorite(EsmaItem item) {
    final isAdding = !_favoriteNumbers.contains(item.number);
    setState(() {
      if (!_favoriteNumbers.add(item.number)) {
        _favoriteNumbers.remove(item.number);
      }
    });

    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logEvent(
            isAdding ? 'favorite_added' : 'favorite_removed',
            parameters: {
              'source': 'esma',
              'dhikr_id': 'esma-${item.number}',
              'dhikr_category': 'Esma-ul Husna',
              'esma_number': item.number,
              'is_builtin': true,
            },
          ),
    );
  }

  void _startEsma(EsmaItem item) {
    final feedback = ref.read(interactionFeedbackServiceProvider);
    ref.read(counterControllerProvider.notifier).startDhikr(item.toDhikr());
    context.push(AppRoutes.counter);
    feedback.primaryAction();
  }

  void _listenEsma(EsmaItem item) {
    ref.read(interactionFeedbackServiceProvider).selection();
    unawaited(_playEsmaAudio(item));
  }

  Future<void> _playEsmaAudio(EsmaItem item) async {
    try {
      await _audioService.play(item);
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logEvent(
              'esma_audio_played',
              parameters: {
                'esma_number': item.number,
                'dhikr_id': 'esma-${item.number}',
                'dhikr_category': 'Esma-ul Husna',
              },
            ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ses şu an çalınamadı.')));
    }
  }

  void _expandEsma(EsmaItem item) {
    setState(() => _expandedNumber = item.number);
    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (!mounted || _expandedNumber != item.number) return;
      _scrollExpandedCardIntoView(duration: const Duration(milliseconds: 520));
    });
  }

  void _scrollExpandedCardIntoView({required Duration duration}) {
    if (!mounted) return;
    final cardContext = _cardKeys[_expandedNumber]?.currentContext;
    if (cardContext == null || !cardContext.mounted) return;
    Scrollable.ensureVisible(
      cardContext,
      alignment: 0.08,
      duration: duration,
      curve: Curves.easeInOutCubic,
    );
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
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final double scale;
  final double safeTop;
  final double contentWidth;
  final double horizontalInset;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

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
            _SectionHeader(
              scale: scale,
              horizontalInset: horizontalInset,
              count: esmaItems.where((item) => item.hasDisplayNumber).length,
            ),
            SizedBox(height: 10 * scale),
            _EsmaFilterRail(
              scale: scale,
              horizontalInset: horizontalInset,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
            ),
            SizedBox(height: 14 * scale),
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
  const _SectionHeader({
    required this.scale,
    required this.horizontalInset,
    required this.count,
  });

  final double scale;
  final double horizontalInset;
  final int count;

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
              "Allah'ın 99 İsmi",
              style: TextStyle(
                color: _primaryGreen,
                fontSize: 18.6 * scale,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          Text(
            '$count isim',
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

class _EsmaFilterRail extends StatelessWidget {
  const _EsmaFilterRail({
    required this.scale,
    required this.horizontalInset,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final double scale;
  final double horizontalInset;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final options = <_EsmaFilterOption>[
      _EsmaFilterOption(
        label: 'Tümü',
        value: null,
        count: esmaItems.where((item) => item.hasDisplayNumber).length,
      ),
      ..._categoryFilters.map(
        (category) => _EsmaFilterOption(
          label: category,
          value: category,
          count: esmaItems
              .where(
                (item) => item.category == category && item.hasDisplayNumber,
              )
              .length,
        ),
      ),
    ];

    return SizedBox(
      height: 37 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
        itemCount: options.length,
        separatorBuilder: (_, _) => SizedBox(width: 8 * scale),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = option.value == selectedCategory;
          return _EsmaFilterChip(
            option: option,
            selected: selected,
            scale: scale,
            onTap: () => onCategorySelected(option.value),
          );
        },
      ),
    );
  }
}

class _EsmaFilterOption {
  const _EsmaFilterOption({
    required this.label,
    required this.value,
    required this.count,
  });

  final String label;
  final String? value;
  final int count;
}

class _EsmaFilterChip extends StatelessWidget {
  const _EsmaFilterChip({
    required this.option,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final _EsmaFilterOption option;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? const Color(0xFFF5E7B5) : _primaryGreen;
    final background = selected
        ? _primaryGreen
        : _cardSurface.withValues(alpha: 0.88);

    return _PressedScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24 * scale),
        child: InkWell(
          borderRadius: BorderRadius.circular(24 * scale),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 37 * scale,
            padding: EdgeInsets.only(left: 13 * scale, right: 8 * scale),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24 * scale),
              border: Border.all(
                color: selected
                    ? _softGold.withValues(alpha: 0.68)
                    : Colors.white.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(
                    alpha: selected ? 0.12 : 0.05,
                  ),
                  blurRadius: 18 * scale,
                  offset: Offset(0, 8 * scale),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12.2 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(width: 7 * scale),
                Container(
                  height: 21 * scale,
                  constraints: BoxConstraints(minWidth: 22 * scale),
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.13)
                        : _paleSage.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14 * scale),
                  ),
                  child: Text(
                    '${option.count}',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFF5E7B5)
                          : _primaryGreen.withValues(alpha: 0.82),
                      fontSize: 10.5 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
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

class _EsmaMosaic extends StatelessWidget {
  const _EsmaMosaic({
    required this.items,
    required this.scale,
    required this.horizontalInset,
    required this.expandedNumber,
    required this.favoriteNumbers,
    required this.cardKeys,
    required this.onExpand,
    required this.onFavorite,
    required this.onListen,
    required this.onStart,
  });

  final List<EsmaItem> items;
  final double scale;
  final double horizontalInset;
  final int expandedNumber;
  final Set<int> favoriteNumbers;
  final Map<int, GlobalKey> cardKeys;
  final ValueChanged<EsmaItem> onExpand;
  final ValueChanged<EsmaItem> onFavorite;
  final ValueChanged<EsmaItem> onListen;
  final ValueChanged<EsmaItem> onStart;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyEsmaState(scale: scale, horizontalInset: horizontalInset);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 10 * scale;
          final compactWidth = (constraints.maxWidth - gap) / 2;
          final fullWidth = constraints.maxWidth;
          final compactHeight = _esmaCompactCardHeight * scale;
          final expandedHeight = _esmaExpandedCardHeight * scale;
          final slots = _buildEsmaCardSlots(
            items: items,
            expandedNumber: expandedNumber,
            compactWidth: compactWidth,
            fullWidth: fullWidth,
            compactHeight: compactHeight,
            expandedHeight: expandedHeight,
            gap: gap,
          );
          final stackHeight = slots.isEmpty
              ? 0.0
              : slots.map((slot) => slot.top + slot.height).reduce(math.max);
          final paintedSlots = [
            ...slots.where((slot) => slot.item.number != expandedNumber),
            ...slots.where((slot) => slot.item.number == expandedNumber),
          ];

          return AnimatedSize(
            duration: _esmaCardMotionDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: stackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final slot in paintedSlots)
                    AnimatedPositioned(
                      key: ValueKey('esma-slot-${slot.item.number}'),
                      left: slot.left,
                      top: slot.top,
                      width: slot.width,
                      height: slot.height,
                      duration: _esmaCardMotionDuration,
                      curve: Curves.easeInOutCubic,
                      child: _EsmaCard(
                        key: cardKeys.putIfAbsent(
                          slot.item.number,
                          () =>
                              GlobalKey(debugLabel: 'esma.${slot.item.number}'),
                        ),
                        item: slot.item,
                        scale: scale,
                        expanded: slot.item.number == expandedNumber,
                        favorite: favoriteNumbers.contains(slot.item.number),
                        onExpand: () => onExpand(slot.item),
                        onFavorite: () => onFavorite(slot.item),
                        onListen: () => onListen(slot.item),
                        onStart: () => onStart(slot.item),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_EsmaCardSlot> _buildEsmaCardSlots({
    required List<EsmaItem> items,
    required int expandedNumber,
    required double compactWidth,
    required double fullWidth,
    required double compactHeight,
    required double expandedHeight,
    required double gap,
  }) {
    final slots = <_EsmaCardSlot>[];
    var top = 0.0;
    var column = 0;

    for (final item in items) {
      final expanded = item.number == expandedNumber;
      if (expanded) {
        if (column == 1) {
          top += compactHeight + gap;
          column = 0;
        }
        slots.add(
          _EsmaCardSlot(
            item: item,
            left: 0,
            top: top,
            width: fullWidth,
            height: expandedHeight,
          ),
        );
        top += expandedHeight + gap;
        continue;
      }

      final left = column == 0 ? 0.0 : compactWidth + gap;
      slots.add(
        _EsmaCardSlot(
          item: item,
          left: left,
          top: top,
          width: compactWidth,
          height: compactHeight,
        ),
      );

      if (column == 0) {
        column = 1;
      } else {
        top += compactHeight + gap;
        column = 0;
      }
    }

    return slots;
  }
}

class _EsmaCardSlot {
  const _EsmaCardSlot({
    required this.item,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final EsmaItem item;
  final double left;
  final double top;
  final double width;
  final double height;
}

class _EmptyEsmaState extends StatelessWidget {
  const _EmptyEsmaState({required this.scale, required this.horizontalInset});

  final double scale;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset + 19 * scale,
        4 * scale,
        horizontalInset + 19 * scale,
        0,
      ),
      child: Container(
        padding: EdgeInsets.all(22 * scale),
        decoration: BoxDecoration(
          color: _cardSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(27 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: _primaryGreen,
              size: 26 * scale,
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                'Bu aramada eşleşen Esma bulunamadı.',
                style: TextStyle(
                  color: _primaryGreen.withValues(alpha: 0.82),
                  fontSize: 13.8 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EsmaCard extends StatefulWidget {
  const _EsmaCard({
    super.key,
    required this.item,
    required this.scale,
    required this.expanded,
    required this.favorite,
    required this.onExpand,
    required this.onFavorite,
    required this.onListen,
    required this.onStart,
  });

  final EsmaItem item;
  final double scale;
  final bool expanded;
  final bool favorite;
  final VoidCallback onExpand;
  final VoidCallback onFavorite;
  final VoidCallback onListen;
  final VoidCallback onStart;

  @override
  State<_EsmaCard> createState() => _EsmaCardState();
}

class _EsmaCardState extends State<_EsmaCard> {
  var _showExpandedDetails = false;
  var _revealToken = 0;

  @override
  void initState() {
    super.initState();
    _showExpandedDetails = widget.expanded;
  }

  @override
  void didUpdateWidget(covariant _EsmaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == oldWidget.expanded) return;

    _revealToken++;
    final token = _revealToken;
    if (!widget.expanded) {
      if (_showExpandedDetails) {
        setState(() => _showExpandedDetails = false);
      }
      return;
    }

    if (_showExpandedDetails) {
      setState(() => _showExpandedDetails = false);
    }
    Future<void>.delayed(_esmaCardMotionDuration, () {
      if (!mounted || token != _revealToken || !widget.expanded) return;
      setState(() => _showExpandedDetails = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      (widget.expanded ? 31 : 24) * widget.scale,
    );
    final cardChild = _showExpandedDetails
        ? KeyedSubtree(
            key: ValueKey('expanded-${widget.item.number}'),
            child: _ExpandedEsmaCardContent(
              item: widget.item,
              scale: widget.scale,
              favorite: widget.favorite,
              onFavorite: widget.onFavorite,
              onListen: widget.onListen,
              onStart: widget.onStart,
            ),
          )
        : KeyedSubtree(
            key: ValueKey('compact-${widget.item.number}'),
            child: _CompactEsmaCardContent(
              item: widget.item,
              scale: widget.scale,
              favorite: widget.favorite,
              onFavorite: widget.onFavorite,
            ),
          );

    return _PressedScale(
      enabled: !widget.expanded,
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: _esmaCardMotionDuration,
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: _cardSurface.withValues(
              alpha: widget.expanded ? 0.98 : 0.95,
            ),
            borderRadius: radius,
            border: Border.all(
              color: widget.expanded
                  ? _softGold.withValues(alpha: 0.64)
                  : Colors.white.withValues(alpha: 0.68),
              width: widget.expanded ? 1.25 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(
                  alpha: widget.expanded ? 0.12 : 0.06,
                ),
                blurRadius: (widget.expanded ? 34 : 22) * widget.scale,
                offset: Offset(0, (widget.expanded ? 16 : 10) * widget.scale),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.68),
                blurRadius: 10 * widget.scale,
                offset: Offset(0, -2 * widget.scale),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.expanded ? null : widget.onExpand,
              child: AnimatedSwitcher(
                duration: _showExpandedDetails
                    ? _esmaCardRevealDuration
                    : Duration.zero,
                reverseDuration: Duration.zero,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      for (final child in previousChildren)
                        Positioned.fill(child: child),
                      if (currentChild != null)
                        Positioned.fill(child: currentChild),
                    ],
                  );
                },
                child: cardChild,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactEsmaCardContent extends StatelessWidget {
  const _CompactEsmaCardContent({
    required this.item,
    required this.scale,
    required this.favorite,
    required this.onFavorite,
  });

  final EsmaItem item;
  final double scale;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _esmaCompactCardHeight * scale,
      child: Stack(
        children: [
          Positioned(
            right: -14 * scale,
            bottom: -10 * scale,
            child: _SoftEsmaGlow(size: 78 * scale, opacity: 0.32),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12 * scale,
              11 * scale,
              11 * scale,
              12 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _EsmaIdentityBadge(item: item, scale: scale),
                    const Spacer(),
                    _FavoriteButton(
                      scale: scale,
                      favorite: favorite,
                      onTap: onFavorite,
                    ),
                  ],
                ),
                SizedBox(height: 8 * scale),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 15.4 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      item.meaning,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 12.1 * scale,
                        fontWeight: FontWeight.w600,
                        height: 1.12,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5 * scale),
                SizedBox(
                  height: 44 * scale,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 6,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CategoryPill(item: item, scale: scale),
                        ),
                      ),
                      SizedBox(width: 5 * scale),
                      Flexible(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 4 * scale),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                item.arabicText,
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: _primaryGreen,
                                  fontFamily: 'Amiri Quran',
                                  fontSize: 21.5 * scale,
                                  fontWeight: FontWeight.w500,
                                  height: 1.36,
                                ),
                              ),
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
        ],
      ),
    );
  }
}

class _ExpandedEsmaCardContent extends StatelessWidget {
  const _ExpandedEsmaCardContent({
    required this.item,
    required this.scale,
    required this.favorite,
    required this.onFavorite,
    required this.onListen,
    required this.onStart,
  });

  final EsmaItem item;
  final double scale;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onListen;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -30 * scale,
          top: -28 * scale,
          child: _SoftEsmaGlow(size: 182 * scale, opacity: 0.36, warm: true),
        ),
        Positioned(
          left: -44 * scale,
          bottom: -52 * scale,
          child: _SoftEsmaGlow(size: 138 * scale, opacity: 0.30),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            17 * scale,
            16 * scale,
            17 * scale,
            16 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EsmaIdentityBadge(
                    item: item,
                    scale: scale,
                    highlighted: true,
                    size: 42,
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryGreen,
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        _CategoryPill(
                          item: item,
                          scale: scale,
                          prominent: true,
                        ),
                      ],
                    ),
                  ),
                  _FavoriteButton(
                    scale: scale,
                    favorite: favorite,
                    onTap: onFavorite,
                    large: true,
                  ),
                ],
              ),
              SizedBox(height: 12 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.meaning,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryGreen.withValues(alpha: 0.86),
                            fontSize: 14.8 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                          ),
                        ),
                        SizedBox(height: 11 * scale),
                        Container(
                          height: 1,
                          width: 128 * scale,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _gold.withValues(alpha: 0.0),
                                _gold.withValues(alpha: 0.52),
                                _gold.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        Text(
                          _expandedExplanationCopy(item),
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedText.withValues(alpha: 0.92),
                            fontSize: 12.4 * scale,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  Transform.translate(
                    offset: Offset(0, -12 * scale),
                    child: _ExpandedEsmaArabicSeal(
                      item: item,
                      scale: scale,
                      size: 124 * scale,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8 * scale,
                    runSpacing: 8 * scale,
                    children: [
                      _EsmaActionPill(
                        scale: scale,
                        icon: Icons.volume_up_rounded,
                        label: 'Dinle',
                        backgroundColor: _paleSage.withValues(alpha: 0.78),
                        foregroundColor: _primaryGreen,
                        borderColor: Colors.white.withValues(alpha: 0.62),
                        onTap: onListen,
                      ),
                      _EsmaActionPill(
                        scale: scale,
                        icon: Icons.spa_rounded,
                        label: 'Ebced sayısı: ${item.ebcedNumber}',
                        backgroundColor: _softGold.withValues(alpha: 0.46),
                        foregroundColor: const Color(0xFF7B6421),
                        borderColor: _gold.withValues(alpha: 0.22),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * scale),
                  _EsmaPrimaryActionButton(scale: scale, onTap: onStart),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _expandedExplanationCopy(EsmaItem item) {
    final explanation = item.explanation?.trim();
    if (explanation != null && explanation.isNotEmpty) return explanation;

    final tone = switch (item.category) {
      'Rahmet' => 'rahmeti ve yakınlığı',
      'Kudret' => 'gücü ve teslimiyeti',
      'Huzur' => 'sükûneti ve güveni',
      'Rızık' => 'bolluğu ve kapıların açılışını',
      'Koruma' => 'emanı ve korunmayı',
      'Hikmet' => 'idrakı ve doğru yönelişi',
      'Celal' => 'azamet karşısında tevazuyu',
      'Mülk' => 'mülkün gerçek sahibini',
      'Yaratılış' => 'varlığın ölçüsünü ve güzelliğini',
      _ => 'kalpte derin bir hatırlayışı',
    };
    return 'Bu isim zikredilirken kalp $tone hatırlar.';
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.scale,
    required this.favorite,
    required this.onTap,
    this.large = false,
  });

  final double scale;
  final bool favorite;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = (large ? 36 : 30) * scale;
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: favorite
                  ? _gold.withValues(alpha: 0.16)
                  : _paleSage.withValues(alpha: 0.48),
              shape: BoxShape.circle,
            ),
            child: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? _gold : _primaryGreen,
              size: (large ? 18 : 15.5) * scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _EsmaActionPill extends StatelessWidget {
  const _EsmaActionPill({
    required this.scale,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.onTap,
  });

  final double scale;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20 * scale);
    final content = Container(
      height: 34 * scale,
      padding: EdgeInsets.symmetric(horizontal: 11 * scale),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor, size: 15 * scale),
          SizedBox(width: 6 * scale),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11.2 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}

class _EsmaPrimaryActionButton extends StatelessWidget {
  const _EsmaPrimaryActionButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(24 * scale),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 46 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale),
          decoration: BoxDecoration(
            color: _buttonGreen,
            borderRadius: BorderRadius.circular(24 * scale),
            boxShadow: [
              BoxShadow(
                color: _buttonGreen.withValues(alpha: 0.24),
                blurRadius: 18 * scale,
                offset: Offset(0, 9 * scale),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: const Color(0xFFFFF5D4),
                size: 21 * scale,
              ),
              SizedBox(width: 8 * scale),
              Text(
                'Zikre Başla',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.4 * scale,
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

class _ExpandedEsmaArabicSeal extends StatelessWidget {
  const _ExpandedEsmaArabicSeal({
    required this.item,
    required this.scale,
    required this.size,
  });

  final EsmaItem item;
  final double scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size * 0.90,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _softGold.withValues(alpha: 0.13),
                    _paleSage.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.54, 1.0],
                ),
              ),
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _ExpandedEsmaSealPainter(strokeWidth: 2.4 * scale),
          ),
          SizedBox(
            width: size * 0.68,
            height: size * 0.36,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, -11 * scale),
                  child: Text(
                    item.arabicText,
                    maxLines: 1,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontFamily: 'Amiri Quran',
                      fontSize: 39 * scale,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
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

class _ExpandedEsmaSealPainter extends CustomPainter {
  const _ExpandedEsmaSealPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.47;

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.22),
          _paleSage.withValues(alpha: 0.22),
          _softGold.withValues(alpha: 0.06),
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.86))
      ..style = PaintingStyle.fill;

    final path = Path();
    const points = 24;
    for (var i = 0; i < points; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / points);
      final pointRadius = radius * (i.isEven ? 0.92 : 0.80);
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final outlinePaint = Paint()
      ..color = const Color(0xFFC4D4C0).withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final outlineHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, strokeWidth * 0.30)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius * 0.76, fillPaint);
    canvas.drawPath(path, outlinePaint);
    canvas.drawPath(path, outlineHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant _ExpandedEsmaSealPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
}

class _SoftEsmaGlow extends StatelessWidget {
  const _SoftEsmaGlow({
    required this.size,
    required this.opacity,
    this.warm = false,
  });

  final double size;
  final double opacity;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final core = warm ? _softGold : _paleSage;
    final ring = warm ? _gold : _primaryGreen;

    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                core.withValues(alpha: 0.32 * opacity),
                core.withValues(alpha: 0.18 * opacity),
                ring.withValues(alpha: 0.045 * opacity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.46, 0.72, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _EsmaIdentityBadge extends StatelessWidget {
  const _EsmaIdentityBadge({
    required this.item,
    required this.scale,
    this.highlighted = false,
    this.size = 33,
  });

  final EsmaItem item;
  final double scale;
  final bool highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasNumber = item.hasDisplayNumber;
    return Container(
      width: size * scale,
      height: size * scale,
      decoration: BoxDecoration(
        color: highlighted ? _primaryGreen : _paleSage,
        shape: BoxShape.circle,
        border: highlighted
            ? Border.all(color: _softGold.withValues(alpha: 0.78), width: 1.2)
            : null,
      ),
      alignment: Alignment.center,
      child: hasNumber
          ? Text(
              '${item.number}',
              style: TextStyle(
                color: highlighted ? const Color(0xFFF4E8B8) : _primaryGreen,
                fontSize: (highlighted ? 14.2 : 12.7) * scale,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(
              Icons.auto_awesome_rounded,
              color: highlighted ? const Color(0xFFF4E8B8) : _primaryGreen,
              size: (highlighted ? 18 : 15) * scale,
            ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.item,
    required this.scale,
    this.prominent = false,
  });

  final EsmaItem item;
  final double scale;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (prominent ? 23 : 22) * scale,
      padding: EdgeInsets.symmetric(horizontal: (prominent ? 10 : 9.5) * scale),
      decoration: BoxDecoration(
        color: prominent
            ? _softGold.withValues(alpha: 0.22)
            : _paleSage.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(15 * scale),
        border: prominent
            ? Border.all(color: _gold.withValues(alpha: 0.18))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(item.categoryIcon),
            color: _primaryGreen,
            size: (prominent ? 12.5 : 12.2) * scale,
          ),
          SizedBox(width: (prominent ? 4 : 4.5) * scale),
          Text(
            item.category,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: (prominent ? 10.6 : 10.8) * scale,
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
      EsmaCategoryIcon.star => Icons.star_rounded,
      EsmaCategoryIcon.leaf => Icons.eco_rounded,
      EsmaCategoryIcon.shield => Icons.shield_rounded,
      EsmaCategoryIcon.balance => Icons.balance_rounded,
      EsmaCategoryIcon.spark => Icons.auto_awesome_rounded,
    };
  }
}

class _PressedScale extends StatefulWidget {
  const _PressedScale({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<_PressedScale> createState() => _PressedScaleState();
}

class _PressedScaleState extends State<_PressedScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

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
