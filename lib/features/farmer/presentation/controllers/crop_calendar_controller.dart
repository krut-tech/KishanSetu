import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/farmer/domain/models/crop_calendar_event_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class CropCalendarState extends Equatable {
  final List<CropCalendarEventModel> events;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const CropCalendarState({
    this.events = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  CropCalendarState copyWith({
    List<CropCalendarEventModel>? events,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CropCalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [events, isLoading, isSubmitting, errorMessage, successMessage];
}

class CropCalendarController extends StateNotifier<CropCalendarState> {
  final FarmerRepository _repository;

  CropCalendarController(this._repository) : super(const CropCalendarState());

  Future<void> fetchEvents(String farmerId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _repository.getCropCalendarEvents(farmerId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (events) => state = state.copyWith(isLoading: false, events: events),
    );
  }

  Future<bool> addEvent(CropCalendarEventModel event) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    final result = await _repository.addCropCalendarEvent(event);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        final updated = [...state.events, created]
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
        state = state.copyWith(
          isSubmitting: false,
          events: updated,
          successMessage: 'Reminder added successfully!',
        );
        return true;
      },
    );
  }

  Future<bool> toggleCompleted(String eventId, bool isCompleted) async {
    final result = await _repository.toggleCropCalendarEventCompleted(eventId, isCompleted);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          events: state.events
              .map((e) => e.id == eventId ? e.copyWith(isCompleted: isCompleted) : e)
              .toList(),
        );
        return true;
      },
    );
  }

  Future<bool> deleteEvent(String eventId) async {
    final result = await _repository.deleteCropCalendarEvent(eventId);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          events: state.events.where((e) => e.id != eventId).toList(),
          successMessage: 'Reminder deleted.',
        );
        return true;
      },
    );
  }

  void reset() {
    state = const CropCalendarState();
  }
}
