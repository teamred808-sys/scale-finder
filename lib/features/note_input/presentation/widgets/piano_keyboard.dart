import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/note_input_page.dart';

/// Interactive 2-octave piano keyboard for note selection.
class PianoKeyboard extends ConsumerWidget {
  const PianoKeyboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNotes = ref.watch(selectedNotesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Tap keys to select notes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _PianoKeyboardLayout(
                  selectedNotes: selectedNotes,
                  onNoteTap: (pc) {
                    HapticFeedback.lightImpact();
                    ref.read(selectedNotesProvider.notifier).toggleNote(pc);
                  },
                  width: constraints.maxWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PianoKeyboardLayout extends StatelessWidget {
  final Set<PitchClass> selectedNotes;
  final void Function(PitchClass) onNoteTap;
  final double width;

  const _PianoKeyboardLayout({
    required this.selectedNotes,
    required this.onNoteTap,
    required this.width,
  });

  // White key pitch classes in order (one octave)
  static const _whiteKeys = [
    PitchClass.c, PitchClass.d, PitchClass.e,
    PitchClass.f, PitchClass.g, PitchClass.a, PitchClass.b,
  ];

  // Black key pitch classes and their positions (offset from left of associated white key)
  static const _blackKeyMap = {
    0: PitchClass.cSharp,  // between C and D
    1: PitchClass.dSharp,  // between D and E
    3: PitchClass.fSharp,  // between F and G
    4: PitchClass.gSharp,  // between G and A
    5: PitchClass.aSharp,  // between A and B
  };

  @override
  Widget build(BuildContext context) {
    final whiteKeyWidth = width / 7;
    final blackKeyWidth = whiteKeyWidth * 0.6;
    final keyHeight = 200.0;

    return SizedBox(
      height: keyHeight,
      child: Stack(
        children: [
          // White keys
          Row(
            children: List.generate(7, (i) {
              final pc = _whiteKeys[i];
              final isSelected = selectedNotes.contains(pc);
              return GestureDetector(
                onTap: () => onNoteTap(pc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: whiteKeyWidth,
                  height: keyHeight,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.pianoWhiteKeyActive
                        : AppColors.pianoWhiteKey,
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 0.5,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        pc.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Black keys
          ..._blackKeyMap.entries.map((entry) {
            final i = entry.key;
            final pc = entry.value;
            final isSelected = selectedNotes.contains(pc);
            final left = (i + 1) * whiteKeyWidth - blackKeyWidth / 2;

            return Positioned(
              left: left,
              top: 0,
              child: GestureDetector(
                onTap: () => onNoteTap(pc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: blackKeyWidth,
                  height: keyHeight * 0.6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.pianoBlackKeyActive
                        : AppColors.pianoBlackKey,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Center(
                          child: Text(
                            pc.flatName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
