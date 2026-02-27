import 'package:bible_decision_simulator/core/di.dart';
import 'package:bible_decision_simulator/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationControllerState {
  const NotificationControllerState({
    required this.initialized,
    required this.isScheduling,
    required this.permissionGranted,
    this.lastError,
  });

  factory NotificationControllerState.initial() {
    return const NotificationControllerState(
      initialized: false,
      isScheduling: false,
      permissionGranted: false,
      lastError: null,
    );
  }

  final bool initialized;
  final bool isScheduling;
  final bool permissionGranted;
  final String? lastError;

  NotificationControllerState copyWith({
    bool? initialized,
    bool? isScheduling,
    bool? permissionGranted,
    String? lastError,
  }) {
    return NotificationControllerState(
      initialized: initialized ?? this.initialized,
      isScheduling: isScheduling ?? this.isScheduling,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      lastError: lastError,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationControllerState>(
        (ref) {
  return NotificationController(
    service: ref.read(notificationServiceProvider),
    prefs: ref.read(sharedPreferencesProvider),
  );
});

class NotificationController
    extends StateNotifier<NotificationControllerState> {
  NotificationController({
    required NotificationService service,
    required SharedPreferences prefs,
  })  : _service = service,
        _prefs = prefs,
        super(NotificationControllerState.initial());

  final NotificationService _service;
  final SharedPreferences _prefs;

  static const _permissionExplainerSeenKey = 'notification.explainer_seen';

  Future<void> handleAppOpen({
    required BuildContext context,
    required CompletedTodayResolver hasCompletedToday,
    required String localeCode,
  }) async {
    await initialize();
    if (!context.mounted) return;

    final granted = await _service.areNotificationsEnabled();
    if (!context.mounted) return;
    if (!granted) {
      await _runPermissionFlow(context);
    }

    final latestPermission = await _service.areNotificationsEnabled();
    state = state.copyWith(permissionGranted: latestPermission);
    if (!latestPermission) return;

    await _scheduleFromConfig(
      hasCompletedToday,
      localeCode: localeCode,
    );
  }

  Future<void> handleAppResume({
    required CompletedTodayResolver hasCompletedToday,
    required String localeCode,
  }) async {
    await initialize();
    final granted = await _service.areNotificationsEnabled();
    state = state.copyWith(permissionGranted: granted);
    if (!granted) return;
    await _scheduleFromConfig(
      hasCompletedToday,
      localeCode: localeCode,
    );
  }

  Future<void> initialize() async {
    if (state.initialized) return;
    try {
      await _service.init();
      state = state.copyWith(
        initialized: true,
        permissionGranted: await _service.areNotificationsEnabled(),
      );
    } catch (error) {
      state = state.copyWith(lastError: error.toString());
    }
  }

  Future<void> _scheduleFromConfig(
    CompletedTodayResolver hasCompletedToday, {
    required String localeCode,
  }) async {
    try {
      state = state.copyWith(isScheduling: true, lastError: null);
      await _service.scheduleAll(
        hasCompletedToday: hasCompletedToday,
        localeCode: localeCode,
      );
      state = state.copyWith(isScheduling: false, lastError: null);
    } catch (error) {
      state = state.copyWith(
        isScheduling: false,
        lastError: 'Failed to schedule notifications: $error',
      );
    }
  }

  Future<void> _runPermissionFlow(BuildContext context) async {
    final hasShownExplainer =
        _prefs.getBool(_permissionExplainerSeenKey) ?? false;
    var shouldRequest = true;
    if (!hasShownExplainer && context.mounted) {
      shouldRequest = await _showPermissionExplainer(context);
      await _prefs.setBool(_permissionExplainerSeenKey, true);
    }
    if (!shouldRequest) return;

    final granted = await _service.requestPermission();
    if (granted || !context.mounted) return;
    await _showSettingsDialog(context);
  }

  Future<bool> _showPermissionExplainer(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _NotificationPermissionExplainerScreen(),
      ),
    );
    return result ?? false;
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Allow notifications in Settings'),
          content: const Text(
            'You can enable reminders later in system settings if you change your mind.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _service.openSystemNotificationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationPermissionExplainerScreen extends StatelessWidget {
  const _NotificationPermissionExplainerScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stay on track'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enable daily reminders',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'We only send local reminders from your on-device schedule. '
                'No backend, no push notifications.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              const _PermissionLine(
                  text: 'Daily scene reminder at your configured time'),
              const _PermissionLine(
                  text: 'Streak reminder only when not completed today'),
              const _PermissionLine(text: 'Weekly content reminder'),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Maybe later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
