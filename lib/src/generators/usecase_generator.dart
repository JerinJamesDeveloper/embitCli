/// UseCase Generator
///
/// Generates usecase files and updates architecture files.
library;

import 'dart:io';

import '../models/usecase_config.dart';
import '../templates/usecase_type_templates.dart';

class UseCaseGenerator {
  final UseCaseConfig config;
  final bool verbose;

  UseCaseGenerator(this.config, {this.verbose = false});

  Future<void> generate() async {
    _log('📝 Creating usecase file...');
    await _createUseCaseFile();

    _log('🔗 Updating Domain Layer (Repository Interface)...');
    await _updateRepositoryInterface();

    _log('🔗 Updating Data Layer (Repository Implementation)...');
    await _updateRepositoryImpl();

    _log('🔗 Updating Data Layer (Remote Data Source)...');
    await _updateRemoteDataSource();

    _log('🔧 Updating DI container...');
    await _updateDIContainer();

    _log('🎯 Updating BLoC...');
    await _updateBLoC();

    if (config.withEvent) {
      _log('📋 Adding BLoC event...');
      await _addBlocEvent();
    }

    print('✅ UseCase "${config.useCaseName}" generated successfully!');
  }

  void _log(String message) {
    if (verbose) print(message);
  }

  // ==================== CREATE USECASE FILE ====================

  Future<void> _createUseCaseFile() async {
    final useCaseFile = File('${config.projectPath}/${config.useCaseFilePath}');

    if (useCaseFile.existsSync() && !config.force) {
      throw Exception('UseCase file already exists. Use --force to overwrite.');
    }

    // Ensure directory exists
    if (!useCaseFile.parent.existsSync()) {
      useCaseFile.parent.createSync(recursive: true);
    }

    final content = UseCaseTypeTemplates.generate(config);
    await useCaseFile.writeAsString(content);
    _log('  ✓ Created ${config.useCaseFilePath}');
  }

  // ==================== UPDATE REPOSITORY IMPLEMENTATION ====================

  Future<void> _updateRepositoryImpl() async {
    // 1. Construct path carefully
    final path =
        '${config.projectPath}/${config.featureBasePath}/data/repositories/${config.featureSnakeCase}_repository_impl.dart';
    final file = File(path);

    if (verbose) print('  🔍  Checking Repo Impl at: $path');

    if (!file.existsSync()) {
      _log('  ❌  Repository implementation NOT found.');
      _log('      Expected at: $path');
      return;
    }

    var content = await file.readAsString();

    // 2. Strict Check: Ensure we check for "methodName(" to avoid matching comments or substrings
    if (content.contains('${config.repositoryMethodName}(')) {
      _log(
          '  ⚠️  Method "${config.repositoryMethodName}" already exists in implementation. Skipping.');
      return;
    }

    final impl = UseCaseTypeTemplates.repositoryMethodImpl(config);

    // 3. Robust Insertion: Find the last closing brace
    final lastBrace = content.lastIndexOf('}');

    if (lastBrace != -1) {
      // Insert code BEFORE the last closing brace
      content = content.substring(0, lastBrace) +
          '\n$impl\n' +
          content.substring(lastBrace);

      await file.writeAsString(content);
      _log(
          '  ✓ Added implementation to ${config.featurePascalCase}RepositoryImpl');
    } else {
      _log(
          '  ❌  Error: Malformed file. Could not find closing "}" in ${file.path}');
    }
  }

  // ==================== UPDATE REPOSITORY INTERFACE ====================

  Future<void> _updateRepositoryInterface() async {
    final path = '${config.projectPath}/${config.repositoryFilePath}';
    final file = File(path);

    if (!file.existsSync()) {
      _log('  ⚠️ Repository interface not found at: $path');
      return;
    }

    var content = await file.readAsString();

    if (content.contains('${config.repositoryMethodName}(')) {
      _log('  ⚠️  Method already exists in Repository Interface.');
      return;
    }

    final signature = UseCaseTypeTemplates.repositoryMethodSignature(config);

    final lastBrace = content.lastIndexOf('}');
    if (lastBrace != -1) {
      content = content.substring(0, lastBrace) +
          '\n$signature\n' +
          content.substring(lastBrace);
      await file.writeAsString(content);
      _log('  ✓ Added method signature to ${config.repositoryName}');
    }
  }

  // ==================== UPDATE REMOTE DATA SOURCE ====================

