import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _breakfastReminder = false;
  bool _lunchReminder = false;
  bool _dinnerReminder = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final permissions = await NotificationService().requestPermissions();
    setState(() => _notificationsEnabled = permissions);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermissions();
      setState(() => _notificationsEnabled = granted);
      if (granted) {
        await NotificationService().showNotification(
          title: 'Notifications Enabled',
          body: 'You will now receive meal reminders',
        );
      }
    } else {
      await NotificationService().cancelAllNotifications();
      setState(() => _notificationsEnabled = false);
    }
  }

  Future<void> _toggleMealReminder(String meal, bool value) async {
    setState(() {
      if (meal == 'breakfast') _breakfastReminder = value;
      if (meal == 'lunch') _lunchReminder = value;
      if (meal == 'dinner') _dinnerReminder = value;
    });

    if (value) {
      await NotificationService().showMealReminder(mealType: meal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Tools'),
            _buildToolsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('Appearance'),
            _buildThemeCard(themeMode),
            const SizedBox(height: 24),
            _buildSectionHeader('Notifications'),
            _buildNotificationSettings(),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/calorie-calculator'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calculate, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Calorie Calculator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ThemeMode themeMode) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            'Dark Mode',
            'Default dark theme',
            themeMode == ThemeMode.dark,
            () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          _buildThemeOption(
            'Light Mode',
            'Clean light theme',
            themeMode == ThemeMode.light,
            () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          _buildThemeOption(
            'System Default',
            'Follow system settings',
            themeMode == ThemeMode.system,
            () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Enable Notifications',
            'Receive meal and habit reminders',
            _notificationsEnabled,
            (value) => _toggleNotifications(value),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          if (_notificationsEnabled) ...[
            _buildSwitchTile(
              'Breakfast Reminder',
              '8:00 AM reminder',
              _breakfastReminder,
              (value) => _toggleMealReminder('breakfast', value),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            _buildSwitchTile(
              'Lunch Reminder',
              '1:00 PM reminder',
              _lunchReminder,
              (value) => _toggleMealReminder('lunch', value),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            _buildSwitchTile(
              'Dinner Reminder',
              '7:00 PM reminder',
              _dinnerReminder,
              (value) => _toggleMealReminder('dinner', value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow('Version', '1.0.0'),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          _buildInfoRow('Build', '1'),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          GestureDetector(
            onTap: () => context.push('/privacy-policy'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          GestureDetector(
            onTap: _openTermsOfService,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _openTermsOfService() async {
    final Uri url = Uri.parse('https://cocal.visionquantech.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
