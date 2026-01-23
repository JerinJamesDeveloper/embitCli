import 'package:args/args.dart';
import 'dart:io';
import '../models/field_definition.dart';
import '../generators/model_generator.dart';
import 'base_command.dart';

class ModelCommand extends BaseCommand {
@override
  String get name => 'model';

  @override
  String get description => 'Create a new model and entity with specified fields';

  @override
  ArgParser get argParser => ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the model (e.g., Product, User)')
    ..addOption('feature', abbr: 'f', help: 'Feature this model belongs to')
    ..addMultiOption('string',
        help: 'Add String field (use name? for nullable, name=default for default)')
    ..addMultiOption('int', help: 'Add int field')
    ..addMultiOption('double', help: 'Add double field')
    ..addMultiOption('bool', help: 'Add bool field (e.g., isActive=true)')
    ..addMultiOption('datetime', help: 'Add DateTime field')
    ..addFlag('help', abbr: 'h', help: 'Show help for model command', negatable: false);

  @override
  Future<void> execute(ArgResults results, { bool verbose = false}) async {
    if (results['help'] == true) {
      _printHelp();
      return;
    }

    final name = results['name'] as String?;
    final feature = results['feature'] as String?;

    // ─────────────────────────────────────────────────────────────────────────
    // Validation
    // ─────────────────────────────────────────────────────────────────────────
    if (name == null || feature == null) {
      stderr.writeln('❌ Error: --name (-n) and --feature (-f) are required');
      stderr.writeln('');
      _printHelp();
      exit(1);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parse Fields
    // ─────────────────────────────────────────────────────────────────────────
    List<FieldDefinition> fields = [];

    _parseFields(results, 'string', 'String', fields);
    _parseFields(results, 'int', 'int', fields);
    _parseFields(results, 'double', 'double', fields);
    _parseFields(results, 'bool', 'bool', fields);
    _parseFields(results, 'datetime', 'DateTime', fields);

    if (fields.isEmpty) {
      stderr.writeln('❌ Error: No fields provided.');
      stderr.writeln('   Use --string, --int, --double, --bool, --datetime');
      stderr.writeln('');
      _printHelp();
      exit(1);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Verbose Output
    // ─────────────────────────────────────────────────────────────────────────
    if (verbose) {
      print('');
      print('╔════════════════════════════════════════╗');
      print('║         Model Generation               ║');
      print('╚════════════════════════════════════════╝');
      print('');
      print('📦 Model Name : $name');
      print('📁 Feature    : $feature');
      print('📋 Fields     :');
      for (final field in fields) {
        final nullable = field.isNullable ? '?' : '';
        final defaultVal = field.hasDefault ? ' = ${field.defaultValue}' : '';
        final required = field.isRequired ? ' (required)' : '';
        print('   • ${field.name}: ${field.type}$nullable$defaultVal$required');
      }
      print('');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Generate Files
    // ─────────────────────────────────────────────────────────────────────────
    final config = ModelGeneratorConfig(
      featureName: feature,
      modelName: name,
      fields: fields,
    );

    try {
      final generator = ModelGenerator();
      await generator.generate(config, verbose: verbose);
      print('');
      print('✅ Model and Entity generation complete!');
      print('');
      print('Generated files:');
      print('   📄 lib/features/${_toSnakeCase(feature)}/domain/entities/${_toSnakeCase(name)}_entity.dart');
      print('   📄 lib/features/${_toSnakeCase(feature)}/data/models/${_toSnakeCase(name)}_model.dart');
    } catch (e, stackTrace) {
      stderr.writeln('❌ Error generating model: $e');
      if (verbose) {
        stderr.writeln(stackTrace);
      }
      exit(1);
    }
  }

  void _parseFields(
    ArgResults results,
    String option,
    String type,
    List<FieldDefinition> fields,
  ) {
    if (results.wasParsed(option)) {
      for (var input in results[option] as List<String>) {
        fields.add(FieldDefinition.parse(input, type));
      }
    }
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '')
        .toLowerCase();
  }

  void _printHelp() {
    print('''
╔════════════════════════════════════════╗
║         Model Command Help             ║
╚════════════════════════════════════════╝

Generate Entity and Model files with full serialization support.

Usage: embit model -f <feature> -n <name> [field options]

Required Options:
  -f, --feature     Feature name (e.g., auth, products, home)
  -n, --name        Model name in PascalCase (e.g., Product, User)

Field Options:
  --string          Add String field
  --int             Add int field  
  --double          Add double field
  --bool            Add bool field
  --datetime        Add DateTime field

Field Syntax:
  fieldName         Required field
  fieldName?        Nullable/optional field
  fieldName=value   Field with default value

Examples:

  # Simple model with basic fields
  embit model -f auth -n User \\
    --string id \\
    --string name \\
    --string email

  # Model with nullable fields
  embit model -f products -n Product \\
    --string id \\
    --string name \\
    --string "description?" \\
    --double price \\
    --string "imageUrl?"

  # Full model with all field types
  embit model -f home -n Product \\
    --string id \\
    --string name \\
    --string "description?" \\
    --double price \\
    --int categoryId \\
    --string "imageUrl?" \\
    --bool "isActive=true" \\
    --datetime createdAt \\
    --datetime "updatedAt?"

Generated Files:
  lib/features/<feature>/domain/entities/<name>_entity.dart
  lib/features/<feature>/data/models/<name>_model.dart

Features included in generated files:
  ✓ Equatable extension with props
  ✓ copyWith method
  ✓ empty() factory constructor
  ✓ isEmpty / isNotEmpty getters
  ✓ fromJson / toJson serialization
  ✓ fromEntity / toEntity conversion
  ✓ Snake_case JSON keys
  ✓ Null-safe JSON parsing
  ✓ DateTime parsing helper
''');
  }
}