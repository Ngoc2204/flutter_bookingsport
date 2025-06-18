import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test123/models/field_model.dart';         // <<<< SỬA TÊN PACKAGE
import 'package:test123/providers/time_slot_providers.dart'; // <<<< SỬA TÊN PACKAGE
import 'package:test123/widgets/common/loading_indicator.dart'; // <<<< SỬA TÊN PACKAGE

class TimeSlotSelector extends ConsumerWidget {
  final String fieldId;
  final FieldModel fieldModel;
  final DateTime initialSelectedDate;
  final Function(DateTime startTime, int durationMinutes) onSlotConfirmed;

  const TimeSlotSelector({
    super.key,
    required this.fieldId,
    required this.fieldModel,
    required this.initialSelectedDate,
    required this.onSlotConfirmed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlotProviderParams = (fieldId: fieldId, fieldModel: fieldModel, initialDate: initialSelectedDate);
    final timeSlotState = ref.watch(timeSlotNotifierProvider(timeSlotProviderParams));
    final timeSlotNotifier = ref.read(timeSlotNotifierProvider(timeSlotProviderParams).notifier);

    final DateFormat timeFormat = DateFormat('HH:mm');
    final List<int> availableDurations = [60, 90, 120];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (timeSlotState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(timeSlotState.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),

        if (timeSlotState.isLoading && timeSlotState.availableSlots.isEmpty)
          const Padding( // Giữ const nếu LoadingIndicator là const
            padding: EdgeInsets.symmetric(vertical: 20),
            child: LoadingIndicator(), // Giả sử LoadingIndicator có const constructor
          ),

        if (!timeSlotState.isLoading || timeSlotState.availableSlots.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: timeSlotState.availableSlots.map((slot) {
              final isSelected = timeSlotState.selectedStartTime == slot.startTime;
              return ChoiceChip(
                label: Text('${timeFormat.format(DateTime(0,0,0,slot.startTime.hour, slot.startTime.minute))} - ${timeFormat.format(DateTime(0,0,0,slot.endTime.hour, slot.endTime.minute))}'),
                selected: isSelected,
                onSelected: slot.isSelectable
                    ? (selected) {
                  if (selected) {
                    timeSlotNotifier.selectStartTime(slot.startTime);
                  }
                }
                    : null,
                backgroundColor: !slot.isAvailable ? Colors.grey.shade300 : (slot.isSelectable ? null : Colors.grey.shade200),
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (!slot.isAvailable || !slot.isSelectable ? Colors.grey.shade500 : null),
                ),
              );
            }).toList(),
          ),
        if (timeSlotState.availableSlots.isEmpty && !timeSlotState.isLoading)
          const Padding( // Giữ const nếu Text là const
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(child: Text('Không có khung giờ trống cho ngày này.')),
          ),

        if (timeSlotState.selectedStartTime != null) ...[
          const SizedBox(height: 16),
          Text('Chọn thời lượng:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: availableDurations.map((duration) {
              final isSelected = timeSlotState.selectedDurationMinutes == duration;
              return ChoiceChip(
                label: Text('$duration phút'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    timeSlotNotifier.selectDuration(duration);
                  }
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              );
            }).toList(),
          ),
        ],

        if (timeSlotState.selectedStartTime != null && timeSlotState.selectedDurationMinutes != null) ...[
          const SizedBox(height: 24),
          timeSlotState.isLoading
              ? const Center(child: LoadingIndicator()) // Giữ const nếu LoadingIndicator là const
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await timeSlotNotifier.confirmAndProceed(
                        (startTime, durationMinutes) {
                      onSlotConfirmed(startTime, durationMinutes);
                    });
              },
              child: const Text('Đặt sân ngay'),
            ),
          ),
        ],
      ],
    );
  }
}