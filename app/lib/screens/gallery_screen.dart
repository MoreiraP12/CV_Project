import 'dart:io';
import 'package:app/providers/prediction_provider.dart';
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
  bool _busy = false;

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final File imageFile = File(image.path);

    setState(() {
      _image = imageFile;
      _busy = true;
    });

    await ref.read(predictionProvider.notifier).predictImage(imageFile);

    setState(() {
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final predictions = ref.watch(predictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery Emotion Detection'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: _image == null
                ? [Text('No image selected.')]
                : [
                    Image.file(_image!),
                    if (_busy)
                      const Center(child: CircularProgressIndicator())
                    else if (predictions != null)
                      SizedBox(
                        width: double.infinity,
                        child: PredictionInformation(predictions: predictions),
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