import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment_provider.dart';
import '../../../core/config/store_channel.dart';
import '../../../core/monetization/monetization.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../application/settings_controller.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _topSurface = Color(0xFFFFFCF7);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _cardBackground = Color(0xFFFAFAF4);
const _primaryText = Color(0xFF123B2B);
const _secondaryText = Color(0xFF69766E);
const _gold = Color(0xFFD4BA75);
const _dividerColor = Color(0xFFDDE4D9);

const _logoAsset = 'assets/images/splash_logo_icon.png';
const _motifAsset = 'assets/images/menu_bottom_motif.webp';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final env = ref.watch(appEnvironmentProvider);
    final entitlement = ref.watch(entitlementProvider);
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.14).toDouble();
    final quietMode = !settings.vibrationEnabled && !settings.soundEnabled;

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
          drawer: const AppMenuDrawer(),
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _pageBackground)),
              Positioned.fill(
                child: CustomPaint(painter: _SettingsWashPainter()),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: media.padding.bottom + 24 * scale,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SettingsTopCluster(
                            scale: scale,
                            topInset: media.padding.top,
                            settings: settings,
                            quietMode: quietMode,
                          ),
                          SizedBox(height: 12 * scale),
                          _SettingsSection(
                            scale: scale,
                            icon: Icons.palette_rounded,
                            title: 'Görünüm',
                            description:
                                'Tema ve okuma yoğunluğunu kullanım alışkanlığına göre ayarla.',
                            children: [
                              _ThemeModePicker(
                                scale: scale,
                                value: settings.themeMode,
                                onChanged: controller.setThemeMode,
                              ),
                              SizedBox(height: 10 * scale),
                              _PreferenceSwitchTile(
                                scale: scale,
                                icon: Icons.format_size_rounded,
                                title: 'Büyük metin modu',
                                subtitle:
                                    'Uygulama genelinde metni daha rahat okunur yapar.',
                                value: settings.largeTextMode,
                                onChanged: controller.setLargeTextMode,
                              ),
                              SizedBox(height: 8 * scale),
                              _PreferenceSwitchTile(
                                scale: scale,
                                icon: Icons.chrome_reader_mode_rounded,
                                title: 'Kolay okuma modu',
                                subtitle:
                                    'Daha sakin metin ölçeğiyle uzun içerikleri rahatlatır.',
                                value: settings.easyReadMode,
                                onChanged: controller.setEasyReadMode,
                              ),
                            ],
                          ),
                          SizedBox(height: 12 * scale),
                          _SettingsSection(
                            scale: scale,
                            icon: Icons.touch_app_rounded,
                            title: 'Geri bildirim',
                            description:
                                'Sayaç, tesbih ve seçim anlarındaki fiziksel/sesli tepkileri yönet.',
                            children: [
                              _PreferenceSwitchTile(
                                scale: scale,
                                icon: Icons.vibration_rounded,
                                title: 'Titreşim',
                                subtitle:
                                    'Zikir sayarken dokunsal tepki verir.',
                                value: settings.vibrationEnabled,
                                onChanged: controller.setVibrationEnabled,
                              ),
                              SizedBox(height: 8 * scale),
                              _PreferenceSwitchTile(
                                scale: scale,
                                icon: settings.soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                title: 'Ses',
                                subtitle:
                                    'Tesbih ve tamamlanma seslerini açıp kapatır.',
                                value: settings.soundEnabled,
                                onChanged: controller.setSoundEnabled,
                              ),
                              SizedBox(height: 8 * scale),
                              _PreferenceSwitchTile(
                                scale: scale,
                                icon: Icons.do_not_disturb_on_rounded,
                                title: 'Sessiz kullanım',
                                subtitle:
                                    'Sesi ve titreşimi tek dokunuşla kapatır.',
                                value: quietMode,
                                onChanged: controller.setQuietFeedbackMode,
                              ),
                            ],
                          ),
                          SizedBox(height: 12 * scale),
                          _SettingsSection(
                            scale: scale,
                            icon: Icons.verified_user_rounded,
                            title: 'Uygulama',
                            description:
                                'Dağıtım kanalı ve premium hazırlık durumunu görüntüle.',
                            children: [
                              _InfoRow(
                                scale: scale,
                                icon: Icons.storefront_rounded,
                                title: 'Store kanalı',
                                value: _storeChannelLabel(env.storeChannel),
                              ),
                              SizedBox(height: 8 * scale),
                              _InfoRow(
                                scale: scale,
                                icon: Icons.workspace_premium_rounded,
                                title: 'Premium durumu',
                                value: entitlement.hasPremium
                                    ? 'Aktif'
                                    : 'Hazırlıkta',
                              ),
                              SizedBox(height: 8 * scale),
                              _InfoRow(
                                scale: scale,
                                icon: Icons.payments_rounded,
                                title: 'Monetization modu',
                                value: _monetizationLabel(entitlement.mode),
                              ),
                              SizedBox(height: 12 * scale),
                              _PremiumNote(scale: scale),
                            ],
                          ),
                          SizedBox(height: 12 * scale),
                          _ResetPreferencesCard(
                            scale: scale,
                            onReset: controller.resetExperienceSettings,
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
      ),
    );
  }
}

