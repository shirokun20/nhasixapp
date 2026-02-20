import 'package:flutter/material.dart';
import 'package:nhasixapp/services/ad_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';

class AdGuardWarningDialog {
  /// Munculkan dialog peringatan AdGuard yang tidak bisa di-_bypass_
  /// Function ini akan menahan proses _await_ selama DNS masih aktif
  /// dan hanya akan return true jika DNS sudah terbukti bersih.
  static Future<void> showNonBypassable(BuildContext context) async {
    bool isAdGuard = await getIt<AdService>().isAdGuardDnsActive();

    while (isAdGuard && context.mounted) {
      bool isChecking = false;
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Peringatan Private DNS'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Terdeteksi penggunaan Private DNS (seperti AdGuard) aktif.\n\n'
                      'Iklan sangat diperlukan untuk keberlangsungan operasional aplikasi gratis ini. '
                      'Mohon matikan Private DNS / AdBlocker pada Setelan perangkat Anda untuk melanjutkan.',
                    ),
                    if (isChecking) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ]
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isChecking
                        ? null
                        : () async {
                            setState(() => isChecking = true);
                            isAdGuard =
                                await getIt<AdService>().isAdGuardDnsActive();
                            if (ctx.mounted) {
                              if (!isAdGuard) {
                                Navigator.of(ctx).pop();
                              } else {
                                setState(() => isChecking = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Private DNS masih terdeteksi aktif')),
                                );
                              }
                            }
                          },
                    child: const Text('Cek Ulang'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
}
