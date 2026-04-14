import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/dns_models.dart';
import '../../../core/di/service_locator.dart';
import '../../cubits/dns_settings/dns_settings_cubit.dart';
import '../../../core/network/dns_settings_service.dart';
import 'package:logger/logger.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';
/// DNS Settings configuration screen
class DnsSettingsScreen extends StatelessWidget {
  const DnsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DnsSettingsCubit(
        settingsService: getIt<DnsSettingsService>(),
        logger: getIt<Logger>(),
      )..initialize(),
      child: const _DnsSettingsView(),
    );
  }
}

class _DnsSettingsView extends StatefulWidget {
  const _DnsSettingsView();

  @override
  State<_DnsSettingsView> createState() => _DnsSettingsViewState();
}

class _DnsSettingsViewState extends State<_DnsSettingsView> {
  late TextEditingController _dnsServerController;
  late TextEditingController _dohUrlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<DnsSettingsCubit>().state;
    _dnsServerController =
        TextEditingController(text: settings.customDnsServer);
    _dohUrlController = TextEditingController(text: settings.customDohUrl);
  }

  @override
  void dispose() {
    _dnsServerController.dispose();
    _dohUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dnsSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.resetToDefaults,
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<DnsSettingsCubit, DnsSettings>(
        builder: (context, settings) {
          return ListView(
            children: [
              // DNS-over-HTTPS Enable Switch
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.enableDnsOverHttps),
                subtitle: Text(
                  AppLocalizations.of(context)!.dnsEncryptedDescription,
                ),
                value: settings.enabled,
                onChanged: (enabled) {
                  context.read<DnsSettingsCubit>().toggleEnabled(enabled);
                },
              ),

              const Divider(),

              // Info banner when disabled
              if (!settings.enabled)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.usingSystemDns,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Provider Selection (only when enabled)
              if (settings.enabled) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    AppLocalizations.of(context)!.dnsProvider,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                RadioGroup<DnsProvider>(
                  groupValue: settings.provider,
                  onChanged: (DnsProvider? value) {
                    if (value != null) {
                      context.read<DnsSettingsCubit>().updateProvider(value);
                    }
                  },
                  child: Column(
                    children: DnsProvider.values
                        .where((p) => p != DnsProvider.system)
                        .map((provider) => RadioListTile<DnsProvider>(
                              title: Text(provider.displayName),
                              subtitle: provider.dnsServers.isNotEmpty
                                  ? Text(
                                      provider.dnsServers.join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                    )
                                  : null,
                              value: provider,
                            ))
                        .toList(),
                  ),
                ),

                // Custom DNS input (if custom selected)
                if (settings.provider == DnsProvider.custom) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.customConfiguration,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _dnsServerController,
                          decoration: const InputDecoration(
                            labelText: AppLocalizations.of(context)!.dnsServerIp,
                            hintText: '1.1.1.1',
                            helperText: AppLocalizations.of(context)!.primaryDnsAddress,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            context.read<DnsSettingsCubit>().setCustomDns(
                                  value.isNotEmpty ? value : null,
                                  _dohUrlController.text.isNotEmpty
                                      ? _dohUrlController.text
                                      : null,
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _dohUrlController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.dohUrlOptional,
                            hintText: 'https://dns.example.com/dns-query',
                            helperText: AppLocalizations.of(context)!.dnsOverHttpsUrl,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            context.read<DnsSettingsCubit>().setCustomDns(
                                  _dnsServerController.text.isNotEmpty
                                      ? _dnsServerController.text
                                      : null,
                                  value.isNotEmpty ? value : null,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // Information section
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.aboutDoh,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.dohDescription,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.security, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.dnsQueriesEncrypted,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.vpn_lock, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.enhancedPrivacy,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetDnsSettings),
        content: Text(
          AppLocalizations.of(context)!.resetDnsConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<DnsSettingsCubit>().resetToDefaults();
              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(context)!.reset),
          ),
        ],
      ),
    );
  }
}
