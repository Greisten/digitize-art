# Défis Potentiels & Solutions - digitize.art

## 1. Qualité de Caméra Variable

### Problème
Les smartphones ont des capteurs de qualités très différentes (budget phones vs flagship). Les résultats peuvent varier énormément.

### Solutions

#### A. Détection adaptative de qualité
```dart
class DeviceCapabilities {
  // Detect device camera capabilities on startup
  static Future<CameraQuality> detectQuality() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    
    // Check sensor resolution
    // Adjust processing based on device tier
    return CameraQuality.fromResolution(backCamera);
  }
}
```

#### B. Multi-shot avec bracketing
- Prendre 3 photos avec différentes expositions
- Fusionner en HDR pour meilleure qualité
- Améliore particulièrement sur devices mid-range

#### C. Recommandations contextuelles
```dart
if (deviceQuality == CameraQuality.low) {
  showTip('Pour de meilleurs résultats, utilisez un éclairage extérieur');
  recommendExternalCamera();
}
```

#### D. Compression intelligente
- Utiliser HEIF/HEIC sur iOS (meilleure compression)
- Ajuster qualité JPEG selon device storage
- Offrir option "Raw mode" sur devices compatibles

---

## 2. Gestion de la Batterie

### Problème
AR, traitement ML et caméra haute résolution consomment beaucoup de batterie.

### Solutions

#### A. Mode batterie optimisé
```dart
class PowerManager {
  static PowerMode currentMode = PowerMode.balanced;
  
  static void optimizeForBattery() {
    // Reduce camera resolution
    cameraResolution = ResolutionPreset.high; // instead of veryHigh
    
    // Disable AR guidance
    arEnabled = false;
    
    // Reduce ML inference frequency
    mlInferenceInterval = Duration(seconds: 2); // instead of realtime
    
    // Lower screen brightness during capture
  }
}
```

#### B. Processing progressif
- Effectuer traitement lourd en background après capture
- Utiliser isolates pour éviter UI freeze
- Option "Process later" pour batch processing quand en charge

#### C. Monitoring batterie
```dart
void checkBatteryLevel() async {
  final batteryLevel = await Battery().batteryLevel;
  
  if (batteryLevel < 20) {
    showDialog('Low battery - Switch to power saving mode?');
    PowerManager.optimizeForBattery();
  }
}
```

#### D. Wake locks intelligents
```dart
// Keep screen on ONLY during active capture
await WakelockPlus.enable(); // During camera session
await WakelockPlus.disable(); // When idle in editor
```

---

## 3. Performance du Traitement d'Images

### Problème
Processing d'images haute résolution peut prendre plusieurs secondes et bloquer l'UI.

### Solutions

#### A. Background processing avec Isolates
```dart
Future<String> processImageBackground(String path) async {
  return await compute(_processImage, path);
}

static Future<String> _processImage(String path) async {
  // Heavy processing in separate isolate
  // Perspective correction, enhancement, etc.
}
```

#### B. Progressive loading
```dart
// Show low-res preview immediately
final thumbnail = await generateThumbnail(image);
showPreview(thumbnail);

// Process full resolution in background
final processed = await processFullResolution(image);
updatePreview(processed);
```

#### C. Caching agressif
```dart
class ImageCache {
  static final Map<String, ProcessedImage> _cache = {};
  
  static ProcessedImage? get(String key) => _cache[key];
  
  static void set(String key, ProcessedImage value) {
    _cache[key] = value;
    _cleanupOldEntries(); // LRU eviction
  }
}
```

#### D. Optimisation OpenCV
```dart
// Use pyramid processing for large images
if (image.width > 4000) {
  // Process at lower resolution first
  final downscaled = resize(image, width: 2000);
  final corners = detectEdges(downscaled);
  
  // Scale corners back to original size
  final scaledCorners = corners.map((c) => c * 2.0);
  
  // Apply to full resolution
  return correctPerspective(image, scaledCorners);
}
```

