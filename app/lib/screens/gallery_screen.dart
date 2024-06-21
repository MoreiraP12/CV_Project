import 'dart:io';
import 'dart:math';
import 'package:app/providers/name_detection_result_provider.dart';
import 'package:app/services/emotion_detection_interface.dart';
import 'package:collection/collection.dart';
import 'package:app/main.dart';
import 'package:app/providers/emotion_detection_result_provider.dart';
import 'package:app/services/emotion_detection_service.dart';
import 'package:app/services/name_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/prediction_information.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  File? _image;

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final File imageFile = File(image.path);

    setState(() {
      _image = imageFile;
    });

    await Future.wait([
      ref.read(emotionDetectionResultProvider.notifier).predictImage(imageFile),
      ref.read(nameDetectionResultProvider.notifier).predictImage(imageFile),
    ]);
/*
    await ref.read(nameDetectionServiceProvider.notifier).build();
    final names = await ref
        .read(nameDetectionServiceProvider.notifier)
        .recognizeFacesInImage(imageFile);
    print('recognized name $names');
    print('');
    */
  }

  @override
  Widget build(BuildContext context) {
    final predictions = ref.watch(emotionDetectionResultProvider);
    final detectedFace = ref.watch(detectedFaceProvider);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion & Name Detection Demo App'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: _image == null
                ? [Text('No image selected.')]
                : [
                    Stack(children: [
                      Image.file(_image!),
                      if (predictions.valueOrNull?.isNotEmpty ?? false)
                        BoundingBoxes(image: _image, predictions: predictions),
                    ]),
                    ref.watch(nameDetectionResultProvider).when(
                        data: (names) => Text(
                              'Recognized persons: ${names.map((e) => e.name).toList()}',
                              style: TextStyle(fontSize: 24),
                            ),
                        loading: () => SizedBox.shrink(),
                        error: (error, stackTrace) =>
                            Text('Error: $error, $stackTrace')),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: RegisterPersonButton(
                        key: ValueKey(_image?.path),
                        image: _image!,
                      ),
                    ),
                    if (predictions.valueOrNull?.isNotEmpty ?? false)
                      SizedBox(
                        width: double.infinity,
                        child: PredictionInformation(
                            predictions: predictions.requireValue),
                      ),
                  ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.image),
      ),
    );
  }
}

class BoundingBoxes extends StatelessWidget {
  const BoundingBoxes({
    super.key,
    required File? image,
    required this.predictions,
  }) : _image = image;

  final File? _image;
  final AsyncValue<List<EmotionDetectionResult>> predictions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return FutureBuilder(
          future: decodeImageFromList(_image!.readAsBytesSync()),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            final image = snapshot.requireData;
            final imageWidth = image.width;
            final imageHeight = image.height;
            final displayWidth = constraints.maxWidth;
            // Calculate scale factors
            final widthScaleFactor = displayWidth / imageWidth;
            final heightScaleFactor =
                1.0; // because it's in a vertical scroll view

            final scaleFactor = min(widthScaleFactor, heightScaleFactor);

            final colorMap = generateColorMap(predictions.requireValue.length);

            return ConstrainedBox(
              constraints:
                  constraints.tighten(height: imageHeight * scaleFactor),
              child: Stack(children: [
                ...predictions.requireValue
                    .mapIndexed((index, prediction) => Positioned(
                          left: prediction.region.x * scaleFactor,
                          top: prediction.region.y * scaleFactor,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorMap[index],
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            width: prediction.region.w *
                                scaleFactor, // devicePixelRatio,
                            height: prediction.region.h *
                                scaleFactor, // devicePixelRatio,
                          ),
                        ))
              ]),
            );
          });
    });
  }
}

class RegisterPersonButton extends ConsumerStatefulWidget {
  const RegisterPersonButton({super.key, required this.image});

  final File image;

  @override
  ConsumerState<RegisterPersonButton> createState() =>
      _RegisterPersonButtonState();
}

class _RegisterPersonButtonState extends ConsumerState<RegisterPersonButton> {
  final TextEditingController _nameController = TextEditingController();
  bool disabled = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Register person'),
      onPressed: disabled
          ? null
          : () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Register person'),
                    content: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: "Name"),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: Text('Ok'),
                        onPressed: () {
                          ref
                              .read(nameDetectionResultProvider.notifier)
                              .registerPerson(
                                  _nameController.text, widget.image);
                          setState(() {
                            disabled = true;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
    );
  }
}
