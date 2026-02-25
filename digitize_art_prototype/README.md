# Digitize Art - MVP Prototype

Prototype Flutter fonctionnel pour la numérisation d'œuvres d'art avec détection de contours en temps réel et overlay AR.

## 🎯 Fonctionnalités

- ✅ **Caméra en temps réel** avec preview haute résolution
- ✅ **Détection de contours live** (algorithme Sobel)
- ✅ **Overlay AR** (grille, guides, visualisation des coins détectés)
- ✅ **Capture d'image** activée quand une œuvre est détectée
- ✅ **Gestion des permissions** (Camera, Storage)
- ✅ **Multi-caméra** (avant/arrière)

## 🏗️ Architecture

```
lib/
├── main.dart                          # Point d'entrée
├── screens/
│   └── camera_screen.dart             # Écran principal avec caméra + AR
├── services/
│   ├── camera_service.dart            # Gestion caméra (Provider)
│   └── edge_detection_service.dart    # Détection temps réel
└── widgets/
    ├── ar_overlay.dart                # Overlay AR (grille + coins)
    └── capture_button.dart            # Bouton de capture
```

## 📦 Installation

### Prérequis

- Flutter SDK ≥ 3.0.0
- Android Studio / Xcode
- Un appareil physique (recommandé pour tester la caméra)

### Setup

```bash
# 1. Clone le repo
git clone https://github.com/Greisten/digitize-art.git
cd digitize-art/digitize_art_prototype

# 2. Installer les dépendances
flutter pub get

# 3. Lancer sur device
flutter run
```

### Android

Permissions déjà configurées dans `android/app/src/main/AndroidManifest.xml` :
- `CAMERA`
- `WRITE_EXTERNAL_STORAGE`
- `READ_EXTERNAL_STORAGE`

### iOS

Permissions dans `ios/Runner/Info.plist` :
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## 🚀 Utilisation

1. **Autoriser** l'accès à la caméra au démarrage
2. **Pointer** la caméra vers une œuvre d'art
3. **Cadrer** avec la grille AR
4. **Capturer** quand le bouton devient actif (détection validée)

## 🧪 État du Prototype

### ✅ Fonctionnel
- Caméra live avec preview
- Conversion YUV420 → RGB
- Détection Sobel (grayscale + blur + edge detection)
- UI complète avec overlay AR
- Capture d'image

### 🚧 À implémenter
- **Détection avancée des coins** (actuellement placeholder)
  - Contour detection
  - Hough transform pour détecter les lignes
  - Détection de quadrilatère
- **Perspective transform** après capture
- **Post-processing** (correction couleur, contraste)
- **Sauvegarde** dans la galerie
- **Export** (PDF, haute résolution)

## 🎨 Tech Stack

| Package | Version | Usage |
|---------|---------|-------|
| `camera` | ^0.10.5 | Accès caméra native |
| `image` | ^4.1.3 | Traitement d'image |
| `opencv_dart` | ^1.0.4 | Edge detection (alternative future) |
| `provider` | ^6.1.1 | State management |
| `permission_handler` | ^11.0.1 | Permissions runtime |

## 📝 Notes de Développement

### Performance
- Edge detection à ~10 FPS pour éviter de surcharger le CPU
- Utilisation de `ImageFormatGroup.yuv420` pour performance
- Skip des frames si traitement en cours

### Prochaines Étapes
1. Implémenter corner detection robuste
2. Ajouter perspective transform
3. Intégrer ML model (TFLite) pour améliorer la détection
4. Tester sur différents types d'œuvres (tableaux, dessins, sculptures)

## 🐛 Debug

```bash
# Logs en temps réel
flutter run --verbose

# Build release
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📄 Licence

Projet prototype - Usage libre pour développement personnel.

---

**Créé le**: 2026-02-25  
**Auteur**: Greisten  
**Repo**: https://github.com/Greisten/digitize-art
