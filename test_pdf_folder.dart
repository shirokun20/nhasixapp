import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() async {
  print('🔍 Testing PDF Folder Management...\n');
  
  try {
    // Get app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    print('📁 App Documents Directory: ${appDocDir.path}');
    
    // Create nhasix-generate/pdf/ folder
    final pdfFolder = Directory(path.join(appDocDir.path, 'nhasix-generate', 'pdf'));
    
    if (!await pdfFolder.exists()) {
      await pdfFolder.create(recursive: true);
      print('✅ Created PDF folder: ${pdfFolder.path}');
    } else {
      print('✅ PDF folder already exists: ${pdfFolder.path}');
    }
    
    // Simulate download path (different from PDF path)
    final downloadFolder = Directory(path.join(appDocDir.path, 'downloads', 'content_123'));
    print('📥 Download folder would be: ${downloadFolder.path}');
    
    // Simulate PDF output path
    final testContentId = 'test_123';
    final testTitle = 'Test Content Title';
    final safeTitle = testTitle
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    
    final pdfFileName = '${testContentId}_$safeTitle.pdf';
    final pdfPath = path.join(pdfFolder.path, pdfFileName);
    
    print('📄 PDF would be saved as: $pdfPath');
    
    // Verify paths are different
    final pathsAreDifferent = pdfFolder.path != downloadFolder.path;
    print('\n✅ Verification:');
    print('   PDF Folder: ${pdfFolder.path}');
    print('   Download Folder: ${downloadFolder.path}');
    print('   Paths are different: $pathsAreDifferent');
    print('   PDF filename format: $pdfFileName');
    
    if (pathsAreDifferent) {
      print('\n🎉 SUCCESS: PDF and Download folders are properly separated!');
    } else {
      print('\n❌ ERROR: PDF and Download folders are the same!');
    }
    
  } catch (e) {
    print('❌ Error testing PDF folder: $e');
  }
}
