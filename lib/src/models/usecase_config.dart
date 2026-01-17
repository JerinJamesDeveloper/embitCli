/// UseCase Configuration
///
/// Configuration model for generating usecases.
library;

import '../utils/string_utils.dart';

/// Types of usecases
enum UseCaseType {
  get('get', 'Get single entity'),
  getList('get-list', 'Get list of entities'),
  create('create', 'Create entity'),
  update('update', 'Update entity'),
  delete('delete', 'Delete entity'),
  custom('custom', 'Custom usecase');

  final String value;
  final String description;

  const UseCaseType(this.value, this.description);

  static UseCaseType fromString(String value) {
    return UseCaseType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => UseCaseType.custom,
    );
  }
}

/// Configuration for usecase generation
class UseCaseConfig {
  /// Feature name (e.g., 'products')
  final String featureName;

  /// UseCase name (e.g., 'archive_product')
  final String useCaseName;

  /// Type of usecase
  final UseCaseType type;

  /// Project name
  final String projectName;

  /// Project path
  final String projectPath;

  /// Force overwrite
  final bool force;

  /// Dry run mode
  final bool dryRun;

  /// Generate BLoC event automatically
  final bool withEvent;

  UseCaseConfig({
    required this.featureName,
    required this.useCaseName,
    required this.type,
    required this.projectName,
    required this.projectPath,
    this.force = false,
    this.dryRun = false,
    this.withEvent = false,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Feature in snake_case (e.g., 'user_profile')
  String get featureSnakeCase => StringUtils.toSnakeCase(featureName);

  /// Feature in PascalCase (e.g., 'UserProfile')
  String get featurePascalCase => StringUtils.toPascalCase(featureName);

  /// Feature in camelCase (e.g., 'userProfile')
  String get featureCamelCase => StringUtils.toCamelCase(featureName);

  /// UseCase in snake_case (e.g., 'archive_product')
  String get useCaseSnakeCase => StringUtils.toSnakeCase(useCaseName);

  /// UseCase in PascalCase (e.g., 'ArchiveProduct')
  String get useCasePascalCase => StringUtils.toPascalCase(useCaseName);

  /// UseCase in camelCase (e.g., 'archiveProduct')
  String get useCaseCamelCase => StringUtils.toCamelCase(useCaseName);

  /// UseCase class name (e.g., 'ArchiveProductUseCase')
  String get useCaseClassName => '${useCasePascalCase}UseCase';

  /// UseCase params class name (e.g., 'ArchiveProductParams')
  String get paramsClassName => '${useCasePascalCase}Params';

  /// Entity name (e.g., 'ProductEntity')
  String get entityName => '${featurePascalCase}Entity';

  /// Repository name (e.g., 'ProductRepository')
  String get repositoryName => '${featurePascalCase}Repository';

  /// BLoC name (e.g., 'ProductBloc')
  String get blocName => '${featurePascalCase}Bloc';

  /// Event name (e.g., 'ProductArchiveRequested')
  String get eventName => '$featurePascalCase${useCasePascalCase}Requested';

  // ==================== PATHS ====================

  /// Feature base path
  String get featureBasePath => 'lib/features/$featureSnakeCase';

  /// Domain layer path
  String get domainPath => '$featureBasePath/domain';

  /// Usecases directory path
  String get usecasesPath => '$domainPath/usecases';

  /// UseCase file path
  String get useCaseFilePath => '$usecasesPath/${useCaseSnakeCase}_usecase.dart';

  /// Entity file path
  String get entityFilePath => '$domainPath/entities/${featureSnakeCase}_entity.dart';

  /// Repository file path
  String get repositoryFilePath => '$domainPath/repositories/${featureSnakeCase}_repository.dart';

  /// BLoC directory path
  String get blocPath => '$featureBasePath/presentation/bloc';

  /// BLoC file path
  String get blocFilePath => '$blocPath/${featureSnakeCase}_bloc.dart';

  /// Event file path
  String get eventFilePath => '$blocPath/${featureSnakeCase}_event.dart';

  /// Method name for repository (e.g., 'archiveProduct')
  String get repositoryMethodName => useCaseCamelCase;

  /// Returns entity or list based on type
  String get returnType {
    if (type == UseCaseType.getList) {
      return 'List<$entityName>';
    } else if (type == UseCaseType.delete) {
      return 'Unit';
    } else {
      return entityName;
    }
  }

  /// Whether this usecase needs params
  bool get needsParams {
    return type != UseCaseType.getList; // getList usually has no params
  }

  @override
  String toString() {
    return 'UseCaseConfig(feature: $featureName, usecase: $useCaseName, type: ${type.value})';
  }
}