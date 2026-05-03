import 'package:flutter/material.dart';

const _timePickerPrimaryGreen = Color(0xFF13472F);
const _timePickerButtonGreen = Color(0xFF327653);
const _timePickerSurface = Color(0xFFFAFAF4);
const _timePickerSage = Color(0xFFE5ECE2);
const _timePickerText = Color(0xFF123B2B);
const _timePickerMutedText = Color(0xFF69766E);
const _timePickerGold = Color(0xFFCDAA3B);

Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String helpText = 'Hatırlatma saati',
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: 'Vazgeç',
    confirmText: 'Seç',
    hourLabelText: 'Saat',
    minuteLabelText: 'Dakika',
    errorInvalidText: 'Geçerli bir saat gir',
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme.copyWith(
        primary: _timePickerButtonGreen,
        onPrimary: Colors.white,
        surface: _timePickerSurface,
        onSurface: _timePickerText,
        secondary: _timePickerGold,
        onSecondary: _timePickerText,
      );

      return MediaQuery(
        data: media.copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: theme.copyWith(
            colorScheme: colorScheme,
            timePickerTheme: TimePickerThemeData(
              backgroundColor: _timePickerSurface,
              hourMinuteColor: WidgetStateColor.resolveWith(
                _hourMinuteBackgroundColor,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                _hourMinuteTextColor,
              ),
              dialBackgroundColor: _timePickerSage.withValues(alpha: 0.74),
              dialHandColor: _timePickerPrimaryGreen,
              dialTextColor: WidgetStateColor.resolveWith(_dialTextColor),
              entryModeIconColor: _timePickerPrimaryGreen,
              dayPeriodColor: _timePickerSage,
              dayPeriodTextColor: _timePickerPrimaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              helpTextStyle: const TextStyle(
                color: _timePickerMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _timePickerPrimaryGreen,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );
}

Color _hourMinuteBackgroundColor(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) {
    return _timePickerPrimaryGreen;
  }

  return _timePickerSage;
}

Color _hourMinuteTextColor(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) {
    return Colors.white;
  }

  return _timePickerPrimaryGreen;
}

Color _dialTextColor(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) {
    return Colors.white;
  }

  return _timePickerText;
}