  Future<void> _updateRemoteDataSource() async {
    final path =
        '${config.projectPath}/${config.featureBasePath}/data/datasources/${config.featureSnakeCase}_remote_datasource.dart';
    final file = File(path);

    if (!file.existsSync()) {
      _log('  ⚠️ Remote data source not found at: $path');
      _printManualDIInstructions();
      return;
    }

    var content = await file.readAsString();
    if (content.contains('${config.repositoryMethodName}(')) return;

    // 1. Update Interface (Insert before "class ...Impl")
    final signature =
        UseCaseTypeTemplates.remoteDataSourceMethodSignature(config);
    final implClassStart = content
        .indexOf('class ${config.featurePascalCase}RemoteDataSourceImpl');

    if (implClassStart != -1) {
      final interfaceEnd = content.lastIndexOf('}', implClassStart);
      if (interfaceEnd != -1) {
        content = content.substring(0, interfaceEnd) +
            '\n$signature\n' +
            content.substring(interfaceEnd);
      }
    } else {
      // Fallback: If Abstract and Impl are in separate files, or structure differs
      // Just look for the first closing brace that isn't the file end
      // This part depends heavily on your file structure consistency
    }

    // 2. Update Implementation (Append to end of file)
    final impl = UseCaseTypeTemplates.remoteDataSourceMethodImpl(config);
    final lastBrace = content.lastIndexOf('}');

    if (lastBrace != -1) {
      content = content.substring(0, lastBrace) +
          '\n$impl\n' +
          content.substring(lastBrace);

      await file.writeAsString(content);
      _log('  ✓ Updated Remote Data Source');
    }
  }

  // ==================== UPDATE DI CONTAINER (FIXED) ====================

  Future<void> _updateDIContainer() async {
    final diFile = File('${config.projectPath}/lib/core/di/injection_container.dart');

    if (!diFile.existsSync()) {
      print('  ⚠️  injection_container.dart not found. Skipping DI update.');
      return;
    }

    var content = await diFile.readAsString();

    // Check if already registered
    if (content.contains(config.useCaseClassName)) {
      _log('  ⚠️  UseCase already registered in DI container');
      return;
    }

    // 1. Add Import (Standard logic)
    final useCaseImport = "import '../../features/${config.featureSnakeCase}/domain/usecases/${config.useCaseSnakeCase}_usecase.dart';";
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();
    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content = '${content.substring(0, lastImportEnd)}\n$useCaseImport${content.substring(lastImportEnd)}';
    }

    // 2. Register UseCase (Standard logic)
    final featureInitMarker = '_init${config.featurePascalCase}Feature';
    final featureInitIndex = content.indexOf(featureInitMarker);

    if (featureInitIndex != -1) {
       // Look for the Repository comment to insert UseCases before it
       final insertMarker = '// ========== Repository ==========';
       final insertIndex = content.indexOf(insertMarker, featureInitIndex);

       if (insertIndex != -1) {
         final registration = '''
  sl.registerLazySingleton<${config.useCaseClassName}>(
    () => ${config.useCaseClassName}(sl()),
  );
  
  ''';
         content = content.substring(0, insertIndex) + registration + content.substring(insertIndex);
       }
    }

    // 3. Add to BLoC (NEW STRATEGY: Insert at start)
    final blocConstructorMarker = '=> ${config.blocName}(';
    final blocIndex = content.indexOf(blocConstructorMarker);
    
    if (blocIndex != -1) {
      // Calculate where to insert: immediately after "=> FeedBloc("
      final insertionIndex = blocIndex + blocConstructorMarker.length;
      
      // Add newline and indentation for clean formatting
      final newParam = '\n      ${config.useCaseCamelCase}UseCase: sl(),';
      
      content = content.substring(0, insertionIndex) + 
                newParam + 
                content.substring(insertionIndex);
                
    } else {
       _log('  ⚠️  Could not find BLoC constructor "$blocConstructorMarker" in DI file.');
    }


