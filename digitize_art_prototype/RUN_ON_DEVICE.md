# Lancer l'app sur un iPhone (depuis un Mac récent)

> ⚠️ Nécessite **macOS 15 / 26** et **Xcode récent** pour cibler un iPhone récent (iOS 26).
> Un Mac Intel ancien bloqué sous macOS 13 **ne peut pas** : utiliser un Mac 2019+ à jour.

## 1. Prérequis (une seule fois)

```bash
# Xcode : installer depuis le Mac App Store, puis :
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# Flutter (via Homebrew) + CocoaPods
brew install --cask flutter
brew install cocoapods

flutter doctor   # doit afficher ✓ pour Flutter et Xcode
```

## 2. Récupérer le projet

```bash
git clone https://github.com/Greisten/digitize-art.git
cd digitize-art/digitize_art_prototype

# Pour tester les nouvelles fonctionnalités v1.1 :
git checkout feat/v1.1-smart-detection
```

## 3. Installer les dépendances iOS

Le projet iOS (Runner.xcodeproj, asset catalog, icône) est désormais inclus dans le dépôt :

```bash
flutter pub get
cd ios && pod install && cd ..
```

> Si Xcode signale un projet à mettre à niveau (Flutter plus récent), accepte la migration proposée. En dernier recours seulement : `flutter create --platforms=ios .` régénère l'échafaudage sans toucher à `lib/`.

## 4. Signer l'app (Apple ID gratuit suffit pour un test)

```bash
open ios/Runner.xcworkspace
```
Dans Xcode : cible **Runner** → onglet **Signing & Capabilities** →
- cocher **Automatically manage signing**
- choisir ton **Team** (ton Apple ID ; « Add an Account… » si besoin)
- mettre un **Bundle Identifier** unique, ex. `art.digitize.proto.tonnom`

## 5. Préparer l'iPhone

- Réglages → **Confidentialité et sécurité** → **Mode développeur** → activer, redémarrer.
- Brancher en USB, **faire confiance** à l'ordinateur.

## 6. Lancer

### Option A — mode démo, SANS Firebase (le plus rapide)
Va directement à la caméra ; teste capture, détection des bords, guidage lumière, HDR, éditeur (recadrage/perspective/réglages), galerie. L'authentification est désactivée.

```bash
flutter run --dart-define=DEMO=true
```

### Option B — app complète AVEC Firebase
Configure Firebase automatiquement (connexion Google requise), puis lance normalement :

```bash
dart pub global activate flutterfire_cli
flutterfire configure        # crée firebase_options.dart + GoogleService-Info.plist
flutter run
```

> En mode complet, pense à initialiser avec les options générées dans `lib/main.dart` :
> `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`

## 7. Première ouverture sur l'iPhone

iOS bloque l'app la 1ʳᵉ fois : Réglages → **Général** → **VPN et gestion de l'appareil** → faire confiance à ton certificat développeur, puis relancer.

---

### Dépannage
- **« Untrusted Developer »** → étape 7.
- **Build signing failed** → vérifier Team + Bundle ID unique (étape 4).
- **Pods error** → `cd ios && pod repo update && pod install`.
- **Caméra noire en mode démo** → normal sur Simulateur (pas de caméra) ; utiliser un **vrai iPhone**.
