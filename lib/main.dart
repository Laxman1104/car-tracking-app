import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dev/fuel_stage_preview.dart';
import 'dev/stage_4_preview.dart';

const _showFuelStagePreview = bool.fromEnvironment('STAGE_2_PREVIEW');

void main() {
  runApp(
    const ProviderScope(
      child: _showFuelStagePreview
          ? FuelStagePreviewApp()
          : StageFourPreviewApp(),
    ),
  );
}
