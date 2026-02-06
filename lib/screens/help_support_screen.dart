import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _formspreeUrl = 'https://formspree.io/f/mdkyoyna';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I track my meals?',
              'Tap on the "+" button on the home screen and select "Food" to log your meals. You can search for foods, scan barcodes, or add custom foods.',
            ),
            _buildFaqItem(
              'How does the calorie target work?',
              'Your daily calorie target is calculated based on your profile information. You can adjust it manually in Settings > Calorie Target.',
            ),
            _buildFaqItem(
              'Can I use CoCal offline?',
              'Yes! CoCal works offline. Your data will sync automatically when you reconnect to the internet.',
            ),
            _buildFaqItem(
              'How do streaks work?',
              'Streaks track consecutive days of logging meals, exercises, weights, and habits. Keep your streaks alive by logging daily!',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 16),
            
            _buildContactCard(
              Icons.email,
              'Email Support',
              'Get help via email',
              () => _openFormspree(),
            ),
            const SizedBox(height: 12),
            
            _buildContactCard(
              Icons.rate_review,
              'Rate Our App',
              'Share your feedback on the Play Store',
              () => _openPlayStore(),
            ),
            const SizedBox(height: 12),
            
            _buildContactCard(
              Icons.privacy_tip,
              'Privacy Policy',
              'View our privacy policy',
              () => context.push('/privacy-policy'),
            ),
            const SizedBox(height: 12),
            
            _buildContactCard(
              Icons.description,
              'Terms of Service',
              'View terms and conditions',
              () => _openTermsOfService(),
            ),
            const SizedBox(height: 32),
            
            Center(
              child: Text(
                'CoCal v1.0.0',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _openFormspree() async {
    final Uri url = Uri.parse(_formspreeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openPlayStore() async {
    final Uri url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.cocal.visionquantech',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openTermsOfService() async {
    final Uri url = Uri.parse('https://cocal.visionquantech.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
