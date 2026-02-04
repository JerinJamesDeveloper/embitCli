/// Entity Schema Model
///
/// Represents an entity definition from JSON schema.
library;

import '../field_definition.dart';

/// Entity schema - fields and metadata
class EntitySchema {
  /// Entity name (PascalCase)
  final String name;

  /// Custom fields for this entity
  final List<FieldDefinition> fields;

  /// Description for documentation
  final String? description;

  const EntitySchema({
    required this.name,
    this.fields = const [],
    this.description,
  });

  /// Parse from JSON
  factory EntitySchema.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as List<dynamic>? ?? [];

    return EntitySchema(
      name: json['name'] as String,
      description: json['description'] as String?,
      fields: fieldsJson
          .map((f) => FieldDefinition.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  /// Get name in snake_case
  String get snakeCase => _toSnakeCase(name);

  /// Get name in PascalCase
  String get pascalCase => name;

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}
