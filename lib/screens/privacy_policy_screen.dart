import 'package:flutter/material.dart';
import '../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Last Updated', 'February 5, 2026'),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Introduction'),
            const SizedBox(height: 8),
            _buildParagraph(
              'Welcome to CoCal ("we," "our," or "us"). We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you use our mobile application.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('2. Data We Collect'),
            const SizedBox(height: 8),
            _buildParagraph(
              'We may collect, use, store, and transfer different kinds of personal data about you which we have grouped together follows:',
            ),
            const SizedBox(height: 8),
            _buildListItem('Identity Data: Name, username, or similar identifier'),
            _buildListItem('Contact Data: Email address, phone number'),
            _buildListItem('Health Data: Weight, height, body fat percentage, calorie intake, exercise logs'),
            _buildListItem('Technical Data: IP address, browser type, device information'),
            _buildListItem('Usage Data: How you use the app'),
            const SizedBox(height: 24),
            _buildSectionTitle('3. How We Use Your Data'),
            const SizedBox(height: 8),
            _buildListItem('To provide and maintain our service'),
            _buildListItem('To notify you about changes to our service'),
            _buildListItem('To provide customer support'),
            _buildListItem('To provide analysis or valuable information so that we can improve the service'),
            _buildListItem('To monitor the usage of our service'),
            _buildListItem('To detect, prevent, and address technical issues'),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Data Storage and Security'),
            const SizedBox(height: 8),
            _buildParagraph(
              'We use Supabase as our backend service to store and manage your data. All data is encrypted in transit and at rest. We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('5. Data Retention'),
            const SizedBox(height: 8),
            _buildParagraph(
              'We will retain your personal data only for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('6. Your Rights'),
            const SizedBox(height: 8),
            _buildParagraph(
              'You have the right to:',
            ),
            const SizedBox(height: 8),
            _buildListItem('Access the personal data we hold about you'),
            _buildListItem('Request correction of your personal data'),
            _buildListItem('Request deletion of your personal data'),
            _buildListItem('Object to processing of your personal data'),
            _buildListItem('Request restriction of processing your personal data'),
            _buildListItem('Request transfer of your personal data'),
            const SizedBox(height: 24),
            _buildSectionTitle('7. Children\'s Privacy'),
            const SizedBox(height: 8),
            _buildParagraph(
              'Our service is not intended for use by children under the age of 13. We do not knowingly collect personally identifiable information from children under 13.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('8. Changes to This Privacy Policy'),
            const SizedBox(height: 8),
            _buildParagraph(
              'We may update our privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('9. Contact Us'),
            const SizedBox(height: 8),
            _buildParagraph(
              'If you have any questions about this Privacy Policy, please contact us through the Help & Support section in the app.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 CoCal. All rights reserved.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.primary,
          ),
        ),
        Text(
          value,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppTheme.primary)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
