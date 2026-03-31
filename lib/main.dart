import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/ad_service/ad_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob SDK via the centralized AdService
  await AdService.instance.initialize();

  runApp(
    const ProviderScope(
      child: ScaleFinderApp(),
    ),
  );
}
