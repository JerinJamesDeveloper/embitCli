/// BLoC Templates
library;

import '../models/feature_config.dart';

/// Standard BLoC templates for feature generation
class BlocTemplates {
  BlocTemplates._();

  /// Generate BLoC file
  static String bloc(FeatureConfig config) {
    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:\${config.projectName}/core/errors/failures.dart';
import '../../domain/usecases/get_\${config.snakeCase}_usecase.dart';
import '../../domain/usecases/get_all_\${config.snakeCase}s_usecase.dart';
import '../../domain/usecases/create_\${config.snakeCase}_usecase.dart';
import '../../domain/usecases/update_\${config.snakeCase}_usecase.dart';
import '../../domain/usecases/delete_\${config.snakeCase}_usecase.dart';

part '\${config.snakeCase}_event.dart';
part '\${config.snakeCase}_state.dart';

class \${config.pascalCase}Bloc extends Bloc<\${config.pascalCase}Event, \${config.pascalCase}State> {
  final Get\${config.pascalCase}UseCase get\${config.pascalCase}UseCase;
  final GetAll\${config.pascalCase}sUseCase getAll\${config.pascalCase}sUseCase;
  final Create\${config.pascalCase}UseCase create\${config.pascalCase}UseCase;
  final Update\${config.pascalCase}UseCase update\${config.pascalCase}UseCase;
  final Delete\${config.pascalCase}UseCase delete\${config.pascalCase}UseCase;

  \${config.pascalCase}Bloc({
    required this.get\${config.pascalCase}UseCase,
    required this.getAll\${config.pascalCase}sUseCase,
    required this.create\${config.pascalCase}UseCase,
    required this.update\${config.pascalCase}UseCase,
    required this.delete\${config.pascalCase}UseCase,
  }) : super(\${config.pascalCase}Initial()) {
    on<Load\${config.pascalCase}Event>(_onLoad\${config.pascalCase});
    on<LoadAll\${config.pascalCase}sEvent>(_onLoadAll\${config.pascalCase}s);
    on<Create\${config.pascalCase}Event>(_onCreate\${config.pascalCase});
    on<Update\${config.pascalCase}Event>(_onUpdate\${config.pascalCase});
    on<Delete\${config.pascalCase}Event>(_onDelete\${config.pascalCase});
  }

  Future<void> _onLoad\${config.pascalCase}(
    Load\${config.pascalCase}Event event,
    Emitter<\${config.pascalCase}State> emit,
  ) async {
    emit(\${config.pascalCase}Loading());
    final result = await get\${config.pascalCase}UseCase(event.id);
    result.fold(
      (failure) => emit(\${config.pascalCase}Error(failure.message)),
      (entity) => emit(\${config.pascalCase}Loaded(entity)),
    );
  }

  Future<void> _onLoadAll\${config.pascalCase}s(
    LoadAll\${config.pascalCase}sEvent event,
    Emitter<\${config.pascalCase}State> emit,
  ) async {
    emit(\${config.pascalCase}Loading());
    final result = await getAll\${config.pascalCase}sUseCase(null);
    result.fold(
      (failure) => emit(\${config.pascalCase}Error(failure.message)),
      (entities) => emit(\${config.pascalCase}sLoaded(entities)),
    );
  }

  Future<void> _onCreate\${config.pascalCase}(
    Create\${config.pascalCase}Event event,
    Emitter<\${config.pascalCase}State> emit,
  ) async {
    emit(\${config.pascalCase}Loading());
    final result = await create\${config.pascalCase}UseCase(event.entity);
    result.fold(
      (failure) => emit(\${config.pascalCase}Error(failure.message)),
      (_) => emit(const \${config.pascalCase}OperationSuccess('Created successfully')),
    );
  }

  Future<void> _onUpdate\${config.pascalCase}(
    Update\${config.pascalCase}Event event,
    Emitter<\${config.pascalCase}State> emit,
  ) async {
    emit(\${config.pascalCase}Loading());
    final result = await update\${config.pascalCase}UseCase(event.entity);
    result.fold(
      (failure) => emit(\${config.pascalCase}Error(failure.message)),
      (_) => emit(const \${config.pascalCase}OperationSuccess('Updated successfully')),
    );
  }

  Future<void> _onDelete\${config.pascalCase}(
    Delete\${config.pascalCase}Event event,
    Emitter<\${config.pascalCase}State> emit,
  ) async {
    emit(\${config.pascalCase}Loading());
    final result = await delete\${config.pascalCase}UseCase(event.id);
    result.fold(
      (failure) => emit(\${config.pascalCase}Error(failure.message)),
      (_) => emit(const \${config.pascalCase}OperationSuccess('Deleted successfully')),
    );
  }
}
''';
  }

  /// Generate events file
  static String events(FeatureConfig config) {
    return '''
part of '\${config.snakeCase}_bloc.dart';

abstract class \${config.pascalCase}Event {
  const \${config.pascalCase}Event();
}

class Load\${config.pascalCase}Event extends \${config.pascalCase}Event {
  final String id;
  const Load\${config.pascalCase}Event(this.id);
}

class LoadAll\${config.pascalCase}sEvent extends \${config.pascalCase}Event {
  const LoadAll\${config.pascalCase}sEvent();
}

class Create\${config.pascalCase}Event extends \${config.pascalCase}Event {
  final \${config.pascalCase}Entity entity;
  const Create\${config.pascalCase}Event(this.entity);
}

class Update\${config.pascalCase}Event extends \${config.pascalCase}Event {
  final \${config.pascalCase}Entity entity;
  const Update\${config.pascalCase}Event(this.entity);
}

class Delete\${config.pascalCase}Event extends \${config.pascalCase}Event {
  final String id;
  const Delete\${config.pascalCase}Event(this.id);
}
''';
  }

  /// Generate states file
  static String states(FeatureConfig config) {
    return '''
part of '\${config.snakeCase}_bloc.dart';

abstract class \${config.pascalCase}State {
  const \${config.pascalCase}State();
}

class \${config.pascalCase}Initial extends \${config.pascalCase}State {}

class \${config.pascalCase}Loading extends \${config.pascalCase}State {}

class \${config.pascalCase}Loaded extends \${config.pascalCase}State {
  final \${config.pascalCase}Entity entity;
  const \${config.pascalCase}Loaded(this.entity);
}

class \${config.pascalCase}sLoaded extends \${config.pascalCase}State {
  final List<\${config.pascalCase}Entity> entities;
  const \${config.pascalCase}sLoaded(this.entities);
}

class \${config.pascalCase}Error extends \${config.pascalCase}State {
  final String message;
  const \${config.pascalCase}Error(this.message);
}

class \${config.pascalCase}OperationSuccess extends \${config.pascalCase}State {
  final String message;
  const \${config.pascalCase}OperationSuccess(this.message);
}
''';
  }
}
