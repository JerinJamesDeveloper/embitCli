/// Generate Command
/// 
/// Generates features/screens from user-created JSON schema files.
/// 
/// Usage:
///   embit generate -s templates/orders.json
///   embit generate --schema templates/home.json --verbose
///   embit generate -s templates/cart.json --dry-run
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../models/schema/action_schema.dart';
import '../models/schema/feature_schema.dart';
import 'base_command.dart';
import '../parsers/schema_parser.dart';
import '../generators/schema_feature_generator.dart';
import '../validators/project_validator.dart';

/// Command to generate from user's JSON schema
class GenerateCommand extends BaseCommand {
  @override
  String get name => 'generate';

  @override
  String get description => '''
Generate feature from JSON schema file.

The schema file should be in your project directory (e.g., templates/orders.json).
Run this command from your Flutter project root.

Examples:
  embit generate -s templates/orders.json
  embit generate --schema templates/home.json --verbose
  embit generate -s templates/cart.json --dry-run --force''';

  @override
  ArgParser get argParser => ArgParser()
    ..addOption(
      'schema',
      abbr: 's',
      help: 'Path to JSON schema file (relative to project root)',
      valueHelp: 'path/to/schema.json',
      mandatory: true,
    )
    ..addFlag(
      'force',
      abbr: 'f',
      help: 'Force overwrite existing files',
      negatable: false,
    )
    ..addFlag(
      'dry-run',
      help: 'Preview what would be generated without creating files',
      negatable: false,
    )
    ..addFlag(
      'skip-di',
      help: 'Skip updating dependency injection',
      negatable: false,
    )
    ..addFlag(
      'skip-routes',
      help: 'Skip updating routes',
      negatable: false,
    );

  @override
  Future<void> execute(ArgResults results, {bool verbose = false}) async {
    final schemaPath = results['schema'] as String;
    final force = results['force'] == true;
    final dryRun = results['dry-run'] == true;
    final skipDI = results['skip-di'] == true;
    final skipRoutes = results['skip-routes'] == true;
    
    // Get current working directory (user's project)
    final projectPath = Directory.current.path;

    print('''
╔════════════════════════════════════════╗
║   Embit CLI - Generate from Schema     ║
╚════════════════════════════════════════╝
''');

    // ========== Step 1: Validate Project ==========
    print('🔍 Validating project...');
    
    if (!ProjectValidator.isFlutterProject(projectPath)) {
      _exitWithError(
        'Not a Flutter project',
        'Make sure you are in a Flutter project directory.',
      );
    }

    if (!ProjectValidator.isStarterKitInitialized(projectPath)) {
      _exitWithError(
        'Starter kit not initialized',
        'Run "embit init" first to set up the project structure.',
      );
    }

    final projectName = ProjectValidator.getProjectName(projectPath);
    print('   ✓ Project: $projectName');
    print('   ✓ Path: $projectPath');

    // ========== Step 2: Locate Schema File ==========
    print('');
    print('📄 Locating schema file...');
    
    // Build full path to schema file
    final fullSchemaPath = path.isAbsolute(schemaPath)
        ? schemaPath
        : path.join(projectPath, schemaPath);
    
    final schemaFile = File(fullSchemaPath);
    
    if (!schemaFile.existsSync()) {
      _exitWithError(
        'Schema file not found',
        'Could not find: $schemaPath\n'
        '   Full path: $fullSchemaPath\n\n'
        '   Make sure the file exists in your project.\n'
        '   Example structure:\n'
        '   my_app/\n'
        '   ├── templates/\n'
        '   │   └── orders.json  ← Your schema file\n'
        '   ├── lib/\n'
        '   └── pubspec.yaml',
      );
    }

    print('   ✓ Found: $schemaPath');

    // ========== Step 3: Parse Schema ==========
    print('');
    print('📋 Parsing schema...');
    
    final parseResult = await SchemaParser.parseFile(fullSchemaPath);
    
    if (!parseResult.success) {
      stderr.writeln('');
      stderr.writeln('❌ Schema parsing failed:');
      for (final error in parseResult.errors) {
        stderr.writeln('   • $error');
      }
      stderr.writeln('');
      stderr.writeln('💡 Check your JSON syntax and required fields.');
      exit(1);
    }

    final schema = parseResult.schema!;
    print('   ✓ Feature: ${schema.name}');
    print('   ✓ Screens: ${schema.screens.length}');

    // Print warnings if any
    if (parseResult.warnings.isNotEmpty) {
      print('');
      print('⚠️  Warnings:');
      for (final warning in parseResult.warnings) {
        print('   • $warning');
      }
    }

    // ========== Step 4: Show Summary ==========
    print('');
    print('═══════════════════════════════════════════════════════════════');
    print('');
    _printSchemaSummary(schema);

    // ========== Step 5: Check Existing Feature ==========
    final featureDir = Directory('$projectPath/lib/features/${schema.snakeCase}');
    
    if (featureDir.existsSync() && !force) {
      _exitWithError(
        'Feature "${schema.name}" already exists',
        'Use --force to overwrite existing files.\n'
        '   embit generate -s $schemaPath --force',
      );
    }

    // ========== Step 6: Dry Run ==========
    if (dryRun) {
      print('');
      print('📋 DRY RUN - Would generate:');
      print('');
      _printGenerationPlan(schema, projectPath);
      print('');
      print('   Run without --dry-run to generate files:');
      print('   embit generate -s $schemaPath');
      return;
    }

    // ========== Step 7: Generate ==========
    print('');
    print('🚀 Generating feature...');
    print('');

    try {
      final generator = SchemaFeatureGenerator(
        schema: schema,
        projectPath: projectPath,
        projectName: projectName,
        force: force,
        skipDI: skipDI,
        skipRoutes: skipRoutes,
        verbose: verbose,
      );
      
      await generator.generate();
    } catch (e, stackTrace) {
      stderr.writeln('');
      stderr.writeln('❌ Generation failed: $e');
      if (verbose) {
        stderr.writeln('');
        stderr.writeln(stackTrace);
      }
      exit(1);
    }

    // ========== Step 8: Success ==========
    _printSuccess(schema, schemaPath);
  }

