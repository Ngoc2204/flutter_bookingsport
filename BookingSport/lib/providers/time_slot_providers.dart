import 'package:flutter/material.dart'; // Cần cho TimeOfDay
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Để format log thời gian nếu cần
import 'package:test123/models/booking_model.dart';
import 'package:test123/models/field_model.dart';
import 'package:test123/providers/booking_providers.dart'; // Đảm bảo provider này được định nghĩa
import 'package:test123/services/booking_service.dart'; // Service được inject

// --- State cho TimeSlotSelector ---
class TimeSlotState {
  final DateTime selectedDate;
  final List<TimeSlot> availableSlots;
  final bool isLoading;
  final String? errorMessage;
  final TimeOfDay? selectedStartTime;
  final int? selectedDurationMinutes;

  TimeSlotState({
    required this.selectedDate,
    this.availableSlots = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedStartTime,
    this.selectedDurationMinutes,
  });

  TimeSlotState copyWith({
    DateTime? selectedDate,
    List<TimeSlot>? availableSlots,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    TimeOfDay? selectedStartTime,
    bool clearSelectedStartTime = false,
    int? selectedDurationMinutes,
    bool clearSelectedDurationMinutes = false,
  }) {
    return TimeSlotState(
      selectedDate: selectedDate ?? this.selectedDate,
      availableSlots: availableSlots ?? this.availableSlots,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      selectedStartTime: clearSelectedStartTime ? null : selectedStartTime ?? this.selectedStartTime,
      selectedDurationMinutes: clearSelectedDurationMinutes ? null : selectedDurationMinutes ?? this.selectedDurationMinutes,
    );
  }
}

// Model cho một khung giờ
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final bool isSelectable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.isSelectable = true,
  });
}

// --- StateNotifier ---
class TimeSlotNotifier extends StateNotifier<TimeSlotState> {
  final BookingService _bookingService;
  final String fieldId;
  final FieldModel fieldModel;

  TimeSlotNotifier(
      this._bookingService,
      this.fieldId,
      this.fieldModel,
      DateTime initialDate,
      ) : super(TimeSlotState(selectedDate: initialDate, isLoading: true)) {
    // Gọi fetchAvailableSlots trong constructor.
    // fetchAvailableSlots cần tự bảo vệ bằng cách kiểm tra 'mounted'.
    fetchAvailableSlots(initialDate);
  }

  Future<void> fetchAvailableSlots(DateTime date) async {
    // Kiểm tra mounted ở đầu hàm nếu có thể, nhưng quan trọng hơn là sau await
    if (!mounted) return; // Thoát sớm nếu đã dispose

    state = state.copyWith(
        isLoading: true,
        selectedDate: date,
        availableSlots: [],
        clearErrorMessage: true,
        clearSelectedStartTime: true,
        clearSelectedDurationMinutes: true);

    try {
      print("[TimeSlotNotifier-$fieldId] Fetching slots for date: ${DateFormat('yyyy-MM-dd').format(date)}");
      final bookingsOnDate = await _bookingService.getBookingsForFieldOnDate(fieldId, date);

      // Sau khi await, notifier có thể đã bị dispose, kiểm tra lại
      if (!mounted) return;

      print("[TimeSlotNotifier-$fieldId] Found ${bookingsOnDate.length} bookings for ${DateFormat('yyyy-MM-dd').format(date)}");
      final generatedSlots = _generateTimeSlots(date, bookingsOnDate); // Hàm này đồng bộ

      if (!mounted) return; // Kiểm tra lần nữa trước khi cập nhật state cuối cùng

      print("[TimeSlotNotifier-$fieldId] Generated ${generatedSlots.length} slots for ${DateFormat('yyyy-MM-dd').format(date)}");
      state = state.copyWith(availableSlots: generatedSlots, isLoading: false);

    } catch (e, stackTrace) {
      print("[TimeSlotNotifier-$fieldId] ERROR fetching/generating slots for ${DateFormat('yyyy-MM-dd').format(date)}: $e");
      print(stackTrace);
      if (!mounted) return; // Kiểm tra trước khi cập nhật state lỗi
      state = state.copyWith(
          errorMessage: "Lỗi tải khung giờ: ${e.toString()}",
          isLoading: false);
    }
  }

