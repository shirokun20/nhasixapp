import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_auth/crotpedia_auth_cubit.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';
class CrotpediaLoginPage extends StatelessWidget {
  const CrotpediaLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loginToCrotpedia),
      ),
      body: BlocConsumer<CrotpediaAuthCubit, CrotpediaAuthState>(
        listener: (context, state) {
          if (state is CrotpediaAuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.syncedAsUser(state.username))),
            );
          } else if (state is CrotpediaAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CrotpediaAuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CrotpediaAuthSuccess) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loggedInAsUser(state.username),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<CrotpediaAuthCubit>().logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(AppLocalizations.of(context)!.logout),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_person, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.loginRequired,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppLocalizations.of(context)!.loginToCrotpediaDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _launchNativeLogin(context),
                    icon: const Icon(Icons.login),
                    label: Text(AppLocalizations.of(context)!.loginViaSecureBrowser),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchNativeLogin(BuildContext context) async {
    try {
      final result = await KuronNative.instance.showLoginWebView(
        url: 'https://crotpedia.net/login/',
        successUrlFilters: ['/wp-admin', '/dashboard'],
      );

      if (!context.mounted) return;

      if (result != null && result['success'] == true) {
        final cookiesStrList =
            (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];

        // 🔍 Verification: Check if we actually have a session cookie
        final hasSession =
            cookiesStrList.any((c) => c.contains('wordpress_logged_in'));

        if (hasSession) {
          final sessionCookie = cookiesStrList
              .firstWhere((c) => c.contains('wordpress_logged_in'));
          final value = sessionCookie.split('=').length > 1
              ? sessionCookie.split('=').sublist(1).join('=')
              : '';
          final username = value.split('%7C').firstOrNull ?? 'User';
          await context
              .read<CrotpediaAuthCubit>()
              .externalLogin(username, cookiesStrList);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)!.loginIncomplete)),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginFailedError(e.toString()))),
        );
      }
    }
  }
}