  void _printSchemaSummary(FeatureSchema schema) {
    print('📱 Feature: ${schema.pascalCase}');
    print('   Route: ${schema.route}');
    if (schema.addToBottomNav) {
      print('   Navigation: Bottom Nav Bar ✓');
      print('   Icon: ${schema.icon ?? 'default'}');
      print('   Label: ${schema.label ?? schema.pascalCase}');
    }
    print('');
    
    print('📄 Screens:');
    for (final screen in schema.screens) {
      print('   ┌── ${screen.name}');
      print('   │   Type: ${screen.type.value}');
      print('   │   Route: ${screen.route}');
      if (screen.dataSource != null) {
        print('   │   Data: ${screen.dataSource}');
      }
      print('   │   Widgets: ${screen.widgets.length}');
      
      // List widgets
      for (var i = 0; i < screen.widgets.length; i++) {
        final widget = screen.widgets[i];
        final isLast = i == screen.widgets.length - 1;
        final prefix = isLast ? '   └──' : '   ├──';
        print('$prefix ${widget.name} (${widget.template.value})');
      }
      print('');
    }
  }

  void _printGenerationPlan(FeatureSchema schema, String projectPath) {
    final featurePath = '$projectPath/lib/features/${schema.snakeCase}';

    // Collect all files that would be created
    final files = <String>[];

    // Domain layer
    files.add('lib/features/${schema.snakeCase}/domain/entities/${schema.snakeCase}_entity.dart');
    files.add('lib/features/${schema.snakeCase}/domain/repositories/${schema.snakeCase}_repository.dart');

    // Collect usecases
    final usecases = _collectUsecases(schema);
    for (final usecase in usecases) {
      files.add('lib/features/${schema.snakeCase}/domain/usecases/${_toSnakeCase(usecase)}_usecase.dart');
    }

    // Data layer
    files.add('lib/features/${schema.snakeCase}/data/models/${schema.snakeCase}_model.dart');
    files.add('lib/features/${schema.snakeCase}/data/datasources/${schema.snakeCase}_remote_datasource.dart');
    files.add('lib/features/${schema.snakeCase}/data/datasources/${schema.snakeCase}_local_datasource.dart');
    files.add('lib/features/${schema.snakeCase}/data/repositories/${schema.snakeCase}_repository_impl.dart');

    // Presentation layer
    files.add('lib/features/${schema.snakeCase}/presentation/bloc/${schema.snakeCase}_bloc.dart');
    files.add('lib/features/${schema.snakeCase}/presentation/bloc/${schema.snakeCase}_event.dart');
    files.add('lib/features/${schema.snakeCase}/presentation/bloc/${schema.snakeCase}_state.dart');

    for (final screen in schema.screens) {
      files.add('lib/features/${schema.snakeCase}/presentation/pages/${screen.snakeCase}_page.dart');
    }

    // Print files
    print('   Files to create:');
    for (final file in files) {
      print('   📄 $file');
    }

    print('');
    print('   Files to update:');
    print('   📝 lib/core/di/injection_container.dart');
    print('   📝 lib/navigation/route_names.dart');
    print('   📝 lib/navigation/app_router.dart');
    print('   📝 lib/core/constants/api_endpoints.dart');
    if (schema.addToBottomNav) {
      print('   📝 lib/navigation/role_based_navigator.dart');
    }
  }

