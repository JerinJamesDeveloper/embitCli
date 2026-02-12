import 'dart:io';
import '../lib/src/models/field_definition.dart';
import '../lib/src/generators/model_generator.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('embit_test_');
  final featurePath = '${tempDir.path}/lib/features/test_feature';

  print('Generating in ${tempDir.path}...');

  final fields = [
    FieldDefinition.fromCustom('CareEntity'),
    FieldDefinition.fromCustom('details:DetailEntity?'),
    FieldDefinition.fromCustom('items:List<ItemEntity>'),
  ];

  final config = ModelGeneratorConfig(
    featureName: 'test_feature',
    modelName: 'TestModel',
    fields: fields,
    projectName: 'test_project',
    projectPath: tempDir.path,
  );

  final generator = ModelGenerator();

  // We need to change the path logic in generator to use config.projectPath properly?
  // The generator uses: 'lib/features/${_toSnakeCase(config.featureName)}'
  // It assumes running from root.
  // We can trick it by changing Directory.current?

  final originalDir = Directory.current;
  Directory.current = tempDir;

  try {
    await generator.generate(config);

    final modelFile = File(
        '${tempDir.path}/lib/features/test_feature/data/models/test_model_model.dart');
    if (!modelFile.existsSync()) {
      print('❌ Model file not generated');
      exit(1);
    }

    final content = await modelFile.readAsString();
    print('Generated Content Snippets:');

    bool hasFromJson = content.contains("CareEntity.fromJson");
    bool hasEmpty = content.contains("CareEntity.empty()");
    bool hasListMap = content.contains(
        ".map((e) => ItemEntity.fromJson(e as Map<String, dynamic>))");
    bool hasToJson = content.contains("careEntity.toJson()");

    if (hasFromJson)
      print('✅ CareEntity.fromJson found');
    else
      print('❌ CareEntity.fromJson NOT found');

    if (hasEmpty)
      print('✅ CareEntity.empty() found');
    else
      print('❌ CareEntity.empty() NOT found');

    if (hasListMap)
      print('✅ List handling found');
    else
      print('❌ List handling found');

    if (hasToJson)
      print('✅ careEntity.toJson() found');
    else
      print('❌ careEntity.toJson() found');
  } catch (e, st) {
    print('Error: $e');
    print(st);
  } finally {
    Directory.current = originalDir;
    // tempDir.deleteSync(recursive: true);
  }
}
