import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/camera_screen.dart';
import 'services/camera_service.dart';
import 'services/edge_detection_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(const DigitizeArtApp());
}

class DigitizeArtApp extends StatelessWidget {
  const DigitizeArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraService()),
        Provider(create: (_) => EdgeDetectionService()),
      ],
      child: MaterialApp(
        title: 'Digitize Art Prototype',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const CameraScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
