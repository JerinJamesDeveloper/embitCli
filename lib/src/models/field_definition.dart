// /// Field definition for model generation
// class FieldDefinition {
//   final String name;
//   final String type;
//   final bool isNullable;
//   final String? defaultValue;

//   FieldDefinition({
//     required this.name,
//     required this.type,
//     this.isNullable = false,
//     this.defaultValue,
//   });

//   /// JSON key in snake_case
//   String get jsonKey => _toSnakeCase(name);

//   /// Full Dart type with nullability
//   String get dartType => isNullable ? '$type?' : type;

//   /// Whether field has a default value
//   bool get hasDefault => defaultValue != null;

//   /// Whether field is required in constructor
//   bool get isRequired => !isNullable && !hasDefault;

//   /// Parse field from CLI input like "name", "name?", "name=default"
//   factory FieldDefinition.parse(String input, String type) {
//     String name = input.trim();
//     bool isNullable = false;
//     String? defaultValue;

//     // Check for default value first (e.g., "isActive=true")
//     if (name.contains('=')) {
//       final parts = name.split('=');
//       name = parts[0];
//       defaultValue = parts.sublist(1).join('='); // Handle values with '='
//     }

//     // Check for nullable (e.g., "description?")
//     if (name.endsWith('?')) {
//       isNullable = true;
//       name = name.substring(0, name.length - 1);
//     }

//     return FieldDefinition(
//       name: name,
//       type: type,
//       isNullable: isNullable,
//       defaultValue: defaultValue,
//     );
//   }

//   static String _toSnakeCase(String input) {
//     return input
//         .replaceAllMapped(
//           RegExp(r'[A-Z]'),
//           (match) => '_${match.group(0)!.toLowerCase()}',
//         )
//         .replaceFirst(RegExp(r'^_'), '');
//   }
// }

// /// Configuration for model generation
// class ModelGeneratorConfig {
//   final String featureName;
//   final String modelName;
//   final List<FieldDefinition> fields;
//   final String? description;

//   ModelGeneratorConfig({
//     required this.featureName,
//     required this.modelName,
//     required this.fields,
//     this.description,
//   });
// }

/// Field Definition
///
/// Represents a field for entity, model, and usecase params generation.
library;

/// Definition of a field
class FieldDefinition {
  /// Field name in camelCase (e.g., productName)
  final String name;

  /// Dart type (String, int, bool, List<String>, etc.)
  final String type;

  /// Whether the field is nullable (adds ? to type)
  final bool isNullable;

  /// Whether the field is required in constructor
  final bool isRequired;

  /// Default value (optional)
  final String? defaultValue;

  /// Description for documentation
  final String? description;

