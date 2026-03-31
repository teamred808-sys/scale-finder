import 'package:flutter/material.dart';

/// A shared, mathematically centered layout for audio recording pages.
/// Ensures the microphone button remains visibly centered across different screen sizes
/// without relying on fragile hardcoded margins or spacers.
class SharedRecordingLayout extends StatelessWidget {
  /// The instructional hint or state text shown above the centered area.
  final Widget hintWidget;
  
  /// The primary recording button (usually the mic button).
  final Widget micButton;
  
  /// Optional status content (timer, processing indicator, error messaging)
  /// displayed above the mic button.
  final Widget? statusWidget;

  const SharedRecordingLayout({
    super.key,
    required this.hintWidget,
    required this.micButton,
    this.statusWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Placed at the top with flexible padding around it depending on screen,
        // but typically just sits directly under AppBar padding.
        const SizedBox(height: 24),
        hintWidget,
        
        // Fills the remaining space, forcing its child (the Column) to be dead center.
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap its children securely
              children: [
                if (statusWidget != null) ...[
                  statusWidget!,
                  const SizedBox(height: 48), // Padding between status and mic
                ],
                micButton,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
