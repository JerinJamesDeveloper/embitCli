/// Entity Schema Templates
library;

import '../models/schema/schema_models.dart';
import '../models/field_definition.dart';

class EntitySchemaTemplates {
  EntitySchemaTemplates._();

  static String generate(FeatureSchema schema, String projectName) {
    final entity = schema.entity;
    final pascalCase = entity?.pascalCase ?? schema.pascalCase;

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

    final fieldDeclarations = fields.generateFieldDeclarations();
    final constructorParams = fields.generateConstructorParams();
    final copyWithParams = fields.generateCopyWithParams();
    final copyWithAssignments = fields.generateCopyWithAssignments();
    final propsItems = fields.generatePropsItems();

    return '''
/// $pascalCase Entity
///
/// Core business entity for ${schema.pascalCase} feature.
library;

import 'package:equatable/equatable.dart';

/// $pascalCase entity
class ${pascalCase}Entity extends Equatable {
$fieldDeclarations

  const ${pascalCase}Entity({
$constructorParams
  });

  ${pascalCase}Entity copyWith({
$copyWithParams
  }) {
    return ${pascalCase}Entity(
$copyWithAssignments
    );
  }

  factory ${pascalCase}Entity.empty() {
    return ${pascalCase}Entity(
      id: '',
      createdAt: DateTime.now(),
      // Note: Other fields will use their default values or be null
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [$propsItems];

  @override
  String toString() => '${pascalCase}Entity(id: \$id)';
}
''';
  }
}
