import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'leaderboard_entry.dart';
import 'leaderboard_service.dart';
import '../core/toolbar_button.dart';

class LeaderboardWidget extends StatefulWidget {
  final bool isEditMode;
  final VoidCallback? onSave;

  const LeaderboardWidget({
    super.key,
    this.isEditMode = false,
    this.onSave,
  });

  @override
  State<LeaderboardWidget> createState() => LeaderboardWidgetState();
}

class LeaderboardWidgetState extends State<LeaderboardWidget> {
  final LeaderboardService _service = LeaderboardService();
  List<LeaderboardEntry> _editEntries = [];
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeEditMode(List<LeaderboardEntry> currentEntries) {
    // Only initialize if we don't have edit entries yet
    // This prevents resetting edits when stream updates while in edit mode
    if (_editEntries.isEmpty && widget.isEditMode) {
      _editEntries = currentEntries.map((e) => e.copyWith()).toList();
      // Initialize controllers
      for (final entry in _editEntries) {
        _nameControllers[entry.id] = TextEditingController(text: entry.name);
        _scoreControllers[entry.id] =
            TextEditingController(text: entry.score.toString());
      }
    }
  }

  void _clearEditMode() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
    _scoreControllers.clear();
    _editEntries.clear();
  }

  void cancelEdit() {
    _clearEditMode();
  }

  @override
  void didUpdateWidget(LeaderboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When exiting edit mode, clear the edit state
    if (oldWidget.isEditMode && !widget.isEditMode) {
      _clearEditMode();
    }
  }

  Future<void> saveLeaderboard() async {
    try {
      // Validate and update entries
      final updatedEntries = <LeaderboardEntry>[];
      for (final entry in _editEntries) {
        final nameController = _nameControllers[entry.id];
        final scoreController = _scoreControllers[entry.id];
        if (nameController != null && scoreController != null) {
          final name = nameController.text.trim();
          final scoreText = scoreController.text.trim();
          if (name.isNotEmpty) {
            final score = int.tryParse(scoreText) ?? 0;
            updatedEntries.add(entry.copyWith(name: name, score: score));
          }
        }
      }

      await _service.saveLeaderboard(updatedEntries);
      _clearEditMode();
      widget.onSave?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Leaderboard updated successfully!'),
            backgroundColor: const Color(0xFF4caf50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save leaderboard: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _addParticipant() {
    final newEntry = LeaderboardEntry(
      id: const Uuid().v4(),
      name: '',
      score: 0,
    );
    setState(() {
      _editEntries.add(newEntry);
      _nameControllers[newEntry.id] = TextEditingController();
      _scoreControllers[newEntry.id] = TextEditingController(text: '0');
    });
  }

  void _removeParticipant(String entryId) {
    setState(() {
      _editEntries.removeWhere((e) => e.id == entryId);
      _nameControllers[entryId]?.dispose();
      _scoreControllers[entryId]?.dispose();
      _nameControllers.remove(entryId);
      _scoreControllers.remove(entryId);
    });
  }

  List<LeaderboardEntry> _sortEntries(List<LeaderboardEntry> entries) {
    final sorted = List<LeaderboardEntry>.from(entries);
    sorted.sort((a, b) {
      // Primary sort: by score (descending)
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      // Secondary sort: alphabetically by name
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _service.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading leaderboard: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (widget.isEditMode) {
          // Initialize with sorted entries to preserve view mode order
          final sortedEntries = _sortEntries(entries);
          _initializeEditMode(sortedEntries);
          return _buildEditMode(context);
        } else {
          return _buildViewMode(context, entries);
        }
      },
    );
  }

  Widget _buildViewMode(BuildContext context, List<LeaderboardEntry> entries) {
    final sortedEntries = _sortEntries(entries);

    return Expanded(
      child: sortedEntries.isEmpty
          ? Center(
              child: Text(
                'No participants yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return _LeaderboardEntryWidget(
                      entry: entry,
                      rank: index + 1,
                    );
                  },
                ),
    );
  }

  Widget _buildEditMode(BuildContext context) {
    // Use edit entries
    final displayEntries = _editEntries;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: displayEntries.isEmpty
                ? Center(
                    child: Text(
                      'No participants. Add one to get started!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: displayEntries.length,
                    itemBuilder: (context, index) {
                      final entry = displayEntries[index];
                      return _EditableLeaderboardEntryWidget(
                        entry: entry,
                        nameController: _nameControllers[entry.id]!,
                        scoreController: _scoreControllers[entry.id]!,
                        onDelete: () => _removeParticipant(entry.id),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _addParticipant,
              icon: const Icon(Icons.add),
              label: const Text('Add Participant'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardEntryWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const _LeaderboardEntryWidget({
    required this.entry,
    required this.rank,
  });

  Widget? _getTrophyIcon() {
    switch (rank) {
      case 1:
        return Icon(
          Icons.emoji_events,
          color: Colors.amber,
          size: 24,
        );
      case 2:
        return Icon(
          Icons.emoji_events,
          color: Colors.grey.shade400,
          size: 24,
        );
      case 3:
        return Icon(
          Icons.emoji_events,
          color: const Color(0xFFCD7F32), // Bronze color
          size: 24,
        );
      default:
        return const SizedBox(width: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEvenRank = rank % 2 == 0;
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isEvenRank
            ? Color.lerp(
                baseColor,
                Colors.black,
                0.15,
              )
            : baseColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          _getTrophyIcon() ?? const SizedBox(width: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            '${entry.score}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EditableLeaderboardEntryWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final TextEditingController nameController;
  final TextEditingController scoreController;
  final VoidCallback onDelete;

  const _EditableLeaderboardEntryWidget({
    required this.entry,
    required this.nameController,
    required this.scoreController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Score',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: onDelete,
            isDelete: true,
          ),
        ],
      ),
    );
  }
}
