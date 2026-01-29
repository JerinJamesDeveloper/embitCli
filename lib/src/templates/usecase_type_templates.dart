/// UseCase Type Templates
///
/// Templates for different types of usecases.
library;

import '../models/usecase_config.dart';

/// Templates for different usecase types
class UseCaseTypeTemplates {
  UseCaseTypeTemplates._();

  /// Generate usecase based on type
  /// If custom fields are provided, uses those instead of default fields
  static String generate(UseCaseConfig config) {
    // If custom fields are defined, use the custom fields template
    if (config.hasCustomFields) {
      return _customFieldsTemplate(config);
    }

    // Otherwise, use type-based default template
    switch (config.type) {
      case UseCaseType.get:
        return _getTemplate(config);
      case UseCaseType.getList:
        return _getListTemplate(config);
      case UseCaseType.create:
        return _createTemplate(config);
      case UseCaseType.update:
        return _updateTemplate(config);
      case UseCaseType.delete:
        return _deleteTemplate(config);
      case UseCaseType.custom:
        return _customTemplate(config);
    }
  }

  /// Template that uses custom fields from config
  static String _customFieldsTemplate(UseCaseConfig config) {
    final fieldDeclarations = config.generateFieldDeclarations();
    final constructorParams = config.generateConstructorParams();
    final propsItems = config.generatePropsItems();
    final validationCode = config.generateValidationCode();
    final repositoryCallArgs = config.generateRepositoryCallArgs();

    return '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${config.featureSnakeCase}_entity.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// Parameters for ${config.useCaseClassName}
class ${config.paramsClassName} extends Equatable {
$fieldDeclarations

  const ${config.paramsClassName}({
$constructorParams
  });

  @override
  List<Object?> get props => [$propsItems];
}

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCase<${config.returnType}, ${config.paramsClassName}> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, ${config.returnType}>> call(${config.paramsClassName} params) async {
    // Validation
$validationCode
    return await _repository.${config.repositoryMethodName}(
$repositoryCallArgs
    );
  }
}
''';
  }

  /// Get single entity template
  static String _getTemplate(UseCaseConfig config) => '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${config.featureSnakeCase}_entity.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// Parameters for ${config.useCaseClassName}
class ${config.paramsClassName} extends Equatable {
  final String id;

  const ${config.paramsClassName}({required this.id});

  @override
  List<Object?> get props => [id];
}

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCase<${config.entityName}, ${config.paramsClassName}> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, ${config.entityName}>> call(${config.paramsClassName} params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID cannot be empty',
        fieldErrors: {'id': ['ID is required']},
      ));
    }

    return await _repository.${config.repositoryMethodName}(params.id);
  }
}
''';

  /// Get list template
  static String _getListTemplate(UseCaseConfig config) => '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${config.featureSnakeCase}_entity.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCaseNoParams<List<${config.entityName}>> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, List<${config.entityName}>>> call() async {
    return await _repository.${config.repositoryMethodName}();
  }
}
''';

  /// Create entity template
  static String _createTemplate(UseCaseConfig config) => '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${config.featureSnakeCase}_entity.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// Parameters for ${config.useCaseClassName}
class ${config.paramsClassName} extends Equatable {
  final String name;
  final String? description;

  const ${config.paramsClassName}({
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [name, description];
}

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCase<${config.entityName}, ${config.paramsClassName}> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, ${config.entityName}>> call(${config.paramsClassName} params) async {
    // Validation
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(
        message: 'Name cannot be empty',
        fieldErrors: {'name': ['Name is required']},
      ));
    }

    return await _repository.${config.repositoryMethodName}(
      name: params.name.trim(),
      description: params.description?.trim(),
    );
  }
}
''';

  /// Update entity template
  static String _updateTemplate(UseCaseConfig config) => '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${config.featureSnakeCase}_entity.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// Parameters for ${config.useCaseClassName}
class ${config.paramsClassName} extends Equatable {
  final String id;
  final String? name;
  final String? description;

