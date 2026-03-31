import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/note_input_page.dart';

/// Interactive guitar fretboard for note selection.
///
/// Standard tuning (E A D G B E) with 12 frets displayed.
class GuitarFretboard extends ConsumerWidget {
  const GuitarFretboard({super.key});

  // Standard tuning: low E to high E (pitch class values)
  static const _tuning = [
    PitchClass.e,  // String 6 (low E)
    PitchClass.a,  // String 5
    PitchClass.d,  // String 4
    PitchClass.g,  // String 3
    PitchClass.b,  // String 2
    PitchClass.e,  // String 1 (high E)
  ];

  static const _stringNames = ['E', 'A', 'D', 'G', 'B', 'e'];
  static const _fretCount = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNotes = ref.watch(selectedNotesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Tap frets to select notes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          // Fret numbers
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: List.generate(_fretCount + 1, (fret) {
                return Expanded(
                  child: Center(
                    child: Text(
                      '$fret',
                      style: TextStyle(
                        color: AppColors.textTertiaryDark,
                        fontSize: 10,
                        fontWeight: [3, 5, 7, 9, 12].contains(fret)
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Fretboard
          Expanded(
            child: Row(
              children: [
                // String labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _stringNames.map((name) {
                    return SizedBox(
                      width: 28,
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Frets
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (stringIndex) {
                          return _StringRow(
                            stringIndex: stringIndex,
                            openNote: _tuning[stringIndex],
                            selectedNotes: selectedNotes,
                            onNoteTap: (pc) {
                              HapticFeedback.lightImpact();
                              ref.read(selectedNotesProvider.notifier).toggleNote(pc);
                            },
                            width: constraints.maxWidth,
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StringRow extends StatelessWidget {
  final int stringIndex;
  final PitchClass openNote;
  final Set<PitchClass> selectedNotes;
  final void Function(PitchClass) onNoteTap;
  final double width;

  const _StringRow({
    required this.stringIndex,
    required this.openNote,
    required this.selectedNotes,
    required this.onNoteTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final fretWidth = width / 13;

    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          // String line
          Positioned(
            left: 0,
            right: 0,
            top: 17,
            child: Container(
              height: 2 - stringIndex * 0.15,
              color: Colors.grey.shade600,
            ),
          ),
          // Fret dots
          Row(
            children: List.generate(13, (fret) {
              final pc = openNote.transpose(fret);
              final isSelected = selectedNotes.contains(pc);
              final noteName = EnharmonicSpeller.spell(pc);

              return GestureDetector(
                onTap: () => onNoteTap(pc),
                child: Container(
                  width: fretWidth,
                  height: 36,
                  decoration: fret > 0
                      ? BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1,
                            ),
                          ),
                        )
                      : null,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 28 : 6,
                      height: isSelected ? 28 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.noteActive
                            : Colors.transparent,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Center(
                              child: Text(
                                noteName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
