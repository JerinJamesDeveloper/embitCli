import '../models/feature_config.dart';

class BlocTemplates {
  /// BLoC template
  static String bloc(FeatureConfig config) => '''
/// ${config.pascalCase} BLoC
///
/// Business Logic Component for ${config.name} management.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/${config.snakeCase}_entity.dart';
import '../../domain/usecases/create_${config.snakeCase}_usecase.dart';
import '../../domain/usecases/delete_${config.snakeCase}_usecase.dart';
import '../../domain/usecases/get_${config.snakeCase}_usecase.dart';
import '../../domain/usecases/get_all_${config.snakeCase}s_usecase.dart';
import '../../domain/usecases/update_${config.snakeCase}_usecase.dart';
import '${config.snakeCase}_event.dart';
import '${config.snakeCase}_state.dart';

/// ${config.pascalCase} BLoC
class ${config.pascalCase}Bloc extends Bloc<${config.pascalCase}Event, ${config.pascalCase}State> {
  final Get${config.pascalCase}UseCase _get${config.pascalCase}UseCase;
  final GetAll${config.pascalCase}sUseCase _getAll${config.pascalCase}sUseCase;
  final Create${config.pascalCase}UseCase _create${config.pascalCase}UseCase;
  final Update${config.pascalCase}UseCase _update${config.pascalCase}UseCase;
  final Delete${config.pascalCase}UseCase _delete${config.pascalCase}UseCase;

  ${config.pascalCase}Bloc({
    required Get${config.pascalCase}UseCase get${config.pascalCase}UseCase,
    required GetAll${config.pascalCase}sUseCase getAll${config.pascalCase}sUseCase,
    required Create${config.pascalCase}UseCase create${config.pascalCase}UseCase,
    required Update${config.pascalCase}UseCase update${config.pascalCase}UseCase,
    required Delete${config.pascalCase}UseCase delete${config.pascalCase}UseCase,
  })  : _get${config.pascalCase}UseCase = get${config.pascalCase}UseCase,
        _getAll${config.pascalCase}sUseCase = getAll${config.pascalCase}sUseCase,
        _create${config.pascalCase}UseCase = create${config.pascalCase}UseCase,
        _update${config.pascalCase}UseCase = update${config.pascalCase}UseCase,
        _delete${config.pascalCase}UseCase = delete${config.pascalCase}UseCase,
        super(const ${config.pascalCase}Initial()) {
    on<${config.pascalCase}LoadRequested>(_onLoadRequested);
    on<${config.pascalCase}ListLoadRequested>(_onListLoadRequested);
    on<${config.pascalCase}CreateRequested>(_onCreate);
    on<${config.pascalCase}UpdateRequested>(_onUpdate);
    on<${config.pascalCase}DeleteRequested>(_onDelete);
    on<${config.pascalCase}RefreshRequested>(_onRefresh);
    on<${config.pascalCase}ErrorCleared>(_onErrorCleared);
  }

  Future<void> _onLoadRequested(
    ${config.pascalCase}LoadRequested event,
    Emitter<${config.pascalCase}State> emit,
  ) async {
    emit(const ${config.pascalCase}Loading(message: 'Loading...'));

    final result = await _get${config.pascalCase}UseCase(
      Get${config.pascalCase}Params(id: event.id),
    );

    result.fold(
      (failure) => emit(${config.pascalCase}Error(message: failure.message)),
      (${config.camelCase}) => emit(${config.pascalCase}Loaded(${config.camelCase}: ${config.camelCase})),
    );
  }

  Future<void> _onListLoadRequested(
    ${config.pascalCase}ListLoadRequested event,
    Emitter<${config.pascalCase}State> emit,
  ) async {
    emit(const ${config.pascalCase}Loading(message: 'Loading list...'));

    final result = await _getAll${config.pascalCase}sUseCase();

    result.fold(
      (failure) => emit(${config.pascalCase}Error(message: failure.message)),
      (${config.camelCase}s) => emit(${config.pascalCase}ListLoaded(${config.camelCase}s: ${config.camelCase}s)),
    );
  }

  Future<void> _onCreate(
    ${config.pascalCase}CreateRequested event,
    Emitter<${config.pascalCase}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${config.pascalCase}Operating(
      ${config.camelCase}s: currentItems,
      operation: ${config.pascalCase}Operation.create,
    ));

    final result = await _create${config.pascalCase}UseCase(
      Create${config.pascalCase}Params(
        name: event.name,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      (${config.camelCase}) {
        final updatedItems = [...currentItems, ${config.camelCase}];
        emit(${config.pascalCase}OperationSuccess(
          ${config.camelCase}s: updatedItems,
          message: '${config.pascalCase} created successfully',
        ));
      },
    );
  }

  Future<void> _onUpdate(
    ${config.pascalCase}UpdateRequested event,
    Emitter<${config.pascalCase}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${config.pascalCase}Operating(
      ${config.camelCase}s: currentItems,
      operation: ${config.pascalCase}Operation.update,
    ));

    final result = await _update${config.pascalCase}UseCase(
      Update${config.pascalCase}Params(
        id: event.id,
        name: event.name,
        description: event.description,
        isActive: event.isActive,
      ),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      (${config.camelCase}) {
        final updatedItems = currentItems.map((item) {
          return item.id == ${config.camelCase}.id ? ${config.camelCase} : item;
        }).toList();
        emit(${config.pascalCase}OperationSuccess(
          ${config.camelCase}s: updatedItems,
          message: '${config.pascalCase} updated successfully',
        ));
      },
    );
  }

  Future<void> _onDelete(
    ${config.pascalCase}DeleteRequested event,
    Emitter<${config.pascalCase}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${config.pascalCase}Operating(
      ${config.camelCase}s: currentItems,
      operation: ${config.pascalCase}Operation.delete,
    ));

    final result = await _delete${config.pascalCase}UseCase(
      Delete${config.pascalCase}Params(id: event.id),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      (_) {
        final updatedItems = currentItems.where((item) => item.id != event.id).toList();
        emit(${config.pascalCase}OperationSuccess(
          ${config.camelCase}s: updatedItems,
          message: '${config.pascalCase} deleted successfully',
        ));
      },
    );
  }

  Future<void> _onRefresh(
    ${config.pascalCase}RefreshRequested event,
    Emitter<${config.pascalCase}State> emit,
  ) async {
    final result = await _getAll${config.pascalCase}sUseCase();

    result.fold(
      (failure) {
        // Keep current state on refresh failure
      },
      (${config.camelCase}s) => emit(${config.pascalCase}ListLoaded(${config.camelCase}s: ${config.camelCase}s)),
    );
  }

  void _onErrorCleared(
    ${config.pascalCase}ErrorCleared event,
    Emitter<${config.pascalCase}State> emit,
  ) {
    final currentItems = _getCurrentItems();
    if (currentItems.isNotEmpty) {
      emit(${config.pascalCase}ListLoaded(${config.camelCase}s: currentItems));
    } else {
      emit(const ${config.pascalCase}Initial());
    }
  }

  List<${config.pascalCase}Entity> _getCurrentItems() {
    final currentState = state;
    if (currentState is ${config.pascalCase}ListLoaded) return currentState.${config.camelCase}s;
    if (currentState is ${config.pascalCase}Operating) return currentState.${config.camelCase}s;
    if (currentState is ${config.pascalCase}OperationSuccess) return currentState.${config.camelCase}s;
    if (currentState is ${config.pascalCase}Error) return currentState.${config.camelCase}s ?? [];
    return [];
  }

  ${config.pascalCase}Error _mapFailureToState(Failure failure, List<${config.pascalCase}Entity> items) {
    if (failure is ValidationFailure) {
      return ${config.pascalCase}Error(
        message: failure.message,
        fieldErrors: failure.fieldErrors,
        ${config.camelCase}s: items,
      );
    }
    return ${config.pascalCase}Error(
      message: failure.message,
      ${config.camelCase}s: items,
    );
  }
}
''';