class _SettingsTopCluster extends StatelessWidget {
  const _SettingsTopCluster({
    required this.scale,
    required this.topInset,
    required this.settings,
    required this.quietMode,
  });

  final double scale;
  final double topInset;
  final SettingsState settings;
  final bool quietMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: -36 * scale,
          child: const _SettingsTopClusterBackground(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsHero(scale: scale, topInset: topInset),
            SizedBox(height: 8 * scale),
            _SettingsSummaryStrip(
              scale: scale,
              settings: settings,
              quietMode: quietMode,
            ),
            SizedBox(height: 4 * scale),
          ],
        ),
      ],
    );
  }
}

class _SettingsTopClusterBackground extends StatelessWidget {
  const _SettingsTopClusterBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_topSurface, _topSurface, _pageBackground],
          stops: [0.0, 0.58, 1.0],
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.scale, required this.topInset});

  final double scale;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final heroHeight = topInset + 150 * scale;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -44 * scale,
            top: -12 * scale,
            width: 255 * scale,
            height: 180 * scale,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.32,
                child: Image.asset(
                  _motifAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20 * scale,
            top: topInset + 4 * scale,
            child: _HeroMenuButton(scale: scale),
          ),
          Positioned(
            right: 22 * scale,
            top: topInset + 26 * scale,
            child: _SettingsLogoSeal(scale: scale),
          ),
          Positioned(
            left: 64 * scale,
            top: topInset + 10 * scale,
            right: 104 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ayarlar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  'Deneyimi sadeleştir, görünümü seç, geri bildirimi incelt.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryText.withValues(alpha: 0.86),
                    fontSize: 11.8 * scale,
                    fontWeight: FontWeight.w600,
                    height: 1.34,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20 * scale,
            right: 20 * scale,
            bottom: 12 * scale,
            child: _HeroCallout(scale: scale),
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

class _SettingsLogoSeal extends StatelessWidget {
  const _SettingsLogoSeal({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 68 * scale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7350), Color(0xFF103E2A)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.16),
            blurRadius: 20 * scale,
            offset: Offset(0, 9 * scale),
          ),
          BoxShadow(
            color: _gold.withValues(alpha: 0.13),
            blurRadius: 16 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(13 * scale),
        child: Image.asset(
          _logoAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _HeroCallout extends StatelessWidget {
  const _HeroCallout({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        13 * scale,
        10 * scale,
        12 * scale,
        10 * scale,
      ),
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.74),
          width: 0.8 * scale,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34 * scale,
            height: 34 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _buttonGreen.withValues(alpha: 0.10),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: _primaryGreen,
              size: 18 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              'Yeni görünüm, tema seçimi ve tek dokunuşla sessiz kullanım hazır.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText,
                fontSize: 11.5 * scale,
                fontWeight: FontWeight.w700,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSummaryStrip extends StatelessWidget {
  const _SettingsSummaryStrip({
    required this.scale,
    required this.settings,
    required this.quietMode,
  });

  final double scale;
  final SettingsState settings;
  final bool quietMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              scale: scale,
              icon: _themeModeIcon(settings.themeMode),
              title: 'Tema',
              value: _themeModeLabel(settings.themeMode),
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: _SummaryCard(
              scale: scale,
              icon: quietMode
                  ? Icons.notifications_off_rounded
                  : Icons.sensors_rounded,
              title: 'Geri bildirim',
              value: quietMode ? 'Sessiz' : 'Aktif',
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: _SummaryCard(
              scale: scale,
              icon: Icons.text_fields_rounded,
              title: 'Okuma',
              value: settings.largeTextMode || settings.easyReadMode
                  ? 'Konfor'
                  : 'Standart',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.scale,
    required this.icon,
    required this.title,
    required this.value,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78 * scale,
      padding: EdgeInsets.all(11 * scale),
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
          width: 0.8 * scale,
        ),
        boxShadow: _softShadow(scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryGreen, size: 18 * scale),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 9.6 * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryText,
              fontSize: 12.6 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.scale,
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24 * scale);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _softShadow(scale),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _cardBackground.withValues(alpha: 0.92),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.68),
              width: 0.8 * scale,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              15 * scale,
              14 * scale,
              15 * scale,
              15 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionIcon(scale: scale, icon: icon),
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
                              color: _primaryText,
                              fontSize: 17 * scale,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                          SizedBox(height: 5 * scale),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _secondaryText,
                              fontSize: 11.4 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14 * scale),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.scale, required this.icon});

  final double scale;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38 * scale,
      height: 38 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _buttonGreen.withValues(alpha: 0.10),
      ),
      child: Icon(icon, color: _primaryGreen, size: 20 * scale),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker({
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(
          color: _dividerColor.withValues(alpha: 0.82),
          width: 0.8 * scale,
        ),
      ),
      child: Row(
        children: AppThemeMode.values.map((mode) {
          return Expanded(
            child: _ThemeModePill(
              scale: scale,
              mode: mode,
              selected: mode == value,
              onTap: () => onChanged(mode),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeModePill extends StatelessWidget {
  const _ThemeModePill({
    required this.scale,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15 * scale);
    final foreground = selected ? Colors.white : _primaryText;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          height: 42 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF347756), Color(0xFF13472F)],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 14 * scale,
                      offset: Offset(0, 6 * scale),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_themeModeIcon(mode), color: foreground, size: 15 * scale),
              SizedBox(width: 5 * scale),
              Flexible(
                child: Text(
                  _themeModeLabel(mode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11.4 * scale,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    height: 1,
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

class _PreferenceSwitchTile extends StatelessWidget {
  const _PreferenceSwitchTile({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            11 * scale,
            10 * scale,
            8 * scale,
            10 * scale,
          ),
          decoration: BoxDecoration(
            color: value
                ? _buttonGreen.withValues(alpha: 0.075)
                : Colors.white.withValues(alpha: 0.48),
            borderRadius: radius,
            border: Border.all(
              color: value
                  ? _gold.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.78),
              width: 0.8 * scale,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34 * scale,
                height: 34 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? _primaryGreen.withValues(alpha: 0.10)
                      : _dividerColor.withValues(alpha: 0.40),
                ),
                child: Icon(
                  icon,
                  color: value ? _primaryGreen : _secondaryText,
                  size: 18 * scale,
                ),
              ),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 13.4 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 10.4 * scale,
                        fontWeight: FontWeight.w600,
                        height: 1.24,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * scale),
              Transform.scale(
                scale: (0.82 * scale).clamp(0.78, 0.92).toDouble(),
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: _buttonGreen,
                  activeTrackColor: _buttonGreen.withValues(alpha: 0.34),
                  inactiveThumbColor: _secondaryText.withValues(alpha: 0.76),
                  inactiveTrackColor: _dividerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.scale,
    required this.icon,
    required this.title,
    required this.value,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        11 * scale,
        10 * scale,
        11 * scale,
        10 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.74),
          width: 0.8 * scale,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34 * scale,
            height: 34 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryGreen.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: _primaryGreen, size: 18 * scale),
          ),
          SizedBox(width: 11 * scale),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(width: 10 * scale),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _buttonGreen,
                fontSize: 12.2 * scale,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumNote extends StatelessWidget {
  const _PremiumNote({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gold.withValues(alpha: 0.16),
            _buttonGreen.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(
          color: _gold.withValues(alpha: 0.32),
          width: 0.8 * scale,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: _gold, size: 19 * scale),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              'İlk sürümde premium görünmez/no-op. Sonraki fazda store IAP adaptörleri açılacak.',
              style: TextStyle(
                color: _primaryText,
                fontSize: 11.2 * scale,
                fontWeight: FontWeight.w700,
                height: 1.34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPreferencesCard extends StatelessWidget {
  const _ResetPreferencesCard({required this.scale, required this.onReset});

  final double scale;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        14 * scale,
        15 * scale,
        15 * scale,
      ),
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
          width: 0.8 * scale,
        ),
        boxShadow: _softShadow(scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tercihleri yenile',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 14.8 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  'Tema, okuma ve geri bildirim ayarlarını varsayılana döndürür.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 10.8 * scale,
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * scale),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: Icon(Icons.refresh_rounded, size: 17 * scale),
            label: const Text('Sıfırla'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryGreen,
              side: BorderSide(color: _buttonGreen.withValues(alpha: 0.34)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * scale),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 10 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.032)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 1.10, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.52,
        size.width * -0.10,
        size.height * 0.82,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

String _themeModeLabel(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => 'Sistem',
    AppThemeMode.light => 'Açık',
    AppThemeMode.dark => 'Koyu',
  };
}

IconData _themeModeIcon(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => Icons.brightness_auto_rounded,
    AppThemeMode.light => Icons.light_mode_rounded,
    AppThemeMode.dark => Icons.dark_mode_rounded,
  };
}

String _storeChannelLabel(StoreChannel channel) {
  return switch (channel) {
    StoreChannel.googlePlay => 'Google Play',
    StoreChannel.huaweiAppGallery => 'Huawei AppGallery',
    StoreChannel.appStore => 'App Store',
    StoreChannel.development => 'Geliştirme',
  };
}

String _monetizationLabel(MonetizationMode mode) {
  return switch (mode) {
    MonetizationMode.freeLaunch => 'Ücretsiz lansman',
    MonetizationMode.adSupported => 'Reklam destekli',
    MonetizationMode.premiumGated => 'Premium kilitli',
  };
}
