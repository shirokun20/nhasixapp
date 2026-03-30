# Kuron Native

A powerhouse Flutter plugin providing premium native utilities and widgets.

## Features 🚀

-   **Wrapper Widgets**: High-quality, glassmorphism-styled widgets for PDF, Web, and Downloads.
-   **Ad-Blocking Web**: Built-in native ad-blocker for clean web browsing.
-   **SSO Login**: Robust OAuth/OIDC login flow with token interception.
-   **System Utilities**: Access Device RAM, Battery, and Storage stats.
-   **Backup & Restore**: Easy JSON export/import to local storage.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  kuron_native:
    path: packages/kuron_native
```

## Widgets Usage

### 1. SSO Login Button
Handle complex login flows effortlessly.

```dart
KuronSSOButton(
  label: 'Login with Kuron',
  loginUrl: 'https://example.com/login',
  redirectUrl: 'https://example.com/callback',
  onSuccess: (data) {
    print('Token: ${data['cookies']}');
  },
)
```

### 2. PDF & Downloads
Auto-handles permissions and file checks.

```dart
// Open PDF
KuronPdfButton(
  filePath: '/storage/.../file.pdf',
  label: 'Open Report',
);

// Download File
KuronDownloadCard(
  url: 'https://example.com/file.pdf',
  fileName: 'report.pdf',
  title: 'Annual Report',
);
```

### 3. Web & Ad-Block
Open web pages with built-in ad protection.

```dart
KuronWebButton(
  url: 'https://example.com',
  label: 'Browse',
  enableAdBlock: true, // Blocks ads natively!
);
```

### 4. System Info
Display device health stats.

```dart
KuronInfoCard(title: 'RAM Usage', type: 'ram');
KuronInfoCard(title: 'Battery', type: 'battery');
```

### 5. Backup & Restore
Export data to JSON file in Downloads.

```dart
// Export
KuronExportButton(
  data: '{"favorite": "manga"}', 
  fileName: 'backup.json'
);

// Import
KuronImportButton(
  onImport: (jsonString) {
    print('Restored: $jsonString');
  },
);
```

## Permissions
This package uses `permission_handler` to automatically request:
-   `storage` (for downloads/backup)

Ensure your `AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```