  /// Events template
  static String events(FeatureConfig config) => '''
/// ${config.pascalCase} BLoC Events
///
/// Events that trigger state changes in the ${config.pascalCase}Bloc.
library;

import 'package:equatable/equatable.dart';

/// Base class for all ${config.name} events
sealed class ${config.pascalCase}Event extends Equatable {
  const ${config.pascalCase}Event();

  @override
  List<Object?> get props => [];
}

/// Event to load a single ${config.name}
class ${config.pascalCase}LoadRequested extends ${config.pascalCase}Event {
  final String id;

  const ${config.pascalCase}LoadRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event to load all ${config.name}s
class ${config.pascalCase}ListLoadRequested extends ${config.pascalCase}Event {
  const ${config.pascalCase}ListLoadRequested();
}

/// Event to create a new ${config.name}
class ${config.pascalCase}CreateRequested extends ${config.pascalCase}Event {
  final String name;
  final String? description;

  const ${config.pascalCase}CreateRequested({
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [name, description];
}

/// Event to update an existing ${config.name}
class ${config.pascalCase}UpdateRequested extends ${config.pascalCase}Event {
  final String id;
  final String? name;
  final String? description;
  final bool? isActive;

  const ${config.pascalCase}UpdateRequested({
    required this.id,
    this.name,
    this.description,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, name, description, isActive];
}

/// Event to delete a ${config.name}
class ${config.pascalCase}DeleteRequested extends ${config.pascalCase}Event {
  final String id;

  const ${config.pascalCase}DeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event to refresh ${config.name}s
class ${config.pascalCase}RefreshRequested extends ${config.pascalCase}Event {
  const ${config.pascalCase}RefreshRequested();
}

/// Event to clear error state
class ${config.pascalCase}ErrorCleared extends ${config.pascalCase}Event {
  const ${config.pascalCase}ErrorCleared();
}
''';

