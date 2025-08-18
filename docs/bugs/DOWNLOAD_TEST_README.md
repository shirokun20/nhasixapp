# 🧪 Download System Test Guide

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK installed
- Android device/emulator connected
- Internet connection
- Storage permissions granted

### 2. Run Test
```bash
# Method 1: Using script
./run_download_test.sh

# Method 2: Manual
flutter clean
flutter pub get
flutter run test_main.dart
```

### 3. Test Content
**URL**: https://nhentai.net/g/590111/
- **ID**: 590111
- **Title**: Test Content - Nhentai 590111
- **Pages**: 5 (optimized for quick testing)
- **Format**: JPG images

## 📱 Test App Interface

### Main Actions
1. **Download Images Only** - Test basic download functionality
2. **Download as PDF** - Test PDF conversion
3. **Test Services** - Test individual services

### Status Display
- Real-time download progress
- Error messages
- File paths
- Download statistics

## 🔍 What to Test

### ✅ Basic Download Flow
1. Tap "Download Images Only"
2. **Expected**: 
   - Notification appears: "Download Started"
   - Progress updates: 20%, 40%, 60%, 80%, 100%
   - Completion notification: "Download Complete"
   - Files saved to: `/storage/emulated/0/Download/nhasix/590111/images/`

### ✅ PDF Conversion
1. Tap "Download as PDF"
2. **Expected**:
   - Images download first
   - PDF conversion starts
   - PDF saved: `/storage/emulated/0/Download/nhasix/590111/590111_Test_Content.pdf`

### ✅ Notification System
1. Check notification panel during download
2. **Expected**:
   - Progress notification with percentage
   - Action buttons (Pause/Cancel)
   - Completion notification with "Open" action

### ✅ File Structure
```
/storage/emulated/0/Download/nhasix/590111/
├── images/
│   ├── page_001.jpg
│   ├── page_002.jpg
│   ├── page_003.jpg
│   ├── page_004.jpg
│   └── page_005.jpg
├── metadata.json
└── 590111_Test_Content.pdf
```

## 🛠️ Troubleshooting

### ❌ Download Not Starting
**Symptoms**: No notification, no progress
**Solutions**:
1. Check internet connection
2. Grant storage permissions: Settings > Apps > NhasixApp > Permissions
3. Check logs: `flutter logs`

### ❌ Notifications Not Showing
**Symptoms**: Download works but no notifications
**Solutions**:
1. Grant notification permissions
2. Check notification settings
3. Restart app

### ❌ Files Not Saved
**Symptoms**: Download completes but no files
**Solutions**:
1. Check storage permissions
2. Check available storage space
3. Verify path: `/storage/emulated/0/Download/nhasix/`

### ❌ PDF Not Generated
**Symptoms**: Images download but no PDF
**Solutions**:
1. Check PDF service logs
2. Verify image files exist
3. Check write permissions

## 📊 Verification Commands

### Check Files
```bash
# List download directory
adb shell ls -la /storage/emulated/0/Download/nhasix/590111/

# Check images
adb shell ls -la /storage/emulated/0/Download/nhasix/590111/images/

# View metadata
adb shell cat /storage/emulated/0/Download/nhasix/590111/metadata.json
```

### Monitor Performance
```bash
# Memory usage
adb shell dumpsys meminfo com.example.nhasixapp

# Storage usage
adb shell df /storage/emulated/0/Download/

# App logs
flutter logs
```

## 🎯 Success Criteria

### ✅ Functional Requirements
- [ ] Download starts successfully
- [ ] Progress notifications appear
- [ ] Files saved to correct location
- [ ] PDF conversion works
- [ ] Error handling graceful

### ✅ Performance Requirements
- [ ] Memory usage < 100MB
- [ ] Download speed reasonable (2-5s per image)
- [ ] UI remains responsive
- [ ] No crashes or ANRs

### ✅ User Experience
- [ ] Clear progress indication
- [ ] Helpful error messages
- [ ] Background download works
- [ ] Notification actions functional

## 📝 Test Report Template

```
## Download Test Report

**Date**: [DATE]
**Device**: [DEVICE_MODEL]
**Android Version**: [VERSION]
**App Version**: [VERSION]

### Test Results
- [ ] Basic Download: ✅/❌
- [ ] PDF Conversion: ✅/❌
- [ ] Notifications: ✅/❌
- [ ] File Structure: ✅/❌
- [ ] Error Handling: ✅/❌

### Performance
- Memory Usage: [XX MB]
- Download Time: [XX seconds]
- File Sizes: [XX MB total]

### Issues Found
1. [Issue description]
2. [Issue description]

### Screenshots
- [Attach screenshots of notifications]
- [Attach file manager screenshots]
```

## 🔧 Advanced Testing

### Custom Content Test
```dart
// Modify test_main.dart to test different content
final customContent = Content(
  id: 'YOUR_CONTENT_ID',
  title: 'Your Test Content',
  // ... other properties
);
```

### Stress Testing
```dart
// Test multiple concurrent downloads
for (int i = 0; i < 3; i++) {
  context.read<DownloadBloc>().add(DownloadQueueEvent(content: testContent));
  context.read<DownloadBloc>().add(DownloadStartEvent(testContent.id));
}
```

### Network Simulation
```bash
# Simulate slow network
adb shell tc qdisc add dev wlan0 root netem delay 100ms

# Simulate packet loss
adb shell tc qdisc add dev wlan0 root netem loss 1%

# Reset network
adb shell tc qdisc del dev wlan0 root
```

## 📞 Support

If you encounter issues:
1. Check logs: `flutter logs`
2. Verify permissions in device settings
3. Test on different device/emulator
4. Check network connectivity
5. Review error messages in app

**Happy Testing! 🎉**