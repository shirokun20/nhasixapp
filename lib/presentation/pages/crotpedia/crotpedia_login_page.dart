import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_auth/crotpedia_auth_cubit.dart';
import 'dart:io' as io;

class CrotpediaLoginPage extends StatelessWidget {
  const CrotpediaLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Crotpedia'),
      ),
      body: BlocConsumer<CrotpediaAuthCubit, CrotpediaAuthState>(
        listener: (context, state) {
          if (state is CrotpediaAuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Synced as ${state.username}')),
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
                  Text('Logged in as ${state.username}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<CrotpediaAuthCubit>().logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
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
                    'Login Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Login to Crotpedia using the native secure browser to access bookmarks and more.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _launchNativeLogin(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Login via Secure Browser'),
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
        successUrlFilters: ['/wp-admin', '/dashboard', 'crotpedia.net/'],
      );

      if (!context.mounted) return;

      if (result != null && result['success'] == true) {
        final cookiesStrList =
            (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
        
        final cookies = cookiesStrList.map((str) {
            final parts = str.split('=');
            return io.Cookie(parts[0].trim(), parts.length > 1 ? parts.sublist(1).join('=') : '');
         }).toList();

        context.read<CrotpediaAuthCubit>().externalLogin('User', cookies);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }
}
