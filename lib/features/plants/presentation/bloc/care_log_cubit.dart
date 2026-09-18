import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/usecases/get_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';

enum CareLogStatus { initial, loading, loaded, failure }

class CareLogState extends Equatable {
  const CareLogState({
    this.status = CareLogStatus.initial,
    this.events = const [],
    this.isLogging = false,
    this.errorMessage,
  });

  final CareLogStatus status;
  final List<CareEvent> events;
  final bool isLogging;
  final String? errorMessage;

  CareLogState copyWith({
    CareLogStatus? status,
    List<CareEvent>? events,
    bool? isLogging,
    String? errorMessage,
  }) {
    return CareLogState(
      status: status ?? this.status,
      events: events ?? this.events,
      isLogging: isLogging ?? this.isLogging,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, isLogging, errorMessage];
}

class CareLogCubit extends Cubit<CareLogState> {
  CareLogCubit(this._getCareEvents, this._logCareEvent)
      : super(const CareLogState());

  final GetCareEvents _getCareEvents;
  final LogCareEvent _logCareEvent;
  static const Uuid _uuid = Uuid();

  Future<void> load(String plantId) async {
    emit(state.copyWith(status: CareLogStatus.loading, errorMessage: null));
    try {
      final events = await _getCareEvents(plantId);
      emit(state.copyWith(status: CareLogStatus.loaded, events: events));
    } catch (error) {
      emit(
        state.copyWith(
          status: CareLogStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> markWatered(
    String plantId, {
    CareEventSource source = CareEventSource.detail,
  }) async {
    if (state.isLogging) {
      return;
    }
    emit(state.copyWith(isLogging: true, errorMessage: null));
    try {
      await _logCareEvent(
        CareEvent(
          id: _uuid.v4(),
          plantId: plantId,
          completedAt: DateTime.now(),
          source: source,
        ),
      );
      final events = await _getCareEvents(plantId);
      emit(
        state.copyWith(
          status: CareLogStatus.loaded,
          events: events,
          isLogging: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isLogging: false, errorMessage: error.toString()),
      );
    }
  }
}
