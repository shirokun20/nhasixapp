import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:nhasixapp/presentation/cubits/crotpedia_auth/crotpedia_auth_cubit.dart';
import 'dart:io' as io;

class CrotpediaLoginPage extends StatelessWidget {
  const CrotpediaLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CrotpediaLoginView();
  }
}

class _CrotpediaLoginView extends StatefulWidget {
  const _CrotpediaLoginView();

  @override
  State<_CrotpediaLoginView> createState() => _CrotpediaLoginViewState();
}

class _CrotpediaLoginViewState extends State<_CrotpediaLoginView> {
  double _progress = 0;
  InAppWebViewController? _webViewController;
  bool _isExtracting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Crotpedia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Clear Session & Reload',
            onPressed: () async {
              await CookieManager.instance().deleteAllCookies();
              _webViewController?.reload();
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Cookies cleared. Reloading...')),
                 );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<CrotpediaAuthCubit, CrotpediaAuthState>(
        listener: (context, state) {
          if (state is CrotpediaAuthSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Synced as ${state.username}')),
            );
            // UX Update: Do NOT close the page automatically. 
            // User remains in control to browse or logout manually.
          } else if (state is CrotpediaAuthError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            setState(() {
              _isExtracting = false;
            });
          }
        },
        builder: (context, state) {
          if (_isExtracting) {
             return const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Syncing session with app...'),
                 ],
               ),
             );
          }
          
          return Column(
            children: [
              if (_progress < 1.0)
                LinearProgressIndicator(value: _progress),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://crotpedia.net/'),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    useHybridComposition: true,
                    userAgent: "Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36", // Use a mobile UA
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    if (url == null) return;
                    
                    try {
                      // Check Login Status via Dropdown Menu
                      final result = await controller.evaluateJavascript(source: """
                        (function() {
                           var dropdown = document.querySelector('#dropdown-user');
                           if (!dropdown) return { status: 'unknown' };
                           
                           var html = dropdown.innerHTML;
                           
                           // Check for Logged In indicators (Logout link OR Profile link)
                           if (html.includes('action=logout') || html.includes('/profile/')) {
                               // Extract Username
                               // Priority 1: Admin Bar
                               var adminUser = document.querySelector('#wp-admin-bar-my-account span.display-name');
                               if (adminUser) return { status: 'logged_in', username: adminUser.innerText };
                               
                               // Priority 2: Profile Header
                               var profileUser = document.querySelector('.profile-head h1 span');
                               if (profileUser) return { status: 'logged_in', username: profileUser.innerText };
                               
                               return { status: 'logged_in', username: 'User' };
                           }
                           
                           // Check for Not Logged In indicators (Login link OR Register link)
                           if (html.includes('/login/') || html.includes('/register/')) {
                               return { status: 'not_logged_in' };
                           }
                           
                           return { status: 'unknown' };
                        })();
                      """);
                      
                      if (!mounted) return; // Fix linter: check mounted after await

                      if (result != null && result is Map) {
                         final status = result['status'];
                         final urlStr = url.toString();
                         
                         // LOGIC UPDATE: Handle Unknown status (Missing Dropdown) on Login pages
                         // If we are on wp-login.php or /login/ and can't find the user dropdown, 
                         // we are definitely NOT logged in.
                         bool isNotLoggedIn = status == 'not_logged_in';
                         if (status == 'unknown' && (urlStr.contains('/login') || urlStr.contains('wp-login'))) {
                            isNotLoggedIn = true;
                         }

                         if (status == 'logged_in') {
                            final username = result['username'] ?? 'User';
                            _handleLoginSuccess(controller, url, usernameOverride: username);
                            return;
                         } else if (isNotLoggedIn) {
                            // Force Logout if we detect we aren't logged in
                            // This cleans up any stale cookies that might exist
                            await CookieManager.instance().deleteAllCookies();
                            
                            // SYNC: Explicitly tell App Cubit to logout so Drawer updates
                            if (mounted) context.read<CrotpediaAuthCubit>().logout();

                            // If we aren't on the login page, redirect there
                            // But avoid infinite loops if we are already there
                            if (!urlStr.contains('/login') && !urlStr.contains('wp-login.php')) {
                               controller.loadUrl(urlRequest: URLRequest(url: WebUri('https://crotpedia.net/login/')));
                            }
                         }
                      }
                      
                    } catch (e) {
                      // JS evaluation failed, ignore
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleLoginSuccess(InAppWebViewController controller, WebUri url, {String? usernameOverride}) async {
    // 0. Check if already synced to avoid spamming
    final currentAuthState = context.read<CrotpediaAuthCubit>().state;
    if (currentAuthState is CrotpediaAuthSuccess) {
       if (usernameOverride != null && currentAuthState.username == usernameOverride) {
          return;
       }
       if (usernameOverride == null) return;
    }

    if (_isExtracting) return;
    
    setState(() {
      _isExtracting = true;
    });

    try {
      // 1. Get Cookies
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: url);
      
      if (cookies.isEmpty) {
         setState(() => _isExtracting = false);
         return;
      }
      
      final ioCookies = cookies.map((c) => io.Cookie(c.name, c.value)
         ..domain = c.domain
         ..path = c.path
         ..secure = c.isSecure ?? false
         ..httpOnly = c.isHttpOnly ?? false
      ).toList();

      // 2. Identify username
      String username = usernameOverride ?? 'User';
      
      if (usernameOverride == null) {
        try {
           final scrapedUser = await controller.evaluateJavascript(source: """
              (function() {
                 var accountNode = document.querySelector('#wp-admin-bar-my-account > a');
                 if (accountNode) return accountNode.innerText.replace('Howdy, ', '').trim();
                 
                 var profileLink = document.querySelector('a[href*="/author/"]');
                 if (profileLink) return profileLink.innerText.trim();
                 
                 return null;
              })();
           """);
           
           if (scrapedUser != null && scrapedUser.toString().isNotEmpty && scrapedUser.toString() != 'null') {
              username = scrapedUser.toString();
           }
        } catch (e) {
           // Ignore scraping errors
        }
      }

      // 3. Sync with App directly (No Dialog, Stay Open)
      if (mounted) {
         context.read<CrotpediaAuthCubit>().externalLogin(username, ioCookies);
         setState(() => _isExtracting = false);
      }
      
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Session sync failed: $e')),
          );
          setState(() => _isExtracting = false);
       }
    }
  }
}
