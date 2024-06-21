import 'package:app/providers/emotion_detection_result_provider.dart';
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
        children: [
          Expanded(child: Center(child: VideoFeed())),
          Consumer(builder: (context, ref, _) {
            final predictions = ref.watch(emotionDetectionResultProvider);
            if (predictions.valueOrNull?.isEmpty ?? true ) {
              return const SizedBox.shrink();
            }
            return PredictionInformation(predictions: predictions.requireValue);
          })
        ],
      ),
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
    final _controller = ref.watch(_cameraControllerProvider).value;
    return (_controller?.value.isInitialized ?? false)
        ? CameraPreview(_controller!)
        : const Center(child: CircularProgressIndicator());
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
        await ref
            .read(emotionDetectionResultProvider.notifier)
            .predictCameraStream(image);
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
              .read(emotionDetectionResultProvider.notifier)
              .predictCameraStream(image);
        });
      }

      ref.onDispose(controller.dispose);
      state = AsyncValue.data(controller);
    }
  }
}
