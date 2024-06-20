import 'package:app/providers/prediction_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_provider.dart';
import '../widgets/prediction_information.dart';

class LiveChatScreen extends ConsumerWidget {
  const LiveChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Name & Emotion Detection'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: () =>
                ref.read(_cameraControllerProvider.notifier).switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [Expanded(child: VideoFeed()), Expanded(child: ChatBox())],
      ),
    );
  }
}

class ChatBox extends StatelessWidget {
  const ChatBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      child: Text('Chatbox'),
    );
  }
}

class VideoFeed extends ConsumerStatefulWidget {
  @override
  _VideoFeedState createState() => _VideoFeedState();
}

class _VideoFeedState extends ConsumerState<VideoFeed> {
  @override
  Widget build(BuildContext context) {
    final predictions = ref.watch(predictionProvider) ?? [];
    final _controller = ref.watch(_cameraControllerProvider).value;
    return (_controller?.value.isInitialized ?? false)
        ? Row(
            children: [
              Expanded(child: CameraPreview(_controller!)),
              SizedBox(
                  height: double.infinity,
                  child: PredictionInformation(predictions: predictions)),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }
}

final _cameraControllerProvider = AsyncNotifierProvider.autoDispose<
    _CameraControllerNotifier, CameraController?>(
  () => _CameraControllerNotifier(),
);

class _CameraControllerNotifier
    extends AutoDisposeAsyncNotifier<CameraController?> {
  List<CameraDescription> _cameras = [];
  CameraDescription? _selectedCamera;

  @override
  Future<CameraController?> build() async {
    _cameras = await availableCameras();
    print('Warning: There are no cameras available');
    if (_cameras.isEmpty) return null;

    _selectedCamera = _cameras.first;
    final controller =
        CameraController(_selectedCamera!, ResolutionPreset.high);
    await controller.initialize();
    if (!controller.value.isStreamingImages) {
      controller.startImageStream((CameraImage image) async {
        await ref.read(predictionProvider.notifier).predictCameraStream(image);
      });
    }

    ref.onDispose(controller.dispose);

    return controller;
  }

  Future<void> switchCamera() async {
    if (_cameras.isNotEmpty) {
      state = const AsyncValue.loading();
      _selectedCamera =
          (_selectedCamera == _cameras.first) ? _cameras.last : _cameras.first;
      final controller =
          CameraController(_selectedCamera!, ResolutionPreset.high);
      await controller.initialize();
      if (!controller.value.isStreamingImages) {
        controller.startImageStream((CameraImage image) async {
          await ref
              .read(predictionProvider.notifier)
              .predictCameraStream(image);
        });
      }

      ref.onDispose(controller.dispose);
      state = AsyncValue.data(controller);
    }
  }
}
