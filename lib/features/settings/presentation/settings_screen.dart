import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
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
                            icon: Icons.text_fields_rounded,
                            title: 'Görünüm',
                            description:
                                'Okuma yoğunluğunu kullanım alışkanlığına göre ayarla.',
                            children: [
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
                          _ContactCard(scale: scale),
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
            left: 20 * scale,
            top: topInset + 4 * scale,
            child: _HeroMenuButton(scale: scale),
          ),
          Positioned(
            left: 64 * scale,
            top: topInset + 10 * scale,
            right: 20 * scale,
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
                  'Deneyimi sadeleştir, okuma ayarlarını ve geri bildirimi incelt.',
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
              'Okuma konforu ve tek dokunuşla sessiz kullanım hazır.',
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.scale});

  final double scale;

  static const _email = 'info@zikirmatik.pro';
  static const _website = 'www.zikirmatik.pro';
  static const _privacyUrl = 'https://zikirmatik.pro/privacy.html';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SectionIcon(scale: scale, icon: Icons.contact_support_rounded),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İletişim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 14.8 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      'Destek ve geri bildirim için bize ulaş.',
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
            ],
          ),
          SizedBox(height: 12 * scale),
          _ContactRow(
            scale: scale,
            icon: Icons.mail_outline_rounded,
            label: 'E-posta',
            value: _email,
            onTap: () => _copyValue(context, 'E-posta', _email),
          ),
          SizedBox(height: 8 * scale),
          _ContactRow(
            scale: scale,
            icon: Icons.language_rounded,
            label: 'Web sitesi',
            value: _website,
            onTap: () => _copyValue(context, 'Web sitesi', _website),
          ),
          SizedBox(height: 8 * scale),
          _ContactRow(
            scale: scale,
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy',
            value: _privacyUrl,
            trailingIcon: Icons.open_in_new_rounded,
            onTap: () => _openPrivacyPolicy(context),
          ),
        ],
      ),
    );
  }

  Future<void> _copyValue(
    BuildContext context,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label kopyalandı'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1300),
        ),
      );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(_privacyUrl);
    var opened = false;

    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      opened = false;
    }

    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Privacy linki açılamadı'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1300),
        ),
      );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.scale,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailingIcon = Icons.copy_rounded,
  });

  final double scale;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(17 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            11 * scale,
            9 * scale,
            10 * scale,
            9 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
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
                child: Icon(icon, color: _primaryGreen, size: 18 * scale),
              ),
              SizedBox(width: 11 * scale),
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
                        color: _secondaryText,
                        fontSize: 10.2 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 12.8 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * scale),
              Icon(
                trailingIcon,
                color: _buttonGreen.withValues(alpha: 0.78),
                size: 17 * scale,
              ),
            ],
          ),
        ),
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