  const ${config.paramsClassName}({
    required this.id,
    this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCase<${config.entityName}, ${config.paramsClassName}> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, ${config.entityName}>> call(${config.paramsClassName} params) async {
    // Validation
    if (params.id.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID cannot be empty',
        fieldErrors: {'id': ['ID is required']},
      ));
    }

    return await _repository.${config.repositoryMethodName}(
      id: params.id,
      name: params.name?.trim(),
      description: params.description?.trim(),
    );
  }
}
''';

  /// Delete entity template
  static String _deleteTemplate(UseCaseConfig config) => '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// Parameters for ${config.useCaseClassName}
class ${config.paramsClassName} extends Equatable {
  final String id;

  const ${config.paramsClassName}({required this.id});

  @override
  List<Object?> get props => [id];
}

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCase<Unit, ${config.paramsClassName}> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, Unit>> call(${config.paramsClassName} params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID cannot be empty',
        fieldErrors: {'id': ['ID is required']},
      ));
    }

    return await _repository.${config.repositoryMethodName}(params.id);
  }
}
''';

  /// Custom template (flexible)
  static String _customTemplate(UseCaseConfig config) => '''
/// ${config.useCasePascalCase} Use Case
///
/// ${config.useCasePascalCase} for ${config.featureName}.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${config.featureSnakeCase}_entity.dart';
import '../repositories/${config.featureSnakeCase}_repository.dart';

/// Parameters for ${config.useCaseClassName}
class ${config.paramsClassName} extends Equatable {
  // TODO: Add your parameters here
  final String id;

  const ${config.paramsClassName}({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

/// ${config.useCasePascalCase} use case
class ${config.useCaseClassName} implements UseCase<${config.entityName}, ${config.paramsClassName}> {
  final ${config.repositoryName} _repository;

  ${config.useCaseClassName}(this._repository);

  @override
  Future<Either<Failure, ${config.entityName}>> call(${config.paramsClassName} params) async {
    // TODO: Add your validation logic here
    
    // TODO: Call repository method
    return await _repository.${config.repositoryMethodName}(id : params.id);
  }
}
''';

  /// BLoC event template
  // ==================== BLOC EVENT TEMPLATES ====================

  static String blocEvent(UseCaseConfig config) {
    // If custom fields are defined, use custom fields event template
    if (config.hasCustomFields) {
      return _eventCustomFieldsTemplate(config);
    }

    // Otherwise, use type-based default template
    switch (config.type) {
      case UseCaseType.get:
        return _eventGetTemplate(config);
      case UseCaseType.getList:
        return _eventGetListTemplate(config);
      case UseCaseType.create:
        return _eventCreateTemplate(config);
      case UseCaseType.update:
        return _eventUpdateTemplate(config);
      case UseCaseType.delete:
        return _eventDeleteTemplate(config);
      case UseCaseType.custom:
        return _eventCustomTemplate(config);
    }
  }

  /// Event template that uses custom fields from config
  static String _eventCustomFieldsTemplate(UseCaseConfig config) {
    final fieldDeclarations = config.generateFieldDeclarations();
    final constructorParams = config.generateConstructorParams();
    final propsItems = config.generatePropsItems();

    return '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
$fieldDeclarations

  const ${config.eventName}({
$constructorParams
  });

  @override
  List<Object?> get props => [$propsItems];
}
''';
  }

  static String _eventGetTemplate(UseCaseConfig config) => '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
  final String id;

  const ${config.eventName}({required this.id});

  @override
  List<Object?> get props => [id];
}
''';

  static String _eventGetListTemplate(UseCaseConfig config) => '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
  const ${config.eventName}();
}
''';

  static String _eventCreateTemplate(UseCaseConfig config) => '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
  final String name;
  final String? description;

  const ${config.eventName}({
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [name, description];
}
''';

  static String _eventUpdateTemplate(UseCaseConfig config) => '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
  final String id;
  final String? name;
  final String? description;
  final bool? isActive;

  const ${config.eventName}({
    required this.id,
    this.name,
    this.description,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, name, description, isActive];
}
''';

  static String _eventDeleteTemplate(UseCaseConfig config) => '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
  final String id;

  const ${config.eventName}({required this.id});

  @override
  List<Object?> get props => [id];
}
''';

  static String _eventCustomTemplate(UseCaseConfig config) => '''

/// Event to ${config.useCasePascalCase}
class ${config.eventName} extends ${config.featurePascalCase}Event {
  final String id;
  // TODO: Add your event parameters

  const ${config.eventName}({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}
''';


  // ==================== BLOC STATE UPDATE (OPERATION ENUM) ====================

  /// Returns the new operation enum value to add (if needed)
  /// Returns null if no state update is needed
  static String? stateOperationEnumValue(UseCaseConfig config) {
    // Only update/delete/custom types need operation enum
    switch (config.type) {
      case UseCaseType.get:
      case UseCaseType.getList:
        return null; // No operation enum needed
      case UseCaseType.create:
      case UseCaseType.update:
      case UseCaseType.delete:
      case UseCaseType.custom:
        return '  ${config.useCaseCamelCase},';
    }
  }
  // ==================== BLOC EVENT HANDLER TEMPLATES ====================

  static String blocEventHandler(UseCaseConfig config) {
    // If custom fields are defined, use custom fields handler template
    if (config.hasCustomFields) {
      return _handlerCustomFieldsTemplate(config);
    }

    // Otherwise, use type-based default template
    switch (config.type) {
      case UseCaseType.get:
        return _handlerGetTemplate(config);
      case UseCaseType.getList:
        return _handlerGetListTemplate(config);
      case UseCaseType.create:
        return _handlerCreateTemplate(config);
      case UseCaseType.update:
        return _handlerUpdateTemplate(config);
      case UseCaseType.delete:
        return _handlerDeleteTemplate(config);
      case UseCaseType.custom:
        return _handlerCustomTemplate(config);
    }
  }

  /// Handler template that uses custom fields from config
  static String _handlerCustomFieldsTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final paramsClass = config.paramsClassName;
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;
    final operationName = config.useCaseCamelCase;
    final eventToParamsArgs = config.generateEventToParamsArgs();

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${featurePascal}Operating(
      ${featureCamel}s: currentItems,
      operation: ${featurePascal}Operation.$operationName,
    ));

    final result = await $useCaseField(
      $paramsClass(
$eventToParamsArgs
      ),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      ($featureCamel) {
        final updatedItems = [...currentItems, $featureCamel];
        emit(${featurePascal}OperationSuccess(
          ${featureCamel}s: updatedItems,
          message: '${config.useCasePascalCase} completed successfully',
        ));
      },
    );
  }
