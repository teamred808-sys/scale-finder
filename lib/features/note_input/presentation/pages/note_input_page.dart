import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theory_engine/theory_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/guitar_fretboard.dart';
import '../widgets/text_note_input.dart';

/// Provider to manage selected notes across all input modes.
final selectedNotesProvider = StateNotifierProvider<SelectedNotesNotifier, Set<PitchClass>>(
  (ref) => SelectedNotesNotifier(),
);

class SelectedNotesNotifier extends StateNotifier<Set<PitchClass>> {
  SelectedNotesNotifier() : super({});

  void toggleNote(PitchClass note) {
    if (state.contains(note)) {
      state = {...state}..remove(note);
    } else {
      state = {...state, note};
    }
  }

  void addNote(PitchClass note) {
    state = {...state, note};
  }

  void removeNote(PitchClass note) {
    state = {...state}..remove(note);
  }

  void clear() {
    state = {};
  }

  void setNotes(Set<PitchClass> notes) {
    state = notes;
  }
}

/// Note input page with 3 tab modes: piano, guitar, text.
class NoteInputPage extends ConsumerStatefulWidget {
  const NoteInputPage({super.key});

  @override
  ConsumerState<NoteInputPage> createState() => _NoteInputPageState();
}

class _NoteInputPageState extends ConsumerState<NoteInputPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedNotes = ref.watch(selectedNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Notes'),
        actions: [
          if (selectedNotes.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(selectedNotesProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [
            Tab(icon: Icon(Icons.piano), text: 'Piano'),
            Tab(icon: Icon(Icons.grid_4x4), text: 'Guitar'),
            Tab(icon: Icon(Icons.keyboard), text: 'Text'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selected notes bar
          if (selectedNotes.isNotEmpty)
            _SelectedNotesBar(
              notes: selectedNotes,
              onRemoveNote: (note) =>
                  ref.read(selectedNotesProvider.notifier).removeNote(note),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                PianoKeyboard(),
                GuitarFretboard(),
                TextNoteInput(),
              ],
            ),
          ),

          // Find Scales button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedNotes.length >= 2
                    ? () {
                        HapticFeedback.mediumImpact();
                        final noteStrings = selectedNotes
                            .map((pc) => EnharmonicSpeller.spell(pc))
                            .toList();
                        context.push('/results', extra: noteStrings);
                      }
                    : null,
                icon: const Icon(Icons.search_rounded),
                label: Text(
                  selectedNotes.isEmpty
                      ? 'Select at least 2 notes'
                      : selectedNotes.length < 2
                          ? 'Select ${2 - selectedNotes.length} more'
                          : 'Find Scales (${selectedNotes.length} notes)',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: AppColors.surfaceElevatedDark,
                  disabledForegroundColor: AppColors.textTertiaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedNotesBar extends StatelessWidget {
  final Set<PitchClass> notes;
  final void Function(PitchClass) onRemoveNote;

  const _SelectedNotesBar({
    required this.notes,
    required this.onRemoveNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.surfaceHighDark)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: notes.map((note) {
          return Chip(
            label: Text(
              EnharmonicSpeller.spell(note),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.primary,
            deleteIconColor: Colors.white70,
            onDeleted: () => onRemoveNote(note),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}
