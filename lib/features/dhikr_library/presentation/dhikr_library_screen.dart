import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_services.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/application/settings_controller.dart';
import '../application/dhikr_providers.dart';
import '../domain/dhikr_item.dart';
import 'dhikr_detail_screen.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _libraryHeroEdgeCream = Color(0xFFF6F3EE);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _mutedGreen = Color(0xFF7F9E88);
const _cardBackground = Color(0xFFFAFAF4);
const _primaryText = Color(0xFF123B2B);
const _secondaryText = Color(0xFF69766E);
const _libraryCardBodyText = Color(0xFF52695F);
const _gold = Color(0xFFD4BA75);

const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;
const _favoritePreviewLimit = 3;

const _dhikrLibraryHeroAsset = 'assets/images/zikir-hero.webp';
const _allCategory = 'Tümü';
const _favoriteCategory = 'Favoriler';
const _detailSheetTransitionDuration = Duration(milliseconds: 420);
const _libraryCategoryOrder = [
  'Tesbih',
  'Tevhid',
  'İstiğfar',
  'Korunma',
  'Esma-ül Hüsna',
];
const _customDhikrCategories = ['Özel', ..._libraryCategoryOrder];

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

String _analyticsText(String value) {
  return value.length > 100 ? value.substring(0, 100) : value;
}

class DhikrLibraryScreen extends ConsumerStatefulWidget {
  const DhikrLibraryScreen({super.key});

  @override
  ConsumerState<DhikrLibraryScreen> createState() => _DhikrLibraryScreenState();
}

