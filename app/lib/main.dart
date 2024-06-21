import 'package:app/providers/model_provider.dart';
import 'package:app/services/name_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/gallery_screen.dart';
import 'screens/live_chat_screen.dart';
import 'screens/model_settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: EmotionDetectionApp(),
    ),
  );
}

class EmotionDetectionApp extends StatelessWidget {
  @override
      
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emotion Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: HomeScreen(),
      initialRoute: '/gallery',
      routes: {
        '/gallery': (context) => GalleryScreen(),
        '/live-chat': (context) => LiveChatScreen(),
        '/model-settings': (context) => ModelSettingsScreen(),
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelLoaded = ref.watch(modelLoadedProvider);
    final selectedModel = ref.watch(modelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Detection App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: !modelLoaded
              ? const [CircularProgressIndicator(), Text('Loading model...')]
              : <Widget>[
                  Text('Selected Model: ${selectedModel.displayName}'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/gallery');
                    },
                    child: Text('Import from Gallery'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/live-chat');
                    },
                    child: Text('Live Camera'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/model-settings');
                    },
                    child: Text('Model Settings'),
                  ),
                ],
        ),
      ),
    );
  }
}
