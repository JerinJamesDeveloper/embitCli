/// Model Schema Templates
library;

import '../models/schema/feature_schema.dart';
import '../models/schema/schema_models.dart';
import '../models/field_definition.dart';

class ModelSchemaTemplates {
  ModelSchemaTemplates._();

  static String generate(FeatureSchema schema, String projectName) {
    final entity = schema.entity;
    final pascalCase = entity?.pascalCase ?? schema.pascalCase;
    final snakeCase = entity?.snakeCase ?? schema.snakeCase;

    // Default fields if no entity defined
    final fields = entity?.fields ??
        [
          const FieldDefinition(name: 'id', type: 'String', isRequired: true),
          const FieldDefinition(
              name: 'createdAt', type: 'DateTime', isRequired: true),
          const FieldDefinition(
              name: 'updatedAt',
              type: 'DateTime',
              isNullable: true,
              isRequired: false),
        ];

    final constructorParams =
        fields.map((f) => '    required super.${f.name},').join('\n');
    final fromJsonAssignments = fields.generateFromJsonAssignments();
    final toJsonAssignments = fields.generateToJsonAssignments();

    return '''
/// ${pascalCase} Model
///
/// Data model with JSON serialization for ${pascalCase}.
library;

import '../../domain/entities/${snakeCase}_entity.dart';

/// ${pascalCase} model with JSON serialization
class ${pascalCase}Model extends ${pascalCase}Entity {
  const ${pascalCase}Model({
$constructorParams
  });

  factory ${pascalCase}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalCase}Model(
$fromJsonAssignments
    );
  }

  Map<String, dynamic> toJson() {
    return {
$toJsonAssignments
    };
  }

  factory ${pascalCase}Model.fromEntity(${pascalCase}Entity entity) {
    return ${pascalCase}Model(
${fields.map((f) => '      ${f.name}: entity.${f.name},').join('\n')}
    );
  }

  ${pascalCase}Entity toEntity() => this;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
''';
  }
}