class _DhikrLibraryScreenState extends ConsumerState<DhikrLibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = _allCategory;
  Timer? _searchAnalyticsDebounce;
  String? _lastLoggedSearchQuery;

  @override
  void dispose() {
    _searchAnalyticsDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
    final scrollBottomPadding =
        bottomReservedHeight + _scrollExtraBottomSpacing * scale;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.14).toDouble();
    final dhikrs = ref.watch(dhikrItemsProvider);

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
                child: CustomPaint(painter: _LibraryWashPainter()),
              ),
              Positioned.fill(
                bottom: bottomReservedHeight,
                child: dhikrs.when(
                  data: (items) {
                    final categories = _categoriesFor(items);
                    final selectedCategory = categories.contains(_category)
                        ? _category
                        : _allCategory;
                    final filtered = _filterDhikrs(
                      items,
                      query: _query,
                      category: selectedCategory,
                    );
                    final isAllCategory = selectedCategory == _allCategory;
                    final showFavoriteSection =
                        isAllCategory && _query.trim().isEmpty;
                    final favoriteItems = showFavoriteSection
                        ? filtered.where((item) => item.isFavorite).toList()
                        : const <DhikrItem>[];
                    final favoritePreviewItems = favoriteItems
                        .take(_favoritePreviewLimit)
                        .toList(growable: false);
                    final hasMoreFavorites =
                        favoriteItems.length > _favoritePreviewLimit;
                    final categorySections = isAllCategory
                        ? _groupDhikrsByCategory(
                            filtered,
                            categories: categories,
                          )
                        : const <_DhikrCategorySection>[];

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: 0,
                        bottom: scrollBottomPadding,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LibraryTopCluster(
                                scale: scale,
                                topInset: media.padding.top,
                                controller: _searchController,
                                query: _query,
                                onChanged: _handleSearchChanged,
                                onClear: _query.isEmpty
                                    ? null
                                    : () {
                                        _searchAnalyticsDebounce?.cancel();
                                        _lastLoggedSearchQuery = null;
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                onAdd: () {
                                  ref
                                      .read(interactionFeedbackServiceProvider)
                                      .primaryAction();
                                  _showAddDhikrSheet(scale);
                                },
                                categories: categories,
                                selectedCategory: selectedCategory,
                                onSelected: (category) =>
                                    setState(() => _category = category),
                              ),
                              if (filtered.isEmpty)
                                _EmptyLibraryState(
                                  scale: scale,
                                  query: _query,
                                  onReset: () {
                                    _searchController.clear();
                                    setState(() {
                                      _query = '';
                                      _category = _allCategory;
                                    });
                                  },
                                )
                              else ...[
                                if (favoriteItems.isNotEmpty) ...[
                                  _LibraryListSection(
                                    scale: scale,
                                    title: 'Favoriler',
                                    leadingIcon: Icons.star_rounded,
                                    leadingColor: const Color(0xFFC39B32),
                                    detail: '${favoriteItems.length} kayıt',
                                    actionLabel: hasMoreFavorites
                                        ? 'Tümünü Gör'
                                        : null,
                                    onAction: hasMoreFavorites
                                        ? () => _showAllFavoritesSheet(
                                            scale,
                                            favoriteItems,
                                          )
                                        : null,
                                    cardKeyPrefix: 'dhikr.favorite.card',
                                    items: favoritePreviewItems,
                                    onOpen: _openDhikrDetail,
                                  ),
                                  SizedBox(height: 14 * scale),
                                ],
                                if (isAllCategory)
                                  for (
                                    var index = 0;
                                    index < categorySections.length;
                                    index++
                                  ) ...[
                                    _LibraryListSection(
                                      scale: scale,
                                      title: categorySections[index].title,
                                      leadingIcon: _categoryIcon(
                                        categorySections[index].title,
                                      ),
                                      leadingColor: _buttonGreen,
                                      detail:
                                          '${categorySections[index].items.length} kayıt',
                                      cardKeyPrefix:
                                          'dhikr.category.${_normalize(categorySections[index].title)}.card',
                                      items: categorySections[index].items,
                                      onOpen: _openDhikrDetail,
                                    ),
                                    if (index != categorySections.length - 1)
                                      SizedBox(height: 14 * scale),
                                  ]
                                else
                                  _LibraryListSection(
                                    scale: scale,
                                    title: selectedCategory,
                                    leadingIcon: _categoryIcon(
                                      selectedCategory,
                                    ),
                                    leadingColor: _buttonGreen,
                                    detail: '${filtered.length} kayıt',
                                    items: filtered,
                                    onOpen: _openDhikrDetail,
                                  ),
                                if (isAllCategory &&
                                    categorySections.isEmpty &&
                                    favoriteItems.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18 * scale,
                                    ),
                                    child: _EmptyLibraryState(
                                      scale: scale,
                                      query: '',
                                      onReset: () => setState(
                                        () => _category = _allCategory,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  error: (error, stackTrace) => _LibraryLoadState(
                    scale: scale,
                    icon: Icons.error_outline_rounded,
                    title: 'Zikirler yüklenemedi',
                    message: '$error',
                  ),
                  loading: () => _LibraryLoadState(
                    scale: scale,
                    icon: Icons.menu_book_rounded,
                    title: 'Zikirler hazırlanıyor',
                    message: 'Kütüphane birazdan açılacak.',
                    loading: true,
                  ),
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.dhikrLibrary,
                quickStartKey: const Key('library.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSearchChanged(String value) {
    setState(() => _query = value);
    _searchAnalyticsDebounce?.cancel();

    final normalizedQuery = _normalize(value);
    if (normalizedQuery.length < 2) {
      return;
    }

    _searchAnalyticsDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _lastLoggedSearchQuery == normalizedQuery) return;

      final items = ref
          .read(dhikrItemsProvider)
          .maybeWhen(data: (items) => items, orElse: () => const <DhikrItem>[]);
      final resultCount = _filterDhikrs(
        items,
        query: value,
        category: _category,
      ).length;
      _lastLoggedSearchQuery = normalizedQuery;

      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logEvent(
              'search_used',
              parameters: {
                'source': 'dhikr_library',
                'query_length': value.trim().length,
                'has_results': resultCount > 0,
                'result_count': resultCount,
                'category': _analyticsText(_category),
              },
            ),
      );
    });
  }

  Future<void> _openDhikrDetail(DhikrItem item) async {
    ref.read(interactionFeedbackServiceProvider).selection();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zikir detayını kapat',
      barrierColor: Colors.transparent,
      transitionDuration: _detailSheetTransitionDuration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final media = MediaQuery.of(dialogContext);
        final scale = proportionalLayoutScaleFor(media.size.width);
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: FadeTransition(
                    opacity: curved,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curved),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: media.size.height * 0.92,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28 * scale),
                          ),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.55),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.55),
                              blurRadius: 1 * scale,
                              offset: Offset(0, -0.5 * scale),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(27 * scale),
                          ),
                          child: DhikrDetailScreen(
                            dhikrId: item.id,
                            sheetMode: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAllFavoritesSheet(
    double scale,
    List<DhikrItem> fallbackItems,
  ) async {
    ref.read(interactionFeedbackServiceProvider).selection();
    final selectedItem = await showModalBottomSheet<DhikrItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (sheetContext) {
        return _AllFavoritesSheet(scale: scale, fallbackItems: fallbackItems);
      },
    );

    if (selectedItem == null || !mounted) return;
    await _openDhikrDetail(selectedItem);
  }

  Future<void> _showAddDhikrSheet(double scale) async {
    final draft = await showModalBottomSheet<_CustomDhikrDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (sheetContext) {
        return _CustomDhikrSheet(scale: scale);
      },
    );

    if (draft == null) return;

    await ref
        .read(dhikrRepositoryProvider)
        .addCustomDhikr(
          name: draft.name,
          category: draft.category,
          defaultTarget: draft.target,
          arabicText: draft.arabicText,
          meaning: draft.meaning,
        );

    if (!mounted) return;
    ref.read(interactionFeedbackServiceProvider).primaryAction();
    setState(() {
      _category = draft.category;
      _query = '';
      _searchController.clear();
    });
  }

  // ignore: unused_element
  Future<void> _showFilterSheet(
    double scale,
    List<String> categories,
    String selectedCategory,
  ) async {
    ref.read(interactionFeedbackServiceProvider).selection();
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      builder: (sheetContext) {
        return _LibraryFilterSheet(
          scale: scale,
          categories: categories,
          selectedCategory: selectedCategory,
          onAddCustom: () {
            Navigator.of(sheetContext).pop();
            _showAddDhikrSheet(scale);
          },
        );
      },
    );

    if (selection == null || !mounted) return;
    setState(() => _category = selection);
  }
}

