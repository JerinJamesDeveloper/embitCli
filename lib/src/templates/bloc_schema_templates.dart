/// BLoC Schema Templates
///
/// Generates BLoC files from schema with all usecases.
library;

import '../models/schema/feature_schema.dart';
import '../models/usecase_config.dart';
import 'usecase_type_templates.dart';

/// BLoC templates for schema
class BlocSchemaTemplates {
  BlocSchemaTemplates._();

  /// Generate BLoC file
  static String bloc(
    FeatureSchema schema,
    List<UseCaseConfig> usecases,
    String projectName,
  ) {
    // Generate usecase imports
    final usecaseImports = usecases
        .map((uc) =>
            "import '../../domain/usecases/${uc.useCaseSnakeCase}_usecase.dart';")
        .join('\n');

    // Generate usecase fields
    final usecaseFields = usecases
        .map((uc) =>
            '  final ${uc.useCaseClassName} _${uc.useCaseCamelCase}UseCase;')
        .join('\n');

    // Generate constructor params
    final constructorParams = usecases
        .map((uc) =>
            '    required ${uc.useCaseClassName} ${uc.useCaseCamelCase}UseCase,')
        .join('\n');

    // Generate initializers
    final initializers = usecases
        .map((uc) =>
            '        _${uc.useCaseCamelCase}UseCase = ${uc.useCaseCamelCase}UseCase')
        .join(',\n');

    // Generate event registrations
    final eventRegistrations = usecases
        .where((uc) => uc.withEvent)
        .map((uc) => '    on<${uc.eventName}>(_on${uc.useCasePascalCase});')
        .join('\n');

    // Generate event handlers
    final eventHandlers = usecases
        .where((uc) => uc.withEvent)
        .map((uc) => UseCaseTypeTemplates.blocEventHandler(uc))
        .join('\n');

    return '''
/// ${schema.pascalCase} BLoC
///
/// Business Logic Component for ${schema.pascalCase} feature.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$projectName/core/errors/failures.dart';
$usecaseImports
import '../../domain/entities/${schema.snakeCase}_entity.dart';

part '${schema.snakeCase}_event.dart';
part '${schema.snakeCase}_state.dart';

/// BLoC for ${schema.pascalCase} feature
class ${schema.pascalCase}Bloc extends Bloc<${schema.pascalCase}Event, ${schema.pascalCase}State> {
$usecaseFields

  ${schema.pascalCase}Bloc({
$constructorParams
  }) : $initializers,
        super(const ${schema.pascalCase}Initial()) {
$eventRegistrations
  }

$eventHandlers
}
''';
  }

  /// Generate events file
  static String events(
    FeatureSchema schema,
    List<UseCaseConfig> usecases,
    String projectName,
  ) {
    // Generate event classes
    final eventClasses = usecases
        .where((uc) => uc.withEvent)
        .map(UseCaseTypeTemplates.blocEvent)
        .join('\n');

    return '''
part of '${schema.snakeCase}_bloc.dart';

/// Base event for ${schema.pascalCase}
sealed class ${schema.pascalCase}Event {
  const ${schema.pascalCase}Event();
}

/// Event to load initial data
class ${schema.pascalCase}LoadRequested extends ${schema.pascalCase}Event {
  const ${schema.pascalCase}LoadRequested();
}

/// Event to refresh data
class ${schema.pascalCase}RefreshRequested extends ${schema.pascalCase}Event {
  const ${schema.pascalCase}RefreshRequested();
}

/// Event to clear error
class ${schema.pascalCase}ErrorCleared extends ${schema.pascalCase}Event {
  const ${schema.pascalCase}ErrorCleared();
}
$eventClasses
''';
  }

  /// Generate states file
  static String states(
    FeatureSchema schema,
    List<UseCaseConfig> usecases,
    String projectName,
  ) {
    // Generate operation enum values
    final operationValues = usecases
        .where((uc) =>
            uc.type != UseCaseType.get && uc.type != UseCaseType.getList)
        .map((uc) => '  ${uc.useCaseCamelCase},')
        .join('\n');

    return '''
part of '${schema.snakeCase}_bloc.dart';

/// Operations for ${schema.pascalCase}
enum ${schema.pascalCase}Operation {
  load,
  refresh,
$operationValues
}

/// Base state for ${schema.pascalCase}
sealed class ${schema.pascalCase}State {
  final ${schema.pascalCase}Entity? ${schema.camelCase};
  final List<${schema.pascalCase}Entity> ${schema.camelCase}s;
  
  const ${schema.pascalCase}State({
    this.${schema.camelCase},
    this.${schema.camelCase}s = const [],
  });
}

/// Initial state
class ${schema.pascalCase}Initial extends ${schema.pascalCase}State {
  const ${schema.pascalCase}Initial() : super();
}

/// Loading state
class ${schema.pascalCase}Loading extends ${schema.pascalCase}State {
  final ${schema.pascalCase}Operation operation;
  final String? message;
  
  const ${schema.pascalCase}Loading({
    required this.operation,
    this.message,
    super.${schema.camelCase},
    super.${schema.camelCase}s,
  });
}

/// Single item loaded
class ${schema.pascalCase}Loaded extends ${schema.pascalCase}State {
  const ${schema.pascalCase}Loaded({required ${schema.pascalCase}Entity ${schema.camelCase}})
      : super(${schema.camelCase}: ${schema.camelCase});
}

/// List loaded
class ${schema.pascalCase}ListLoaded extends ${schema.pascalCase}State {
  final bool hasMore;
  final int? totalCount;
  
  const ${schema.pascalCase}ListLoaded({
    required List<${schema.pascalCase}Entity> ${schema.camelCase}s,
    this.hasMore = false,
    this.totalCount,
  }) : super(${schema.camelCase}s: ${schema.camelCase}s);
}

/// Operation success
class ${schema.pascalCase}OperationSuccess extends ${schema.pascalCase}State {
  final String message;
  final ${schema.pascalCase}Operation operation;
  
  const ${schema.pascalCase}OperationSuccess({
    required this.message,
    required this.operation,
    super.${schema.camelCase},
    super.${schema.camelCase}s,
  });
}

/// Error state
class ${schema.pascalCase}Error extends ${schema.pascalCase}State {
  final String message;
  final ${schema.pascalCase}Operation? operation;
  final Map<String, List<String>>? fieldErrors;
  
  const ${schema.pascalCase}Error({
    required this.message,
    this.operation,
    this.fieldErrors,
    super.${schema.camelCase},
    super.${schema.camelCase}s,
  });
  
  String? getFieldError(String field) => fieldErrors?[field]?.first;
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;
}
''';
  }
}
