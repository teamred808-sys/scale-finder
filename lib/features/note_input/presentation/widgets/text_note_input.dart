import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/note_input_page.dart';

/// Text-based note input with real-time parsing and validation.
class TextNoteInput extends ConsumerStatefulWidget {
  const TextNoteInput({super.key});

  @override
  ConsumerState<TextNoteInput> createState() => _TextNoteInputState();
}

class _TextNoteInputState extends ConsumerState<TextNoteInput> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseAndApply() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ref.read(selectedNotesProvider.notifier).clear();
      setState(() => _errorText = null);
      return;
    }

    final notes = NoteParser.parseMultiple(text);
    if (notes.isEmpty) {
      setState(() => _errorText = 'No valid notes found. Try: C E G Bb');
      return;
    }

    final pitchClasses = Normalizer.toPitchClassSet(notes);
    ref.read(selectedNotesProvider.notifier).setNotes(pitchClasses);
    setState(() => _errorText = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Type note names',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Separate with spaces or commas. Supports sharps (#) and flats (b).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'e.g. C E G Bb',
              errorText: _errorText,
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: _parseAndApply,
                color: AppColors.primary,
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _parseAndApply(),
            onSubmitted: (_) => _parseAndApply(),
          ),
          const SizedBox(height: 24),

          // Quick note buttons
          Text(
            'Quick Select',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PitchClass.values.map((pc) {
              final isSelected = ref.watch(selectedNotesProvider).contains(pc);
              return FilterChip(
                label: Text(pc.name),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(selectedNotesProvider.notifier).toggleNote(pc);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimaryDark,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