  const FieldDefinition({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.isRequired = true,
    this.defaultValue,
    this.description,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// JSON key in snake_case (e.g., product_name)
  String get jsonKey => _toSnakeCase(name);

  /// Full Dart type with nullability
  String get dartType {
    if (isNullable && !type.endsWith('?')) {
      return '$type?';
    }
    return type;
  }

  /// Whether field has a default value
  bool get hasDefault => defaultValue != null;

  /// Whether field needs 'required' keyword in constructor
  bool get needsRequired => isRequired && !hasDefault;

  /// Whether field is optional (nullable or has default)
  bool get isOptional => !isRequired || isNullable || hasDefault;

  /// Get constructor parameter declaration
  /// e.g., "required this.name," or "this.description,"
  String get constructorParam {
    if (needsRequired) {
      return 'required this.$name,';
    } else if (hasDefault) {
      return 'this.$name = $defaultValue,';
    } else {
      return 'this.$name,';
    }
  }

  /// Get field declaration
  /// e.g., "final String name;" or "final String? description;"
  String get fieldDeclaration {
    final doc = description != null ? '  /// $description\n' : '';
    return '$doc  final $dartType $name;';
  }

  /// Get copyWith parameter
  /// e.g., "String? name,"
  String get copyWithParam => '$type? $name,';

  /// Get copyWith assignment
  /// e.g., "name: name ?? this.name,"
  String get copyWithAssignment => '$name: $name ?? this.$name,';

  /// Get props entry for Equatable
  String get propsEntry => name;

  /// Get fromJson assignment
  String get fromJsonAssignment {
    return "$name: ${_getFromJsonParser("json['$jsonKey']")},";
  }

  /// Get toJson assignment
  String get toJsonAssignment {
    if (isNullable) {
      return "if ($name != null) '$jsonKey': ${_getToJsonValue(name)},";
    }
    return "'$jsonKey': ${_getToJsonValue(name)},";
  }

  // ==================== PARSING ====================

  /// Parse field from CLI input format: "name:type" or "name:type?" or "name:type=default"
  ///
  ///
  ///
  factory FieldDefinition.parse(String input, String type) {
    String name = input.trim();
    bool isNullable = false;
    String? defaultValue;

    // Check for default value first (e.g., "isActive=true")
    if (name.contains('=')) {
      final parts = name.split('=');
      name = parts[0];
      defaultValue = parts.sublist(1).join('='); // Handle values with '='
    }

    // Check for nullable (e.g., "description?")
    if (name.endsWith('?')) {
      isNullable = true;
      name = name.substring(0, name.length - 1);
    }

    return FieldDefinition(
      name: name,
      type: type,
      isNullable: isNullable,
      defaultValue: defaultValue,
    );
  }

  /// Examples:
  /// - "id:String" → required String id
  /// - "description:String?" → optional String? description
  /// - "isActive:bool=true" → bool isActive = true
  /// - "count:int?=0" → optional int? count = 0
  factory FieldDefinition.parser(
    String input,
  ) {
    // Format: name:type or name:type? or name:type=default or name:type?=default
    final colonIndex = input.indexOf(':');
    if (colonIndex == -1) {
      throw FormatException(
        'Invalid field format: "$input". Expected: name:type\n'
        'Examples: id:String, description:String?, isActive:bool=true',
      );
    }

    final name = input.substring(0, colonIndex).trim();
    var typePart = input.substring(colonIndex + 1).trim();

    String? defaultValue;
    bool isNullable = false;
    bool isRequired = true;

    // Check for default value (e.g., "bool=true" or "String?=default")
    if (typePart.contains('=')) {
      final eqIndex = typePart.indexOf('=');
      defaultValue = typePart.substring(eqIndex + 1).trim();
      typePart = typePart.substring(0, eqIndex).trim();
      isRequired = false; // Has default, so not required
    }

    // Check for nullable (e.g., "String?")
    if (typePart.endsWith('?')) {
      typePart = typePart.substring(0, typePart.length - 1).trim();
      isNullable = true;
      isRequired = false; // Nullable fields are not required
    }

    if (name.isEmpty) {
      throw FormatException('Field name cannot be empty: "$input"');
    }

    if (typePart.isEmpty) {
      throw FormatException('Field type cannot be empty: "$input"');
    }

    return FieldDefinition(
      name: name,
      type: typePart,
      isNullable: isNullable,
      isRequired: isRequired,
      defaultValue: defaultValue,
    );
  }

  /// Parse from simple format: "name" with separate type
  /// Used for simpler CLI input like --fields "name,description?,count"
  factory FieldDefinition.parseSimple(String input, String type) {
    String name = input.trim();
    bool isNullable = false;
    bool isRequired = true;
    String? defaultValue;

    // Check for default value first (e.g., "isActive=true")
    if (name.contains('=')) {
      final parts = name.split('=');
      name = parts[0].trim();
      defaultValue = parts.sublist(1).join('=').trim();
      isRequired = false;
    }

    // Check for nullable (e.g., "description?")
    if (name.endsWith('?')) {
      isNullable = true;
      isRequired = false;
      name = name.substring(0, name.length - 1).trim();
    }

    // Check for required marker (e.g., "name!")
    if (name.endsWith('!')) {
      isRequired = true;
      isNullable = false;
      name = name.substring(0, name.length - 1).trim();
    }

    return FieldDefinition(
      name: name,
      type: type,
      isNullable: isNullable,
      isRequired: isRequired,
      defaultValue: defaultValue,
    );
  }

  /// Parse multiple fields from comma-separated string
  /// Format: "name:String,description:String?,count:int=0"
  static List<FieldDefinition> parseMultiple(String input) {
    if (input.trim().isEmpty) return [];

    return input
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .map(FieldDefinition.parser)
        .toList();
  }

  /// Parse from JSON schema field definition
  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    return FieldDefinition(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'String',
      isNullable:
          json['nullable'] as bool? ?? json['isNullable'] as bool? ?? false,
      isRequired:
          json['required'] as bool? ?? json['isRequired'] as bool? ?? true,
      defaultValue:
          json['default'] as String? ?? json['defaultValue'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'nullable': isNullable,
        'required': isRequired,
        'default': defaultValue,
        'description': description,
      };

  // ==================== HELPERS ====================

  String _getFromJsonParser(String accessor) {
    final baseType = type.replaceAll('?', '');

    switch (baseType) {
      case 'String':
        return isNullable
            ? "$accessor as String?"
            : "$accessor as String? ?? ''";
      case 'int':
        return isNullable
            ? "$accessor as int?"
            : "$accessor as int? ?? ${defaultValue ?? '0'}";
      case 'double':
        return isNullable
            ? "($accessor as num?)?.toDouble()"
            : "($accessor as num?)?.toDouble() ?? ${defaultValue ?? '0.0'}";
      case 'bool':
        return isNullable
            ? "$accessor as bool?"
            : "$accessor as bool? ?? ${defaultValue ?? 'false'}";
      case 'DateTime':
        return isNullable
            ? "_parseDateTime($accessor)"
            : "_parseDateTime($accessor) ?? DateTime.now()";
      case 'List':
        return "$accessor as List<dynamic>? ?? []";
      case 'Map':
        return "$accessor as Map<String, dynamic>? ?? {}";
      default:
        if (type.startsWith('List<')) {
          final innerType = type.substring(5, type.length - 1);
          return "($accessor as List<dynamic>?)?.map((e) => e as $innerType).toList() ?? []";
        }
        return "$accessor as $dartType";
    }
  }

  String _getToJsonValue(String fieldName) {
    final baseType = type.replaceAll('?', '');

    switch (baseType) {
      case 'DateTime':
        return isNullable
            ? '$fieldName?.toIso8601String()'
            : '$fieldName.toIso8601String()';
      default:
        return fieldName;
    }
  }

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  // ==================== EQUALITY & STRING ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldDefinition &&
        other.name == name &&
        other.type == type &&
        other.isNullable == isNullable &&
        other.isRequired == isRequired;
  }

  @override
  int get hashCode => Object.hash(name, type, isNullable, isRequired);

  @override
  String toString() {
    final nullable = isNullable ? '?' : '';
    final required = isRequired ? ' (required)' : '';
    final def = hasDefault ? ' = $defaultValue' : '';
    return 'FieldDefinition($name: $type$nullable$def$required)';
  }
}

/// Configuration for model generation
class ModelGeneratorConfig {
  final String featureName;
  final String modelName;
  final List<FieldDefinition> fields;
  final String? description;
  final bool generateCopyWith;
  final bool generateEquatable;
  final bool generateJson;

  const ModelGeneratorConfig({
    required this.featureName,
    required this.modelName,
    required this.fields,
    this.description,
    this.generateCopyWith = true,
    this.generateEquatable = true,
    this.generateJson = true,
  });

  /// Feature name in PascalCase
  String get featurePascalCase => _toPascalCase(featureName);

  /// Feature name in snake_case
  String get featureSnakeCase => _toSnakeCase(featureName);

  /// Model name in PascalCase
  String get modelPascalCase => _toPascalCase(modelName);

  /// Model name in snake_case
  String get modelSnakeCase => _toSnakeCase(modelName);

  /// Get required fields only
  List<FieldDefinition> get requiredFields =>
      fields.where((f) => f.isRequired).toList();

  /// Get optional fields only
  List<FieldDefinition> get optionalFields =>
      fields.where((f) => !f.isRequired).toList();

  /// Get nullable fields only
  List<FieldDefinition> get nullableFields =>
      fields.where((f) => f.isNullable).toList();

  /// Get fields with defaults
  List<FieldDefinition> get fieldsWithDefaults =>
      fields.where((f) => f.hasDefault).toList();

  static String _toPascalCase(String input) {
    return input.split('_').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join();
  }

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

/// Extension methods for List<FieldDefinition>
extension FieldDefinitionListExtension on List<FieldDefinition> {
  /// Generate field declarations
  String generateFieldDeclarations() {
    return map((f) => f.fieldDeclaration).join('\n');
  }

  /// Generate constructor parameters
  String generateConstructorParams({int indent = 4}) {
    final indentStr = ' ' * indent;
    return map((f) => '$indentStr${f.constructorParam}').join('\n');
  }

  /// Generate copyWith parameters
  String generateCopyWithParams({int indent = 4}) {
    final indentStr = ' ' * indent;
    return map((f) => '$indentStr${f.copyWithParam}').join('\n');
  }

  /// Generate copyWith assignments
  String generateCopyWithAssignments({int indent = 6}) {
    final indentStr = ' ' * indent;
    return map((f) => '$indentStr${f.copyWithAssignment}').join('\n');
  }

  /// Generate Equatable props
  String generatePropsItems() {
    return map((f) => f.propsEntry).join(', ');
  }

  /// Generate fromJson assignments
  String generateFromJsonAssignments({int indent = 6}) {
    final indentStr = ' ' * indent;
    return map((f) => '$indentStr${f.fromJsonAssignment}').join('\n');
  }

  /// Generate toJson assignments
  String generateToJsonAssignments({int indent = 6}) {
    final indentStr = ' ' * indent;
    return map((f) => '$indentStr${f.toJsonAssignment}').join('\n');
  }

  /// Generate validation code for required string fields
  String generateValidationCode({int indent = 4}) {
    final indentStr = ' ' * indent;
    final validations = <String>[];

    for (final field in this) {
      if (field.isRequired && field.type == 'String') {
        validations.add('''
${indentStr}if (params.${field.name}.trim().isEmpty) {
${indentStr}  return const Left(ValidationFailure(
${indentStr}    message: '${_toTitleCase(field.name)} cannot be empty',
${indentStr}    fieldErrors: {'${field.name}': ['${_toTitleCase(field.name)} is required']},
${indentStr}  ));
${indentStr}}
''');
      }
    }

    return validations.join('\n');
  }

  /// Generate repository method signature parameters
  String generateRepositorySignatureParams({int indent = 4}) {
    if (isEmpty) return '';
    final indentStr = ' ' * indent;
    final params = map((f) {
      if (f.needsRequired) {
        return '${indentStr}required ${f.dartType} ${f.name},';
      } else {
        return '$indentStr${f.dartType} ${f.name},';
      }
    }).join('\n');
    return '{\n$params\n  }';
  }

  /// Generate repository call arguments
  String generateRepositoryCallArgs({int indent = 6}) {
    if (isEmpty) return '';
    final indentStr = ' ' * indent;
    return map((f) {
      if (f.type == 'String' && f.isRequired) {
        return '$indentStr${f.name}: params.${f.name}.trim(),';
      } else if (f.type == 'String' && !f.isRequired) {
        return '$indentStr${f.name}: params.${f.name}?.trim(),';
      } else {
        return '$indentStr${f.name}: params.${f.name},';
      }
    }).join('\n');
  }

  /// Generate API body parameters
  String generateApiBodyParams({int indent = 10}) {
    if (isEmpty) return '';
    final indentStr = ' ' * indent;
    return map((f) {
      final jsonKey = _toSnakeCase(f.name);
      if (f.isNullable) {
        return "${indentStr}if (${f.name} != null) '$jsonKey': ${f.name},";
      } else {
        return "$indentStr'$jsonKey': ${f.name},";
      }
    }).join('\n');
  }

  /// Generate event to params arguments
  String generateEventToParamsArgs({int indent = 8}) {
    if (isEmpty) return '';
    final indentStr = ' ' * indent;
    return map((f) => '$indentStr${f.name}: event.${f.name},').join('\n');
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
    final spaced = input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
