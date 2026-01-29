/// UseCase Configuration
///
/// Configuration model for generating usecases.
library;

import 'field_definition.dart';
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

  /// Custom fields for the Params class
  final List<FieldDefinition> fields;

  UseCaseConfig({
    required this.featureName,
    required this.useCaseName,
    required this.type,
    required this.projectName,
    required this.projectPath,
    this.force = false,
    this.dryRun = false,
    this.withEvent = false,
    this.fields = const [],
  });

  /// Whether custom fields are defined
  bool get hasCustomFields => fields.isNotEmpty;

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

  // ==================== FIELD HELPERS ====================

  /// Generates field declarations for Params/Event class
  /// Example: "final String productName;\n  final String? description;"
  String generateFieldDeclarations() {
    if (!hasCustomFields) return '';
    return fields.map((f) => '  final ${f.dartType} ${f.name};').join('\n');
  }

  /// Generates constructor parameters for Params/Event class
  /// Example: "required this.productName,\n    this.description,"
  String generateConstructorParams() {
    if (!hasCustomFields) return '';
    return fields.map((f) {
      if (f.isRequired) {
        return '    required this.${f.name},';
      } else {
        return '    this.${f.name},';
      }
    }).join('\n');
  }

  /// Generates Equatable props list items
  /// Example: "productName, description, price"
  String generatePropsItems() {
    if (!hasCustomFields) return '';
    return fields.map((f) => f.name).join(', ');
  }

  /// Generates validation code for required String fields
  String generateValidationCode() {
    if (!hasCustomFields) return '';
    final validations = <String>[];
    
    for (final field in fields) {
      if (field.isRequired && field.type == 'String') {
        validations.add('''
    if (params.${field.name}.trim().isEmpty) {
      return const Left(ValidationFailure(
        message: '${_toTitleCase(field.name)} cannot be empty',
        fieldErrors: {'${field.name}': ['${_toTitleCase(field.name)} is required']},
      ));
    }
''');
      }
    }
    
    return validations.join('\n');
  }

  /// Generates repository method signature parameters
  /// Example: "{\n    required String productName,\n    String? description,\n  }"
  String generateRepositorySignatureParams() {
    if (!hasCustomFields) return '';
    final params = fields.map((f) {
      if (f.isRequired) {
        return '    required ${f.dartType} ${f.name},';
      } else {
        return '    ${f.dartType} ${f.name},';
      }
    }).join('\n');
    return '{\n$params\n  }';
  }

  /// Generates repository call arguments
  /// Example: "productName: params.productName,\n      description: params.description,"
  String generateRepositoryCallArgs() {
    if (!hasCustomFields) return '';
    return fields.map((f) {
      if (f.type == 'String' && f.isRequired) {
        return '      ${f.name}: params.${f.name}.trim(),';
      } else if (f.type == 'String' && !f.isRequired) {
        return '      ${f.name}: params.${f.name}?.trim(),';
      } else {
        return '      ${f.name}: params.${f.name},';
      }
    }).join('\n');
  }

  /// Generates data source method parameters (for signature)
  String generateDataSourceParams() {
    if (!hasCustomFields) return '';
    return fields.map((f) {
      if (f.isRequired) {
        return '    required ${f.dartType} ${f.name},';
      } else {
        return '    ${f.dartType} ${f.name},';
      }
    }).join('\n');
  }

  /// Generates API request body mappings
  /// Example: "'product_name': productName,\n          if (description != null) 'description': description,"
  String generateApiBodyParams() {
    if (!hasCustomFields) return '';
    return fields.map((f) {
      final jsonKey = _toSnakeCase(f.name);
      if (f.isNullable) {
        return "          if (${f.name} != null) '$jsonKey': ${f.name},";
      } else {
        return "          '$jsonKey': ${f.name},";
      }
    }).join('\n');
  }

  /// Generates event fields passed to params
  /// Example: "name: event.name,\n        description: event.description,"
  String generateEventToParamsArgs() {
    if (!hasCustomFields) return '';
    return fields.map((f) => '        ${f.name}: event.${f.name},').join('\n');
  }

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  static String _toTitleCase(String input) {
    if (input.isEmpty) return input;
    // Convert camelCase to Title Case
    final spaced = input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  String toString() {
    return 'UseCaseConfig(feature: $featureName, usecase: $useCaseName, type: ${type.value}, fields: ${fields.length})';
  }
}