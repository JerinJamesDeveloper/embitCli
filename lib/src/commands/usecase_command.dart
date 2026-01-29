/// UseCase Command
///
/// Creates a new usecase for an existing feature.
library;

import 'dart:io';

import 'package:args/args.dart';

import 'base_command.dart';
import '../models/field_definition.dart';
import '../models/usecase_config.dart';
import '../validators/project_validator.dart';
import '../validators/usecase_validator.dart';
import '../generators/usecase_generator.dart';
import '../utils/cli_prompts.dart';

/// Command to create a new usecase
class UseCaseCommand extends BaseCommand {
  @override
  String get name => 'usecase';

  @override
  String get description => 'Create a new usecase for an existing feature';

  @override
  ArgParser get argParser => ArgParser()
    ..addOption(
      'feature',
      abbr: 'f',
      help: 'Feature name (existing feature)',
      mandatory: true,
    )
    ..addOption(
      'name',
      abbr: 'n',
      help: 'UseCase name in snake_case (e.g., archive_product)',
      mandatory: true,
    )
    ..addOption(
      'type',
      abbr: 't',
      help: 'UseCase type: get, get-list, create, update, delete, custom',
      defaultsTo: 'custom',
    )
    ..addFlag(
      'with-event',
      help: 'Generate BLoC event automatically',
      negatable: false,
    )
    ..addFlag(
      'force',
      help: 'Force overwrite if usecase exists',
      negatable: false,
    )
    ..addFlag(
      'dry-run',
      help: 'Show what would be created without creating files',
      negatable: false,
    )
    ..addFlag(
      'interactive',
      abbr: 'i',
      help: 'Interactive mode - prompts for options',
      negatable: false,
    )
    // Field options (same as model command)
    ..addMultiOption('string',
        help: 'Add String field (use name? for nullable)')
    ..addMultiOption('int', help: 'Add int field')
    ..addMultiOption('double', help: 'Add double field')
    ..addMultiOption('bool', help: 'Add bool field')
    ..addMultiOption('datetime', help: 'Add DateTime field');

