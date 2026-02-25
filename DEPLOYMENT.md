# Deployment Guide - digitize.art

## Pre-Deployment Checklist

### Code Quality
- [ ] All tests passing (`flutter test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Performance profiling done
- [ ] Memory leaks checked
- [ ] Code coverage > 80%

### Assets & Resources
- [ ] App icons generated (iOS + Android)
- [ ] Splash screens created
- [ ] ML models optimized and included
- [ ] Translations complete (FR, EN minimum)
- [ ] Privacy policy & Terms of Service written

### Integrations
- [ ] Firebase project configured
- [ ] Google Play Console set up
- [ ] Apple Developer account ready
- [ ] Payment provider configured (Stripe/RevenueCat)
- [ ] Analytics integrated
- [ ] Crash reporting enabled (Sentry/Firebase Crashlytics)

---

## Build Configuration

### Version Management

**pubspec.yaml**
```yaml
name: digitize_art
description: Professional artwork digitization app
publish_to: 'none'

version: 1.0.0+1  # version+build_number
# Increment:
# - Major (1.x.x): Breaking changes
# - Minor (x.1.x): New features
# - Patch (x.x.1): Bug fixes
# - Build (+1): Each build
```

### Environment Variables

Create `.env` file (add to `.gitignore`):
```env
# Firebase
FIREBASE_API_KEY=your_key_here
FIREBASE_APP_ID=your_app_id

# RevenueCat (for subscriptions)
REVENUECAT_API_KEY=your_key

# Sentry (crash reporting)
SENTRY_DSN=your_dsn

# Feature flags
ENABLE_AR_GUIDANCE=true
ENABLE_PREMIUM_FEATURES=true
```

---

## iOS Deployment

### 1. Xcode Configuration

**ios/Runner/Info.plist**
```xml
<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan your artwork</string>

<!-- Photo library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Save and import artwork images</string>

<!-- ARKit -->
<key>NSCameraUsageDescription</key>
<string>AR guidance for optimal artwork positioning</string>
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
</array>
```

### 2. Build for iOS

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS
flutter build ios --release

# Or build IPA for distribution
flutter build ipa --release
```

### 3. App Store Connect

1. **Create app listing**:
   - App name: digitize.art
   - Primary language: French
   - Bundle ID: art.digitize.app
   - SKU: digitize-art-001

2. **App Information**:
   - Category: Graphics & Design / Productivity
   - Age Rating: 4+ (no sensitive content)
   - Privacy Policy URL: https://digitize.art/privacy
   - Support URL: https://digitize.art/support

3. **Pricing**:
   - Base app: Free
   - In-App Purchases:
     - Premium Monthly: 9.99€
     - Premium Yearly: 79.99€
     - Lifetime: 199.99€

4. **Submit for Review**:
   - Upload build via Xcode or Application Loader
   - Add screenshots (6.5", 5.5", iPad Pro)
   - Write App Preview video (optional but recommended)
   - Fill out review notes

### 4. TestFlight Beta

```bash
# Upload to TestFlight
flutter build ipa --release
# Upload via Xcode or Transporter app

# Add beta testers
# Internal: Up to 100 (Apple ID)
# External: Up to 10,000 (email)
```

---

## Android Deployment

### 1. Build Configuration

**android/app/build.gradle**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "art.digitize.app"
        minSdkVersion 24  // Android 7.0
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        
        multiDexEnabled true
    }
    
    signingConfigs {
        release {
            storeFile file(KEYSTORE_PATH)
            storePassword KEYSTORE_PASSWORD
            keyAlias KEY_ALIAS
            keyPassword KEY_PASSWORD
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. Generate Keystore

```bash
keytool -genkey -v -keystore digitize-art-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias digitize-art

# Store keystore securely (DO NOT commit to git)
# Create key.properties:
storePassword=<password>
keyPassword=<password>
keyAlias=digitize-art
storeFile=../digitize-art-keystore.jks
```

### 3. Build Android

```bash
# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 4. Google Play Console

1. **Create app**:
   - App name: digitize.art
   - Default language: French
   - App/Game: App
   - Free/Paid: Free

2. **Store Listing**:
   - Short description (80 chars): "Numérisez vos œuvres d'art en qualité pro avec votre smartphone"
   - Full description: [Write compelling description]
   - App icon: 512x512 PNG
   - Screenshots: Phone (min 2), Tablet (optional)
   - Feature graphic: 1024x500 PNG

3. **Content Rating**:
   - PEGI: 3
   - ESRB: Everyone

4. **App Pricing**:
   - Free
   - In-app products: [Configure subscriptions]

5. **Release**:
   - Production track: Upload AAB
   - Internal testing → Closed testing → Open testing → Production
   - Roll out to 10% → 50% → 100%

---

## CI/CD Pipeline (GitHub Actions)

**`.github/workflows/build.yml`**
```yaml
name: Build & Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # Tests
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  # Build iOS
  build-ios:
    runs-on: macos-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
      # Upload to TestFlight (requires Apple credentials)

  # Build Android
  build-android:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
      - run: flutter build appbundle --release
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: art.digitize.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

---

## Fastlane Integration (Recommended)

### Setup Fastlane

```bash
# Install
sudo gem install fastlane

# Initialize for iOS
cd ios
fastlane init

# Initialize for Android
cd android
fastlane init
```

### iOS Fastfile

**`ios/fastlane/Fastfile`**
```ruby
default_platform(:ios)

platform :ios do
  desc "Push to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "Runner.xcodeproj")
    
    # Build
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    
    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
    
    # Notify team
    slack(message: "New iOS build uploaded to TestFlight!")
  end
  
  desc "Deploy to App Store"
  lane :release do
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_app_store
  end
end
```

### Android Fastfile

**`android/fastlane/Fastfile`**
```ruby
default_platform(:android)

platform :android do
  desc "Deploy to internal track"
  lane :internal do
    gradle(task: "bundle", build_type: "Release")
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
  
  desc "Promote to production"
  lane :production do
    upload_to_play_store(
      track: 'production',
      skip_upload_aab: true,
      skip_upload_metadata: false
    )
  end
end
```

---

## Monitoring & Analytics

### Firebase Analytics

```dart
// Track key events
class Analytics {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  static Future<void> logArtworkScanned() async {
    await analytics.logEvent(
      name: 'artwork_scanned',
      parameters: {'method': 'camera'},
    );
  }
  
  static Future<void> logPremiumUpgrade() async {
    await analytics.logEvent(
      name: 'premium_upgrade',
      parameters: {'plan': 'yearly'},
    );
  }
}
```

### Crash Reporting (Sentry)

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.tracesSampleRate = 0.1;
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

### Performance Monitoring

```dart
// Track critical operations
Future<void> processImage(String path) async {
  final trace = FirebasePerformance.instance.newTrace('image_processing');
  await trace.start();
  
  try {
    // Process image
    await imageService.process(path);
    trace.setMetric('image_size_mb', sizeInMB);
  } finally {
    await trace.stop();
  }
}
```

---

## Release Checklist

### Pre-Release
- [ ] Version bumped in `pubspec.yaml`
- [ ] Changelog updated (`CHANGELOG.md`)
- [ ] All translations complete
- [ ] Beta tested on TestFlight/Internal Track
- [ ] No critical bugs in production
- [ ] Performance benchmarks met
- [ ] Security audit completed

### Release Day
- [ ] Build and upload to stores
- [ ] Submit for review
- [ ] Monitor crash reports
- [ ] Check analytics for anomalies
- [ ] Prepare rollback plan

### Post-Release
- [ ] Monitor user reviews
- [ ] Track key metrics (DAU, retention, crashes)
- [ ] Hotfix ready if needed
- [ ] Plan next release features

---

## Rollback Strategy

### iOS
```bash
# If critical bug found, submit hotfix immediately
flutter build ipa --release
# Upload new build
# Select old build as current version in App Store Connect
```

### Android
```bash
# Use Google Play Console
# Halt rollout at current percentage
# Fix bug, upload new APK
# Resume rollout
```

---

## Update Strategy

### Semantic Versioning
- **1.0.x**: Patch (bug fixes)
- **1.x.0**: Minor (new features, backward compatible)
- **x.0.0**: Major (breaking changes)

### Release Cadence
- **Hotfixes**: As needed (critical bugs)
- **Patch**: Every 2 weeks
- **Minor**: Monthly
- **Major**: Quarterly

### Feature Flags
```dart
class FeatureFlags {
  static bool get arGuidanceEnabled => 
    RemoteConfig.instance.getBool('ar_guidance_enabled');
  
  static bool get aiEnhancementEnabled => 
    RemoteConfig.instance.getBool('ai_enhancement_enabled');
}

// Roll out features gradually
// Enable for 10% users → 50% → 100%
```

---

## Cost Estimation (Monthly)

### Development
- Firebase (Spark plan): Free → $25/month
- Sentry (Team): $26/month
- CI/CD (GitHub Actions): Free (public) / $4/month (private)

### Distribution
- Apple Developer: $99/year
- Google Play: $25 one-time

### Premium Revenue (estimated)
- 1,000 users @ 10% conversion = 100 premium
- 100 × 9.99€/month = €999/month
- Minus 30% App Store fee = €699/month net

### Scaling Costs
- 10,000 users: ~$100/month (Firebase + storage)
- 100,000 users: ~$500/month
- 1,000,000 users: ~$3,000/month

---

## Support & Maintenance

### User Support Channels
- Email: support@digitize.art
- In-app chat (Intercom/Zendesk)
- FAQs: https://digitize.art/faq
- Community: Discord/Reddit

### Maintenance Schedule
- **Daily**: Monitor crashes, analytics
- **Weekly**: Review user feedback, triage bugs
- **Monthly**: Security updates, dependency upgrades
- **Quarterly**: Major features, redesign

---

**✅ Ready to deploy! Follow this guide step-by-step for a smooth launch.**