''';
  }

  static String _handlerGetTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final paramsClass = config.paramsClassName;
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    emit(const ${featurePascal}Loading(message: 'Loading...'));

    final result = await $useCaseField(
      $paramsClass(id: event.id),
    );

    result.fold(
      (failure) => emit(${featurePascal}Error(message: failure.message)),
      ($featureCamel) => emit(${featurePascal}Loaded($featureCamel: $featureCamel)),
    );
  }
''';
  }

  static String _handlerGetListTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    emit(const ${featurePascal}Loading(message: 'Loading list...'));

    final result = await $useCaseField();

    result.fold(
      (failure) => emit(${featurePascal}Error(message: failure.message)),
      (${featureCamel}s) => emit(${featurePascal}ListLoaded(${featureCamel}s: ${featureCamel}s)),
    );
  }
''';
  }

//   static String _handlerCreateTemplate(UseCaseConfig config) {
//     final eventName = config.eventName;
//     final handlerName = '_on${config.useCasePascalCase}';
//     final useCaseField = '_${config.useCaseCamelCase}UseCase';
//     final paramsClass = config.paramsClassName;
//     final featurePascal = config.featurePascalCase;
//     final featureCamel = config.featureCamelCase;

//     return '''

//   Future<void> $handlerName(
//     $eventName event,
//     Emitter<${featurePascal}State> emit,
//   ) async {
//     final currentItems = _getCurrentItems();
//     emit(${featurePascal}Operating(
//       ${featureCamel}s: currentItems,
//       operation: ${featurePascal}Operation.create,
//     ));

