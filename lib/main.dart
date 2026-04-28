import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/session/session_provider.dart';
import 'features/notifications/notification_service.dart';
import 'features/grayscale/grayscale_service.dart';
import 'ui/check_in_screen.dart';
import 'ui/tunnel_setup_screen.dart';
import 'ui/in_progress_screen.dart';
import 'ui/recovery_screen.dart';
import 'ui/finished_screen.dart';
import 'ui/micro_wins_screen.dart';
import 'ui/history_screen.dart';
import 'ui/theme/luxury_theme.dart';
import 'ui/app_settings_screen.dart';
import 'ui/widgets/overlay_lock_widget.dart';
import 'features/overlay/overlay_service.dart';
import 'features/kiosk/kiosk_service.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const OverlayLockWidget(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for luxury feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: LuxuryColors.richBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize notifications
  await NotificationService.initialize();
  
  // TODO: Replace with your Supabase URL and Anon Key
  try {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
    // Continue running app even if Supabase fails, for UI demo purposes.
  }

  runApp(const ProviderScope(child: BioLockedApp()));
}

class BioLockedApp extends ConsumerStatefulWidget {
  const BioLockedApp({super.key});

  @override
  ConsumerState<BioLockedApp> createState() => _BioLockedAppState();
}

class _BioLockedAppState extends ConsumerState<BioLockedApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(sessionStateProvider.notifier).setCheckIn();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── Session lock check ──────────────────────────────────────────────────

  /// Returns true when the app is actively running a locked session.
  bool _isSessionLocked() {
    final sessionState = ref.read(sessionStateProvider);
    final lockLevel = ref.read(lockLevelProvider);

    // These are the states where the user must NOT be able to leave the app.
    const lockedStates = {
      SessionState.inProgress,
      SessionState.alarm,
      SessionState.waitingForFaceDown,
    };

    return lockedStates.contains(sessionState) &&
        (lockLevel == SessionLockLevel.hard ||
            lockLevel == SessionLockLevel.standard);
  }

  // ─── Lifecycle — Overlay & Kiosk re-assertion ────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cover ALL backgrounding transitions:
    //   paused   → app is fully in background (Android: onStop)
    //   inactive → transitioning / notification shade pulled down
    //   hidden   → Flutter 3.13+ state between paused and detached
    //   detached → process still alive but no view attached
    final isBackgrounding = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;

    if (isBackgrounding && _isSessionLocked()) {
      // Show system-level overlay so the screen is blocked even when the
      // user switches to another app via recents, notifications, etc.
      ref.read(overlayServiceProvider).showOverlay();
    } else if (state == AppLifecycleState.resumed) {
      // Always clean up the overlay when the user returns.
      ref.read(overlayServiceProvider).hideOverlay();

      // Re-assert kiosk/screen-pin if it was somehow dismissed while away.
      if (_isSessionLocked()) {
        final lockLevel = ref.read(lockLevelProvider);
        if (lockLevel == SessionLockLevel.hard ||
            lockLevel == SessionLockLevel.standard) {
          ref.read(kioskServiceProvider).enableKioskMode();
        }
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);
    final isGrayscale = ref.watch(grayscaleModeProvider);

    // Re-evaluate lock status reactively (needed for PopScope canPop).
    final lockLevel = ref.watch(lockLevelProvider);
    const lockedStates = {
      SessionState.inProgress,
      SessionState.alarm,
      SessionState.waitingForFaceDown,
    };
    final isLocked = lockedStates.contains(sessionState) &&
        (lockLevel == SessionLockLevel.hard ||
            lockLevel == SessionLockLevel.standard);

    Widget app = MaterialApp(
      title: 'Bio-Locked',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: LuxuryColors.platinumBlue,
        scaffoldBackgroundColor: LuxuryColors.richBlack,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: LuxuryColors.platinumBlue,
          secondary: LuxuryColors.burnishedGold,
          surface: LuxuryColors.elevatedSurface,
          error: LuxuryColors.rubyRed,
        ),
        textTheme: TextTheme(
          displayLarge: LuxuryTextStyles.displayLarge,
          headlineLarge: LuxuryTextStyles.headlineLarge,
          titleLarge: LuxuryTextStyles.titleLarge,
          bodyLarge: LuxuryTextStyles.bodyLarge,
          bodyMedium: LuxuryTextStyles.bodyMedium,
          labelLarge: LuxuryTextStyles.labelLarge,
        ),
      ),
      home: switch (sessionState) {
        SessionState.idle =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        SessionState.setup => const CheckInScreen(),
        SessionState.checkIn => const CheckInScreen(),
        SessionState.tunnelSetup => const TunnelSetupScreen(),
        SessionState.waitingForFaceDown ||
        SessionState.inProgress ||
        SessionState.alarm =>
          const InProgressScreen(),
        SessionState.recoveryMode => const RecoveryScreen(),
        SessionState.microWinsMode => const MicroWinsScreen(),
        SessionState.history => const HistoryScreen(),
        SessionState.finished => const FinishedScreen(),
        SessionState.accountSettings => const AppSettingsScreen(),
      },
    );

    // ── 🔒 Back-button / system-navigation lock ──────────────────────────
    // PopScope sits above MaterialApp so it intercepts ANY attempt to pop
    // the root navigator — including the Android system back gesture and
    // the predictive-back animation — while a locked session is active.
    app = PopScope(
      canPop: !isLocked, // false = swallow the back event
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isLocked) {
          // Heavy haptic nudge to make the block feel intentional.
          HapticFeedback.heavyImpact();
          debugPrint('[BioLocked] Back navigation blocked — session is locked.');
        }
      },
      child: app,
    );

    // ── 🌑 Grayscale mode — wraps entire app during sessions ─────────────
    if (isGrayscale) {
      app = ColorFiltered(
        colorFilter: const ColorFilter.matrix(grayscaleMatrix),
        child: app,
      );
    }

    return app;
  }
}
