import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _designWidth = 440.0;
  static const _designHeight = 956.0;
  static const _green = Color(0xFF114B35);
  static const _logoSuffixGreen = Color(0xFF828C6F);
  static const _arabicGreen = Color(0xFF18523C);
  static const _bodyGreen = Color(0xFF1D4B36);
  static const _referenceGreen = Color(0xFF4D9580);
  static const _dividerGreen = Color(0xFF8DA18B);
  static const _backgroundImage = AssetImage(
    'assets/images/splash_background.jpg',
  );
  static const _logoImage = AssetImage('assets/images/splash_logo_icon.png');
  static const _dashboardHeroImage = AssetImage(
    'assets/images/home_mosque.webp',
  );
  static const _splashDuration = Duration(milliseconds: 4650);
  static const _transitionDuration = Duration(milliseconds: 850);

  late final AnimationController _controller;
  late final AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _splashDuration);
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _transitionController.forward();
      }
    });
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go(AppRoutes.dashboard);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.value == 0) {
        _controller.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_backgroundImage, context);
    precacheImage(_logoImage, context);
    precacheImage(_dashboardHeroImage, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  double _interval(double begin, double end, Curve curve) {
    final value = _controller.value;
    if (value <= begin) {
      return 0;
    }
    if (value >= end) {
      return 1;
    }
    return curve.transform((value - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF5F5F1),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F1),
        body: AnimatedBuilder(
          animation: Listenable.merge([_controller, _transitionController]),
          builder: (context, _) {
            final logo = _interval(0.08, 0.28, Curves.easeOutCubic);
            final title = _interval(0.14, 0.36, Curves.easeOutCubic);
            final tagline = _interval(0.24, 0.46, Curves.easeOutCubic);
            final verse = _interval(0.44, 0.70, Curves.easeOutCubic);
            final meal = _interval(0.56, 0.78, Curves.easeOutCubic);
            final transition = Curves.easeInOutCubic.transform(
              _transitionController.value,
            );
            final splashOpacity = (1 - transition).clamp(0.0, 1.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                if (transition > 0)
                  IgnorePointer(
                    child: Opacity(
                      opacity: transition,
                      child: const DashboardScreen(),
                    ),
                  ),
                IgnorePointer(
                  ignoring: transition > 0,
                  child: Opacity(
                    opacity: splashOpacity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scale = math.max(
                          constraints.maxWidth / _designWidth,
                          constraints.maxHeight / _designHeight,
                        );
                        final designLeft =
                            (constraints.maxWidth - _designWidth * scale) / 2;
                        final designTop =
                            (constraints.maxHeight - _designHeight * scale) / 2;
                        final pixelRatio = MediaQuery.devicePixelRatioOf(
                          context,
                        );

                        double snap(double value) {
                          return (value * pixelRatio).round() / pixelRatio;
                        }

                        Widget positioned({
                          required double left,
                          required double top,
                          required double width,
                          required double height,
                          required Widget child,
                        }) {
                          return Positioned(
                            left: snap(designLeft + left * scale),
                            top: snap(designTop + top * scale),
                            width: snap(width * scale),
                            height: snap(height * scale),
                            child: child,
                          );
                        }

                        Widget reveal({
                          required double progress,
                          required Widget child,
                          double dy = 16,
                        }) {
                          return Opacity(
                            opacity: progress.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                snap((1 - progress) * dy * scale),
                              ),
                              child: child,
                            ),
                          );
                        }

                        return RepaintBoundary(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: const Image(
                                  image: _backgroundImage,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              positioned(
                                left: 181,
                                top: 127,
                                width: 74,
                                height: 108,
                                child: reveal(
                                  progress: logo,
                                  dy: 18,
                                  child: const Image(
                                    image: _logoImage,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                              positioned(
                                left: 93,
                                top: 235,
                                width: 260,
                                height: 59,
                                child: reveal(
                                  progress: title,
                                  dy: 14,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: RichText(
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      textScaler: TextScaler.noScaling,
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: _green,
                                          fontFamily: 'EB Garamond',
                                          fontSize: 45 * scale,
                                          fontWeight: FontWeight.w500,
                                          height: 59 / 45,
                                        ),
                                        children: const [
                                          TextSpan(text: 'Zikirmatik'),
                                          TextSpan(
                                            text: '.pro',
                                            style: TextStyle(
                                              color: _logoSuffixGreen,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              positioned(
                                left: 122,
                                top: 297,
                                width: 196,
                                height: 17,
                                child: reveal(
                                  progress: tagline,
                                  dy: 8,
                                  child: _SplashTagline(scale: scale),
                                ),
                              ),
                              positioned(
                                left: 47,
                                top: 685,
                                width: 357,
                                height: 84,
                                child: reveal(
                                  progress: verse,
                                  dy: 18,
                                  child: Text(
                                    'اَلَّذٖينَ اٰمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللّٰهِؕ\n'
                                    'اَلَا بِذِكْرِ اللّٰهِ تَطْمَئِنُّ الْقُلُوبُؕ',
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      color: _arabicGreen,
                                      fontFamily: 'Amiri',
                                      fontSize: 24 * scale,
                                      fontWeight: FontWeight.w400,
                                      height: 42 / 24,
                                    ),
                                  ),
                                ),
                              ),
                              positioned(
                                left: 174,
                                top: 777,
                                width: 92,
                                height: 10,
                                child: Opacity(
                                  opacity: meal.clamp(0.0, 1.0),
                                  child: _SplashDivider(scale: scale),
                                ),
                              ),
                              positioned(
                                left: 104,
                                top: 791,
                                width: 243,
                                height: 42,
                                child: reveal(
                                  progress: meal,
                                  dy: 14,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Bilesiniz ki, kalpler ancak\n'
                                      'Allah’ı zikretmekle huzur bulur.',
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        color: _bodyGreen,
                                        fontFamily: 'Inter',
                                        fontSize: 17 * scale,
                                        fontWeight: FontWeight.w400,
                                        height: 21 / 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              positioned(
                                left: 184,
                                top: 840,
                                width: 83,
                                height: 17,
                                child: reveal(
                                  progress: meal,
                                  dy: 12,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '(Ra’d, 13/28)',
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        color: _referenceGreen,
                                        fontFamily: 'Inter',
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w400,
                                        height: 17 / 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashTagline extends StatelessWidget {
  const _SplashTagline({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 8 * scale,
          child: _Line(width: 19 * scale, color: _SplashScreenState._green),
        ),
        Positioned(
          left: 30 * scale,
          top: 0,
          width: 135 * scale,
          height: 17 * scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'ZİKİRLE HUZUR BUL',
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: _SplashScreenState._green,
                fontFamily: 'Inter',
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                height: 17 / 14,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 8 * scale,
          child: _Line(width: 19 * scale, color: _SplashScreenState._green),
        ),
      ],
    );
  }
}

class _SplashDivider extends StatelessWidget {
  const _SplashDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 3 * scale,
          top: 4.5 * scale,
          child: _Line(
            width: 35 * scale,
            color: _SplashScreenState._dividerGreen,
          ),
        ),
        Positioned(
          left: 43 * scale,
          top: 2 * scale,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 6 * scale,
              height: 6 * scale,
              color: _SplashScreenState._dividerGreen,
            ),
          ),
        ),
        Positioned(
          right: 3 * scale,
          top: 4.5 * scale,
          child: _Line(
            width: 35 * scale,
            color: _SplashScreenState._dividerGreen,
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 1, color: color);
  }
}