//     final result = await $useCaseField(
//       $paramsClass(
//         name: event.name,
//         description: event.description,
//       ),
//     );

//     result.fold(
//       (failure) => emit(_mapFailureToState(failure, currentItems)),
//       ($featureCamel) {
//         final updatedItems = [...currentItems, $featureCamel];
//         emit(${featurePascal}OperationSuccess(
//           ${featureCamel}s: updatedItems,
//           message: '${featurePascal} created successfully',
//         ));
//       },
//     );
//   }
// ''';
//   }

//   static String _handlerUpdateTemplate(UseCaseConfig config) {
//     final eventName = config.eventName;
//     final handlerName = '_on${config.useCasePascalCase}';
//     final useCaseField = '_${config.useCaseCamelCase}UseCase';
//     final paramsClass = config.paramsClassName;
//     final featurePascal = config.featurePascalCase;
//     final featureCamel = config.featureCamelCase;

//     return '''

//   Future<void> $handlerName(
//     $eventName event,
//     Emitter<${featurePascal}State> emit,
//   ) async {
//     final currentItems = _getCurrentItems();
//     emit(${featurePascal}Operating(
//       ${featureCamel}s: currentItems,
//       operation: ${featurePascal}Operation.update,
//     ));

//     final result = await $useCaseField(
//       $paramsClass(
//         id: event.id,
//         name: event.name,
//         description: event.description,
//         isActive: event.isActive,
//       ),
//     );

//     result.fold(
//       (failure) => emit(_mapFailureToState(failure, currentItems)),
//       ($featureCamel) {
//         final updatedItems = currentItems.map((item) {
//           return item.id == $featureCamel.id ? $featureCamel : item;
//         }).toList();
//         emit(${featurePascal}OperationSuccess(
//           ${featureCamel}s: updatedItems,
//           message: '${featurePascal} updated successfully',
//         ));
//       },
//     );
//   }
// ''';
//   }

//   static String _handlerDeleteTemplate(UseCaseConfig config) {
//     final eventName = config.eventName;
//     final handlerName = '_on${config.useCasePascalCase}';
//     final useCaseField = '_${config.useCaseCamelCase}UseCase';
//     final paramsClass = config.paramsClassName;
//     final featurePascal = config.featurePascalCase;
//     final featureCamel = config.featureCamelCase;

//     return '''

//   Future<void> $handlerName(
//     $eventName event,
//     Emitter<${featurePascal}State> emit,
//   ) async {
//     final currentItems = _getCurrentItems();
//     emit(${featurePascal}Operating(
//       ${featureCamel}s: currentItems,
//       operation: ${featurePascal}Operation.delete,
//     ));

//     final result = await $useCaseField(
//       $paramsClass(id: event.id),
//     );

//     result.fold(
//       (failure) => emit(_mapFailureToState(failure, currentItems)),
//       (_) {
//         final updatedItems = currentItems.where((item) => item.id != event.id).toList();
//         emit(${featurePascal}OperationSuccess(
//           ${featureCamel}s: updatedItems,
//           message: '${featurePascal} deleted successfully',
//         ));
//       },
//     );
//   }
// ''';
//   }

//   static String _handlerCustomTemplate(UseCaseConfig config) {
//     final eventName = config.eventName;
//     final handlerName = '_on${config.useCasePascalCase}';
//     final useCaseField = '_${config.useCaseCamelCase}UseCase';
//     final paramsClass = config.paramsClassName;
//     final featurePascal = config.featurePascalCase;
//     final featureCamel = config.featureCamelCase;

//     return '''