  @override
  Future<void> execute(ArgResults results, {bool verbose = false}) async {
    final featureName = results['feature'] as String;
    final useCaseName = results['name'] as String;
    var typeString = results['type'] as String;
    var withEvent = results['with-event'] == true;
    final force = results['force'] == true;
    final dryRun = results['dry-run'] == true;
    final interactive = results['interactive'] == true;

    final projectPath = Directory.current.path;

    print('''
╔════════════════════════════════════════╗
║      Embit CLI - Create UseCase        ║
╚════════════════════════════════════════╝
''');

    // ========== Validate UseCase Name ==========
    try {
      UseCaseValidator.validateOrThrow(useCaseName);
    } on ArgumentError catch (e) {
      stderr.writeln('❌ $e');
      
      final suggestion = UseCaseValidator.suggestValidName(useCaseName);
      if (suggestion != null) {
        stderr.writeln('\n💡 Did you mean: $suggestion');
      }
      exit(1);
    }

    // ========== Validate Project ==========
    print('🔍 Validating project...');
    
    if (!ProjectValidator.isFlutterProject(projectPath)) {
      stderr.writeln('');
      stderr.writeln('❌ Error: Not a Flutter project');
      exit(1);
    }

    if (!ProjectValidator.isStarterKitInitialized(projectPath)) {
      stderr.writeln('');
      stderr.writeln('❌ Error: Starter kit not initialized');
      stderr.writeln('   Run "embit init" first to set up the project structure.');
      exit(1);
    }

    // ========== Validate Feature ==========
    print('🔍 Validating feature...');
    
    final featureValidation = UseCaseValidator.validateFeatureForUseCase(
      projectPath,
      featureName,
    );

    if (featureValidation != null) {
      stderr.writeln('');
      stderr.writeln('❌ Error: $featureValidation');
      stderr.writeln('   Create the feature first: embit feature -n $featureName');
      exit(1);
    }

    final entityName = UseCaseValidator.getEntityName(projectPath, featureName);
    print('   ✓ Feature "$featureName" exists');
    print('   ✓ Entity "$entityName" found');

    // ========== Check if UseCase Exists ==========
    if (UseCaseValidator.useCaseExists(projectPath, featureName, useCaseName) && !force) {
      stderr.writeln('');
      stderr.writeln('❌ Error: UseCase "$useCaseName" already exists');
      stderr.writeln('   Use --force to overwrite existing usecase');
      exit(1);
    }

    // ========== Interactive Mode ==========
    if (interactive) {
      print('');
      print('📋 UseCase Configuration');
      print('   Feature: $featureName');
      print('   Name: $useCaseName');
      print('');

      // Select type
      final typeIndex = CLIPrompts.select(
        'Select usecase type:',
        [
          'get - Get single entity',
          'get-list - Get list of entities',
          'create - Create entity',
          'update - Update entity',
          'delete - Delete entity',
          'custom - Custom usecase',
        ],
        defaultIndex: 5,
      );

      typeString = ['get', 'get-list', 'create', 'update', 'delete', 'custom'][typeIndex];

      // Ask about event generation
      withEvent = CLIPrompts.confirm(
        'Generate BLoC event automatically?',
        defaultValue: true,
      );
    }

    final useCaseType = UseCaseType.fromString(typeString);

    // ========== Parse Custom Fields ==========
    List<FieldDefinition> fields = [];

    _parseFields(results, 'string', 'String', fields);
    _parseFields(results, 'int', 'int', fields);
    _parseFields(results, 'double', 'double', fields);
    _parseFields(results, 'bool', 'bool', fields);
    _parseFields(results, 'datetime', 'DateTime', fields);

    // Show parsed fields if verbose
    if (verbose && fields.isNotEmpty) {
      print('');
      print('📋 Custom Fields:');
      for (final field in fields) {
        final nullable = field.isNullable ? '?' : '';
        final required = field.isRequired ? ' (required)' : '';
        print('   • ${field.name}: ${field.type}$nullable$required');
      }
    }

    // ========== Get Project Name ==========
    final projectName = ProjectValidator.getProjectName(projectPath);

    // ========== Create Config ==========
    final config = UseCaseConfig(
      featureName: featureName,
      useCaseName: useCaseName,
      type: useCaseType,
      projectName: projectName,
      projectPath: projectPath,
      force: force,
      dryRun: dryRun,
      withEvent: withEvent,
      fields: fields,
    );

    // ========== Dry Run ==========
    if (dryRun) {
      print('');
      print('📋 DRY RUN - Would create usecase: $useCaseName');
      print('');
      _printPreview(config);
      print('');
      print('   Run without --dry-run to create files.');
      return;
    }

    // ========== Generate UseCase ==========
    print('');
    print('🚀 Creating usecase: $useCaseName');
    print('   Feature: $featureName');
    print('   Type: ${useCaseType.description}');
    print('   Entity: $entityName');
    if (withEvent) {
      print('   Event: ✓ Will generate');
    }
    print('');

    try {
      final generator = UseCaseGenerator(config, verbose: verbose);
      await generator.generate();
    } catch (e) {
      stderr.writeln('');
      stderr.writeln('❌ Error generating usecase: $e');
      exit(1);
    }

    // ========== Success Message ==========
    print('');
    print('═══════════════════════════════════════════════════════════════');
    print('');
    print('🎉 UseCase "$useCaseName" created successfully!');
    print('');
    print('📝 Generated:');
    print('   ✓ ${config.useCaseFilePath}');
    if (withEvent) {
      print('   ✓ Event in ${config.eventFilePath}');
    }
    print('');
    print('🔧 Updated:');
    print('   ✓ lib/core/di/injection_container.dart');
    print('   ✓ ${config.blocFilePath}');
    print('');
    print('📋 Next steps:');
    print('');
    print('   1. Add repository method in:');
    print('      ${config.repositoryFilePath}');
    print('');
    print('      Future<Either<Failure, ${config.returnType}>> ${config.repositoryMethodName}(...);');
    print('');
    print('   2. Implement in repository:');
    print('      lib/features/$featureName/data/repositories/${featureName}_repository_impl.dart');
    print('');
    if (withEvent) {
      print('   3. Add event handler in BLoC:');
      print('      on<${config.eventName}>(_on${config.useCasePascalCase});');
      print('');
      print('   4. Use in UI:');
      print('      context.read<${config.blocName}>().add(${config.eventName}(...));');
    } else {
      print('   3. Create BLoC event and handler if needed');
      print('');
      print('   4. Use the usecase:');
      print('      await _${config.useCaseCamelCase}UseCase(${config.paramsClassName}(...));');
    }
    print('');
    print('═══════════════════════════════════════════════════════════════');
  }

  void _printPreview(UseCaseConfig config) {
    print('   Files to be created:');
    print('   📄 ${config.useCaseFilePath}');
    
    if (config.withEvent) {
      print('');
      print('   Files to be updated:');
      print('   📝 ${config.eventFilePath} (add event)');
    }
    
    print('');
    print('   Files to be updated:');
    print('   📝 lib/core/di/injection_container.dart');
    print('   📝 ${config.blocFilePath}');
    
    // Show custom fields if any
    if (config.hasCustomFields) {
      print('');
      print('   Custom Params Fields:');
      for (final field in config.fields) {
        final nullable = field.isNullable ? '?' : '';
        final required = field.isRequired ? ' (required)' : '';
        print('   • ${field.name}: ${field.type}$nullable$required');
      }
    }
    
    print('');
    print('   Repository method to implement:');
    print('   ⚠️  Future<Either<Failure, ${config.returnType}>> ${config.repositoryMethodName}(...)');
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
}