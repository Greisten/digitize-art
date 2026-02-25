#!/bin/bash
# Setup script for digitize.art Flutter project

echo "🎨 Setting up digitize.art..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not installed. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✓ Flutter found: $(flutter --version | head -n 1)"

# Create Flutter project
echo "📦 Creating Flutter project..."
flutter create --org art.digitize --platforms android,ios digitize_art

cd digitize_art || exit

echo "📝 Adding dependencies..."

# Add dependencies to pubspec.yaml
cat >> pubspec.yaml << 'EOF'

dependencies:
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Camera & Image
  camera: ^0.10.5
  image_picker: ^1.0.4
  image: ^4.1.3
  
  # Image Processing
  opencv_dart: ^1.0.4
  
  # ML & AI
  tflite_flutter: ^0.10.4
  google_mlkit_image_labeling: ^0.9.0
  google_mlkit_object_detection: ^0.10.0
  
  # AR
  arcore_flutter_plugin: ^0.1.0
  arkit_plugin: ^1.0.7
  
  # Storage & Database
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  firebase_storage: ^11.5.0
  cloud_firestore: ^4.13.0
  
  # Cloud Integration
  googleapis: ^11.4.0
  googleapis_auth: ^1.4.1
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  photo_view: ^0.14.0
  image_cropper: ^5.0.0
  
  # Utils
  uuid: ^4.2.1
  intl: ^0.18.1
  path: ^1.8.3
  permission_handler: ^11.0.1
  
  # Analytics
  firebase_analytics: ^10.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.6
EOF

echo "📥 Installing dependencies..."
flutter pub get

echo "📁 Creating folder structure..."
mkdir -p lib/{core/{constants,theme,utils,extensions},features/{onboarding,capture,tutorial,ar_guidance,editing,gallery,export,cloud_sync,premium}/{presentation/{screens,widgets,providers},domain/{entities,repositories,usecases},data/{models,repositories,datasources}},shared/{widgets,services,repositories}}

mkdir -p assets/{images,ml_models,tutorials}

echo "🔥 Setting up Firebase..."
echo "⚠️  Manual step required:"
echo "   1. Create Firebase project: https://console.firebase.google.com"
echo "   2. Add iOS & Android apps"
echo "   3. Download google-services.json (Android) and GoogleService-Info.plist (iOS)"
echo "   4. Place them in android/app/ and ios/Runner/ respectively"
echo "   5. Run: flutterfire configure"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. cd digitize_art"
echo "2. Set up Firebase (see instructions above)"
echo "3. Run: flutter run"
