import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class MotivationalPopup {
  static const _morningKey = 'motivation_morning_';
  static const _eveningKey = 'motivation_evening_';

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hour = DateTime.now().hour;

    final isMorning = hour >= 6 && hour < 13;
    final isEvening = hour >= 19 && hour <= 23;

    if (isMorning) {
      final shownKey = '$_morningKey$today';
      if (!(prefs.getBool(shownKey) ?? false)) {
        await prefs.setBool(shownKey, true);
        if (context.mounted) await _show(context, isMorning: true);
      }
    } else if (isEvening) {
      final shownKey = '$_eveningKey$today';
      if (!(prefs.getBool(shownKey) ?? false)) {
        await prefs.setBool(shownKey, true);
        if (context.mounted) await _show(context, isMorning: false);
      }
    }
  }

  static Future<void> _show(BuildContext context, {required bool isMorning}) {
    final quote = kMotivationalQuotes[Random().nextInt(kMotivationalQuotes.length)];
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _MotivationalDialog(isMorning: isMorning, quote: quote),
    );
  }
}

class _MotivationalDialog extends StatefulWidget {
  final bool isMorning;
  final String quote;
  const _MotivationalDialog({required this.isMorning, required this.quote});

  @override
  State<_MotivationalDialog> createState() => _MotivationalDialogState();
}

class _MotivationalDialogState extends State<_MotivationalDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF0F3), Color(0xFFFFD6DC)],
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                    color: AppTheme.primaryDark, size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.isMorning ? 'Good Morning, Beautiful' : 'End Your Day With Love',
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    widget.quote,
                    style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 14,
                      fontWeight: FontWeight.w400, color: AppTheme.textPrimary, height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Thank you'),
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