  void _printSuccess(FeatureSchema schema, String schemaPath) {
    print('');
    print('═══════════════════════════════════════════════════════════════');
    print('');
    print('🎉 Feature "${schema.name}" generated successfully!');
    print('');
    print('📁 Created structure:');
    print('   lib/features/${schema.snakeCase}/');
    print('   ├── data/');
    print('   │   ├── datasources/');
    print('   │   ├── models/');
    print('   │   └── repositories/');
    print('   ├── domain/');
    print('   │   ├── entities/');
    print('   │   ├── repositories/');
    print('   │   └── usecases/');
    print('   └── presentation/');
    print('       ├── bloc/');
    print('       ├── pages/');
    print('       └── widgets/');
    print('');
    
    print('📱 Screens created:');
    for (final screen in schema.screens) {
      print('   • ${screen.name} → ${screen.route}');
    }
    print('');
    
    if (schema.addToBottomNav) {
      print('🧭 Navigation:');
      print('   ✓ Added to bottom navigation bar');
      print('   ✓ Icon: ${schema.icon}');
      print('   ✓ Label: ${schema.label ?? schema.pascalCase}');
      print('');
    }
    
    print('📋 Next steps:');
    print('');
    print('   1. Run: flutter pub get');
    print('');
    print('   2. Implement your entity fields in:');
    print('      lib/features/${schema.snakeCase}/domain/entities/${schema.snakeCase}_entity.dart');
    print('');
    print('   3. Implement API calls in:');
    print('      lib/features/${schema.snakeCase}/data/datasources/${schema.snakeCase}_remote_datasource.dart');
    print('');
    print('   4. Navigate to the feature:');
    print('      context.go(RoutePaths.${schema.camelCase});');
    print('');
    print('   5. You can modify your schema and regenerate:');
    print('      embit generate -s $schemaPath --force');
    print('');
    print('═══════════════════════════════════════════════════════════════');
  }

  Set<String> _collectUsecases(FeatureSchema schema) {
    final usecases = <String>{};
    
    for (final screen in schema.screens) {
      if (screen.dataSource != null) {
        usecases.add(screen.dataSource!);
      }
      
      for (final widget in screen.widgets) {
        if (widget.dataSource != null) {
          usecases.add(widget.dataSource!);
        }
        _collectActionsUsecases(widget.action, usecases);
        _collectActionsUsecases(widget.onTap, usecases);
        _collectActionsUsecases(widget.onLongPress, usecases);
      }
    }
    
    return usecases;
  }

  void _collectActionsUsecases(ActionSchema? action, Set<String> usecases) {
    if (action == null) return;
    if (action.type == ActionType.usecase && action.name != null) {
      usecases.add(action.name!);
    }
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  void _exitWithError(String title, String message) {
    stderr.writeln('');
    stderr.writeln('❌ Error: $title');
    stderr.writeln('');
    stderr.writeln('   $message');
    stderr.writeln('');
    exit(1);
  }
}