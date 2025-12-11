import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'saved_tournament_bracket.dart';
import 'tournament_bracket_service.dart';
import 'bracket_thumbnail.dart';
import '../core/app_header.dart';
import '../core/toolbar_button.dart';
import '../core/navigation_helper.dart';

class BracketListScreen extends StatefulWidget {
  const BracketListScreen({super.key});

  @override
  State<BracketListScreen> createState() => _BracketListScreenState();
}

class _BracketListScreenState extends State<BracketListScreen> {
  final TournamentBracketService _service = TournamentBracketService();

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deleteBracket(SavedTournamentBracket bracket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bracket'),
        content: Text('Are you sure you want to delete "${bracket.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteBracket(bracket.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${bracket.title}" deleted'),
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
              content: Text('Failed to delete bracket: $e'),
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
  }

  void _createNewBracket() {
    navigateWithUrlUpdate(context, '/bracket');
  }

  void _editBracket(SavedTournamentBracket bracket) {
    // Pass initial tournament data via extra and update URL
    updateUrlWeb('/bracket/${bracket.id}');
    context.push(
      '/bracket/${bracket.id}',
      extra: {'initialTournament': bracket.tournament},
    );
  }

  void _viewBracket(SavedTournamentBracket bracket) {
    // Pass initial tournament data via extra and update URL
    updateUrlWeb('/bracket/${bracket.id}');
    context.push(
      '/bracket/${bracket.id}',
      extra: {'initialTournament': bracket.tournament},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            icon: Icons.emoji_events,
            title: 'Tournament Brackets',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: StreamBuilder<List<SavedTournamentBracket>>(
              stream: _service.getBrackets(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final brackets = snapshot.data ?? [];

                if (brackets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No brackets yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first tournament bracket',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: brackets.length,
                  itemBuilder: (context, index) {
                    final bracket = brackets[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;

                        if (isSmallScreen) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _viewBracket(bracket),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bracket.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Updated ${_formatTimestamp(bracket.updatedAt)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        BracketThumbnail(
                                          tournament: bracket.tournament,
                                          width: 100,
                                          height: 64,
                                        ),
                                        const Spacer(),
                                        ToolbarButton(
                                          icon: Icons.edit,
                                          label: 'Edit',
                                          onTap: () => _editBracket(bracket),
                                        ),
                                        const SizedBox(width: 8),
                                        ToolbarButton(
                                          icon: Icons.delete,
                                          label: 'Delete',
                                          onTap: () => _deleteBracket(bracket),
                                          isDelete: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 12,
                              right: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            leading: BracketThumbnail(
                              tournament: bracket.tournament,
                              width: 100,
                              height: 64,
                            ),
                            title: Text(
                              bracket.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Updated ${_formatTimestamp(bracket.updatedAt)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ToolbarButton(
                                  icon: Icons.edit,
                                  label: 'Edit',
                                  onTap: () => _editBracket(bracket),
                                ),
                                const SizedBox(width: 8),
                                ToolbarButton(
                                  icon: Icons.delete,
                                  label: 'Delete',
                                  onTap: () => _deleteBracket(bracket),
                                  isDelete: true,
                                ),
                              ],
                            ),
                            onTap: () => _viewBracket(bracket),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewBracket,
        icon: const Icon(Icons.add),
        label: const Text('New Bracket'),
      ),
    );
  }
}