---

## 4. Précision de Détection des Bords

### Problème
Détecter les bords d'une œuvre peut échouer si:
- Fond similaire à l'œuvre
- Éclairage non uniforme
- Œuvre non rectangulaire
- Reflets sur peintures

### Solutions

#### A. Guide utilisateur interactif
```dart
class ManualEdgeAdjustment extends StatefulWidget {
  // Let user manually adjust detected corners
  // Drag corners to correct positions
  // Preview in real-time
}
```

#### B. Amélioration ML
```dart
// Train custom TFLite model on artwork images
class ArtworkEdgeDetector {
  static Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('artwork_edge_model.tflite');
  }
  
  static Future<List<Point>> detect(Image image) async {
    // Run inference
    // More accurate than generic edge detection
  }
}
```

#### C. Multi-frame analysis
```dart
// Capture multiple frames and average edge detection
Future<List<Point>> robustEdgeDetection() async {
  final frames = await captureMultipleFrames(count: 5);
  final allCorners = await Future.wait(
    frames.map((f) => detectEdges(f)),
  );
  
  // Average corner positions
  return averageCorners(allCorners);
}
```

#### D. Contraste adaptatif
```dart
// Enhance contrast between artwork and background
Future<Image> enhanceForDetection(Image input) async {
  // Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
  // Increase edge visibility
  // Better detection even in poor lighting
}
```

---

## 5. Stockage et Gestion de l'Espace

### Problème
Images haute résolution prennent beaucoup d'espace (10-50 MB par image).

### Solutions

#### A. Compression intelligente
```dart
class StorageManager {
  static Future<void> compressIfNeeded(Artwork artwork) async {
    final size = await File(artwork.originalPath).length();
    
    if (size > 20 * 1024 * 1024) { // > 20 MB
      // Compress with minimal quality loss
      final compressed = await compressImage(
        artwork.originalPath,
        quality: 92, // Sweet spot
      );
      
      // Replace original
      await File(artwork.originalPath).delete();
      artwork.originalPath = compressed;
    }
  }
}
```

#### B. Storage tiers
```dart
enum StorageTier {
  original,    // Full resolution, uncompressed
  processed,   // Full res, optimized compression
  preview,     // Medium res for gallery
  thumbnail,   // Low res for list view
}

// Auto-delete originals after processing (opt-in)
// Keep only processed + thumbnails
```

#### C. Cloud offloading
```dart
// Auto-upload to cloud after 24h
// Delete local original, keep thumbnail
// Download on-demand when user opens

class CloudSync {
  static Future<void> offloadOldImages() async {
    final old = await getImagesOlderThan(days: 1);
    
    for (final artwork in old) {
      if (!artwork.isSynced) {
        await uploadToCloud(artwork);
        await deleteLocalOriginal(artwork);
      }
    }
  }
}
```

#### D. Storage monitoring
```dart
void checkStorageSpace() async {
  final freeSpace = await DiskSpace.getFreeDiskSpace();
  
  if (freeSpace < 500 * 1024 * 1024) { // < 500 MB
    showDialog(
      'Low storage space. Clean up old scans?',
      actions: [
        'Delete processed originals',
        'Upload to cloud',
        'Cancel',
      ],
    );
  }
}
```

---

## 6. Expérience Utilisateur pour Non-Tech

### Problème
Artistes peuvent être intimidés par une app technique.

### Solutions

#### A. Onboarding interactif
```dart
// Step-by-step tutorial with animations
// Show example "before/after"
// Voice guidance option (TTS)

class InteractiveTutorial {
  static List<TutorialStep> steps = [
    TutorialStep(
      title: 'Trouvez un bon éclairage',
      video: 'assets/tutorials/lighting.mp4',
      audioGuide: 'assets/audio/lighting_fr.mp3',
      tip: 'Évitez le flash direct',
    ),
    // ...
  ];
}
```

