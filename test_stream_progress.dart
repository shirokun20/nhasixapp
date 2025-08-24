import 'dart:async';
import 'package:nhasixapp/services/download_manager.dart';
import 'package:nhasixapp/domain/entities/download_task.dart';

/// Test to verify stream-based progress updates work correctly
void main() async {
  print('🔄 Testing Stream-based Progress Updates...\n');
  
  final downloadManager = DownloadManager();
  final streamData = <DownloadProgressUpdate>[];
  
  // Listen to progress stream
  StreamSubscription? subscription;
  subscription = downloadManager.progressStream.listen((data) {
    streamData.add(data);
    print('📊 Progress Update: ${data.contentId} - ${data.downloadedPages}/${data.totalPages} (${data.downloadSpeed ?? 0.0} MB/s)');
  });
  
  // Create a test download task
  const testContentId = 'test_content_123';
  final task = DownloadTask(
    contentId: testContentId,
    title: 'Test Download',
  );
  
  print('🚀 Registering test task...');
  downloadManager.registerTask(task);
  
  // Simulate progress updates
  print('📈 Simulating progress updates...\n');
  
  for (int i = 1; i <= 5; i++) {
    final update = DownloadProgressUpdate(
      contentId: testContentId,
      downloadedPages: i * 20,
      totalPages: 100,
      downloadSpeed: 2.5 + (i * 0.1),
    );
    downloadManager.emitProgress(update);
    
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  // Test pause functionality
  print('\n⏸️  Testing pause functionality...');
  task.pause();
  print('   Task paused: ${task.isPaused}');
  
  // Test cancel functionality
  print('❌ Testing cancel functionality...');
  task.cancel();
  print('   Task cancelled: ${task.isCancelled}');
  
  // Test resume functionality
  print('▶️  Testing resume functionality...');
  task.resume();
  print('   Task resumed: ${!task.isPaused && !task.isCancelled}');
  
  // Wait a bit for all stream events
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Clean up
  print('\n🧹 Cleaning up...');
  downloadManager.unregisterTask(testContentId);
  await subscription.cancel();
  
  // Verify results
  print('\n✅ Verification:');
  print('   Stream events received: ${streamData.length}');
  print('   Expected: 5 progress updates');
  
  if (streamData.length == 5) {
    print('   ✅ Stream progress test PASSED');
    
    // Verify data structure
    final firstEvent = streamData.first;
    final hasRequiredFields = firstEvent.contentId == testContentId && 
                             firstEvent.downloadedPages > 0 && 
                             firstEvent.totalPages == 100 && 
                             firstEvent.downloadSpeed != null;
    
    if (hasRequiredFields) {
      print('   ✅ Stream data structure test PASSED');
    } else {
      print('   ❌ Stream data structure test FAILED');
    }
    
    // Verify progression
    bool progressionCorrect = true;
    for (int i = 0; i < streamData.length; i++) {
      final expected = (i + 1) * 20;
      final actual = streamData[i].downloadedPages;
      if (actual != expected) {
        progressionCorrect = false;
        break;
      }
    }
    
    if (progressionCorrect) {
      print('   ✅ Progress progression test PASSED');
    } else {
      print('   ❌ Progress progression test FAILED');
    }
    
  } else {
    print('   ❌ Stream progress test FAILED (expected 5, got ${streamData.length})');
  }
  
  print('\n🎉 Stream-based Progress Test Complete!\n');
}
