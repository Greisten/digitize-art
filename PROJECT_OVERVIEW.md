# digitize.art - Project Overview

## Vision
Application mobile cross-platform permettant aux artistes de numériser leurs œuvres physiques avec une qualité professionnelle via leur smartphone.

## Core Value Proposition
Transformer un smartphone en scanner professionnel pour œuvres d'art, avec guidance IA et post-production intégrée.

## Target Users
- Artistes indépendants
- Galeries d'art
- Étudiants en arts
- Collectionneurs
- Toute personne créant de l'art physique

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart)
  - Cross-platform (iOS/Android)
  - Performance native
  - UI riche et personnalisable

### Backend & Services
- **Firebase**: 
  - Authentication
  - Firestore (metadata)
  - Cloud Storage (images)
  - Analytics
- **Cloud Functions**: Processing serverless

### Image Processing & AI
- **OpenCV**: Edge detection, perspective correction, enhancement
- **TensorFlow Lite**: ML-based image enhancement
- **ML Kit**: On-device ML capabilities
- **Camera**: camera + image_picker packages

### AR Guidance
- **ARCore** (Android): google_ar_core_flutter
- **ARKit** (iOS): arkit_plugin

### Storage & Export
- **Local**: sqflite
- **Cloud**: Firebase Storage, Google Drive API, iCloud (iOS)

## Monetization Strategy
- **Free Tier**: 
  - 10 scans/mois
  - Résolution limitée (2K)
  - Publicités non-intrusives
  - Watermark léger

- **Premium** (9.99€/mois ou 79.99€/an):
  - Scans illimités
  - Résolution max (8K+)
  - Sans pub
  - Batch processing
  - Export multi-formats (TIFF, RAW)
  - Cloud storage étendu (50GB)
  - Outils IA avancés

## Development Phases
1. **Phase 1 (MVP)**: Capture + basic processing
2. **Phase 2**: Tutorial system + AR guidance
3. **Phase 3**: Advanced post-production
4. **Phase 4**: Cloud sync + social features
5. **Phase 5**: Premium features + monetization