class _LibraryTopCluster extends StatelessWidget {
  const _LibraryTopCluster({
    required this.scale,
    required this.topInset,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onAdd,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final double scale;
  final double topInset;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback onAdd;
  final List<String> categories;
  final String selectedCategory;
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
          child: const _LibraryTopClusterBackground(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LibraryHero(
              scale: scale,
              topInset: topInset,
              controller: controller,
              query: query,
              onChanged: onChanged,
              onClear: onClear,
              onAdd: onAdd,
            ),
            SizedBox(height: 16 * scale),
            _CategoryFilter(
              scale: scale,
              categories: categories,
              selectedCategory: selectedCategory,
              onSelected: onSelected,
            ),
            SizedBox(height: 4 * scale),
          ],
        ),
      ],
    );
  }
}

class _LibraryTopClusterBackground extends StatelessWidget {
  const _LibraryTopClusterBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF7), Color(0xFFFFFCF7), _pageBackground],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
    );
  }
}

class _LibraryHeroAssetEdgeFill extends StatelessWidget {
  const _LibraryHeroAssetEdgeFill();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _libraryHeroEdgeCream,
            Color(0xFFF4F1ED),
            Color(0xFFF0EFE7),
            Color(0x00E9EEE4),
          ],
          stops: [0.0, 0.56, 0.78, 1.0],
        ),
      ),
    );
  }
}

class _LibraryHeroBookWash extends StatelessWidget {
  const _LibraryHeroBookWash();

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

class _LibraryHero extends StatelessWidget {
  const _LibraryHero({
    required this.scale,
    required this.topInset,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onAdd,
  });

  final double scale;
  final double topInset;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const heroAssetBaseWidth = appLayoutBaselineWidth;
    const heroAssetVisualScale = 0.90;
    final heroLayoutHeight = topInset + 150 * scale;
    final heroImageLeftEdge =
        appLayoutBaselineWidth * (1 - heroAssetVisualScale) * scale;

