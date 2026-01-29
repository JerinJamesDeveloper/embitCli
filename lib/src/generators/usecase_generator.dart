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

      _log('📊 Updating BLoC state...');
      await _updateBlocState();
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
    if (content.contains('${config.repositoryMethodName}(') && !config.force) {
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

    if (content.contains('${config.repositoryMethodName}(') && !config.force) {
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
      return;
    }

    var content = await file.readAsString();
    if (content.contains('${config.repositoryMethodName}(') && !config.force) return;

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
  // ==================== UPDATE DI CONTAINER ====================

  Future<void> _updateDIContainer() async {
    final diFile =
        File('${config.projectPath}/lib/core/di/injection_container.dart');

    if (!diFile.existsSync()) {
      print('  ⚠️  injection_container.dart not found. Skipping DI update.');
      _printManualDIInstructions();
      return;
    }

    var content = await diFile.readAsString();

    // Check if already registered
    if (content.contains(config.useCaseClassName) && !config.force) {
      _log('  ⚠️  UseCase already registered in DI container');
      return;
    }

    // 1. Add Import
    final useCaseImport =
        "import '../../features/${config.featureSnakeCase}/domain/usecases/${config.useCaseSnakeCase}_usecase.dart';";

    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();

    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content =
          '${content.substring(0, lastImportEnd)}\n$useCaseImport${content.substring(lastImportEnd)}';
    }

    // 2. Add usecase registration to feature init function
    final featureFunctionName = '_init${config.featurePascalCase}Feature';
    final useCaseRegistration = '''
  sl.registerLazySingleton<${config.useCaseClassName}>(
    () => ${config.useCaseClassName}(sl()),
  );
''';

    // Find the feature init function
    final functionPattern = RegExp(
      'void $featureFunctionName\\(\\) \\{[\\s\\S]*?// ========== Use Cases ==========',
      multiLine: true,
    );

    final functionMatch = functionPattern.firstMatch(content);

    if (functionMatch != null) {
      final insertPosition = functionMatch.end;
      content = content.substring(0, insertPosition) +
          '\n$useCaseRegistration' +
          content.substring(insertPosition);
    } else {
      print('  ⚠️  Could not find feature init function. Add manually.');
      _printManualDIInstructions();
      await diFile.writeAsString(content); // Save import at least
      return;
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
    if (content.contains('_${config.useCaseCamelCase}UseCase') && !config.force) {
      _log('  ⚠️  UseCase already added to BLoC');
      return;
    }

    // 1. Add import
    final useCaseImport =
        "import '../../domain/usecases/${config.useCaseSnakeCase}_usecase.dart';";
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();

    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content =
          '${content.substring(0, lastImportEnd)}\n$useCaseImport${content.substring(lastImportEnd)}';
    }

    // 2. Add field (insert at start of class)
    final classMarker = 'class ${config.blocName} extends Bloc<';
    final classIndex = content.indexOf(classMarker);

    if (classIndex != -1) {
      final braceIndex = content.indexOf('{', classIndex);
      if (braceIndex != -1) {
        final newField =
            '\n  final ${config.useCaseClassName} _${config.useCaseCamelCase}UseCase;';
        content = content.substring(0, braceIndex + 1) +
            newField +
            content.substring(braceIndex + 1);
      }
    }

    // 3. Add constructor parameter (insert at start of constructor)
    final constructorMarker = '${config.blocName}({';
    final constructorIndex = content.indexOf(constructorMarker);

    if (constructorIndex != -1) {
      final insertIndex = constructorIndex + constructorMarker.length;
      final newParam =
          '\n    required ${config.useCaseClassName} ${config.useCaseCamelCase}UseCase,';
      content = content.substring(0, insertIndex) +
          newParam +
          content.substring(insertIndex);
    }

    // 4. Add initializer (insert at start of initializer list)
    // Find ") :" which starts the initializer list
    final initializerPattern = RegExp(r'\)\s*:');
    final initMatch = initializerPattern.firstMatch(content);

    if (initMatch != null) {
      final insertIndex = initMatch.end;
      final newInit =
          ' _${config.useCaseCamelCase}UseCase = ${config.useCaseCamelCase}UseCase,';
      content = content.substring(0, insertIndex) +
          newInit +
          content.substring(insertIndex);
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

     5. Register event (if using --with-event):
        on<${config.eventName}>(_on${config.useCasePascalCase});

     6. Add handler method (if using --with-event):
        Future<void> _on${config.useCasePascalCase}(...) async { ... }
''');
  }


    // ==================== UPDATE BLOC STATE ====================

  Future<void> _updateBlocState() async {
    // Only needed for operations that use the enum
    final enumValue = UseCaseTypeTemplates.stateOperationEnumValue(config);
    if (enumValue == null) {
      _log('  ⚠️  State update not needed for this usecase type');
      return;
    }

    final stateFilePath = '${config.projectPath}/${config.blocPath}/${config.featureSnakeCase}_state.dart';
    final stateFile = File(stateFilePath);

    if (!stateFile.existsSync()) {
      print('  ⚠️  State file not found. Skipping state update.');
      return;
    }

    var content = await stateFile.readAsString();

    // Check if operation already exists
    if (content.contains('${config.useCaseCamelCase},') && !config.force) {
      _log('  ⚠️  Operation "${config.useCaseCamelCase}" already exists in state');
      return;
    }

    // Find the enum and add the new operation
    // Pattern: "enum FeatureOperation {"
    final enumPattern = 'enum ${config.featurePascalCase}Operation {';
    final enumIndex = content.indexOf(enumPattern);

    if (enumIndex != -1) {
      // Find the opening brace
      final braceIndex = content.indexOf('{', enumIndex);
      if (braceIndex != -1) {
        // Insert right after the opening brace
        content = content.substring(0, braceIndex + 1) +
            '\n$enumValue' +
            content.substring(braceIndex + 1);

        await stateFile.writeAsString(content);
        _log('  ✓ Added operation "${config.useCaseCamelCase}" to ${config.featurePascalCase}Operation enum');
      }
    } else {
      _log('  ⚠️  Could not find ${config.featurePascalCase}Operation enum');
    }
  }

  // ==================== ADD BLOC EVENT ====================

  Future<void> _addBlocEvent() async {
    // 1. Add Event to Event File
    await _addEventToEventFile();

    // 2. Add Handler to BLoC File
    await _addHandlerToBlocFile();

    // 3. Register Event in BLoC Constructor
    await _registerEventInBlocConstructor();
  }

  Future<void> _addEventToEventFile() async {
    final eventFile = File('${config.projectPath}/${config.eventFilePath}');

    if (!eventFile.existsSync()) {
      print('  ⚠️  Event file not found. Skipping event generation.');
      return;
    }

    var content = await eventFile.readAsString();

    // Check if event already exists
    if (content.contains(config.eventName) && !config.force) {
      _log('  ⚠️  Event already exists');
      return;
    }

    // Add event before the last closing brace (but we need to be careful)
    // Events file doesn't have a class wrapper, just individual event classes
    // So we append at the end of the file
    final eventCode = UseCaseTypeTemplates.blocEvent(config);

    content = content + eventCode;

    await eventFile.writeAsString(content);
    _log('  ✓ Added event to ${config.featureSnakeCase}_event.dart');
  }

  Future<void> _addHandlerToBlocFile() async {
    final blocFile = File('${config.projectPath}/${config.blocFilePath}');

    if (!blocFile.existsSync()) {
      print('  ⚠️  BLoC file not found. Skipping handler generation.');
      return;
    }

    var content = await blocFile.readAsString();

    final handlerName = '_on${config.useCasePascalCase}';

    // Check if handler already exists
    if (content.contains(handlerName) && !config.force) {
      _log('  ⚠️  Handler already exists');
      return;
    }

    // Add handler before the last closing brace of the class
    final handlerCode = UseCaseTypeTemplates.blocEventHandler(config);

    final lastBrace = content.lastIndexOf('}');
    if (lastBrace != -1) {
      content = content.substring(0, lastBrace) +
          handlerCode +
          '\n${content.substring(lastBrace)}';
    }

    await blocFile.writeAsString(content);
    _log('  ✓ Added handler to ${config.featureSnakeCase}_bloc.dart');
  }

  Future<void> _registerEventInBlocConstructor() async {
    final blocFile = File('${config.projectPath}/${config.blocFilePath}');

    if (!blocFile.existsSync()) {
      return;
    }

    var content = await blocFile.readAsString();

    final eventRegistration = UseCaseTypeTemplates.blocEventRegistration(config);

    // Check if already registered
    if (content.contains('on<${config.eventName}>') && !config.force) {
      _log('  ⚠️  Event already registered in constructor');
      return;
    }

    // Find the constructor and the last "on<" registration
    // We need to insert after the last "on<...>(...)" line

    // Strategy: Find "super(" and insert before it
    final superIndex = content.indexOf('super(const ${config.featurePascalCase}Initial())');

    if (superIndex != -1) {
      // Find the end of super() call - look for the closing ");"
      final superEndSearch = content.indexOf(') {', superIndex);

      if (superEndSearch != -1) {
        // Find the last on<> before the first handler method
        // We look for pattern: on<...>(...);
        final constructorBodyStart = superEndSearch + 3; // after ") {"

        // Find where to insert - after the last existing "on<" line
        // Look for the pattern "on<" within the constructor body
        final lastOnIndex = content.lastIndexOf(RegExp(r'on<\w+>\([^)]+\);'), constructorBodyStart + 500);

        if (lastOnIndex != -1) {
          // Find end of this line
          final lineEnd = content.indexOf(';', lastOnIndex) + 1;
          content = content.substring(0, lineEnd) +
              '\n$eventRegistration' +
              content.substring(lineEnd);
        } else {
          // No existing on<> found, insert after the opening brace
          content = content.substring(0, constructorBodyStart) +
              '\n$eventRegistration' +
              content.substring(constructorBodyStart);
        }

        await blocFile.writeAsString(content);
        _log('  ✓ Registered event in BLoC constructor');
      }
    }
  }
}
