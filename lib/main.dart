import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/dashboard/dashboard_controller.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/session/session_controller.dart';
import 'features/session/session_screen.dart';
import 'features/settings/settings_screen.dart';
import 'services/storage_service.dart';
import 'shared/widgets/glass_navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const FocusZoneApp());
}

class FocusZoneApp extends StatefulWidget {
  const FocusZoneApp({super.key});

  @override
  State<FocusZoneApp> createState() => _FocusZoneAppState();
}

class _FocusZoneAppState extends State<FocusZoneApp> {
  late final ThemeController themeController;
  late final DashboardController dashboardController;
  late final SessionController sessionController;
  late final PageController pageController;
  late final ValueNotifier<int> indexNotifier;

  bool _showSkeleton = true;

  @override
  void initState() {
    super.initState();
    themeController = ThemeController(
      initialValue: StorageService.getThemeValue(),
    );
    dashboardController = DashboardController();
    sessionController = SessionController();
    pageController = PageController();
    indexNotifier = ValueNotifier<int>(0);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() => _showSkeleton = false);
    });
  }

  @override
  void dispose() {
    themeController.dispose();
    dashboardController.dispose();
    sessionController.dispose();
    pageController.dispose();
    indexNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleNavTap(int newIndex) async {
    if (newIndex == indexNotifier.value) {
      return;
    }

    indexNotifier.value = newIndex;
    if (!pageController.hasClients) {
      return;
    }

    pageController.jumpToPage(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (_, __) {
        final theme = AppTheme.theme(themeController.value);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                _AppBackdrop(themeValue: themeController.value),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _showSkeleton
                      ? const _LaunchSkeleton(key: ValueKey<String>('skeleton'))
                      : RepaintBoundary(
                          key: const ValueKey<String>('pages'),
                          child: PageView(
                            controller: pageController,
                            onPageChanged: (value) {
                              indexNotifier.value = value;
                            },
                            children: [
                              RepaintBoundary(
                                child: DashboardScreen(
                                  controller: dashboardController,
                                ),
                              ),
                              RepaintBoundary(
                                child: SessionScreen(
                                  controller: sessionController,
                                  dashboardController: dashboardController,
                                ),
                              ),
                              RepaintBoundary(
                                child: SettingsScreen(
                                  themeController: themeController,
                                  dashboardController: dashboardController,
                                  sessionController: sessionController,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: indexNotifier,
              builder: (context, index, _) {
                return GlassNavbar(currentIndex: index, onTap: _handleNavTap);
              },
            ),
          ),
        );
      },
    );
  }
}

class _AppBackdrop extends StatelessWidget {
  final double themeValue;

  const _AppBackdrop({required this.themeValue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topGlow =
        Color.lerp(const Color(0xFF00F5FF), scheme.primary, themeValue) ??
        const Color(0xFF00F5FF);
    final bottomGlow =
        Color.lerp(const Color(0xFFA78BFA), scheme.tertiary, themeValue) ??
        const Color(0xFFA78BFA);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.surface, scheme.background],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              left: -90,
              child: _GlowOrb(color: topGlow, size: 280),
            ),
            Positioned(
              bottom: -130,
              right: -100,
              child: _GlowOrb(color: bottomGlow, size: 300),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(themeValue * 0.016),
                      Colors.transparent,
                      Colors.black.withOpacity(themeValue * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.42), color.withOpacity(0.02)],
        ),
      ),
    );
  }
}

class _LaunchSkeleton extends StatelessWidget {
  const _LaunchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.13),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 260,
              height: 14,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.09),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: List.generate(4, (_) {
                  return Container(
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
