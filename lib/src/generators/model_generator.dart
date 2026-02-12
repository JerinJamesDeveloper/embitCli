import 'dart:io';
import '../models/feature_config.dart';
import '../models/field_definition.dart';
import '../templates/datasource_templates.dart';

class ModelGenerator {
  Future<void> generate(ModelGeneratorConfig config,
      {bool verbose = false}) async {
    final featurePath = 'lib/features/${_toSnakeCase(config.featureName)}';
    final entityPath = '$featurePath/domain/entities';
    final modelPath = '$featurePath/data/models';

    // Ensure directories exist
    await Directory(entityPath).create(recursive: true);
    await Directory(modelPath).create(recursive: true);

    await _createEntity(config, entityPath, verbose: verbose);
    await _createModel(config, modelPath, verbose: verbose);

    if (config.withSource) {
      await _createLocalDataSource(config, featurePath, verbose: verbose);
    }

    if (config.withState) {
      await _updateBlocState(
          config, 'lib/features/${_toSnakeCase(config.featureName)}',
          verbose: verbose);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ══════════════════════════════════════════════════════════════════════════

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '')
        .toLowerCase();
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return '';
    if (input.contains('_')) {
      return input.split('_').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join('');
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  String _generateFieldComment(FieldDefinition field) {
    // Convert camelCase to readable words
    final words = field.name
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => ' ${match.group(0)!.toLowerCase()}',
        )
        .trim();
    final comment = words[0].toUpperCase() + words.substring(1);
    return field.isNullable ? '$comment (optional)' : comment;
  }

  String _formatDefaultValue(FieldDefinition field) {
    if (field.defaultValue == null) return '';

    switch (field.type) {
      case 'String':
        return "'${field.defaultValue}'";
      case 'bool':
      case 'int':
      case 'double':
        return field.defaultValue!;
      default:
        return field.defaultValue!;
    }
  }

  String _getEmptyValue(FieldDefinition field) {
    switch (field.type) {
      case 'String':
        return "''";
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return field.defaultValue ?? 'false';
      case 'DateTime':
        return 'DateTime.now()';
      case 'List':
        return 'const []';
      case 'Map':
        return 'const {}';
      default:
        if (field.isCustom) {
          if (field.type.startsWith('List<')) {
            return 'const []';
          }
          return '${field.baseEntityName}.empty()';
        }
        return "''";
    }
  }

  String _getIsEmptyCheck(FieldDefinition field) {
    switch (field.type) {
      case 'String':
        return '${field.name}.isEmpty';
      case 'int':
        return '${field.name} == 0';
      case 'double':
        return '${field.name} == 0.0';
      case 'List':
        return '${field.name}.isEmpty';
      default:
        return '${field.name}.isEmpty';
    }
  }

  String _getIsNotEmptyCheck(FieldDefinition field) {
    switch (field.type) {
      case 'String':
        return '${field.name}.isNotEmpty';
      case 'int':
        return '${field.name} != 0';
      case 'double':
        return '${field.name} != 0.0';
      case 'List':
        return '${field.name}.isNotEmpty';
      default:
        return '${field.name}.isNotEmpty';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENTITY GENERATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _createEntity(
    ModelGeneratorConfig config,
    String path, {
    bool verbose = false,
  }) async {
    final className = '${_toPascalCase(config.modelName)}Entity';
    final fileName = '${_toSnakeCase(config.modelName)}_entity';

    final content = _generateEntityContent(config, className);

    await File('$path/$fileName.dart').writeAsString(content);
    print('✔ Entity created: $path/$fileName.dart');
  }

  String _generateEntityContent(ModelGeneratorConfig config, String className) {
    final buffer = StringBuffer();
    final modelNameReadable = _toPascalCase(config.modelName);

    // ─────────────────────────────────────────────────────────────────────────
    // Header & Imports
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('/// $modelNameReadable Entity');
    buffer.writeln('///');
    buffer.writeln(
        '/// Core business entity representing a ${config.modelName.toLowerCase()} in the system.');
    buffer.writeln('/// Pure Dart class with no external dependencies.');
    buffer.writeln('library;');
    buffer.writeln();
    buffer.writeln("import 'package:equatable/equatable.dart';");
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // Class Declaration
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln(
        '/// $modelNameReadable entity representing the core ${config.modelName.toLowerCase()} data');
    buffer.writeln('class $className extends Equatable {');

    // ─────────────────────────────────────────────────────────────────────────
    // Fields
    // ─────────────────────────────────────────────────────────────────────────
    for (final field in config.fields) {
      buffer.writeln('  /// ${_generateFieldComment(field)}');
      buffer.writeln('  final ${field.dartType} ${field.name};');
      buffer.writeln();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  const $className({');
    for (final field in config.fields) {
      if (field.isRequired) {
        buffer.writeln('    required this.${field.name},');
      } else if (field.hasDefault) {
        buffer
            .writeln('    this.${field.name} = ${_formatDefaultValue(field)},');
      } else {
        buffer.writeln('    this.${field.name},');
      }
    }
    buffer.writeln('  });');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // copyWith Method
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Creates a copy with updated fields');
    buffer.writeln('  $className copyWith({');
    for (final field in config.fields) {
      buffer.writeln('    ${field.dartType}? ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $className(');
    for (final field in config.fields) {
      buffer
          .writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // Empty Factory
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Creates an empty $modelNameReadable');
    buffer.writeln('  factory $className.empty() {');
    buffer.writeln('    return $className(');
    for (final field in config.fields) {
      if (field.isRequired) {
        buffer.writeln('      ${field.name}: ${_getEmptyValue(field)},');
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // isEmpty / isNotEmpty
    // ─────────────────────────────────────────────────────────────────────────
    final idField = config.fields.firstWhere(
      (f) => f.name == 'id',
      orElse: () => config.fields.first,
    );
    buffer.writeln('  /// Checks if this is an empty entity');
    buffer.writeln('  bool get isEmpty => ${_getIsEmptyCheck(idField)};');
    buffer.writeln();
    buffer.writeln('  /// Checks if this is not empty');
    buffer.writeln('  bool get isNotEmpty => ${_getIsNotEmptyCheck(idField)};');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // Equatable Props
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  @override');
    buffer.writeln('  List<Object?> get props => [');
    for (final field in config.fields) {
      buffer.writeln('        ${field.name},');
    }
    buffer.writeln('      ];');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // toString
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  @override');
    buffer.writeln('  String toString() {');
    final toStringFields =
        config.fields.take(3).map((f) => '${f.name}: \$${f.name}').join(', ');
    buffer.writeln("    return '$className($toStringFields)';");
    buffer.writeln('  }');

    buffer.writeln('}');

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODEL GENERATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _createModel(
    ModelGeneratorConfig config,
    String path, {
    bool verbose = false,
  }) async {
    final entityName = '${_toPascalCase(config.modelName)}Entity';
    final modelName = '${_toPascalCase(config.modelName)}Model';
    final entityFileName = '${_toSnakeCase(config.modelName)}_entity';
    final modelFileName = '${_toSnakeCase(config.modelName)}_model';

    final content =
        _generateModelContent(config, modelName, entityName, entityFileName);

    await File('$path/$modelFileName.dart').writeAsString(content);
    print('✔ Model created: $path/$modelFileName.dart');
  }

  Future<void> _createLocalDataSource(
    ModelGeneratorConfig config,
    String featurePath, {
    bool verbose = false,
  }) async {
    final dataSourcePath = '$featurePath/data/datasources';
    await Directory(dataSourcePath).create(recursive: true);

    final fileName = '${_toSnakeCase(config.modelName)}_local_datasource';
    final filePath = '$dataSourcePath/$fileName.dart';

    // Override the name to be the model name so the template uses the correct name
    // The template uses config.name for the entity/model prefix
    final modelConfig = FeatureConfig(
      name: _toSnakeCase(config.modelName),
      projectName: config.projectName,
      projectPath: config.projectPath,
    );

    final content = DataSourceTemplates.localDataSource(modelConfig);

    await File(filePath).writeAsString(content);
    print('✔ Local Data Source created: $filePath');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLOC STATE UPDATE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _updateBlocState(
    ModelGeneratorConfig config,
    String featurePath, {
    bool verbose = false,
  }) async {
    final blocStart = '$featurePath/presentation/bloc';
    final stateFile = File('$blocStart/${config.featureSnakeCase}_state.dart');
    final blocFile = File('$blocStart/${config.featureSnakeCase}_bloc.dart');

    if (!stateFile.existsSync()) {
      if (verbose)
        print('⚠ Warning: Bloc state file not found at ${stateFile.path}');
      return;
    }

    // 1. Update State File
    var stateContent = await stateFile.readAsString();
    final newStates = _generateNewStates(config);

    // Check if states already exist (simple check)
    if (stateContent.contains('class ${config.modelPascalCase}Loaded')) {
      if (verbose) print('ℹ States for ${config.modelName} already exist.');
    } else {
      stateContent += '\n$newStates';
      await stateFile.writeAsString(stateContent);
      print('✔ Updated states in: ${stateFile.path}');
    }

    // 2. Update Bloc File (Imports)
    if (blocFile.existsSync()) {
      var blocContent = await blocFile.readAsString();
      final entityImport =
          "import '../../domain/entities/${config.modelSnakeCase}_entity.dart';";

      if (!blocContent.contains(entityImport)) {
        // Find last import
        final lines = blocContent.split('\n');
        final lastImportIndex =
            lines.lastIndexWhere((line) => line.startsWith('import '));

        if (lastImportIndex != -1) {
          lines.insert(lastImportIndex + 1, entityImport);
          await blocFile.writeAsString(lines.join('\n'));
          print('✔ Added import to: ${blocFile.path}');
        }
      }
    }
  }

  String _generateNewStates(ModelGeneratorConfig config) {
    final model = config.modelPascalCase;
    final entity = '${model}Entity';
    final feature = config.featurePascalCase;
    final modelCamel = _toCamelCase(config.modelName);

    return '''
// -------------------- $model States --------------------

class ${model}Initial extends ${feature}State {}

class ${model}Loading extends ${feature}State {}

class ${model}Loaded extends ${feature}State {
  final $entity $modelCamel;
  const ${model}Loaded(this.$modelCamel);
}

class ${model}ListLoaded extends ${feature}State {
  final List<$entity> ${modelCamel}s;
  const ${model}ListLoaded(this.${modelCamel}s);
}

class ${model}OperationSuccess extends ${feature}State {
  final String message;
  final $entity? $modelCamel;
  const ${model}OperationSuccess(this.message, {this.$modelCamel});
}

class ${model}Error extends ${feature}State {
  final String message;
  const ${model}Error(this.message);
}
''';
  }

  String _toCamelCase(String input) {
    if (input.isEmpty) return '';
    if (input.contains('_')) {
      final parts = input.split('_');
      return parts.first.toLowerCase() +
          parts
              .skip(1)
              .map((w) => w.isNotEmpty
                  ? w[0].toUpperCase() + w.substring(1).toLowerCase()
                  : '')
              .join();
    }
    return input[0].toLowerCase() + input.substring(1);
  }

  String _generateModelContent(
    ModelGeneratorConfig config,
    String modelName,
    String entityName,
    String entityFileName,
  ) {
    final buffer = StringBuffer();
    final hasDateTime = config.fields.any((f) => f.type == 'DateTime');
    final modelNameReadable = _toPascalCase(config.modelName);

    // ─────────────────────────────────────────────────────────────────────────
    // Header & Imports
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('/// $modelNameReadable Model');
    buffer.writeln('///');
    buffer.writeln('/// Data model that extends $entityName.');
    buffer.writeln(
        '/// Handles JSON serialization/deserialization for API communication.');
    buffer.writeln('library;');
    buffer.writeln();
    buffer.writeln("import '../../domain/entities/$entityFileName.dart';");
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // Class Declaration
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('/// $modelNameReadable data model with JSON serialization');
    buffer.writeln('class $modelName extends $entityName {');

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  const $modelName({');
    for (final field in config.fields) {
      if (field.isRequired) {
        buffer.writeln('    required super.${field.name},');
      } else if (field.hasDefault) {
        buffer.writeln(
            '    super.${field.name} = ${_formatDefaultValue(field)},');
      } else {
        buffer.writeln('    super.${field.name},');
      }
    }
    buffer.writeln('  });');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // fromJson Factory
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Creates a $modelName from JSON map');
    buffer
        .writeln('  factory $modelName.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $modelName(');
    for (final field in config.fields) {
      buffer
          .writeln('      ${field.name}: ${_generateFromJsonParsing(field)},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // toJson Method
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Converts the model to a JSON map');
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    for (final field in config.fields) {
      buffer
          .writeln("      '${field.jsonKey}': ${_generateToJsonValue(field)},");
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // fromEntity Factory
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Creates a $modelName from a $entityName');
    buffer.writeln('  factory $modelName.fromEntity($entityName entity) {');
    buffer.writeln('    return $modelName(');
    for (final field in config.fields) {
      buffer.writeln('      ${field.name}: entity.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // toEntity Method
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Converts this model to an entity');
    buffer.writeln('  $entityName toEntity() {');
    buffer.writeln('    return $entityName(');
    for (final field in config.fields) {
      buffer.writeln('      ${field.name}: ${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // Empty Factory
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Creates an empty $modelName');
    buffer.writeln('  factory $modelName.empty() {');
    buffer.writeln('    return $modelName(');
    for (final field in config.fields) {
      if (field.isRequired) {
        buffer.writeln('      ${field.name}: ${_getEmptyValue(field)},');
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // copyWith Override
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('  /// Creates a copy with updated fields');
    buffer.writeln('  @override');
    buffer.writeln('  $modelName copyWith({');
    for (final field in config.fields) {
      buffer.writeln('    ${field.dartType}? ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $modelName(');
    for (final field in config.fields) {
      buffer
          .writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    // ─────────────────────────────────────────────────────────────────────────
    // DateTime Helper (if needed)
    // ─────────────────────────────────────────────────────────────────────────
    if (hasDateTime) {
      buffer.writeln();
      buffer.writeln('  /// Helper to parse DateTime from various formats');
      buffer.writeln('  static DateTime? _parseDateTime(dynamic value) {');
      buffer.writeln('    if (value == null) return null;');
      buffer.writeln('    if (value is DateTime) return value;');
      buffer
          .writeln('    if (value is String) return DateTime.tryParse(value);');
      buffer.writeln(
          '    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);');
      buffer.writeln('    return null;');
      buffer.writeln('  }');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JSON PARSING HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _generateFromJsonParsing(FieldDefinition field) {
    final snakeKey = field.jsonKey;
    final camelKey = field.name;

    switch (field.type) {
      case 'String':
        if (field.isNullable) {
          return "json['$snakeKey'] as String?";
        }
        return "json['$snakeKey']?.toString() ?? ''";

      case 'int':
        if (field.isNullable) {
          return "json['$snakeKey'] as int?";
        }
        return "json['$snakeKey'] as int? ?? 0";

      case 'double':
        if (field.isNullable) {
          return "double.tryParse(json['$snakeKey']?.toString() ?? '')";
        }
        return "double.tryParse(json['$snakeKey']?.toString() ?? '') ?? 0.0";

      case 'bool':
        final defaultVal = field.defaultValue ?? 'false';
        if (field.isNullable) {
          return "json['$snakeKey'] as bool? ?? json['$camelKey'] as bool?";
        }
        return '''json['$snakeKey'] as bool? ??
                json['$camelKey'] as bool? ??
                $defaultVal''';

      case 'DateTime':
        if (field.isNullable) {
          return "_parseDateTime(json['$snakeKey'] ?? json['$camelKey'])";
        }
        return "_parseDateTime(json['$snakeKey'] ?? json['$camelKey']) ?? DateTime.now()";

      default:
        if (field.isCustom) {
          final modelName = field.baseModelName;

          // Check for List of custom objects
          if (field.type.startsWith('List<')) {
            if (field.isNullable) {
              return "(json['$snakeKey'] as List<dynamic>?)?.map((e) => $modelName.fromJson(e as Map<String, dynamic>)).toList()";
            }
            return "(json['$snakeKey'] as List<dynamic>?)?.map((e) => $modelName.fromJson(e as Map<String, dynamic>)).toList() ?? []";
          }

          // Single custom object
          if (field.isNullable) {
            return "json['$snakeKey'] != null ? $modelName.fromJson(json['$snakeKey'] as Map<String, dynamic>) : null";
          }
          // Fallback to empty() from Entity or Model? Model.empty() works too.
          // But consistency: explicit .empty()
          return "json['$snakeKey'] != null ? $modelName.fromJson(json['$snakeKey'] as Map<String, dynamic>) : $modelName.empty()";
        }
        return "json['$snakeKey']";
    }
  }

  String _generateToJsonValue(FieldDefinition field) {
    switch (field.type) {
      case 'DateTime':
        if (field.isNullable) {
          return '${field.name}?.toIso8601String()';
        }
        return '${field.name}.toIso8601String()';
      default:
        if (field.isCustom) {
          final modelName = field.baseModelName;

          if (field.type.startsWith('List<')) {
            if (field.isNullable) {
              return '${field.name}?.map((e) => $modelName.fromEntity(e).toJson()).toList()';
            }
            return '${field.name}.map((e) => $modelName.fromEntity(e).toJson()).toList()';
          }

          if (field.isNullable) {
            return '${field.name} != null ? $modelName.fromEntity(${field.name}!).toJson() : null';
          }
          return '$modelName.fromEntity(${field.name}).toJson()';
        }
        return field.name;
    }
  }
}
