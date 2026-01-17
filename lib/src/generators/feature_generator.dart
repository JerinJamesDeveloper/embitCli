/// Feature Generator
/// 
/// Generates all files for a new feature.
library;

import 'dart:io';

import '../models/feature_config.dart';
import '../templates/bloc_templates.dart';
import '../templates/datasource_templates.dart';
import '../templates/di_templates.dart';
import '../templates/entity_templates.dart';
import '../templates/model_templates.dart';
import '../templates/page_templates.dart';
import '../templates/repository_templates.dart';
import '../templates/route_templates.dart';
import '../templates/usecase_templates.dart';
import '../templates/widget_templates.dart';

/// Generates feature files
class FeatureGenerator {
  final FeatureConfig config;
  final bool verbose;

  FeatureGenerator(this.config, {this.verbose = false});

  /// Generate all feature files
  Future<void> generate() async {
    _log('📁 Creating directory structure...');
    await _createDirectoryStructure();

    _log('📝 Generating domain layer...');
    await _generateDomainLayer();

    _log('📝 Generating data layer...');
    await _generateDataLayer(); 

    _log('📝 Generating presentation layer...');
    await _generatePresentationLayer();

    _log('🔧 Updating DI container...');
    await _updateDIContainer();

    _log('🛣️ Updating routes...');
    await _updateRoutes();

    _log('🔗 Updating API endpoints...');
    await _updateApiEndpoints();

    // If nav bar route, update role_based_navigator.dart
    if (config.isNavBarRoute) {
      _log('🧭 Updating navigation bar...');
      await _updateRoleBasedNavigator();
    }

    print('✅ Feature "${config.name}" generated successfully!');
  }

  void _log(String message) {
    if (verbose) {
      print(message);
    }
  }

  // ==================== DIRECTORY STRUCTURE ====================

