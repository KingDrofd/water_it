import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:water_it/features/plants/presentation/widgets/reminder_widgets.dart';

class PlantImageHandler {
  final ImagePicker _imagePicker;
  final int maxImages;

  PlantImageHandler({
    ImagePicker? imagePicker,
    this.maxImages = 4,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  Future<void> pickImages({
    required List<String> imagePaths,
    required VoidCallback onLimitReached,
    required VoidCallback onLimitExceeded,
    required VoidCallback onChanged,
  }) async {
    if (imagePaths.length >= maxImages) {
      onLimitReached();
      return;
    }
    final images = await _imagePicker.pickMultiImage();
    if (images.isEmpty) {
      return;
    }
    final remaining = maxImages - imagePaths.length;
    final selected = images.take(remaining);
    imagePaths.addAll(selected.map((image) => image.path));
    onChanged();
    if (images.length > remaining) {
      onLimitExceeded();
    }
  }

  void removeImage({
    required List<String> imagePaths,
    required String path,
    required VoidCallback onChanged,
  }) {
    imagePaths.remove(path);
    onChanged();
  }

  void setPrimaryImage({
    required List<String> imagePaths,
    required String path,
    required VoidCallback onChanged,
  }) {
    final index = imagePaths.indexOf(path);
    if (index <= 0) {
      return;
    }
    imagePaths
      ..removeAt(index)
      ..insert(0, path);
    onChanged();
  }
}

class ReminderHandlers {
  void addReminder({
    required List<ReminderDraft> reminders,
    required VoidCallback onChanged,
  }) {
    reminders.add(ReminderDraft.empty());
    onChanged();
  }

  void removeReminder({
    required List<ReminderDraft> reminders,
    required ReminderDraft reminder,
    required VoidCallback onChanged,
  }) {
    reminder.dispose();
    reminders.remove(reminder);
    onChanged();
  }

  void toggleDay({
    required ReminderDraft reminder,
    required int day,
    required VoidCallback onChanged,
  }) {
    if (reminder.weekdays.contains(day)) {
      reminder.weekdays.remove(day);
    } else {
      reminder.weekdays.add(day);
    }
    onChanged();
  }

  Future<void> pickTime({
    required BuildContext context,
    required ReminderDraft reminder,
    required VoidCallback onChanged,
  }) async {
    final now = DateTime.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminder.preferredTime ?? now),
    );
    if (pickedTime == null) {
      return;
    }
    reminder.preferredTime = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    onChanged();
  }

  void clearTime({
    required ReminderDraft reminder,
    required VoidCallback onChanged,
  }) {
    reminder.preferredTime = null;
    onChanged();
  }
}
