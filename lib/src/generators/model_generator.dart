import 'dart:io';
import '../models/field_definition.dart';

class ModelGenerator {
  Future<void> generate(ModelGeneratorConfig config, {bool verbose = false}) async {
    final featurePath = 'lib/features/${_toSnakeCase(config.featureName)}';
    final entityPath = '$featurePath/domain/entities';
    final modelPath = '$featurePath/data/models';

    // Ensure directories exist
    await Directory(entityPath).create(recursive: true);
    await Directory(modelPath).create(recursive: true);

    await _createEntity(config, entityPath, verbose: verbose);
    await _createModel(config, modelPath, verbose: verbose);
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
    buffer.writeln('/// Core business entity representing a ${config.modelName.toLowerCase()} in the system.');
    buffer.writeln('/// Pure Dart class with no external dependencies.');
    buffer.writeln('library;');
    buffer.writeln();
    buffer.writeln("import 'package:equatable/equatable.dart';");
    buffer.writeln();

    // ─────────────────────────────────────────────────────────────────────────
    // Class Declaration
    // ─────────────────────────────────────────────────────────────────────────
    buffer.writeln('/// $modelNameReadable entity representing the core ${config.modelName.toLowerCase()} data');
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
        buffer.writeln('    this.${field.name} = ${_formatDefaultValue(field)},');
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
      buffer.writeln('    ${field.type}? ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $className(');
    for (final field in config.fields) {
      buffer.writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
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
    final toStringFields = config.fields.take(3).map((f) => '${f.name}: \$${f.name}').join(', ');
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

    final content = _generateModelContent(config, modelName, entityName, entityFileName);

    await File('$path/$modelFileName.dart').writeAsString(content);
    print('✔ Model created: $path/$modelFileName.dart');
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
    buffer.writeln('/// Handles JSON serialization/deserialization for API communication.');
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
        buffer.writeln('    super.${field.name} = ${_formatDefaultValue(field)},');
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
    buffer.writeln('  factory $modelName.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $modelName(');
    for (final field in config.fields) {
      buffer.writeln('      ${field.name}: ${_generateFromJsonParsing(field)},');
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
      buffer.writeln("      '${field.jsonKey}': ${_generateToJsonValue(field)},");
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
      buffer.writeln('    ${field.type}? ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $modelName(');
    for (final field in config.fields) {
      buffer.writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
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
      buffer.writeln('    if (value is String) return DateTime.tryParse(value);');
      buffer.writeln('    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);');
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
        return field.name;
    }
  }
}