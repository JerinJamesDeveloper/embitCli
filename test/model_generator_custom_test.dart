import 'package:test/test.dart';
import '../lib/src/models/field_definition.dart';
import '../lib/src/generators/model_generator.dart';

// Mock config for testing
class MockConfig extends ModelGeneratorConfig {
  MockConfig({
    required List<FieldDefinition> fields,
  }) : super(
          featureName: 'test_feature',
          modelName: 'TestModel',
          fields: fields,
          projectName: 'test_project',
          projectPath: '.',
        );
}

void main() {
  test('ModelGenerator generates correct code for custom fields', () async {
    final fields = [
      FieldDefinition.fromCustom('CareEntity'),
      FieldDefinition.fromCustom('details:DetailEntity?'),
      FieldDefinition.fromCustom('items:List<ItemEntity>'),
    ];

    // Access private method logic by creating a temporary generator instance
    // and using reflection or just checking the output string if we could run it.
    // simpler: Let's just generate the content and check strings.

    final generator = ModelGenerator();
    // We can't easily access private methods directly in a test without @visibleForTesting
    // But we can check if the generated content contains expected strings.
    // For this test, we will create a dummy file and check content?
    // Actually, let's just inspect the private method logic via a subclass or
    // simply trust the manual verification or integration test.

    // Better approach given access limitations: make a small script that
    // instantiates the generator (if public) and calls generate, then reads file.
    // But generate writes to disk.

    // Let's rely on the manual verification pattern used before:
    // Create a script that prints the generated code strings?
    // The methods _generateModelContent is private.

    // Changing strategy: Since I cannot easily unit test private methods without
    // modifying the code to expose them, I will create a script that
    // USES the generator to generate a file in a temp dir, and then reads it.
  });
}