  /// States template
  static String states(FeatureConfig config) => '''
/// ${config.pascalCase} BLoC States
///
/// States representing the current ${config.name} status.
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/${config.snakeCase}_entity.dart';

/// Base class for all ${config.name} states
sealed class ${config.pascalCase}State extends Equatable {
  const ${config.pascalCase}State();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ${config.pascalCase}Initial extends ${config.pascalCase}State {
  const ${config.pascalCase}Initial();
}

/// Loading state
class ${config.pascalCase}Loading extends ${config.pascalCase}State {
  final String? message;

  const ${config.pascalCase}Loading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Single ${config.name} loaded successfully
class ${config.pascalCase}Loaded extends ${config.pascalCase}State {
  final ${config.pascalCase}Entity ${config.camelCase};

  const ${config.pascalCase}Loaded({required this.${config.camelCase}});

  @override
  List<Object?> get props => [${config.camelCase}];
}

/// List of ${config.name}s loaded successfully
class ${config.pascalCase}ListLoaded extends ${config.pascalCase}State {
  final List<${config.pascalCase}Entity> ${config.camelCase}s;

  const ${config.pascalCase}ListLoaded({required this.${config.camelCase}s});

  @override
  List<Object?> get props => [${config.camelCase}s];
}

/// Operation in progress
class ${config.pascalCase}Operating extends ${config.pascalCase}State {
  final List<${config.pascalCase}Entity> ${config.camelCase}s;
  final ${config.pascalCase}Operation operation;

  const ${config.pascalCase}Operating({
    required this.${config.camelCase}s,
    required this.operation,
  });

  @override
  List<Object?> get props => [${config.camelCase}s, operation];
}

/// Operation completed successfully
class ${config.pascalCase}OperationSuccess extends ${config.pascalCase}State {
  final List<${config.pascalCase}Entity> ${config.camelCase}s;
  final String message;

  const ${config.pascalCase}OperationSuccess({
    required this.${config.camelCase}s,
    this.message = 'Operation completed successfully',
  });

  @override
  List<Object?> get props => [${config.camelCase}s, message];
}

/// Error state
class ${config.pascalCase}Error extends ${config.pascalCase}State {
  final String message;
  final Map<String, List<String>>? fieldErrors;
  final List<${config.pascalCase}Entity>? ${config.camelCase}s;

  const ${config.pascalCase}Error({
    required this.message,
    this.fieldErrors,
    this.${config.camelCase}s,
  });

  String? getFieldError(String field) {
    return fieldErrors?[field]?.first;
  }

  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  @override
  List<Object?> get props => [message, fieldErrors, ${config.camelCase}s];
}

/// Operation types
enum ${config.pascalCase}Operation {
  create,
  update,
  delete,
}
''';
}