    return SizedBox(
      height: heroLayoutHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: heroImageLeftEdge + 4 * scale,
            height: heroLayoutHeight + 46 * scale,
            child: const _LibraryHeroAssetEdgeFill(),
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
                    _dhikrLibraryHeroAsset,
                    width: heroAssetBaseWidth,
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 112 * scale,
            right: 0,
            top: topInset + 32 * scale,
            height: 86 * scale,
            child: const IgnorePointer(child: _LibraryHeroBookWash()),
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
                  'Zikir Kütüphanesi',
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
                  padding: EdgeInsets.only(right: 60 * scale),
                  child: Text(
                    'Gönlü huzura erdiren, kalbi aydınlatan zikirleri keşfet.',
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
          Positioned(
            left: 18 * scale,
            right: 18 * scale,
            top: topInset + 114 * scale,
            child: Row(
              children: [
                Expanded(
                  child: _HeroSearchField(
                    scale: scale,
                    controller: controller,
                    query: query,
                    onChanged: onChanged,
                    onClear: onClear,
                  ),
                ),
                SizedBox(width: 9 * scale),
                _HeroAddButton(scale: scale, onPressed: onAdd),
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

class _HeroSearchField extends StatelessWidget {
  const _HeroSearchField({
    required this.scale,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final double scale;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40 * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardBackground.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20 * scale),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.80),
            width: 0.8 * scale,
          ),
          boxShadow: _softShadow(scale),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            color: _primaryText,
            fontSize: 12.2 * scale,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Ara...',
            hintStyle: TextStyle(
              color: _secondaryText.withValues(alpha: 0.72),
              fontSize: 12.2 * scale,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _primaryGreen,
              size: 17 * scale,
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    icon: Icon(
                      Icons.close_rounded,
                      color: _secondaryText,
                      size: 15.5 * scale,
                    ),
                    onPressed: onClear,
                  ),
            contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
          ),
        ),
      ),
    );
  }
}

class _HeroAddButton extends StatelessWidget {
  const _HeroAddButton({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40 * scale,
      child: Material(
        color: _buttonGreen,
        borderRadius: BorderRadius.circular(20 * scale),
        child: InkWell(
          key: const Key('dhikr.addCustom'),
          borderRadius: BorderRadius.circular(20 * scale),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.5 * scale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+ Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.6 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: 0,
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

class _LibraryFilterSheet extends StatelessWidget {
  const _LibraryFilterSheet({
    required this.scale,
    required this.categories,
    required this.selectedCategory,
    required this.onAddCustom,
  });

  final double scale;
  final List<String> categories;
  final String selectedCategory;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 16 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(24 * scale),
          boxShadow: _softShadow(scale),
        ),
        child: Padding(
          padding: EdgeInsets.all(18 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrele',
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: _secondaryText,
                      size: 20 * scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * scale),
              Wrap(
                spacing: 8 * scale,
                runSpacing: 8 * scale,
                children: [
                  for (final category in categories)
                    _FilterSheetChip(
                      scale: scale,
                      label: category,
                      selected: category == selectedCategory,
                      onTap: () => Navigator.of(context).pop(category),
                    ),
                ],
              ),
              SizedBox(height: 16 * scale),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddCustom,
                  icon: Icon(Icons.add_rounded, size: 18 * scale),
                  label: const Text('Özel zikir ekle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: BorderSide(
                      color: _primaryGreen.withValues(alpha: 0.18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18 * scale),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12 * scale),
                    textStyle: TextStyle(
                      fontSize: 12.6 * scale,
                      fontWeight: FontWeight.w800,
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

class _FilterSheetChip extends StatelessWidget {
  const _FilterSheetChip({
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
      color: selected ? _buttonGreen : _primaryGreen.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 8 * scale,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _primaryText,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.scale,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final double scale;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48 * scale,
      child: ListView.separated(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18 * scale),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 38 * scale,
              child: _CategoryPill(
                scale: scale,
                label: category,
                selected: category == selectedCategory,
                onTap: () => onSelected(category),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: 8 * scale),
        itemCount: categories.length,
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
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
              if (label == _favoriteCategory) ...[
                Icon(Icons.star_rounded, color: foreground, size: 15 * scale),
                SizedBox(width: 5 * scale),
              ],
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

class _LibraryListSection extends StatelessWidget {
  const _LibraryListSection({
    required this.scale,
    required this.title,
    required this.detail,
    required this.items,
    required this.onOpen,
    this.leadingIcon,
    this.leadingColor,
    this.actionLabel,
    this.onAction,
    this.cardKeyPrefix = 'dhikr.card',
  });

  final double scale;
  final String title;
  final String detail;
  final List<DhikrItem> items;
  final ValueChanged<DhikrItem> onOpen;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String cardKeyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LibrarySectionHeader(
          scale: scale,
          title: title,
          detail: detail,
          leadingIcon: leadingIcon,
          leadingColor: leadingColor,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        SizedBox(height: 10 * scale),
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(
              left: 18 * scale,
              right: 18 * scale,
              bottom: 9 * scale,
            ),
            child: _DhikrLibraryCard(
              scale: scale,
              item: item,
              keyPrefix: cardKeyPrefix,
              onOpen: () => onOpen(item),
            ),
          ),
      ],
    );
  }
}

class _AllFavoritesSheet extends ConsumerWidget {
  const _AllFavoritesSheet({required this.scale, required this.fallbackItems});

  final double scale;
  final List<DhikrItem> fallbackItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dhikrs = ref.watch(dhikrItemsProvider);
    final favoriteItems = dhikrs.maybeWhen(
      data: (items) => items.where((item) => item.isFavorite).toList(),
      orElse: () => fallbackItems,
    );
    final sheetRadius = BorderRadius.vertical(top: Radius.circular(30 * scale));
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 16 * scale;
    final initialSize = favoriteItems.length > 5 ? 0.82 : 0.62;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: 0.42,
        maxChildSize: 0.90,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: sheetRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _pageBackground,
                borderRadius: sheetRadius,
              ),
              child: ListView(
                key: const Key('dhikr.favoriteSheet'),
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  18 * scale,
                  12 * scale,
                  18 * scale,
                  bottomPadding,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 42 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: _secondaryText.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 17 * scale),
                  _AllFavoritesSheetHeader(
                    scale: scale,
                    count: favoriteItems.length,
                  ),
                  SizedBox(height: 14 * scale),
                  if (favoriteItems.isEmpty)
                    _FavoriteSheetEmpty(scale: scale)
                  else
                    for (final item in favoriteItems)
                      Padding(
                        padding: EdgeInsets.only(bottom: 9 * scale),
                        child: _DhikrLibraryCard(
                          scale: scale,
                          item: item,
                          keyPrefix: 'dhikr.favoriteSheet.card',
                          onOpen: () => Navigator.of(context).pop(item),
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
}

class _AllFavoritesSheetHeader extends StatelessWidget {
  const _AllFavoritesSheetHeader({required this.scale, required this.count});

  final double scale;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: _gold.withValues(alpha: 0.38),
              width: 0.8 * scale,
            ),
          ),
          child: SizedBox.square(
            dimension: 45 * scale,
            child: Icon(
              Icons.star_rounded,
              color: const Color(0xFFC39B32),
              size: 22 * scale,
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tüm Favoriler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 21 * scale,
                  fontWeight: FontWeight.w800,
                  height: 1.06,
                ),
              ),
              SizedBox(height: 5 * scale),
              Text(
                'Kalbine yakın tuttuğun zikirler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 12.2 * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10 * scale),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(14 * scale),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.66),
              width: 0.7 * scale,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 7 * scale,
            ),
            child: Text(
              '$count kayıt',
              style: TextStyle(
                color: _libraryCardBodyText,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteSheetEmpty extends StatelessWidget {
  const _FavoriteSheetEmpty({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: _softShadow(scale),
      ),
      child: Padding(
        padding: EdgeInsets.all(18 * scale),
        child: Column(
          children: [
            Icon(
              Icons.star_border_rounded,
              color: _mutedGreen,
              size: 42 * scale,
            ),
            SizedBox(height: 9 * scale),
            Text(
              'Favori zikir yok',
              style: TextStyle(
                color: _primaryText,
                fontSize: 16.5 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              'Beğendiğin zikirler burada saklanır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySectionHeader extends StatelessWidget {
  const _LibrarySectionHeader({
    required this.scale,
    required this.title,
    required this.detail,
    this.leadingIcon,
    this.leadingColor,
    this.actionLabel,
    this.onAction,
  });

  final double scale;
  final String title;
  final String detail;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22 * scale),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color: leadingColor ?? _mutedGreen,
              size: 16 * scale,
            ),
            SizedBox(width: 6 * scale),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText,
                fontSize: 18.2 * scale,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8 * scale,
                vertical: 4.5 * scale,
              ),
              child: Text(
                detail,
                style: TextStyle(
                  color: _libraryCardBodyText,
                  fontSize: 10.8 * scale,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
          if (actionLabel != null) ...[
            SizedBox(width: 17 * scale),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18 * scale),
              child: InkWell(
                key: Key('dhikr.sectionAction.${_normalize(title)}'),
                borderRadius: BorderRadius.circular(18 * scale),
                onTap: onAction,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 6 * scale,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 3 * scale),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _primaryGreen,
                        size: 15 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DhikrLibraryCard extends ConsumerWidget {
  const _DhikrLibraryCard({
    required this.scale,
    required this.item,
    required this.keyPrefix,
    required this.onOpen,
  });

  final double scale;
  final DhikrItem item;
  final String keyPrefix;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderRadius = BorderRadius.circular(24 * scale);
    final hasArabic = item.arabicText?.trim().isNotEmpty ?? false;
    final hasMeaning = item.meaning?.trim().isNotEmpty ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.040),
            blurRadius: 20 * scale,
            offset: Offset(0, 9 * scale),
          ),
        ],
      ),
      child: Material(
        color: _cardBackground.withValues(alpha: 0.96),
        borderRadius: borderRadius,
        child: InkWell(
          key: Key('$keyPrefix.${item.id}'),
          borderRadius: borderRadius,
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 112 * scale),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                2 * scale,
                14 * scale,
                10 * scale,
                14 * scale,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _FavoriteButton(scale: scale, item: item),
                  SizedBox(width: 2 * scale),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 15.8 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 7 * scale),
                        if (hasMeaning) ...[
                          Text(
                            item.meaning!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _libraryCardBodyText,
                              fontSize: 11.4 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.28,
                            ),
                          ),
                        ],
                        SizedBox(height: 9 * scale),
                        Wrap(
                          spacing: 5 * scale,
                          runSpacing: 4 * scale,
                          children: [
                            _SmallTag(
                              scale: scale,
                              icon: _categoryIcon(item.category),
                              label: item.category,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  SizedBox(
                    width: 96 * scale,
                    child: hasArabic
                        ? Text(
                            item.arabicText!,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: _primaryGreen,
                              fontFamily: 'Amiri',
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w400,
                              height: 1.18,
                            ),
                          )
                        : Text(
                            item.category,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _secondaryText,
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  SizedBox(width: 7 * scale),
                  _CardChevron(scale: scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.scale, required this.item});

  final double scale;
  final DhikrItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = item.isFavorite ? const Color(0xFFC39B32) : _primaryGreen;

    return SizedBox.square(
      dimension: 40 * scale,
      child: Center(
        child: SizedBox.square(
          dimension: 27 * scale,
          child: Material(
            color: item.isFavorite
                ? _gold.withValues(alpha: 0.18)
                : _primaryGreen.withValues(alpha: 0.05),
            shape: const CircleBorder(),
            child: Tooltip(
              message: item.isFavorite ? 'Favoriden çıkar' : 'Favoriye ekle',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final isAdding = !item.isFavorite;
                  if (item.isBuiltIn) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .toggleFavorite(item.id);
                  } else {
                    await ref
                        .read(dhikrRepositoryProvider)
                        .setCustomDhikrFavorite(
                          id: item.id,
                          isFavorite: !item.isFavorite,
                        );
                  }
                  unawaited(
                    ref
                        .read(analyticsServiceProvider)
                        .logEvent(
                          isAdding ? 'favorite_added' : 'favorite_removed',
                          parameters: {
                            'source': 'dhikr_library',
                            'dhikr_id': _analyticsText(item.id),
                            'dhikr_category': _analyticsText(item.category),
                            'is_builtin': item.isBuiltIn,
                          },
                        ),
                  );
                  ref.read(interactionFeedbackServiceProvider).selection();
                },
                child: Center(
                  child: Icon(
                    item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: iconColor,
                    size: 15.5 * scale,
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

class _CardChevron extends StatelessWidget {
  const _CardChevron({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 31 * scale,
        child: Icon(
          Icons.chevron_right_rounded,
          color: _primaryGreen,
          size: 21 * scale,
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.scale,
    required this.icon,
    required this.label,
  });

  final double scale;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(13.5 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 5 * scale,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _mutedGreen, size: 12 * scale),
            SizedBox(width: 4 * scale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 9.8 * scale,
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

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({
    required this.scale,
    required this.query,
    required this.onReset,
  });

  final double scale;
  final String query;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardBackground.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(24 * scale),
          boxShadow: _softShadow(scale),
        ),
        child: Padding(
          padding: EdgeInsets.all(18 * scale),
          child: Column(
            children: [
              BookIllustration(size: 78 * scale),
              SizedBox(height: 10 * scale),
              Text(
                query.trim().isEmpty ? 'Bu bölüm boş' : 'Sonuç bulunamadı',
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                'Aramayı veya filtreyi temizleyip tekrar bakabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 12.2 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.34,
                ),
              ),
              SizedBox(height: 14 * scale),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: Icon(Icons.refresh_rounded, size: 18 * scale),
                label: const Text('Temizle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryLoadState extends StatelessWidget {
  const _LibraryLoadState({
    required this.scale,
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _cardBackground.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24 * scale),
            boxShadow: _softShadow(scale),
          ),
          child: Padding(
            padding: EdgeInsets.all(18 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator(strokeWidth: 2.6)
                else
                  Icon(icon, color: _primaryGreen, size: 34 * scale),
                SizedBox(height: 12 * scale),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.34,
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

class _CustomDhikrSheet extends StatefulWidget {
  const _CustomDhikrSheet({required this.scale});

  final double scale;

  @override
  State<_CustomDhikrSheet> createState() => _CustomDhikrSheetState();
}

class _CustomDhikrSheetState extends State<_CustomDhikrSheet> {
  final _nameController = TextEditingController();
  final _arabicController = TextEditingController();
  final _meaningController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Özel');
  final _targetController = TextEditingController(text: '33');

  String? _nameError;
  String? _categoryError;
  String? _targetError;

  @override
  void dispose() {
    _nameController.dispose();
    _arabicController.dispose();
    _meaningController.dispose();
    _categoryController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetRadius = BorderRadius.vertical(top: Radius.circular(28 * scale));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: sheetRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _pageBackground,
            borderRadius: sheetRadius,
          ),
          child: SingleChildScrollView(
            key: const Key('dhikr.customSheet'),
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              22 * scale,
              12 * scale,
              22 * scale,
              22 * scale,
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
                      color: _secondaryText.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 17 * scale),
                Text(
                  'Özel zikir ekle',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  'Kendi zikrini kütüphaneye özel bir kart olarak ekle.',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12.4 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 18 * scale),
                _SheetField(
                  controller: _nameController,
                  label: 'Zikir adı',
                  icon: Icons.menu_book_rounded,
                  autofocus: true,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError == null) return;
                    setState(() => _nameError = null);
                  },
                ),
                SizedBox(height: 10 * scale),
                _SheetField(
                  controller: _arabicController,
                  label: 'Arapça metin (isteğe bağlı)',
                  icon: Icons.text_fields_rounded,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 10 * scale),
                _SheetField(
                  controller: _meaningController,
                  label: 'Anlam veya kısa not',
                  icon: Icons.notes_rounded,
                ),
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _SheetCategoryField(
                        controller: _categoryController,
                        errorText: _categoryError,
                        onChanged: (_) {
                          if (_categoryError == null) return;
                          setState(() => _categoryError = null);
                        },
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      flex: 4,
                      child: _SheetField(
                        controller: _targetController,
                        label: 'Hedef',
                        icon: Icons.flag_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        errorText: _targetError,
                        onChanged: (_) {
                          if (_targetError == null) return;
                          setState(() => _targetError = null);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20 * scale),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Kaydet'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _buttonGreen,
                          foregroundColor: Colors.white,
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
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final target = int.tryParse(_targetController.text.trim());

    setState(() {
      _nameError = name.isEmpty ? 'Zikir adı gerekli' : null;
      _categoryError = category.isEmpty ? 'Kategori gerekli' : null;
      _targetError = target == null || target < 1 ? 'Geçersiz' : null;
    });

    if (_nameError != null || _categoryError != null || _targetError != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      _CustomDhikrDraft(
        name: name,
        category: category,
        target: target!,
        arabicText: _optionalText(_arabicController.text),
        meaning: _optionalText(_meaningController.text),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.textDirection,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textDirection: textDirection,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _cardBackground.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.70),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _buttonGreen, width: 1.2),
        ),
      ),
    );
  }
}

class _SheetCategoryField extends StatelessWidget {
  const _SheetCategoryField({
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('dhikr.categoryField'),
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      onTap: () async {
        FocusScope.of(context).unfocus();
        final selectedCategory = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.18),
          builder: (sheetContext) {
            final media = MediaQuery.of(sheetContext);
            return _SheetCategoryPicker(
              scale: proportionalLayoutScaleFor(media.size.width),
              selectedCategory: controller.text.trim(),
            );
          },
        );
        if (selectedCategory == null) return;
        controller.text = selectedCategory;
        onChanged?.call(selectedCategory);
      },
      decoration: InputDecoration(
        labelText: 'Kategori',
        errorText: errorText,
        prefixIcon: const Icon(Icons.category_rounded),
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        filled: true,
        fillColor: _cardBackground.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.70),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _buttonGreen, width: 1.2),
        ),
      ),
    );
  }
}

class _SheetCategoryPicker extends StatelessWidget {
  const _SheetCategoryPicker({
    required this.scale,
    required this.selectedCategory,
  });

  final double scale;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    final sheetRadius = BorderRadius.vertical(top: Radius.circular(28 * scale));
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 16 * scale;

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: sheetRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _pageBackground,
            borderRadius: sheetRadius,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18 * scale,
              12 * scale,
              18 * scale,
              bottomPadding,
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
                      color: _secondaryText.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 17 * scale),
                Text(
                  'Kategori seç',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  'Zikrinin kütüphanede hangi başlık altında görüneceğini seç.',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12.2 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.34,
                  ),
                ),
                SizedBox(height: 15 * scale),
                Wrap(
                  spacing: 8 * scale,
                  runSpacing: 8 * scale,
                  children: [
                    for (final category in _customDhikrCategories)
                      _SheetCategoryOption(
                        scale: scale,
                        label: category,
                        selected: category == selectedCategory,
                        onTap: () => Navigator.of(context).pop(category),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCategoryOption extends StatelessWidget {
  const _SheetCategoryOption({
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
    final radius = BorderRadius.circular(17 * scale);

    return Material(
      color: selected ? _buttonGreen : _cardBackground.withValues(alpha: 0.92),
      borderRadius: radius,
      child: InkWell(
        key: Key('dhikr.categoryOption.${_normalize(label)}'),
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minWidth: 96 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? _gold.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.72),
              width: 0.8 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.055 : 0.025),
                blurRadius: selected ? 14 * scale : 8 * scale,
                offset: Offset(0, selected ? 6 * scale : 3 * scale),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : _categoryIcon(label),
                color: selected ? Colors.white : _mutedGreen,
                size: 16 * scale,
              ),
              SizedBox(width: 6 * scale),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _primaryText,
                  fontSize: 12.6 * scale,
                  fontWeight: FontWeight.w800,
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

class _CustomDhikrDraft {
  const _CustomDhikrDraft({
    required this.name,
    required this.category,
    required this.target,
    this.arabicText,
    this.meaning,
  });

  final String name;
  final String category;
  final int target;
  final String? arabicText;
  final String? meaning;
}

class _LibraryWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lowerPaint = Paint()
      ..color = const Color(0xFFD4BA75).withValues(alpha: 0.030)
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

List<String> _categoriesFor(List<DhikrItem> items) {
  final values = <String>{};
  var hasFavorite = false;
  for (final item in items) {
    values.add(item.category);
    hasFavorite = hasFavorite || item.isFavorite;
  }
  final orderedCategories = [
    for (final category in _libraryCategoryOrder)
      if (values.contains(category)) category,
    for (final category in values.toList()..sort())
      if (!_libraryCategoryOrder.contains(category)) category,
  ];
  return [
    _allCategory,
    if (hasFavorite) _favoriteCategory,
    ...orderedCategories,
  ];
}

List<DhikrItem> _filterDhikrs(
  List<DhikrItem> items, {
  required String query,
  required String category,
}) {
  final normalizedQuery = _normalize(query);
  final filtered = items.where((item) {
    final matchesCategory =
        category == _allCategory ||
        (category == _favoriteCategory && item.isFavorite) ||
        item.category == category;
    final matchesQuery =
        normalizedQuery.isEmpty ||
        _normalize(item.name).contains(normalizedQuery) ||
        _normalize(item.category).contains(normalizedQuery) ||
        _normalize(item.meaning ?? '').contains(normalizedQuery) ||
        _normalize(item.arabicText ?? '').contains(normalizedQuery);
    return matchesCategory && matchesQuery;
  }).toList();
  return filtered;
}

class _DhikrCategorySection {
  const _DhikrCategorySection({required this.title, required this.items});

  final String title;
  final List<DhikrItem> items;
}

List<_DhikrCategorySection> _groupDhikrsByCategory(
  List<DhikrItem> items, {
  required List<String> categories,
}) {
  final grouped = <String, List<DhikrItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.category, () => <DhikrItem>[]).add(item);
  }

  final orderedCategories = [
    for (final category in categories)
      if (category != _allCategory &&
          category != _favoriteCategory &&
          grouped.containsKey(category))
        category,
    for (final category in grouped.keys)
      if (!categories.contains(category)) category,
  ];

  return [
    for (final category in orderedCategories)
      _DhikrCategorySection(title: category, items: grouped[category]!),
  ];
}

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

String? _optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

IconData _categoryIcon(String category) {
  switch (_normalize(category)) {
    case 'istigfar':
      return Icons.restart_alt_rounded;
    case 'salavat':
      return Icons.favorite_rounded;
    case 'dua':
      return Icons.local_florist_rounded;
    case 'korunma':
      return Icons.shield_rounded;
    case 'tevhid':
      return Icons.auto_awesome_rounded;
    case 'tesbih':
      return Icons.spa_rounded;
    case 'esma-ul husna':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.bookmark_rounded;
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
