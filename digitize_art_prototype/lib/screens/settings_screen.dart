import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchWebsite(BuildContext context) async {
    final url = Uri.parse('https://digitize.art');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final url = Uri.parse('mailto:contact@digitize.art');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchSocial(BuildContext context, String platform) async {
    final urls = {
      'twitter': 'https://twitter.com/digitizeart',
      'discord': 'https://discord.gg/digitizeart',
    };

    final url = Uri.parse(urls[platform] ?? '');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
      ),
      body: ListView(
        children: [
          // Hero section with logo and website link
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryMain,
                  AppTheme.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/logo/digitize-art-logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.camera_alt_outlined,
                        size: 60,
                        color: Colors.white,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // App name
                Text(
                  'Digitize.art',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Version
                Text(
                  'Version 0.1.0 (MVP)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),

                const SizedBox(height: 24),

                // Website button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWebsite(context),
                    icon: const Icon(Icons.language),
                    label: const Text('Visit Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Website URL display
                Text(
                  'https://digitize.art',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          // About section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ABOUT',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Digitize.art'),
            subtitle: const Text('Professional artwork digitization service'),
            onTap: () => _launchWebsite(context),
          ),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Services'),
            subtitle: const Text('Learn about our digitization services'),
            onTap: () => _launchWebsite(context),
          ),

          const Divider(),

          // Contact section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CONTACT',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: const Text('contact@digitize.art'),
            onTap: () => _launchEmail(context),
          ),

          // Social media section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'SOCIAL MEDIA',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Twitter'),
            subtitle: const Text('@digitizeart'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _launchSocial(context, 'twitter'),
          ),

          ListTile(
            leading: Image.asset(
              'assets/icons/discord.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.forum_outlined);
              },
            ),
            title: const Text('Discord Community'),
            subtitle: const Text('Join our community'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _launchSocial(context, 'discord'),
          ),

          const Divider(),

          // App info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'APP INFO',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('Open Source'),
            subtitle: const Text('View on GitHub'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () async {
              final url = Uri.parse('https://github.com/Greisten/digitize-art');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _launchWebsite(context),
          ),

          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _launchWebsite(context),
          ),

          const SizedBox(height: 32),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Built with ❤️ for artists, by artists\n© 2026 Digitize.art',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
