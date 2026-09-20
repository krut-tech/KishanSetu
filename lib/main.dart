import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/app.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('main() started -> executing runApp');

  runApp(
    const ProviderScope(
      child: FarmerMarketApp(),
    ),
  );
}