//   Future<void> $handlerName(
//     $eventName event,
//     Emitter<${featurePascal}State> emit,
//   ) async {
//     emit(const ${featurePascal}Loading(message: 'Processing...'));

//     final result = await $useCaseField(
//       $paramsClass(id: event.id),
//     );

//     result.fold(
//       (failure) => emit(${featurePascal}Error(message: failure.message)),
//       ($featureCamel) => emit(${featurePascal}Loaded($featureCamel: $featureCamel)),
//     );
//   }
// ''';
//   }

  static String _handlerCreateTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final paramsClass = config.paramsClassName;
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;
    final operationName = config.useCaseCamelCase; // Dynamic operation name

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${featurePascal}Operating(
      ${featureCamel}s: currentItems,
      operation: ${featurePascal}Operation.$operationName,
    ));

    final result = await $useCaseField(
      $paramsClass(
        name: event.name,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      ($featureCamel) {
        final updatedItems = [...currentItems, $featureCamel];
        emit(${featurePascal}OperationSuccess(
          ${featureCamel}s: updatedItems,
          message: '${config.useCasePascalCase} completed successfully',
        ));
      },
    );
  }
''';
  }

  static String _handlerUpdateTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final paramsClass = config.paramsClassName;
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;
    final operationName = config.useCaseCamelCase; // Dynamic operation name

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${featurePascal}Operating(
      ${featureCamel}s: currentItems,
      operation: ${featurePascal}Operation.$operationName,
    ));

    final result = await $useCaseField(
      $paramsClass(
        id: event.id,
        name: event.name,
        description: event.description,
        isActive: event.isActive,
      ),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      ($featureCamel) {
        final updatedItems = currentItems.map((item) {
          return item.id == $featureCamel.id ? $featureCamel : item;
        }).toList();
        emit(${featurePascal}OperationSuccess(
          ${featureCamel}s: updatedItems,
          message: '${config.useCasePascalCase} completed successfully',
        ));
      },
    );
  }
''';
  }

  static String _handlerDeleteTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final paramsClass = config.paramsClassName;
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;
    final operationName = config.useCaseCamelCase; // Dynamic operation name

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${featurePascal}Operating(
      ${featureCamel}s: currentItems,
      operation: ${featurePascal}Operation.$operationName,
    ));

    final result = await $useCaseField(
      $paramsClass(id: event.id),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      (_) {
        final updatedItems = currentItems.where((item) => item.id != event.id).toList();
        emit(${featurePascal}OperationSuccess(
          ${featureCamel}s: updatedItems,
          message: '${config.useCasePascalCase} completed successfully',
        ));
      },
    );
  }
''';
  }

  static String _handlerCustomTemplate(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';
    final useCaseField = '_${config.useCaseCamelCase}UseCase';
    final paramsClass = config.paramsClassName;
    final featurePascal = config.featurePascalCase;
    final featureCamel = config.featureCamelCase;
    final operationName = config.useCaseCamelCase; // Dynamic operation name

    return '''

  Future<void> $handlerName(
    $eventName event,
    Emitter<${featurePascal}State> emit,
  ) async {
    final currentItems = _getCurrentItems();
    emit(${featurePascal}Operating(
      ${featureCamel}s: currentItems,
      operation: ${featurePascal}Operation.$operationName,
    ));

    final result = await $useCaseField(
      $paramsClass(id: event.id),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure, currentItems)),
      ($featureCamel) {
        // TODO: Update items based on your logic
        emit(${featurePascal}OperationSuccess(
          ${featureCamel}s: currentItems,
          message: '${config.useCasePascalCase} completed successfully',
        ));
      },
    );
  }
