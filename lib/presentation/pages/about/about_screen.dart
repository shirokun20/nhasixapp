import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/cubits/update/update_cubit.dart';
import 'package:nhasixapp/presentation/cubits/update/update_state.dart';
import 'package:nhasixapp/presentation/widgets/app_main_drawer_widget.dart';
import 'package:nhasixapp/presentation/widgets/update_available_sheet.dart';
import 'package:nhasixapp/presentation/widgets/legal_content_sheet.dart';
import 'package:nhasixapp/services/legal_content_service.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UpdateCubit>(),
      child: const _AboutContent(),
    );
  }
}

class _AboutContent extends StatefulWidget {
  const _AboutContent();

  @override
  State<_AboutContent> createState() => _AboutContentState();
}

class _AboutContentState extends State<_AboutContent>
    with SingleTickerProviderStateMixin {
  String _version = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadVersion();

    // Setup pulse animation for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${info.version}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: AppMainDrawerWidget(context: context),
      extendBodyBehindAppBar: true,
      body: BlocListener<UpdateCubit, UpdateState>(
        listener: (context, state) {
          if (state is UpdateAvailable) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) =>
                  UpdateAvailableSheet(updateInfo: state.updateInfo),
            );
          } else if (state is UpdateNotAvailable && state.isManualCheck) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App is up to date!')),
            );
          } else if (state is UpdateError && state.isManualCheck) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Check failed: ${state.message}')),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 20),

                // Hero Section
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Image(
                            image: AssetImage('assets/icons/logo_app.png'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  l10n.appTitle,
                  style: TextStyleConst.headingLarge.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _version,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Update Card
                _buildSectionTitle('Updates'),
                const SizedBox(height: 8),
                _buildUpdateCard(theme),

                const SizedBox(height: 32),

                // Links Section
                _buildSectionTitle('Community & Info'),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _buildMenuItem(
                    context,
                    icon: Icons.code,
                    title: 'GitHub Repository',
                    subtitle: 'View source code & contribute',
                    onTap: () =>
                        _launchURL('https://github.com/shirokun20/nhasixapp'),
                    isExternal: true,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Open Source Licenses',
                    subtitle: 'Libraries used in this app',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appTitle,
                      applicationVersion: _version,
                      applicationIcon: const Image(
                        image: AssetImage('assets/icons/logo_app.png'),
                        height: 48,
                        width: 48,
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.gavel_outlined,
                    title: l10n.termsAndConditions,
                    subtitle: l10n.termsAndConditionsSubtitle,
                    onTap: () => LegalContentSheet.show(
                      context,
                      contentType: LegalContentType.termsAndConditions,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    subtitle: l10n.privacyPolicySubtitle,
                    onTap: () => LegalContentSheet.show(
                      context,
                      contentType: LegalContentType.privacyPolicy,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: l10n.faq,
                    subtitle: l10n.faqSubtitle,
                    onTap: () => LegalContentSheet.show(
                      context,
                      contentType: LegalContentType.faq,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.thumb_up_outlined,
                    title: l10n.facebookPage,
                    subtitle: l10n.facebookPageSubtitle,
                    onTap: () => _launchURL(
                        'https://www.facebook.com/profile.php?id=61586101395866'),
                    isExternal: true,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.coffee_outlined,
                    title: l10n.supportDeveloper,
                    subtitle: l10n.supportDeveloperSubtitle,
                    onTap: () => _showDonationDialog(context, l10n),
                  ),
                ], theme),

                const SizedBox(height: 32),

                // Tech Stack
                _buildSectionTitle('Built With'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTechBadge('Flutter', Colors.blue),
                    _buildTechBadge('Dart', Colors.blueAccent),
                    _buildTechBadge('Bloc', Colors.orange),
                    _buildTechBadge('Clean Arch', Colors.green),
                    _buildTechBadge('GetIt', Colors.purple),
                  ],
                ),

                const SizedBox(height: 48),

                // Footer
                Text(
                  'Made with ❤️ by Shirokun20',
                  style: TextStyleConst.caption.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '© 2025 All Rights Reserved',
                  style: TextStyleConst.caption.copyWith(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildUpdateCard(ThemeData theme) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        String status = 'Check for updates';
        IconData icon = Icons.refresh;
        final bool isLoading = state is UpdateChecking;

        if (isLoading) {
          status = 'Checking...';
        } else if (state is UpdateAvailable) {
          status = 'Update Available!';
          icon = Icons.file_download_outlined;
        } else if (state is UpdateNotAvailable) {
          status = 'Up to date';
          icon = Icons.check_circle_outline;
        } else if (state is UpdateError) {
          status = 'Check failed';
          icon = Icons.error_outline;
        }

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: isLoading
                ? null
                : () {
                    context.read<UpdateCubit>().checkForUpdate(isManual: true);
                  },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary))
                        : Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Updates',
                          style: TextStyleConst.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          status,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.iconTheme.color?.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(List<Widget> children, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isExternal = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyleConst.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyleConst.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isExternal
          ? Icon(Icons.open_in_new,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)
          : Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildTechBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _showDonationDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.coffee, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.supportDeveloper),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.donateMessage),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/donation_qris.jpeg',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.thankYouMessage,
              style: TextStyleConst.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
