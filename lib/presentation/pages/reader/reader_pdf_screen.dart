import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/services/native_pdf_service.dart';

class ReaderPdfScreen extends StatefulWidget {
  final String filePath;
  final String contentId;
  final String title;

  const ReaderPdfScreen({
    super.key,
    required this.filePath,
    required this.contentId,
    required this.title,
  });

  @override
  State<ReaderPdfScreen> createState() => _ReaderPdfScreenState();
}

class _ReaderPdfScreenState extends State<ReaderPdfScreen> {
  @override
  void initState() {
    super.initState();
    _launchNativePdf();
  }

  Future<void> _launchNativePdf() async {
    try {
      final nativeService = GetIt.I<NativePdfService>();
      await nativeService.openPdf(
        path: widget.filePath,
        title: widget.title,
      );
      // After native viewer opens, we can pop this screen so when user returns
      // they go back to the previous screen (e.g. Offline list)
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Error launching native PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: $e')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a black screen (or loading) while native activity launches
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