''';
  }

  /// Returns the event registration line for the constructor
  static String blocEventRegistration(UseCaseConfig config) {
    final eventName = config.eventName;
    final handlerName = '_on${config.useCasePascalCase}';

    return '    on<$eventName>($handlerName);';
  }
  // ==================== REPOSITORY INTERFACE SIGNATURE ====================

  static String repositoryMethodSignature(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;

    // If custom fields are defined, use custom signature
    if (config.hasCustomFields) {
      final paramsSignature = config.generateRepositorySignatureParams();
      return '''
  /// ${config.useCasePascalCase}
  Future<Either<Failure, ${config.returnType}>> $method($paramsSignature);
''';
    }

    // Otherwise, use type-based default signature
    switch (config.type) {
      case UseCaseType.get:
        return '''
  /// ${config.useCasePascalCase}
  Future<Either<Failure, $entity>> $method(String id);
''';

      case UseCaseType.getList:
        return '''
  /// ${config.useCasePascalCase}
  Future<Either<Failure, List<$entity>>> $method();
''';

      case UseCaseType.create:
        return '''
  /// ${config.useCasePascalCase}
  Future<Either<Failure, $entity>> $method({
    required String name,
    String? description,
  });
''';

      case UseCaseType.update:
        return '''
  /// ${config.useCasePascalCase}
  Future<Either<Failure, $entity>> $method({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  });
''';

      case UseCaseType.delete:
        return '''
  /// ${config.useCasePascalCase}
  Future<Either<Failure, Unit>> $method(String id);
''';

      case UseCaseType.custom:
        return '''
  /// ${config.useCasePascalCase}
  /// TODO: Customize parameters as needed
  Future<Either<Failure, $entity>> $method({
    required String id,
  });
