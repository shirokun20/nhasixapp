# 📱 Custom APK Naming Setup

Setup untuk menggenerate APK dengan nama custom format: `nhasix_[version]_[date]_[buildType].apk`

## 🎯 Format Nama File

```
nhasix_[version]_[date]_[buildType].apk
```

**Contoh:**
- `nhasix_0.1.0_20250824_debug.apk`
- `nhasix_0.1.0_20250824_release.apk`
- `nhasix_1.2.3_20250825_release.apk`

## ⚙️ Implementasi

### 1. Modifikasi `android/app/build.gradle`

Tambahkan kode berikut di dalam block `android {}`:

```groovy
android {
    // ... existing config ...

    // Custom APK naming: nhasix_[version]_[date].apk
    applicationVariants.all { variant ->
        variant.outputs.all {
            def versionName = variant.versionName
            def buildType = variant.buildType.name
            def date = new Date().format('yyyyMMdd')
            
            // Custom filename format: nhasix_[version]_[date]_[buildType].apk
            def fileName = "nhasix_${versionName}_${date}_${buildType}.apk"
            outputFileName = fileName
        }
    }
}
```

### 2. Version dari `pubspec.yaml`

Version diambil otomatis dari `pubspec.yaml`:

```yaml
version: 0.1.0+1  # Format: version+buildNumber
```

Version name yang digunakan: `0.1.0`

## 🚀 Cara Build

### Method 1: Flutter Command (Manual)

```bash
# Debug build
flutter build apk --debug

# Release build  
flutter build apk --release
```

**Output location:** `build/app/outputs/apk/[debug|release]/`

### Method 2: Build Script (Recommended)

```bash
# Debug build
./build_apk.sh debug

# Release build
./build_apk.sh release

# Default (debug)
./build_apk.sh
```

**Features script:**
- ✅ Automatic clean project
- ✅ Build with custom naming
- ✅ Show output location
- ✅ Copy to project root for easy access
- ✅ Progress indicators

## 📁 Output Locations

### 1. Original Flutter Output
```
build/app/outputs/flutter-apk/
├── app-debug.apk      # Default debug
└── app-release.apk    # Default release
```

### 2. Custom Named Output
```
build/app/outputs/apk/debug/
└── nhasix_0.1.0_20250824_debug.apk

build/app/outputs/apk/release/
└── nhasix_0.1.0_20250824_release.apk
```

### 3. Project Root (via script)
```
./nhasix_0.1.0_20250824_debug.apk    # Copied by script
./nhasix_0.1.0_20250824_release.apk  # Copied by script
```

## 🔍 Verification

Check custom named APK files:

```bash
# Find all custom named APKs
find build -name "nhasix_*.apk" -type f

# List with details
ls -la build/app/outputs/apk/*/*.apk
```

## 📝 Format Details

| Component | Description | Example |
|-----------|-------------|---------|
| `nhasix` | App name prefix | `nhasix` |
| `[version]` | From pubspec.yaml | `0.1.0` |
| `[date]` | Build date (YYYYMMDD) | `20250824` |
| `[buildType]` | debug/release | `debug` |
| `.apk` | File extension | `.apk` |

## 🎨 Customization

### Change App Name Prefix

Edit `build.gradle` line:
```groovy
def fileName = "yourapp_${versionName}_${date}_${buildType}.apk"
```

### Change Date Format

Edit `build.gradle` line:
```groovy
def date = new Date().format('yyyy-MM-dd')  // 2025-08-24
def date = new Date().format('yyMMdd')      // 250824
```

### Add Build Number

```groovy
def versionCode = variant.versionCode
def fileName = "nhasix_${versionName}_${versionCode}_${date}_${buildType}.apk"
// Result: nhasix_0.1.0_1_20250824_debug.apk
```

## ✅ Benefits

1. **🔍 Easy Identification** - Langsung tahu version dan tanggal build
2. **📦 Version Control** - Track berbagai version APK
3. **🗓️ Date Tracking** - Tahu kapan APK dibuild
4. **🔧 Build Type** - Bedakan debug vs release
5. **📁 Organization** - APK terorganisir dengan baik
6. **🤖 Automation** - Nama generate otomatis setiap build

## 🛠️ Troubleshooting

### APK masih menggunakan nama default?

1. **Check gradle modification:**
   ```bash
   grep -A 10 "applicationVariants.all" android/app/build.gradle
   ```

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter build apk --debug
   ```

3. **Check output location:**
   ```bash
   find build -name "*.apk" -type f
   ```

### Script permission denied?

```bash
chmod +x build_apk.sh
```

### Multiple APK files found?

- Default APK: `build/app/outputs/flutter-apk/`
- Custom APK: `build/app/outputs/apk/[debug|release]/`

Use custom APK for distribution! 🎯
