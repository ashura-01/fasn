import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';
import '../widgets/floating_flowers.dart';
import '../widgets/motivational_popup.dart';
import 'routine/routine_screen.dart';
import 'notes/notes_screen.dart';
import 'gratitude/gratitude_screen.dart';
import 'music/music_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Each screen manages its own FAB / add-dialogs internally.
  final List<Widget> _screens = const [
    RoutineScreen(),
    NotesScreen(),
    GratitudeScreen(),
    MusicScreen(),
    SettingsScreen(),
  ];

  static const List<_NavSpec> _navSpecs = [
    _NavSpec(icon: Icons.space_dashboard_rounded, label: 'Routine'),
    _NavSpec(icon: Icons.sticky_note_2_rounded, label: 'Notes'),
    _NavSpec(icon: Icons.favorite_rounded, label: 'Gratitude'),
    _NavSpec(icon: Icons.music_note_rounded, label: 'Music'),
    _NavSpec(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MotivationalPopup.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-read settings on every build so tab switches pick up changes immediately
    final showFlowers = HiveService.getAppSettings().showFloatingFlowers;
    return FloatingFlowersWidget(
      enabled: showFlowers,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.12),
          blurRadius: 24, offset: const Offset(0, -8))],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navSpecs.length, (i) => _NavItem(
              spec: _navSpecs[i],
              index: i,
              current: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
            )),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData icon;
  final String label;
  const _NavSpec({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.spec,
    required this.index,
    required this.current,
    required this.onTap,
  });

  bool get _active => index == current;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _active ? AppTheme.primaryLight.withOpacity(0.4) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(spec.icon, color: _active ? AppTheme.primaryDark : AppTheme.textHint, size: 22),
            const SizedBox(height: 3),
            Text(spec.label, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 10,
              fontWeight: _active ? FontWeight.w700 : FontWeight.w400,
              color: _active ? AppTheme.primaryDark : AppTheme.textHint,
            )),
          ]),
        ),
      ),
    );
  }
}