#### B. Smart defaults
```dart
// Auto-select best settings
// Hide advanced options by default
// "Simple Mode" vs "Pro Mode"

if (userExperience == ExperienceLevel.beginner) {
  hideAdvancedSettings();
  enableAutoMode();
  showHelpTooltips();
}
```

#### C. Feedback visuel constant
```dart
// Real-time indicators
Widget buildStatusIndicators() {
  return Column(
    children: [
      StatusBadge(
        icon: Icons.wb_sunny,
        label: 'Lighting',
        status: lightingQuality,
        color: lightingColor,
      ),
      StatusBadge(
        icon: Icons.filter_frames,
        label: 'Edges',
        status: edgesDetected ? 'Detected' : 'Searching...',
      ),
      StatusBadge(
        icon: Icons.straighten,
        label: 'Distance',
        status: distance,
      ),
    ],
  );
}
```

#### D. Contextual help
```dart
// Show tips based on detected issues
if (imageTooBlurry) {
  showInlineHelp('Stabilisez votre téléphone ou utilisez un trépied');
}

if (lightingPoor) {
  showInlineHelp('Déplacez-vous vers une source de lumière naturelle');
}
```

---

## 7. Cross-Platform Consistency (iOS vs Android)

### Problème
Comportements différents entre iOS et Android (AR, camera APIs, permissions).

### Solutions

#### A. Platform-specific implementations
```dart
abstract class ARService {
  Future<void> initialize();
  Stream<ARFrame> get frames;
}

class ARServiceIOS implements ARService {
  // ARKit implementation
}

class ARServiceAndroid implements ARService {
  // ARCore implementation
}

ARService createARService() {
  if (Platform.isIOS) return ARServiceIOS();
  return ARServiceAndroid();
}
```

#### B. Graceful degradation
```dart
// If AR not available, use alternative guides
if (!await ARService.isSupported()) {
  useGridOverlay();
  showManualGuidance();
}
```

#### C. Unified testing
```dart
// Integration tests on both platforms
void main() {
  testWidgets('Camera capture works', (tester) async {
    // Test on iOS simulator
    // Test on Android emulator
    // Ensure same behavior
  });
}
```

#### D. Permission handling
```dart
Future<bool> requestCameraPermission() async {
  if (Platform.isIOS) {
    // iOS-specific flow
    final status = await Permission.camera.request();
    if (status.isDenied) {
      showIOSSettingsDialog();
    }
  } else {
    // Android flow
    final status = await Permission.camera.request();
  }
}
```

---

## 8. Sécurité et Confidentialité des Œuvres

### Problème
Les artistes sont protecteurs de leurs créations non publiées.

### Solutions

#### A. Local-first architecture
```dart
// Everything processes on-device by default
// No automatic cloud upload without explicit consent

class PrivacySettings {
  static bool cloudSyncEnabled = false; // Default: OFF
  static bool analyticsEnabled = false;
  static bool crashReportingEnabled = false;
}
```

#### B. Encryption at rest
```dart
// Encrypt images stored locally
class SecureStorage {
  static Future<void> saveImage(String path, Uint8List data) async {
    final encrypted = await encrypt(data, userKey);
    await File(path).writeAsBytes(encrypted);
  }
  
  static Future<Uint8List> loadImage(String path) async {
    final encrypted = await File(path).readAsBytes();
    return await decrypt(encrypted, userKey);
  }
}
```

#### C. Watermarking option
```dart
// Add invisible watermark to shared images
class WatermarkService {
  static Future<String> addWatermark(
    String imagePath,
    String artistName,
  ) async {
    // Embed metadata in EXIF
    // Or use steganography for invisible watermark
  }
}
```

#### D. Export controls
```dart
// Warning before sharing
void shareArtwork(Artwork artwork) {
  showDialog(
    title: 'Share artwork?',
    content: 'This will make your work visible to others. Continue?',
    actions: [
      'Add watermark & share',
      'Share original',
      'Cancel',
    ],
  );
}
```

---

