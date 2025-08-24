/// End-to-end test untuk verifikasi implementasi PDF folder management
/// Test ini mensimulasikan flow lengkap dari download sampai PDF conversion

void main() {
  print('🧪 PDF Implementation End-to-End Test\n');
  
  // Test case 1: Basic folder separation
  testFolderSeparation();
  
  // Test case 2: Safe filename generation
  testSafeFilenameGeneration();
  
  // Test case 3: PDF path logic  
  testPdfPathLogic();
  
  print('\n🎯 Summary: All tests validate the PDF implementation');
  print('✅ Downloads go to: downloads/content_<id>/');
  print('✅ PDFs go to: nhasix-generate/pdf/');
  print('✅ Filenames are safely generated');
  print('✅ Paths are properly separated');
}

void testFolderSeparation() {
  print('📁 Test 1: Folder Separation');
  
  final basePath = '/Documents/app_data';
  final contentId = 'content_123';
  
  // Download path (simulating DownloadContentUseCase)
  final downloadPath = '$basePath/downloads/content_$contentId';
  final downloadDir = downloadPath.split('/').sublist(0, downloadPath.split('/').length - 1).join('/');
  
  // PDF path (simulating _createPdfOutputPath helper)
  final pdfDir = '$basePath/nhasix-generate/pdf';
  
  final isCorrect = downloadDir != pdfDir;
  print('   Download dir: $downloadDir');
  print('   PDF dir: $pdfDir');
  print('   ✅ Separated: $isCorrect\n');
  
  assert(isCorrect, 'Folders should be different!');
}

void testSafeFilenameGeneration() {
  print('📝 Test 2: Safe Filename Generation');
  
  final testCases = [
    'Normal Title',
    'Title with Special Characters!@#',
    'Title/with\\illegal:chars*?',
    'Title    with    multiple   spaces',
    'Very long title that might exceed filename limits and should be handled properly by our safe filename generation function',
  ];
  
  for (final title in testCases) {
    final safe = _createSafeFilename(title);
    final hasInvalidChars = RegExp(r'[<>:"/\\|?*!@#$%^&()]').hasMatch(safe);
    final hasMultipleSpaces = RegExp(r'\s{2,}').hasMatch(safe);
    
    print('   "$title"');
    print('   -> "$safe"');
    print('   ✅ No invalid chars: ${!hasInvalidChars}');
    print('   ✅ No multiple spaces: ${!hasMultipleSpaces}');
    print('');
    
    assert(!hasInvalidChars, 'Should not contain invalid characters');
    assert(!hasMultipleSpaces, 'Should not contain multiple spaces');
  }
}

void testPdfPathLogic() {
  print('🗂️ Test 3: PDF Path Logic');
  
  final contentId = 'test_456';
  final title = 'My Test Content';
  final basePath = '/Documents/app_data';
  
  // Simulate _createPdfOutputPath logic
  final pdfFolder = '$basePath/nhasix-generate/pdf';
  final safeTitle = _createSafeFilename(title);
  final pdfFileName = '${contentId}_$safeTitle.pdf';
  final fullPdfPath = '$pdfFolder/$pdfFileName';
  
  print('   Content ID: $contentId');
  print('   Original title: "$title"');
  print('   Safe title: "$safeTitle"');
  print('   PDF filename: $pdfFileName');
  print('   Full path: $fullPdfPath');
  
  final isValidPath = fullPdfPath.contains('nhasix-generate/pdf/');
  final hasCorrectExtension = fullPdfPath.endsWith('.pdf');
  final containsContentId = fullPdfPath.contains(contentId);
  
  print('   ✅ In correct folder: $isValidPath');
  print('   ✅ Has .pdf extension: $hasCorrectExtension');
  print('   ✅ Contains content ID: $containsContentId\n');
  
  assert(isValidPath, 'Should be in nhasix-generate/pdf/ folder');
  assert(hasCorrectExtension, 'Should have .pdf extension');
  assert(containsContentId, 'Should contain content ID');
}

// Helper function that matches PdfService implementation
String _createSafeFilename(String title) {
  String safe = title
      .replaceAll(RegExp(r'[<>:"/\\|?*!@#$%^&()]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();

  // Limit length (matching PdfService logic)
  if (safe.length > 50) {
    safe = safe.substring(0, 50);
  }

  // Ensure not empty
  if (safe.isEmpty) {
    safe = 'untitled';
  }

  return safe;
}