  Future<void> _createDirectoryStructure() async {
    final directories = [
      // Domain
      '${config.domainPath}/entities',
      '${config.domainPath}/repositories',
      '${config.domainPath}/usecases',
      // Data
      '${config.dataPath}/datasources',
      '${config.dataPath}/models',
      '${config.dataPath}/repositories',
      // Presentation
      '${config.presentationPath}/bloc',
      '${config.presentationPath}/pages',
      '${config.presentationPath}/widgets',
    ];

    for (final dir in directories) {
      final directory = Directory('${config.projectPath}/$dir');
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
        _log('  ✓ Created $dir');
      }
    }
  }

  // ==================== DOMAIN LAYER ====================

  Future<void> _generateDomainLayer() async {
    // Entity
    await _writeFile(
      '${config.domainPath}/entities/${config.snakeCase}_entity.dart',
      EntityTemplates.entity(config),
    );

    // Repository interface
    await _writeFile(
      '${config.domainPath}/repositories/${config.snakeCase}_repository.dart',
      RepositoryTemplates.repositoryInterface(config),
    );

    // Use cases
    await _writeFile(
      '${config.domainPath}/usecases/get_${config.snakeCase}_usecase.dart',
      UseCaseTemplates.getUseCase(config),
    );

    await _writeFile(
      '${config.domainPath}/usecases/get_all_${config.snakeCase}s_usecase.dart',
      UseCaseTemplates.getAllUseCase(config),
    );

    await _writeFile(
      '${config.domainPath}/usecases/create_${config.snakeCase}_usecase.dart',
      UseCaseTemplates.createUseCase(config),
    );

    await _writeFile(
      '${config.domainPath}/usecases/update_${config.snakeCase}_usecase.dart',
      UseCaseTemplates.updateUseCase(config),
    );

    await _writeFile(
      '${config.domainPath}/usecases/delete_${config.snakeCase}_usecase.dart',
      UseCaseTemplates.deleteUseCase(config),
    );
  }

  // ==================== DATA LAYER ====================

  Future<void> _generateDataLayer() async {
    // Model
    await _writeFile(
      '${config.dataPath}/models/${config.snakeCase}_model.dart',
      ModelTemplates.model(config),
    );

    // Remote data source
    await _writeFile(
      '${config.dataPath}/datasources/${config.snakeCase}_remote_datasource.dart',
      DataSourceTemplates.remoteDataSource(config),
    );

    // Local data source
    await _writeFile(
      '${config.dataPath}/datasources/${config.snakeCase}_local_datasource.dart',
      DataSourceTemplates.localDataSource(config),
    );

    // Repository implementation
    await _writeFile(
      '${config.dataPath}/repositories/${config.snakeCase}_repository_impl.dart',
      RepositoryTemplates.repositoryImpl(config),
    );
  }

  // ==================== PRESENTATION LAYER ====================

  Future<void> _generatePresentationLayer() async {
    // Bloc
    await _writeFile(
      '${config.presentationPath}/bloc/${config.snakeCase}_bloc.dart',
      BlocTemplates.bloc(config),
    );

    await _writeFile(
      '${config.presentationPath}/bloc/${config.snakeCase}_event.dart',
      BlocTemplates.events(config),
    );

    await _writeFile(
      '${config.presentationPath}/bloc/${config.snakeCase}_state.dart',
      BlocTemplates.states(config),
    );

    // Pages
    await _writeFile(
      '${config.presentationPath}/pages/${config.snakeCase}_page.dart',
      PageTemplates.page(config),
    );

    await _writeFile(
      '${config.presentationPath}/pages/${config.snakeCase}_detail_page.dart',
      PageTemplates.detailPage(config),
    );

    // Widgets
    await _writeFile(
      '${config.presentationPath}/widgets/${config.snakeCase}_list_widget.dart',
      WidgetTemplates.listWidget(config),
    );

    await _writeFile(
      '${config.presentationPath}/widgets/${config.snakeCase}_item_widget.dart',
      WidgetTemplates.itemWidget(config),
    );
  }

  // ==================== DI CONTAINER ====================

  Future<void> _updateDIContainer() async {
    final diFile = File('${config.projectPath}/lib/core/di/injection_container.dart');

    if (!diFile.existsSync()) {
      print('  ⚠️ injection_container.dart not found. Skipping DI update.');
      _printManualDIInstructions();
      return;
    }

    var content = await diFile.readAsString();

    // Check if feature is already registered
    if (content.contains('_init${config.pascalCase}Feature')) {
      _log('  ⚠️ Feature already registered in DI container');
      return;
    }

    // Add imports
    final imports = DITemplates.featureImports(config, config.projectName);

    // Find the last import line
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();
    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content = '${content.substring(0, lastImportEnd)}\n$imports${content.substring(lastImportEnd)}';
    }

    // Add feature init function
    final registration = DITemplates.featureRegistration(config);

    // Find the END OF FEATURE marker
    const endMarker = '// ==================== END OF FEATURE ====================';
    final index = content.lastIndexOf(endMarker);

    if (index != -1) {
      final insertPos = index + endMarker.length;
      content = '${content.substring(0, insertPos)}\n\n$registration${content.substring(insertPos)}';
    } else {
      // Fallback: add before the last closing brace
      final lastBrace = content.lastIndexOf('}');
      if (lastBrace != -1) {
        content = '${content.substring(0, lastBrace)}\n$registration\n${content.substring(lastBrace)}';
      }
    }

    // Add call to initDependencies
    final initCall = DITemplates.featureInitCall(config);
    final initDepsRegex = RegExp(r'(Future<void> initDependencies\(\) async \{[^}]+)(})');
    content = content.replaceFirstMapped(initDepsRegex, (match) {
      final existingContent = match.group(1)!;
      if (existingContent.contains('_init${config.pascalCase}Feature')) {
        return match.group(0)!;
      }
      return '$existingContent\n$initCall\n${match.group(2)}';
    });

    await diFile.writeAsString(content);
    _log('  ✓ Updated injection_container.dart');
  }

  void _printManualDIInstructions() {
    print('     Please add the following manually:');
    print(DITemplates.featureImports(config, config.projectName));
    print(DITemplates.featureRegistration(config));
  }

  // ==================== ROUTES ====================

  Future<void> _updateRoutes() async {
    await _updateRouteNames();
    await _updateAppRouter();
  }

  Future<void> _updateRouteNames() async {
    final routeNamesFile = File('${config.projectPath}/lib/navigation/route_names.dart');
    if (!routeNamesFile.existsSync()) {
      _log('  ⚠️ route_names.dart not found');
      return;
    }

    var content = await routeNamesFile.readAsString();

    // Check if routes already exist
    if (content.contains("${config.camelCase} = '${config.routePath}'")) {
      _log('  ⚠️ Routes already exist in route_names.dart');
      return;
    }

    // Add to RoutePaths class
    final routePathsMarker = '// ============== ADD YOUR ROUTES ==============';
    final routePathsIndex = content.indexOf(routePathsMarker);
    if (routePathsIndex != -1) {
      content = content.substring(0, routePathsIndex) +
          RouteTemplates.routePaths(config) +
          '\n  $routePathsMarker' +
          content.substring(routePathsIndex + routePathsMarker.length);
    } else {
      // Fallback: find end of RoutePaths class
      final routePathsEnd = content.indexOf('}', content.indexOf('class RoutePaths'));
      if (routePathsEnd != -1) {
        content = content.substring(0, routePathsEnd) +
            RouteTemplates.routePaths(config) +
            content.substring(routePathsEnd);
      }
    }

    // Add to RouteNames class
    final routeNamesMarker = '// ============== ADD YOUR ROUTE NAMES ==============';
    final routeNamesIndex = content.indexOf(routeNamesMarker);
    if (routeNamesIndex != -1) {
      content = content.substring(0, routeNamesIndex) +
          RouteTemplates.routeNames(config) +
          '\n  $routeNamesMarker' +
          content.substring(routeNamesIndex + routeNamesMarker.length);
    } else {
      // Fallback: find end of RouteNames class
      final routeNamesEnd = content.indexOf('}', content.indexOf('class RouteNames'));
      if (routeNamesEnd != -1) {
        content = content.substring(0, routeNamesEnd) +
            RouteTemplates.routeNames(config) +
            content.substring(routeNamesEnd);
      }
    }

    await routeNamesFile.writeAsString(content);
    _log('  ✓ Updated route_names.dart');
  }

  Future<void> _updateAppRouter() async {
    final appRouterFile = File('${config.projectPath}/lib/navigation/app_router.dart');
    if (!appRouterFile.existsSync()) {
      _log('  ⚠️ app_router.dart not found');
      return;
    }

    var content = await appRouterFile.readAsString();

    // Check if routes already exist
    if (content.contains('${config.pascalCase}Page')) {
      _log('  ⚠️ Routes already exist in app_router.dart');
      return;
    }

    // Add import
    final pageImport = RouteTemplates.pageImport(config, config.projectName);
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();
    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content = '${content.substring(0, lastImportEnd)}\n$pageImport${content.substring(lastImportEnd)}';
    }

    // Determine where to add the route
    if (config.isNavBarRoute) {
      // Add inside ShellRoute (MainShell)
      content = _addRouteToShellRoute(content);
    } else {
      // Add as standalone route before error routes
      content = _addStandaloneRoute(content);
    }

    await appRouterFile.writeAsString(content);
    _log('  ✓ Updated app_router.dart');
  }

  String _addRouteToShellRoute(String content) {
    // Find MainShell section
    final mainShellStart = content.indexOf('MainShell(child: child)');
    if (mainShellStart == -1) {
      _log('  ⚠️ Could not find MainShell - adding as standalone route');
      return _addStandaloneRoute(content);
    }

    // Find the routes: [ for this ShellRoute
    final routesStart = content.indexOf('routes: [', mainShellStart);
    if (routesStart == -1) {
      return _addStandaloneRoute(content);
    }

    // Find the closing of routes array
    var bracketCount = 0;
    var inRoutes = false;
    var routesEnd = -1;

    for (var i = routesStart; i < content.length; i++) {
      if (content[i] == '[') {
        if (!inRoutes) inRoutes = true;
        bracketCount++;
      } else if (content[i] == ']') {
        bracketCount--;
        if (bracketCount == 0 && inRoutes) {
          routesEnd = i;
          break;
        }
      }
    }

    if (routesEnd == -1) {
      return _addStandaloneRoute(content);
    }

    // Find the last ")," before the closing "]"
    final insertPoint = content.lastIndexOf('),', routesEnd);
    
    if (insertPoint != -1 && insertPoint > routesStart) {
      final routeEntry = RouteTemplates.shellRouteEntry(config);
      content = '${content.substring(0, insertPoint + 2)}\n$routeEntry${content.substring(insertPoint + 2)}';
    }

    return content;
  }

  String _addStandaloneRoute(String content) {
    final routeEntry = RouteTemplates.goRouteEntries(config);

    // Find the error routes section
    final errorRouteIndex = content.indexOf('// ============== ERROR ROUTES');
    if (errorRouteIndex != -1) {
      var insertPoint = errorRouteIndex;
      
      // Search backwards for "),"
      for (var i = errorRouteIndex - 1; i >= 0; i--) {
        if (i + 2 <= content.length && content.substring(i, i + 2) == '),') {
          insertPoint = i + 2;
          break;
        }
      }

      content = content.substring(0, insertPoint) +
          '\n\n        // ============== ${config.pascalCase.toUpperCase()} ROUTES ==============\n' +
          routeEntry +
          content.substring(insertPoint);
    }

    return content;
  }

  // ==================== API ENDPOINTS ====================

  Future<void> _updateApiEndpoints() async {
    final apiFile = File('${config.projectPath}/lib/core/constants/api_endpoints.dart');
    if (!apiFile.existsSync()) {
      _log('  ⚠️ api_endpoints.dart not found');
      return;
    }

    var content = await apiFile.readAsString();

    // Check if endpoint already exists
    if (content.contains('${config.camelCase}s')) {
      _log('  ⚠️ API endpoints already exist');
      return;
    }

    // Find the ADD YOUR ENDPOINTS marker
    final marker = '// ============== ADD YOUR ENDPOINTS ==============';
    final markerIndex = content.indexOf(marker);
    
    if (markerIndex != -1) {
      content = content.substring(0, markerIndex) +
          RouteTemplates.apiEndpoint(config) +
          '\n  $marker' +
          content.substring(markerIndex + marker.length);
    } else {
      // Fallback: add before last closing brace
      final classEnd = content.lastIndexOf('}');
      if (classEnd != -1) {
        content = content.substring(0, classEnd) +
            RouteTemplates.apiEndpoint(config) +
            content.substring(classEnd);
      }
    }

    await apiFile.writeAsString(content);
    _log('  ✓ Updated api_endpoints.dart');
  }

  // ==================== ROLE BASED NAVIGATOR ====================

  Future<void> _updateRoleBasedNavigator() async {
    final navFile = File('${config.projectPath}/lib/navigation/role_based_navigator.dart');
    if (!navFile.existsSync()) {
      _log('  ⚠️ role_based_navigator.dart not found');
      return;
    }

    var content = await navFile.readAsString();

    // Check if already added
    if (content.contains("route: '${config.routePath}'")) {
      _log('  ⚠️ Nav item already exists in role_based_navigator.dart');
      return;
    }

    // 1. Add to _userNavItems
    content = _addNavItem(content);

    // 2. Add to canAccessRoute public routes
    content = _addToPublicRoutes(content);

    await navFile.writeAsString(content);
    _log('  ✓ Updated role_based_navigator.dart');
  }

  String _addNavItem(String content) {
    // Find the _userNavItems list
    final navItemsPattern = RegExp(
      r'static const List<NavItem> _userNavItems = \[',
      multiLine: true,
    );

    final match = navItemsPattern.firstMatch(content);
    if (match == null) {
      _log('  ⚠️ Could not find _userNavItems');
      return content;
    }

    // Find the closing of the list
    final listStart = match.end;
    var bracketCount = 1;
    var listEnd = listStart;

    for (var i = listStart; i < content.length; i++) {
      if (content[i] == '[') {
        bracketCount++;
      } else if (content[i] == ']') {
        bracketCount--;
        if (bracketCount == 0) {
          listEnd = i;
          break;
        }
      }
    }

    // Find the last NavItem in the list
    final lastNavItemEnd = content.lastIndexOf('),', listEnd);
    if (lastNavItemEnd == -1 || lastNavItemEnd < listStart) {
      return content;
    }

    // Create new NavItem
    final navItem = RouteTemplates.navItem(config);

    // Insert after the last NavItem
    content = content.substring(0, lastNavItemEnd + 2) +
        '\n$navItem' +
        content.substring(lastNavItemEnd + 2);

    return content;
  }

  String _addToPublicRoutes(String content) {
    // Find the publicRoutes list in canAccessRoute
    final publicRoutesPattern = RegExp(
      r"const publicRoutes = \[\s*'[^']+',",
      multiLine: true,
    );

    final match = publicRoutesPattern.firstMatch(content);
    if (match == null) {
      _log('  ⚠️ Could not find publicRoutes');
      return content;
    }

    // Find the closing bracket of publicRoutes
    final listStart = match.start;
    var bracketCount = 0;
    var listEnd = listStart;
    var foundStart = false;

    for (var i = listStart; i < content.length; i++) {
      if (content[i] == '[') {
        foundStart = true;
        bracketCount++;
      } else if (content[i] == ']') {
        bracketCount--;
        if (foundStart && bracketCount == 0) {
          listEnd = i;
          break;
        }
      }
    }

    // Find the last route entry
    final lastRouteEnd = content.lastIndexOf("',", listEnd);
    if (lastRouteEnd == -1 || lastRouteEnd < listStart) {
      return content;
    }

    // Add new route
    final newRoute = "\n      '${config.routePath}',";

    content = content.substring(0, lastRouteEnd + 2) +
        newRoute +
        content.substring(lastRouteEnd + 2);

    return content;
  }

  // ==================== HELPER ====================

  Future<void> _writeFile(String relativePath, String content) async {
    final file = File('${config.projectPath}/$relativePath');
    
    if (file.existsSync() && !config.force) {
      _log('  ⚠️ Skipped (exists): $relativePath');
      return;
    }

    await file.writeAsString(content);
    _log('  ✓ Created $relativePath');
  }
}