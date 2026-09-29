import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await HealthAppController.createPersistent();
  runApp(MedifixApp(controller: controller));
}
