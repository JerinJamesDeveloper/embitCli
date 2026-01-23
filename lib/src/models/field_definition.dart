/// Field definition for model generation
class FieldDefinition {
  final String name;
  final String type;
  final bool isNullable;
  final String? defaultValue;

  FieldDefinition({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.defaultValue,
  });

  /// JSON key in snake_case
  String get jsonKey => _toSnakeCase(name);

  /// Full Dart type with nullability
  String get dartType => isNullable ? '$type?' : type;

  /// Whether field has a default value
  bool get hasDefault => defaultValue != null;

  /// Whether field is required in constructor
  bool get isRequired => !isNullable && !hasDefault;

  /// Parse field from CLI input like "name", "name?", "name=default"
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

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

/// Configuration for model generation
class ModelGeneratorConfig {
  final String featureName;
  final String modelName;
  final List<FieldDefinition> fields;
  final String? description;

  ModelGeneratorConfig({
    required this.featureName,
    required this.modelName,
    required this.fields,
    this.description,
  });
}