  List<TimeSlot> _generateTimeSlots(DateTime date, List<BookingModel> bookings) {
    // ... (Logic của _generateTimeSlots giữ nguyên như bạn đã cung cấp)
    // Đảm bảo logic parse openingHoursDescription và tạo slot là đúng
    List<TimeSlot> slots = [];
    TimeOfDay openingTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closingTime = const TimeOfDay(hour: 22, minute: 0);

    try {
      if (fieldModel.openingHoursDescription.isNotEmpty) {
        final parts = fieldModel.openingHoursDescription.split('-');
        if (parts.length == 2) {
          final openParts = parts[0].trim().split(':');
          final closeParts = parts[1].trim().split(':');
          if (openParts.length == 2 && closeParts.length == 2) {
            openingTime = TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1]));
            closingTime = TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1]));
          } else {
            print("[TimeSlotNotifier-$fieldId] WARN: Invalid openingHoursDescription time parts: ${fieldModel.openingHoursDescription}");
          }
        } else {
          print("[TimeSlotNotifier-$fieldId] WARN: Invalid openingHoursDescription format (no hyphen): ${fieldModel.openingHoursDescription}");
        }
      } else {
        print("[TimeSlotNotifier-$fieldId] WARN: openingHoursDescription is empty. Using default hours.");
      }
    } catch (e) {
      print("[TimeSlotNotifier-$fieldId] ERROR parsing openingHoursDescription '${fieldModel.openingHoursDescription}': $e. Using default hours.");
    }
    print("[TimeSlotNotifier-$fieldId] Using Opening: $openingTime, Closing: $closingTime (From: '${fieldModel.openingHoursDescription}')");

    final int slotDurationMinutes = fieldModel.defaultSlotDurationMinutes ?? 60;
    DateTime currentTimeSlotStart = DateTime(date.year, date.month, date.day, openingTime.hour, openingTime.minute);
    final DateTime now = DateTime.now();
    DateTime dayClosingDateTime = DateTime(date.year, date.month, date.day, closingTime.hour, closingTime.minute);

    if (closingTime.hour == 0 && closingTime.minute == 0) {
      dayClosingDateTime = dayClosingDateTime.add(const Duration(days: 1));
    }

    while (currentTimeSlotStart.isBefore(dayClosingDateTime)) {
      DateTime currentTimeSlotEnd = currentTimeSlotStart.add(Duration(minutes: slotDurationMinutes));
      if (currentTimeSlotEnd.isAfter(dayClosingDateTime)) {
        break;
      }
      TimeOfDay slotStartTime = TimeOfDay.fromDateTime(currentTimeSlotStart);
      TimeOfDay slotEndTime = TimeOfDay.fromDateTime(currentTimeSlotEnd);
      bool isBooked = false;
      for (var booking in bookings) {
        DateTime bookingStartLocal = booking.startTime.toDate();
        DateTime bookingEndLocal = booking.endTime.toDate();
        if (currentTimeSlotStart.isBefore(bookingEndLocal) && currentTimeSlotEnd.isAfter(bookingStartLocal)) {
          isBooked = true;
          break;
        }
      }
      bool isPastSlot = false;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        isPastSlot = currentTimeSlotStart.isBefore(now);
      }
      slots.add(TimeSlot(
        startTime: slotStartTime,
        endTime: slotEndTime,
        isAvailable: !isBooked,
        isSelectable: !isBooked && !isPastSlot,
      ));
      currentTimeSlotStart = currentTimeSlotEnd;
    }
    return slots;
  }

  void selectStartTime(TimeOfDay time) {
    if (!mounted) return;
    state = state.copyWith(selectedStartTime: time, clearSelectedDurationMinutes: true, clearErrorMessage: true);
  }

  void selectDuration(int durationMinutes) {
    if (!mounted) return;
    state = state.copyWith(selectedDurationMinutes: durationMinutes, clearErrorMessage: true);
  }

  Future<bool> confirmAndProceed(Function(DateTime startTime, int durationMinutes) onProceed) async {
    if (!mounted) return false;

    if (state.selectedStartTime == null || state.selectedDurationMinutes == null) {
      state = state.copyWith(errorMessage: "Vui lòng chọn giờ bắt đầu và thời lượng.");
      return false;
    }
    final startTime = DateTime(
        state.selectedDate.year, state.selectedDate.month, state.selectedDate.day,
        state.selectedStartTime!.hour, state.selectedStartTime!.minute);
    final endTime = startTime.add(Duration(minutes: state.selectedDurationMinutes!));

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final isAvailable = await _bookingService.isSlotAvailable(fieldId, startTime, endTime);
      if (!mounted) return false; // Kiểm tra sau await

      if (!isAvailable) {
        state = state.copyWith(isLoading: false, errorMessage: "Rất tiếc, khung giờ này vừa có người khác đặt. Vui lòng chọn lại.");
        // Quan trọng: Tải lại slot để UI cập nhật
        // fetchAvailableSlots sẽ tự kiểm tra mounted bên trong nó
        fetchAvailableSlots(state.selectedDate);
        return false;
      }

      state = state.copyWith(isLoading: false); // Reset loading nếu thành công trước khi callback
      if (!mounted) return false; // Kiểm tra trước khi gọi callback

      onProceed(startTime, state.selectedDurationMinutes!);
      return true;
    } catch (e, stackTrace) {
      print("[TimeSlotNotifier-$fieldId] ERROR in confirmAndProceed: $e");
      print(stackTrace);
      if (!mounted) return false; // Kiểm tra trước khi cập nhật state lỗi
      state = state.copyWith(isLoading: false, errorMessage: "Lỗi khi xác nhận đặt sân: ${e.toString()}");
      return false;
    }
  }
}

// Provider Definition
final timeSlotNotifierProvider = StateNotifierProvider.autoDispose
    .family<TimeSlotNotifier, TimeSlotState, ({String fieldId, FieldModel fieldModel, DateTime initialDate})>((ref, params) {
  final bookingService = ref.watch(bookingServiceProvider);
  return TimeSlotNotifier(
    bookingService,
    params.fieldId,
    params.fieldModel,
    params.initialDate,
  );
});