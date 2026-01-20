import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/dns_models.dart';
import '../../../core/di/service_locator.dart';
import '../../cubits/dns_settings/dns_settings_cubit.dart';
import '../../../core/network/dns_settings_service.dart';
import 'package:logger/logger.dart';

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
    _dnsServerController = TextEditingController(text: settings.customDnsServer);
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
        title: const Text('DNS Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
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
                title: const Text('Enable DNS-over-HTTPS'),
                subtitle: const Text(
                  'Use encrypted DNS for enhanced privacy and bypass censorship',
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Using system default DNS resolver',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Provider Selection (only when enabled)
              if (settings.enabled) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'DNS Provider',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...DnsProvider.values
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
                          groupValue: settings.provider,
                          onChanged: (DnsProvider? value) {
                            if (value != null) {
                              context
                                  .read<DnsSettingsCubit>()
                                  .updateProvider(value);
                            }
                          },
                        )),

                // Custom DNS input (if custom selected)
                if (settings.provider == DnsProvider.custom) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Custom Configuration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _dnsServerController,
                          decoration: const InputDecoration(
                            labelText: 'DNS Server IP',
                            hintText: '1.1.1.1',
                            helperText: 'Primary DNS server address',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            context.read<DnsSettingsCubit>().setCustomDns(
                                  value.isNotEmpty ? value : null,
                                  _dohUrlController.text.isNotEmpty ? _dohUrlController.text : null,
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _dohUrlController,
                          decoration: const InputDecoration(
                            labelText: 'DoH URL (Optional)',
                            hintText: 'https://dns.example.com/dns-query',
                            helperText: 'DNS-over-HTTPS endpoint URL',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            context.read<DnsSettingsCubit>().setCustomDns(
                                  _dnsServerController.text.isNotEmpty ? _dnsServerController.text : null,
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About DNS-over-HTTPS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'DNS-over-HTTPS (DoH) encrypts your DNS queries, '
                      'preventing ISPs and network administrators from '
                      'monitoring which websites you visit. It also helps '
                      'bypass DNS-based censorship and geo-restrictions.',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.security, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'All DNS queries encrypted via HTTPS',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.vpn_lock, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Enhanced privacy and security',
                          style: TextStyle(fontSize: 12),
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
        title: const Text('Reset DNS Settings'),
        content: const Text(
          'This will reset DNS settings to system defaults. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<DnsSettingsCubit>().resetToDefaults();
              Navigator.pop(dialogContext);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
