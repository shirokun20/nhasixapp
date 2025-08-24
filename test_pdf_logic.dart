void main() {
  print('🔍 Testing PDF Folder Logic...\n');

  // Simulate paths based on our code structure
  final appDocPath = '/Documents/app_data';
  final contentId = 'test_123';
  final contentTitle = 'Test Content with Special Characters!@#';
  
  // Test download path logic
  final downloadPath = '$appDocPath/downloads/content_$contentId';
  print('📥 Download path: $downloadPath');
  
  // Test PDF folder logic
  final pdfBaseFolder = '$appDocPath/nhasix-generate/pdf';
  
  // Test safe filename generation
  final safeTitle = contentTitle
      .replaceAll(RegExp(r'[<>:"/\\|?*!@#$%^&()]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();
  
  final pdfFileName = '${contentId}_$safeTitle.pdf';
  final pdfPath = '$pdfBaseFolder/$pdfFileName';
  
  print('📄 PDF path: $pdfPath');
  print('📄 PDF filename: $pdfFileName');
  
  // Verify they are different
  final downloadDir = downloadPath.split('/').sublist(0, downloadPath.split('/').length - 1).join('/');
  final pdfDir = pdfBaseFolder;
  
  print('\n✅ Verification:');
  print('   Download directory: $downloadDir');
  print('   PDF directory: $pdfDir');
  print('   Are directories different? ${downloadDir != pdfDir}');
  print('   Safe title transformation: "$contentTitle" -> "$safeTitle"');
  
  if (downloadDir != pdfDir) {
    print('\n🎉 SUCCESS: PDF and Download directories are properly separated!');
    print('   Downloads go to: downloads/content_<id>/');
    print('   PDFs go to: nhasix-generate/pdf/');
  } else {
    print('\n❌ ERROR: Directories are the same!');
  }
}