## 9. Monétisation Sans Frustrer l'Utilisateur

### Problème
Balance entre free tier et premium sans rendre l'app frustrante.

### Solutions

#### A. Generous free tier
```yaml
Free:
  - 10 scans/mois (reasonable)
  - 2K resolution (good for social media)
  - Basic editing
  - Local storage only
  - Subtle watermark

Premium:
  - Unlimited
  - 8K+ resolution
  - AI enhancement
  - Cloud sync
  - No watermark
  - Batch processing
```

#### B. Value-first upsells
```dart
// Show premium value at the right moment
if (user.hasScanned10Artworks) {
  // They're engaged, good time to upsell
  showPremiumFeatures(
    context: 'You\'re on a roll! Upgrade for unlimited scans',
  );
}

// Don't block core functionality
// Upsell on "nice-to-have" features
```

#### C. Trial period
```dart
// Give 7-day premium trial
class TrialManager {
  static Future<void> startTrial() async {
    await unlockPremiumFeatures();
    await scheduleTrialEnd(days: 7);
  }
  
  static void onTrialEnd() {
    showConversionDialog('Enjoyed premium? Subscribe to keep it');
  }
}
```

#### D. Lifetime option
```dart
// Offer one-time purchase alongside subscription
Pricing:
  - 9.99€/month
  - 79.99€/year (save 33%)
  - 199.99€ lifetime (popular for pros)
```

---

## 10. Performance sur Devices Anciens

### Problème
Support devices 3-4 ans pour maximum reach.

### Solutions

#### A. Tiered processing
```dart
class ProcessingTier {
  static Tier getTier() {
    final year = DateTime.now().year;
    final deviceYear = detectDeviceYear();
    
    if (year - deviceYear > 3) {
      return Tier.light; // Simplified processing
    } else if (year - deviceYear > 1) {
      return Tier.balanced;
    }
    return Tier.full;
  }
}
```

#### B. Reduced animations
```dart
if (isLowEndDevice) {
  disableTransitions();
  reduceAnimationFramerate();
  useSimpleWidgets();
}
```

#### C. Memory management
```dart
// Aggressive cleanup on old devices
void cleanupMemory() {
  imageCache.clear();
  PaintingBinding.instance.imageCache.clear();
  
  // Force garbage collection
  // (Note: not directly available in Dart, but minimize references)
}
```

#### D. Min SDK warnings
```yaml
# Set minimum versions
android:
  minSdkVersion: 24 # Android 7.0 (2016)
ios:
  minimumOSVersion: 13.0 # iOS 13 (2019)

# Show warning for very old devices
# Suggest upgrade for best experience
```

---

## Summary - Priority Mitigations

**High Priority (Must Fix):**
1. ✅ Background processing (isolates) - éviter UI freeze
2. ✅ Battery optimization - modes de puissance
3. ✅ Storage management - compression + cloud
4. ✅ Security - local-first + encryption

**Medium Priority (Should Fix):**
5. ✅ Edge detection fallbacks - manual adjustment
6. ✅ Cross-platform consistency - testing
7. ✅ UX for beginners - tutorials + smart defaults

**Nice to Have:**
8. ✅ Advanced ML models - progressive enhancement
9. ✅ Legacy device support - tiered features
10. ✅ Monetization polish - trials + lifetime

---

## Testing Strategy

```dart
void main() {
  group('Critical Path Tests', () {
    test('Camera initialization on low-end device');
    test('Image processing completes within 10s');
    test('Edge detection works with poor lighting');
    test('Storage cleanup prevents disk full');
    test('Battery drain stays under 5%/min');
  });
  
  group('Platform-Specific', () {
    testWidgets('iOS ARKit integration');
    testWidgets('Android ARCore integration');
    test('Permission flows on both platforms');
  });
  
  group('Performance', () {
    test('8MP image processes in <5s on mid-range');
    test('App uses <200MB RAM');
    test('Startup time <2s');
  });
}
```
