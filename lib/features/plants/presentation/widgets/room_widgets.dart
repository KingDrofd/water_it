import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/presentation/bloc/room_cubit.dart';

/// Horizontal room filter for the library: All, one chip per room, and a
/// trailing manage button. Hidden entirely while no rooms exist except for
/// the manage entry point.
class RoomFilterChips extends StatelessWidget {
  final List<Room> rooms;
  final String? selectedRoomId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onManage;

  const RoomFilterChips({
    super.key,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelected,
    required this.onManage,
  });

  /// Sentinel filter id for plants without a room.
  static const String unassignedId = '__unassigned__';

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // The shell already applies page padding.
        padding: EdgeInsets.zero,
        children: [
          if (rooms.isNotEmpty) ...[
            ChoiceChip(
              label: const Text('All'),
              selected: selectedRoomId == null,
              onSelected: (_) => onSelected(null),
            ),
            SizedBox(width: spacing.xs),
            for (final room in rooms) ...[
              ChoiceChip(
                avatar: room.isOutdoor
                    ? const Icon(Icons.wb_sunny_outlined, size: 16)
                    : null,
                label: Text(room.name),
                selected: selectedRoomId == room.id,
                onSelected: (_) => onSelected(room.id),
              ),
              SizedBox(width: spacing.xs),
            ],
            ChoiceChip(
              label: const Text('Unassigned'),
              selected: selectedRoomId == unassignedId,
              onSelected: (_) => onSelected(unassignedId),
            ),
            SizedBox(width: spacing.xs),
          ],
          ActionChip(
            avatar: const Icon(Icons.tune, size: 16),
            label: Text(rooms.isEmpty ? 'Add rooms' : 'Edit'),
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}

/// Opens the room management sheet bound to an existing [RoomCubit].
Future<void> showManageRoomsSheet(BuildContext context, RoomCubit cubit) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _ManageRoomsSheet(),
    ),
  );
}

class _ManageRoomsSheet extends StatelessWidget {
  const _ManageRoomsSheet();

  Future<void> _addRoom(BuildContext context) async {
    final cubit = context.read<RoomCubit>();
    final room = await _showRoomDialog(context);
    if (room != null) {
      await cubit.save(room.copyWith(sortOrder: cubit.state.rooms.length));
    }
  }

  Future<void> _editRoom(BuildContext context, Room room) async {
    final cubit = context.read<RoomCubit>();
    final edited = await _showRoomDialog(context, existing: room);
    if (edited != null) {
      await cubit.save(edited);
    }
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final cubit = context.read<RoomCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
          'Delete "${room.name}"? Plants in it become unassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.delete(room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: spacing.lg,
        right: spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
      ),
      child: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rooms', style: textTheme.titleMedium),
              SizedBox(height: spacing.sm),
              if (state.rooms.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.md),
                  child: Text(
                    'No rooms yet. Add one to organize your plants.',
                    style: textTheme.bodySmall,
                  ),
                )
              else
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemCount: state.rooms.length,
                    onReorder: (oldIndex, newIndex) {
                      final rooms = List<Room>.from(state.rooms);
                      if (newIndex > oldIndex) newIndex--;
                      final moved = rooms.removeAt(oldIndex);
                      rooms.insert(newIndex, moved);
                      context.read<RoomCubit>().reorder(rooms);
                    },
                    itemBuilder: (context, index) {
                      final room = state.rooms[index];
                      return ListTile(
                        key: ValueKey(room.id),
                        contentPadding: EdgeInsets.zero,
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(room.name),
                        subtitle: Text(room.isOutdoor ? 'Outdoor' : 'Indoor'),
                        onTap: () => _editRoom(context, room),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteRoom(context, room),
                        ),
                      );
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _addRoom(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add room'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<Room?> _showRoomDialog(BuildContext context, {Room? existing}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  var isOutdoor = existing?.isOutdoor ?? false;

  return showDialog<Room>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'New room' : 'Edit room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Living room',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Outdoor'),
              value: isOutdoor,
              onChanged: (value) => setDialogState(() => isOutdoor = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(
                Room(
                  id: existing?.id ?? const Uuid().v4(),
                  name: name,
                  isOutdoor: isOutdoor,
                  sortOrder: existing?.sortOrder ?? 0,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
