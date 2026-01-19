import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/home/domain/entities/weather_slot.dart';
import 'package:water_it/features/home/domain/usecases/get_weather_slots.dart';

enum HomeWeatherStatus { initial, loading, loaded, failure }

class HomeWeatherState extends Equatable {
  const HomeWeatherState({
    this.status = HomeWeatherStatus.initial,
    this.slots = const [],
    this.errorMessage,
  });

  final HomeWeatherStatus status;
  final List<WeatherSlot> slots;
  final String? errorMessage;

  HomeWeatherState copyWith({
    HomeWeatherStatus? status,
    List<WeatherSlot>? slots,
    String? errorMessage,
  }) {
    return HomeWeatherState(
      status: status ?? this.status,
      slots: slots ?? this.slots,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, slots, errorMessage];
}

class HomeWeatherCubit extends Cubit<HomeWeatherState> {
  HomeWeatherCubit(this._getWeatherSlots)
      : super(const HomeWeatherState());

  final GetWeatherSlots _getWeatherSlots;

  Future<void> load({
    required double lat,
    required double lon,
  }) async {
    emit(state.copyWith(status: HomeWeatherStatus.loading, errorMessage: null));
    try {
      final slots = await _getWeatherSlots(lat: lat, lon: lon);
      emit(state.copyWith(status: HomeWeatherStatus.loaded, slots: slots));
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeWeatherStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
