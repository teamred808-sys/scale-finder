import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VolumeMeter extends StatelessWidget {
  /// Amplitude in dB. Typically from -60 or -160 (silence) up to 0 (clipping).
  final double amplitude;

  const VolumeMeter({super.key, required this.amplitude});

  @override
  Widget build(BuildContext context) {
    // Convert amplitude dB to a 0.0 - 1.0 linear scale.
    // -60 dB is practically silent, 0 dB is max.
    const minDb = -60.0;
    const maxDb = 0.0;
    
    double linear = (amplitude - minDb) / (maxDb - minDb);
    linear = linear.clamp(0.0, 1.0);
    
    // Add a bit of logarithmic curve for visual feel
    final visualValue = math.pow(linear, 0.75).toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(15, (index) {
        final boxThres = (index + 1) / 15.0;
        final isActive = visualValue >= boxThres;
        
        Color boxColor;
        if (index > 12) {
          boxColor = AppColors.error;
        } else if (index > 8) {
          boxColor = AppColors.confidenceMedium;
        } else {
          boxColor = AppColors.primary;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? boxColor : AppColors.surfaceHighDark,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive ? [
              BoxShadow(
                color: boxColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 0,
              )
            ] : null,
          ),
        );
      }),
    );
  }
}