''';
    }
  }
  // ==================== REPOSITORY IMPLEMENTATION TEMPLATES ====================

  static String repositoryMethodImpl(UseCaseConfig config) {
    // If custom fields are defined, use custom implementation template
    if (config.hasCustomFields) {
      return _repoCustomFieldsTemplate(config);
    }

    // Otherwise, use type-based default template
    switch (config.type) {
      case UseCaseType.get:
        return _repoGetTemplate(config);
      case UseCaseType.getList:
        return _repoGetListTemplate(config);
      case UseCaseType.create:
        return _repoCreateTemplate(config);
      case UseCaseType.update:
        return _repoUpdateTemplate(config);
      case UseCaseType.delete:
        return _repoDeleteTemplate(config);
      case UseCaseType.custom:
        return _repoCustomTemplate(config);
    }
  }

  /// Repository implementation template that uses custom fields from config
  static String _repoCustomFieldsTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;
    final featurePascal = config.featurePascalCase;
    final paramsSignature = config.generateRepositorySignatureParams();
    
    // Generate parameter forwarding for datasource call
    final paramNames = config.fields.map((f) => '${f.name}: ${f.name},').join('\n        ');

    return '''
  @override
  Future<Either<Failure, $entity>> $method($paramsSignature) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.$method(
        $paramNames
      );
      await _localDataSource.cache$featurePascal(result);
      return Right(result.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.errors,
      ));
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }

  /// Repository GET single entity implementation
  static String _repoGetTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;
    final featurePascal = config.featurePascalCase;

    return '''
  @override
  Future<Either<Failure, $entity>> $method(String id) async {
    try {
      // Try local first
      final localData = await _localDataSource.get$featurePascal(id);
      if (localData != null) {
        // If online, refresh in background
        if (await _networkInfo.isConnected) {
          _refreshFromRemote(id);
        }
        return Right(localData.toEntity());
      }

      // No local data, fetch from remote
      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }

      final remoteData = await _remoteDataSource.$method(id);
      await _localDataSource.cache$featurePascal(remoteData);
      return Right(remoteData.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on StorageException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }

  /// Repository GET LIST implementation
  static String _repoGetListTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;
    final featurePascal = config.featurePascalCase;

    return '''
  @override
  Future<Either<Failure, List<$entity>>> $method() async {
    try {
      if (!await _networkInfo.isConnected) {
        // Return cached data if offline
        final cachedData = await _localDataSource.getAll${featurePascal}s();
        if (cachedData.isNotEmpty) {
          return Right(cachedData.map((m) => m.toEntity()).toList());
        }
        return const Left(NetworkFailure());
      }

      final remoteData = await _remoteDataSource.$method();
      await _localDataSource.cacheAll${featurePascal}s(remoteData);
      return Right(remoteData.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }

  /// Repository CREATE implementation
  static String _repoCreateTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;
    final featurePascal = config.featurePascalCase;

    return '''
  @override
  Future<Either<Failure, $entity>> $method({
    required String name,
    String? description,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.$method(
        name: name,
        description: description,
      );
      await _localDataSource.cache$featurePascal(result);
      return Right(result.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.errors,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }

  /// Repository UPDATE implementation
  static String _repoUpdateTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;
    final featurePascal = config.featurePascalCase;

    return '''
  @override
  Future<Either<Failure, $entity>> $method({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.$method(
        id: id,
        name: name,
        description: description,
        isActive: isActive,
      );
      await _localDataSource.cache$featurePascal(result);
      return Right(result.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.errors,
      ));
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }

  /// Repository DELETE implementation
  static String _repoDeleteTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final featurePascal = config.featurePascalCase;

    return '''
  @override
  Future<Either<Failure, Unit>> $method(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.$method(id);
      await _localDataSource.remove$featurePascal(id);
      return const Right(unit);
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }

  /// Repository CUSTOM implementation (generic template with TODOs)
  static String _repoCustomTemplate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final entity = config.entityName;
    final featurePascal = config.featurePascalCase;

    return '''
  @override
  Future<Either<Failure, $entity>> $method({
    required String id,
    // TODO: Add your parameters here
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.$method(id: id);
      await _localDataSource.cache$featurePascal(result);
      return Right(result.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.errors,
      ));
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
''';
  }
  // ==================== REMOTE DATASOURCE SIGNATURE TEMPLATES ====================

  static String remoteDataSourceMethodSignature(UseCaseConfig config) {
    // If custom fields are defined, use custom signature
    if (config.hasCustomFields) {
      final method = config.repositoryMethodName;
      final model = '${config.featurePascalCase}Model';
      final paramsSignature = config.generateRepositorySignatureParams();
      return '''
  /// ${config.useCasePascalCase}
  Future<$model> $method($paramsSignature);
''';
    }

    // Otherwise, use type-based default signature
    switch (config.type) {
      case UseCaseType.get:
        return _remoteSignatureGet(config);
      case UseCaseType.getList:
        return _remoteSignatureGetList(config);
      case UseCaseType.create:
        return _remoteSignatureCreate(config);
      case UseCaseType.update:
        return _remoteSignatureUpdate(config);
      case UseCaseType.delete:
        return _remoteSignatureDelete(config);
      case UseCaseType.custom:
        return _remoteSignatureCustom(config);
    }
  }

  static String _remoteSignatureGet(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';

    return '''
  /// ${config.useCasePascalCase}
  Future<$model> $method(String id);
''';
  }

  static String _remoteSignatureGetList(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';

    return '''
  /// ${config.useCasePascalCase}
  Future<List<$model>> $method();
''';
  }

  static String _remoteSignatureCreate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';

    return '''
  /// ${config.useCasePascalCase}
  Future<$model> $method({
    required String name,
    String? description,
  });
''';
  }

  static String _remoteSignatureUpdate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';

    return '''
  /// ${config.useCasePascalCase}
  Future<$model> $method({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  });
''';
  }

  static String _remoteSignatureDelete(UseCaseConfig config) {
    final method = config.repositoryMethodName;

    return '''
  /// ${config.useCasePascalCase}
  Future<void> $method(String id);
''';
  }

  static String _remoteSignatureCustom(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';

    return '''
  /// ${config.useCasePascalCase}
  /// TODO: Customize parameters as needed
  Future<$model> $method({
    required String id,
  });
''';
  }

  // ==================== REMOTE DATASOURCE IMPLEMENTATION TEMPLATES ====================

  static String remoteDataSourceMethodImpl(UseCaseConfig config) {
    // If custom fields are defined, use custom implementation template
    if (config.hasCustomFields) {
      return _remoteImplCustomFields(config);
    }

    // Otherwise, use type-based default template
    switch (config.type) {
      case UseCaseType.get:
        return _remoteImplGet(config);
      case UseCaseType.getList:
        return _remoteImplGetList(config);
      case UseCaseType.create:
        return _remoteImplCreate(config);
      case UseCaseType.update:
        return _remoteImplUpdate(config);
      case UseCaseType.delete:
        return _remoteImplDelete(config);
      case UseCaseType.custom:
        return _remoteImplCustom(config);
    }
  }

  /// Remote datasource implementation template that uses custom fields
  static String _remoteImplCustomFields(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;
    final paramsSignature = config.generateRepositorySignatureParams();
    final apiBodyParams = config.generateApiBodyParams();

    return '''
  @override
  Future<$model> $method($paramsSignature) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.${featureCamel}s,
        data: {
$apiBodyParams
        },
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return $model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to $method $featureSnake: \$e');
    }
  }
''';
  }

  /// Remote GET single entity implementation
  static String _remoteImplGet(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;

    return '''
  @override
  Future<$model> $method(String id) async {
    try {
      final response = await _dioClient.get(
        '\${ApiEndpoints.get${featureCamel}s}/\$id',
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return $model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get $featureSnake: \$e');
    }
  }
''';
  }

  /// Remote GET LIST implementation
  static String _remoteImplGetList(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;

    return '''
  @override
  Future<List<$model>> $method() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.getall${featureCamel}s);

      final data = response.data as Map<String, dynamic>;
      final listData = data['data'] as List? ?? [];

      return listData
          .map((item) => $model.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get ${featureSnake}s: \$e');
    }
  }
