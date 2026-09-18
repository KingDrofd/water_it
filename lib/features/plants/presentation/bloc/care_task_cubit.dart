import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/usecases/delete_care_task.dart';
import 'package:water_it/features/plants/domain/usecases/get_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/save_care_task.dart';

enum CareTaskStatus { initial, loading, loaded, failure }

class CareTaskState extends Equatable {
  const CareTaskState({
    this.status = CareTaskStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  final CareTaskStatus status;
  final List<CareTask> tasks;
  final String? errorMessage;

  CareTaskState copyWith({
    CareTaskStatus? status,
    List<CareTask>? tasks,
    String? errorMessage,
  }) {
    return CareTaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}

class CareTaskCubit extends Cubit<CareTaskState> {
  CareTaskCubit(this._getCareTasks, this._saveCareTask, this._deleteCareTask)
      : super(const CareTaskState());

  final GetCareTasks _getCareTasks;
  final SaveCareTask _saveCareTask;
  final DeleteCareTask _deleteCareTask;

  Future<void> load(String plantId) async {
    emit(state.copyWith(status: CareTaskStatus.loading, errorMessage: null));
    try {
      final tasks = await _getCareTasks(plantId);
      emit(state.copyWith(status: CareTaskStatus.loaded, tasks: tasks));
    } catch (error) {
      emit(
        state.copyWith(
          status: CareTaskStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> save(CareTask task) async {
    try {
      await _saveCareTask(task);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return;
    }
    await load(task.plantId);
  }

  Future<void> delete(CareTask task) async {
    try {
      await _deleteCareTask(task.id);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return;
    }
    await load(task.plantId);
  }
}
