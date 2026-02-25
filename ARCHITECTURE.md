# Architecture Technique - digitize.art

## Architecture Globale

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (Dart)                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer                                         │
│  ├─ Screens (UI)                                           │
│  ├─ Widgets (Components réutilisables)                     │
│  └─ State Management (Riverpod/Bloc)                       │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer                                       │
│  ├─ Services (Camera, Image Processing, AR, Export)        │
│  ├─ Repositories (Data access abstraction)                 │
│  └─ Use Cases (Business rules)                             │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│  ├─ Local (SQLite, SharedPreferences)                      │
│  ├─ Remote (Firebase, Cloud APIs)                          │
│  └─ Models (Data structures)                               │
└─────────────────────────────────────────────────────────────┘
           │                │              │
           ▼                ▼              ▼
    ┌──────────┐    ┌──────────┐   ┌──────────┐
    │ Firebase │    │  OpenCV  │   │ ML Models│
    │ Backend  │    │  Native  │   │ TFLite   │
    └──────────┘    └──────────┘   └──────────┘
```

## Structure du Projet Flutter

```
digitize_art/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── extensions/
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── presentation/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── capture/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── camera_screen.dart
│   │   │   │   │   └── preview_screen.dart
│   │   │   │   ├── widgets/
│   │   │   │   └── providers/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── data/
│   │   │       ├── models/
│   │   │       ├── repositories/
│   │   │       └── datasources/
│   │   ├── tutorial/
│   │   │   ├── presentation/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── ar_guidance/
│   │   ├── editing/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── editor_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── crop_widget.dart
│   │   │   │       ├── color_adjustment_widget.dart
│   │   │   │       └── filter_widget.dart
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── gallery/
│   │   ├── export/
│   │   ├── cloud_sync/
│   │   └── premium/
│   └── shared/
│       ├── widgets/
│       ├── services/
│       │   ├── camera_service.dart
│       │   ├── image_processing_service.dart
│       │   ├── ml_service.dart
│       │   └── ar_service.dart
│       └── repositories/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── kotlin/ (OpenCV native bindings)
│               └── AndroidManifest.xml
├── ios/
│   └── Runner/
│       ├── Info.plist
│       └── Native/ (OpenCV/ARKit bindings)
├── assets/
│   ├── images/
│   ├── ml_models/
│   │   ├── edge_detection.tflite
│   │   └── image_enhancement.tflite
│   └── tutorials/
└── test/
```

## Flux Utilisateur Détaillé

### 1. Onboarding (Premier lancement)
```
Start → Welcome Screen → Feature Tour → Permission Requests 
(Camera, Storage, Location?) → Tutorial Choice → Home
```

### 2. Capture Flow (Principal)
```
Home → Tap "Scan" → Camera Screen
│
├─ AR Guidance Mode (Optional)
│  └─ Overlay guides (grid, edges, lighting indicator)
│
├─ Capture Image
│  ├─ Auto edge detection
│  ├─ Quality check (blur detection, lighting analysis)
│  └─ Multi-shot mode (bracket exposure)
│
└─ Preview Screen
   ├─ Accept/Retake
   └─ Next → Processing
      ├─ Edge detection & crop
      ├─ Perspective correction
      ├─ Color optimization
      └─ Enhancement (ML)
         └─ Editor Screen
```

### 3. Editing Flow
```
Editor Screen
├─ Basic Adjustments
│  ├─ Crop/Rotate
│  ├─ Brightness/Contrast
│  ├─ Saturation
│  └─ White Balance
├─ Advanced (Premium)
│  ├─ Selective color correction
│  ├─ Noise reduction
│  ├─ Sharpness
│  └─ AI Enhancement
└─ Metadata
   ├─ Title, Artist, Date
   ├─ Description
   ├─ Tags
   └─ Original dimensions
      └─ Save/Export
```

### 4. Export Flow
```
Export Options
├─ Format Selection
│  ├─ JPEG (quality selector)
│  ├─ PNG
│  └─ TIFF (Premium)
├─ Resolution
│  ├─ Original
│  ├─ 4K
│  ├─ 2K (Free limit)
│  └─ Web (1080p)
├─ Destination
│  ├─ Local Storage
│  ├─ Cloud (Firebase/Drive/iCloud)
│  ├─ Social (Instagram, Twitter, etc.)
│  └─ Email/Share
└─ Process & Export
```

## Services Core

### CameraService
```dart
- initCamera()
- startPreview()
- captureImage()
- detectEdges() (real-time)
- analyzeLighting()
- stabilizationCheck()
```

### ImageProcessingService
```dart
- detectEdges(image)
- correctPerspective(image, corners)
- enhanceImage(image)
- adjustColors(image, params)
- removeNoise(image)
- sharpen(image)
- cropToEdges(image)
```

### MLService
```dart
- loadModels()
- detectArtworkEdges(image)
- enhanceQuality(image)
- colorCorrection(image)
- blurDetection(image)
```

### ARService
```dart
- initAR()
- renderGuides()
- trackSurface()
- measureDistance()
- lightingIndicator()
```

## Data Models

### Artwork
```dart
class Artwork {
  String id;
  String title;
  String artistName;
  DateTime captureDate;
  DateTime creationDate;
  String description;
  List<String> tags;
  
  // Image data
  String originalImagePath;
  String processedImagePath;
  String thumbnailPath;
  
  // Metadata
  ArtworkDimensions originalDimensions;
  ImageQuality quality;
  
  // Processing info
  ProcessingSettings processingSettings;
  
  // Cloud
  bool isSynced;
  String? cloudUrl;
  
  // Premium
  bool isPremium;
}
```

### ProcessingSettings
```dart
class ProcessingSettings {
  double brightness;
  double contrast;
  double saturation;
  double sharpness;
  WhiteBalance whiteBalance;
  CropData? cropData;
  List<Filter> appliedFilters;
}
```

## API & Intégrations

### Firebase
- **Authentication**: Email, Google, Apple Sign-In
- **Firestore**: Artwork metadata, user profiles
- **Storage**: Images (original + processed)
- **Cloud Functions**: 
  - Image processing (backup/heavy processing)
  - Thumbnail generation
  - ML inference (optional cloud-based)

### Third-party APIs (Optional)
- Google Drive API
- iCloud integration (iOS)
- Social media SDKs (Instagram, Pinterest)

## Sécurité & Confidentialité

1. **Local-first**: Processing on-device par défaut
2. **Encryption**: AES-256 pour cloud storage
3. **Privacy**: 
   - Pas de tracking sans consentement
   - Images jamais partagées sans permission explicite
   - Option "Local only" pour ne jamais uploader
4. **RGPD compliant**: Droit à l'oubli, export data

## Performance Considerations

1. **Image Processing**: 
   - Background isolates pour éviter UI freeze
   - Progressive loading
   - Caching intelligent

2. **Battery**: 
   - Limit AR refresh rate
   - Efficient camera usage
   - Background processing optimization

3. **Storage**: 
   - Compression intelligente
   - Cleanup old cache
   - Storage limits avec warnings

4. **Network**: 
   - Upload queue
   - Retry logic
   - Offline mode complet