''';
  }

  /// Remote CREATE implementation
  static String _remoteImplCreate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;

    return '''
  @override
  Future<$model> $method({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.create${featureCamel}s,
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return $model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to create $featureSnake: \$e');
    }
  }
''';
  }

  /// Remote UPDATE implementation
  static String _remoteImplUpdate(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;

    return '''
  @override
  Future<$model> $method({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _dioClient.put(
        '\${ApiEndpoints.update${featureCamel}s}/\$id',
        data: updateData,
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return $model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to update $featureSnake: \$e');
    }
  }
''';
  }

  /// Remote DELETE implementation
  static String _remoteImplDelete(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;

    return '''
  @override
  Future<void> $method(String id) async {
    try {
      await _dioClient.delete('\${ApiEndpoints.delete${featureCamel}s}/\$id');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to delete $featureSnake: \$e');
    }
  }
''';
  }

  /// Remote CUSTOM implementation
  static String _remoteImplCustom(UseCaseConfig config) {
    final method = config.repositoryMethodName;
    final model = '${config.featurePascalCase}Model';
    final featureCamel = config.featureCamelCase;
    final featureSnake = config.featureSnakeCase;

    return '''
  @override
  Future<$model> $method({
    required String id,
    // TODO: Add your parameters here
  }) async {
    try {
      final response = await _dioClient.post(
        '\${ApiEndpoints.${featureCamel}s}/\$id',
        data: {
          // TODO: Map your parameters here
        },
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return $model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to $method $featureSnake: \$e');
    }
  }
''';
  }
  // ==================== HELPERS ====================

  static String _getParamsSignature(UseCaseConfig config) {
    if (config.type == UseCaseType.getList) return '';
    if (config.type == UseCaseType.delete || config.type == UseCaseType.get)
      return 'String id';

    // For Create/Update/Custom, we generate named parameters
    return '{required String id, /* TODO: Add other params */}';
  }

  static String _getArgsUsage(UseCaseConfig config) {
    if (config.type == UseCaseType.getList) return '';
    if (config.type == UseCaseType.delete || config.type == UseCaseType.get)
      return 'id';
    return 'id: id';
  }
}