    await diFile.writeAsString(content);
    _log('  ✓ Updated injection_container.dart');
  }

  void _printManualDIInstructions() {
    print('''
     Please add manually to injection_container.dart:

     1. Import:
        import '../../features/${config.featureSnakeCase}/domain/usecases/${config.useCaseSnakeCase}_usecase.dart';

     2. Register in _init${config.featurePascalCase}Feature():
        sl.registerLazySingleton<${config.useCaseClassName}>(
          () => ${config.useCaseClassName}(sl()),
        );

     3. Add to ${config.blocName} constructor:
        ${config.useCaseCamelCase}UseCase: sl(),
''');
  }

  // ==================== UPDATE BLOC ====================

  Future<void> _updateBLoC() async {
    final blocFile = File('${config.projectPath}/${config.blocFilePath}');

    if (!blocFile.existsSync()) {
      print('  ⚠️  BLoC file not found. Skipping BLoC update.');
      _printManualBlocInstructions();
      return;
    }

    var content = await blocFile.readAsString();

    // Check if already added
    if (content.contains('_${config.useCaseCamelCase}UseCase')) {
      _log('  ⚠️  UseCase already added to BLoC');
      return;
    }

    // Add import
    final useCaseImport =
        "import '../../domain/usecases/${config.useCaseSnakeCase}_usecase.dart';";
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();

    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content =
          '${content.substring(0, lastImportEnd)}\n$useCaseImport${content.substring(lastImportEnd)}';
    }

    // Add field
    final fieldPattern = RegExp(
      'class ${config.blocName} extends Bloc<[^{]+\\{',
      multiLine: true,
    );

    final fieldMatch = fieldPattern.firstMatch(content);

    if (fieldMatch != null) {
      final insertPos = fieldMatch.end;
      final newField =
          '\n  final ${config.useCaseClassName} _${config.useCaseCamelCase}UseCase;';
      content = content.substring(0, insertPos) +
          newField +
          content.substring(insertPos);
    }

    // Add to constructor parameters
    final constructorPattern = RegExp(
      '${config.blocName}\\(\\{[\\s\\S]*?\\}\\)',
      multiLine: true,
    );

    final constructorMatch = constructorPattern.firstMatch(content);

    if (constructorMatch != null) {
      final constructor = constructorMatch.group(0)!;
      final lastParam = constructor.lastIndexOf('UseCase');

      if (lastParam != -1) {
        // Find end of that line
        final lineEnd = constructor.indexOf(',', lastParam);
        if (lineEnd != -1) {
          final newParam =
              '\n    required ${config.useCaseClassName} ${config.useCaseCamelCase}UseCase,';
          final updatedConstructor = constructor.substring(0, lineEnd + 1) +
              newParam +
              constructor.substring(lineEnd + 1);

          content = content.replaceFirst(constructor, updatedConstructor);
        }
      }
    }

    // Add to constructor initialization
    final initPattern = RegExp(
      '\\)\\s*:[\\s\\S]*?super\\(',
      multiLine: true,
    );

    final initMatch = initPattern.firstMatch(content);

    if (initMatch != null) {
      final init = initMatch.group(0)!;
      final lastInit = init.lastIndexOf('_');

      if (lastInit != -1) {
        final lineEnd = init.indexOf(',', lastInit);
        if (lineEnd != -1) {
          final newInit =
              '\n        _${config.useCaseCamelCase}UseCase = ${config.useCaseCamelCase}UseCase,';
          final updatedInit = init.substring(0, lineEnd + 1) +
              newInit +
              init.substring(lineEnd + 1);

          content = content.replaceFirst(init, updatedInit);
        }
      }
    }

    await blocFile.writeAsString(content);
    _log('  ✓ Updated ${config.featureSnakeCase}_bloc.dart');
  }

  void _printManualBlocInstructions() {
    print('''
     Please add manually to ${config.featureSnakeCase}_bloc.dart:

     1. Import:
        import '../../domain/usecases/${config.useCaseSnakeCase}_usecase.dart';

     2. Add field:
        final ${config.useCaseClassName} _${config.useCaseCamelCase}UseCase;

     3. Add constructor parameter:
        required ${config.useCaseClassName} ${config.useCaseCamelCase}UseCase,

     4. Initialize in constructor:
        _${config.useCaseCamelCase}UseCase = ${config.useCaseCamelCase}UseCase,
''');
  }

  // ==================== ADD BLOC EVENT ====================

  Future<void> _addBlocEvent() async {
    final eventFile = File('${config.projectPath}/${config.eventFilePath}');

    if (!eventFile.existsSync()) {
      print('  ⚠️  Event file not found. Skipping event generation.');
      return;
    }

    var content = await eventFile.readAsString();

    // Check if event already exists
    if (content.contains(config.eventName)) {
      _log('  ⚠️  Event already exists');
      return;
    }

    // Add event before the last closing brace
    final eventCode = UseCaseTypeTemplates.blocEvent(config);
    final lastBrace = content.lastIndexOf('}');

    if (lastBrace != -1) {
      content = content.substring(0, lastBrace) +
          eventCode +
          '\n${content.substring(lastBrace)}';
    }

    await eventFile.writeAsString(content);
    _log('  ✓ Added event to ${config.featureSnakeCase}_event.dart');
  }
}
