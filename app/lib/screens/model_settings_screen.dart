import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_provider.dart';

class ModelSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(modelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Model Settings'),
      ),
      body: ListView(
        children: 
          ModelType.values.map((e) => RadioListTile<ModelType>(
            title: Text(e.displayName),
            value: e,
            groupValue: model,
            onChanged: (value) {
              ref.read(modelProvider.notifier).changeModel(value!);
            },
          )).toList(),
      ),
    );
  }
}
