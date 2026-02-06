/// Schema Feature Generator
///
/// Generates complete feature from JSON schema including all usecases.
library;

import 'dart:io';

import '../models/schema/schema_models.dart';
import '../models/schema/usecase_schema.dart';
import '../models/usecase_config.dart';
import '../templates/bloc_schema_templates.dart';
import '../templates/usecase_type_templates.dart';
import '../templates/page_schema_templates.dart';
import '../templates/entity_schema_templates.dart';
import '../templates/model_schema_templates.dart';
import '../templates/di_schema_templates.dart';
import '../templates/route_schema_templates.dart';

/// Generates complete feature from schema
class SchemaFeatureGenerator {
  final FeatureSchema schema;
  final String projectPath;
  final String projectName;
  final bool force;
  final bool skipDI;
  final bool skipRoutes;
  final bool verbose;

  /// Extracted usecases from schema
  late final List<UseCaseSchema> _usecases;

  /// UseCase configs for each extracted usecase
  late final List<UseCaseConfig> _usecaseConfigs;

  SchemaFeatureGenerator({
    required this.schema,
    required this.projectPath,
    required this.projectName,
    this.force = false,
    this.skipDI = false,
    this.skipRoutes = false,
    this.verbose = false,
  }) {
    // Extract usecases from schema
    _usecases = schema.extractUseCases();

    // Create configs for each usecase
    _usecaseConfigs = _usecases
        .map((uc) => schema.toUseCaseConfig(
              uc,
              projectName: projectName,
              projectPath: projectPath,
              force: force,
            ))
        .toList();
  }

  // ==================== PATHS ====================

  String get featurePath => '$projectPath/lib/features/${schema.snakeCase}';
  String get domainPath => '$featurePath/domain';
  String get dataPath => '$featurePath/data';
  String get presentationPath => '$featurePath/presentation';

  // ==================== GENERATE ====================

  /// Generate the complete feature
  Future<void> generate() async {
    _log(' Creating directories...');
    await _createDirectories();

    _log('📝 Generating domain layer...');
    await _generateDomainLayer();

    _log('📝 Generating data layer...');
    await _generateDataLayer();

    _log('📝 Generating presentation layer...');
    await _generatePresentationLayer();

    if (!skipDI) {
      _log('🔧 Updating DI container...');
      await _updateDIContainer();
    }

    if (!skipRoutes) {
      _log('🛣️ Updating routes...');
      await _updateRoutes();

      if (schema.addToBottomNav) {
        _log('🧭 Updating navigation bar...');
        await _updateNavigation();
      }
    }

    _log('🔗 Updating API endpoints...');
    await _updateApiEndpoints();

    if (schema.bottomSheets.isNotEmpty) {
      _log('📑 Generating bottom sheets...');
      await _generateBottomSheets();
    }

    print('');
    print('✅ Feature "${schema.name}" generated successfully!');
    _printSummary();
  }

  void _log(String message) {
    if (verbose) print(message);
  }

  // ==================== DIRECTORIES ====================

  Future<void> _createDirectories() async {
    final directories = [
      '$domainPath/entities',
      '$domainPath/repositories',
      '$domainPath/usecases',
      '$dataPath/datasources',
      '$dataPath/models',
      '$dataPath/repositories',
      '$presentationPath/bloc',
      '$presentationPath/pages',
      '$presentationPath/widgets',
    ];

    for (final dir in directories) {
      await Directory(dir).create(recursive: true);
      _log('   ✓ Created ${dir.replaceFirst(projectPath, '')}');
    }
  }

  // ==================== DOMAIN LAYER ====================

  Future<void> _generateDomainLayer() async {
    // Entity
    await _writeFile(
      '$domainPath/entities/${schema.snakeCase}_entity.dart',
      EntitySchemaTemplates.generate(schema, projectName),
    );

    // Repository interface with all methods
    await _writeFile(
      '$domainPath/repositories/${schema.snakeCase}_repository.dart',
      _generateRepositoryInterface(),
    );

    // Generate each usecase
    for (final config in _usecaseConfigs) {
      await _writeFile(
        '$domainPath/usecases/${config.useCaseSnakeCase}_usecase.dart',
        UseCaseTypeTemplates.generate(config),
      );
      _log('   ✓ Created usecase: ${config.useCaseClassName}');
    }
  }

  String _generateRepositoryInterface() {
    final methods = _usecaseConfigs
        .map((c) => UseCaseTypeTemplates.repositoryMethodSignature(c))
        .join('\n\n');

    return '''
/// ${schema.pascalCase} Repository Interface
///
/// Defines the contract for ${schema.pascalCase} data operations.
library;

import 'package:dartz/dartz.dart';

import 'package:$projectName/core/errors/failures.dart';
import '../entities/${schema.snakeCase}_entity.dart';

/// Repository interface for ${schema.pascalCase} feature
abstract class ${schema.pascalCase}Repository {
$methods
}
''';
  }

  // ==================== DATA LAYER ====================

  Future<void> _generateDataLayer() async {
    // Model
    await _writeFile(
      '$dataPath/models/${schema.snakeCase}_model.dart',
      ModelSchemaTemplates.generate(schema, projectName),
    );

    // Remote data source
    await _writeFile(
      '$dataPath/datasources/${schema.snakeCase}_remote_datasource.dart',
      _generateRemoteDataSource(),
    );

    // Local data source (optional)
    await _writeFile(
      '$dataPath/datasources/${schema.snakeCase}_local_datasource.dart',
      _generateLocalDataSource(),
    );

    // Repository implementation
    await _writeFile(
      '$dataPath/repositories/${schema.snakeCase}_repository_impl.dart',
      _generateRepositoryImpl(),
    );
  }

  String _generateRemoteDataSource() {
    // Generate interface methods
    final interfaceMethods = _usecaseConfigs
        .map((c) => UseCaseTypeTemplates.remoteDataSourceMethodSignature(c))
        .join('\n\n');

    // Generate implementation methods
    final implMethods = _usecaseConfigs
        .map((c) => UseCaseTypeTemplates.remoteDataSourceMethodImpl(c))
        .join('\n\n');

    return '''
/// ${schema.pascalCase} Remote Data Source
///
/// Handles API calls for ${schema.pascalCase} feature.
library;

import 'package:$projectName/core/constants/api_endpoints.dart';
import 'package:$projectName/core/network/dio_client.dart';
import '../models/${schema.snakeCase}_model.dart';

/// Remote data source interface for ${schema.pascalCase}
abstract class ${schema.pascalCase}RemoteDataSource {
$interfaceMethods
}

/// Implementation of ${schema.pascalCase}RemoteDataSource
class ${schema.pascalCase}RemoteDataSourceImpl implements ${schema.pascalCase}RemoteDataSource {
  final DioClient _dioClient;

  ${schema.pascalCase}RemoteDataSourceImpl(this._dioClient);

$implMethods
}
''';
  }

  String _generateLocalDataSource() {
    return '''
/// ${schema.pascalCase} Local Data Source
///
/// Handles local caching for ${schema.pascalCase} feature.
library;

import 'dart:convert';

import 'package:$projectName/core/storage/local_storage.dart';
import '../models/${schema.snakeCase}_model.dart';

/// Local data source interface for ${schema.pascalCase}
abstract class ${schema.pascalCase}LocalDataSource {
  /// Get cached ${schema.pascalCase}
  Future<${schema.pascalCase}Model?> getCached${schema.pascalCase}(String id);
  
  /// Cache ${schema.pascalCase}
  Future<void> cache${schema.pascalCase}(${schema.pascalCase}Model model);
  
  /// Get cached ${schema.pascalCase} list
  Future<List<${schema.pascalCase}Model>> getCached${schema.pascalCase}List();
  
  /// Cache ${schema.pascalCase} list
  Future<void> cache${schema.pascalCase}List(List<${schema.pascalCase}Model> models);
  
  /// Clear cache
  Future<void> clearCache();
}

/// Implementation of ${schema.pascalCase}LocalDataSource
class ${schema.pascalCase}LocalDataSourceImpl implements ${schema.pascalCase}LocalDataSource {
  final LocalStorage _storage;
  
  static const _cacheKey = '${schema.snakeCase}_cache';
  static const _listCacheKey = '${schema.snakeCase}_list_cache';

  ${schema.pascalCase}LocalDataSourceImpl(this._storage);

  @override
  Future<${schema.pascalCase}Model?> getCached${schema.pascalCase}(String id) async {
    final json = await _storage.getString('\${_cacheKey}_\$id');
    if (json == null) return null;
    return ${schema.pascalCase}Model.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> cache${schema.pascalCase}(${schema.pascalCase}Model model) async {
    await _storage.setString(
      '\${_cacheKey}_\${model.id}',
      jsonEncode(model.toJson()),
    );
  }

  @override
  Future<List<${schema.pascalCase}Model>> getCached${schema.pascalCase}List() async {
    final json = await _storage.getString(_listCacheKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ${schema.pascalCase}Model.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cache${schema.pascalCase}List(List<${schema.pascalCase}Model> models) async {
    await _storage.setString(
      _listCacheKey,
      jsonEncode(models.map((m) => m.toJson()).toList()),
    );
  }

  @override
  Future<void> clearCache() async {
    await _storage.remove(_listCacheKey);
    // Note: Individual item caches would need to be tracked separately
  }
}
''';
  }

  String _generateRepositoryImpl() {
    // Generate implementation methods
    final implMethods = _usecaseConfigs
        .map((c) => UseCaseTypeTemplates.repositoryMethodImpl(c))
        .join('\n\n');

    return '''
/// ${schema.pascalCase} Repository Implementation
///
/// Implements ${schema.pascalCase}Repository.
library;

import 'package:dartz/dartz.dart';

import 'package:$projectName/core/errors/exceptions.dart';
import 'package:$projectName/core/errors/failures.dart';
import 'package:$projectName/core/network/network_info.dart';
import '../../domain/entities/${schema.snakeCase}_entity.dart';
import '../../domain/repositories/${schema.snakeCase}_repository.dart';
import '../datasources/${schema.snakeCase}_remote_datasource.dart';
import '../datasources/${schema.snakeCase}_local_datasource.dart';

/// Implementation of ${schema.pascalCase}Repository
class ${schema.pascalCase}RepositoryImpl implements ${schema.pascalCase}Repository {
  final ${schema.pascalCase}RemoteDataSource _remoteDataSource;
  final ${schema.pascalCase}LocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ${schema.pascalCase}RepositoryImpl({
    required ${schema.pascalCase}RemoteDataSource remoteDataSource,
    required ${schema.pascalCase}LocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

$implMethods
}
''';
  }

  // ==================== PRESENTATION LAYER ====================

  Future<void> _generatePresentationLayer() async {
    // BLoC files
    await _writeFile(
      '$presentationPath/bloc/${schema.snakeCase}_bloc.dart',
      BlocSchemaTemplates.bloc(schema, _usecaseConfigs, projectName),
    );

    await _writeFile(
      '$presentationPath/bloc/${schema.snakeCase}_event.dart',
      BlocSchemaTemplates.events(schema, _usecaseConfigs, projectName),
    );

    await _writeFile(
      '$presentationPath/bloc/${schema.snakeCase}_state.dart',
      BlocSchemaTemplates.states(schema, _usecaseConfigs, projectName),
    );

    // Generate pages for each screen
    for (final screen in schema.screens) {
      await _writeFile(
        '$presentationPath/pages/${_toSnakeCase(screen.name)}_page.dart',
        PageSchemaTemplates.generate(screen, schema, projectName),
      );
      _log('   ✓ Created page: ${screen.name}Page');
    }

    // Generate common widgets
    await _writeFile(
      '$presentationPath/widgets/${schema.snakeCase}_list_item.dart',
      _generateListItemWidget(),
    );

    await _writeFile(
      '$presentationPath/widgets/${schema.snakeCase}_loading.dart',
      _generateLoadingWidget(),
    );

    await _writeFile(
      '$presentationPath/widgets/${schema.snakeCase}_error.dart',
      _generateErrorWidget(),
    );

    // Generate bottom sheets
    if (schema.bottomSheets.isNotEmpty) {
      await _generateBottomSheets();
    }
  }

  Future<void> _generateBottomSheets() async {
    for (final bs in schema.bottomSheets) {
      final name = bs['name'] as String;
      final snakeName = _toSnakeCase(name);
      await _writeFile(
        '$presentationPath/widgets/${snakeName}_bottom_sheet.dart',
        _generateBottomSheetTemplate(bs),
      );
    }
  }

  String _generateBottomSheetTemplate(Map<String, dynamic> bs) {
    final name = bs['name'] as String;
    final pascalName = _toFeaturePascalCase(name);
    return '''
import 'package:flutter/material.dart';

class ${pascalName}BottomSheet extends StatelessWidget {
  const ${pascalName}BottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$name', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // TODO: Add bottom sheet content
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

Future<T?> show${pascalName}BottomSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const ${pascalName}BottomSheet(),
  );
}
''';
  }

  static String _toFeaturePascalCase(String input) {
    return input.split('_').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join();
  }

  String _generateListItemWidget() {
    return '''
/// ${schema.pascalCase} List Item Widget
library;

import 'package:flutter/material.dart';

import '../../domain/entities/${schema.snakeCase}_entity.dart';

/// Displays a single ${schema.pascalCase} item in a list
class ${schema.pascalCase}ListItem extends StatelessWidget {
  final ${schema.pascalCase}Entity item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ${schema.pascalCase}ListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(item.id), // TODO: Replace with actual title field
        subtitle: Text('Created: \${item.createdAt}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
''';
  }

  String _generateLoadingWidget() {
    return '''
/// ${schema.pascalCase} Loading Widget
library;

import 'package:flutter/material.dart';

/// Loading indicator for ${schema.pascalCase} feature
class ${schema.pascalCase}Loading extends StatelessWidget {
  final String? message;

  const ${schema.pascalCase}Loading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
''';
  }

  String _generateErrorWidget() {
    return '''
/// ${schema.pascalCase} Error Widget
library;

import 'package:flutter/material.dart';

/// Error display for ${schema.pascalCase} feature
class ${schema.pascalCase}Error extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ${schema.pascalCase}Error({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
''';
  }

  // ==================== DI CONTAINER ====================

  Future<void> _updateDIContainer() async {
    final diFile = File('$projectPath/lib/core/di/injection_container.dart');

    if (!diFile.existsSync()) {
      _log('   ⚠️ injection_container.dart not found');
      return;
    }

    var content = await diFile.readAsString();

    // Check if already registered
    if (content.contains('_init${schema.pascalCase}Feature') && !force) {
      _log('   ⚠️ Feature already registered in DI');
      return;
    }

    // Generate DI code
    final imports =
        DISchemaTemplates.imports(schema, _usecaseConfigs, projectName);
    final registration = DISchemaTemplates.featureRegistration(
        schema, _usecaseConfigs, projectName);

    // Add imports
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();
    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content =
          '${content.substring(0, lastImportEnd)}\n$imports${content.substring(lastImportEnd)}';
    }

    // Add registration function
    const endMarker =
        '// ==================== END OF FEATURE ====================';
    final markerIndex = content.lastIndexOf(endMarker);
    if (markerIndex != -1) {
      final insertPos = markerIndex + endMarker.length;
      content =
          '${content.substring(0, insertPos)}\n\n$registration${content.substring(insertPos)}';
    } else {
      // Fallback
      final lastBrace = content.lastIndexOf('}');
      if (lastBrace != -1) {
        content =
            '${content.substring(0, lastBrace)}\n$registration\n${content.substring(lastBrace)}';
      }
    }

    // Add init call
    final initCall = '  _init${schema.pascalCase}Feature();';
    final initDepsRegex =
        RegExp(r'(Future<void> initDependencies\(\) async \{[^}]+)(})');
    content = content.replaceFirstMapped(initDepsRegex, (match) {
      final existingContent = match.group(1)!;
      if (existingContent.contains('_init${schema.pascalCase}Feature')) {
        return match.group(0)!;
      }
      return '$existingContent\n$initCall\n${match.group(2)}';
    });

    await diFile.writeAsString(content);
    _log('   ✓ Updated injection_container.dart');
  }

  // ==================== ROUTES ====================

  Future<void> _updateRoutes() async {
    await _updateRouteNames();
    await _updateAppRouter();
  }

  Future<void> _updateRouteNames() async {
    final routeNamesFile = File('$projectPath/lib/navigation/route_names.dart');
    if (!routeNamesFile.existsSync()) {
      _log('   ⚠️ route_names.dart not found');
      return;
    }

    var content = await routeNamesFile.readAsString();

    if (content.contains("${schema.camelCase} = '/${schema.snakeCase}'") &&
        !force) {
      _log('   ⚠️ Routes already exist');
      return;
    }

    // Generate route entries
    final routePaths = RouteSchemaTemplates.routePaths(schema);
    final routeNames = RouteSchemaTemplates.routeNames(schema);

    // Add to RoutePaths
    final routePathsMarker = '// ============== ADD YOUR ROUTES ==============';
    var routePathsIndex = content.indexOf(routePathsMarker);
    if (routePathsIndex != -1) {
      content = content.substring(0, routePathsIndex) +
          routePaths +
          '\n  $routePathsMarker' +
          content.substring(routePathsIndex + routePathsMarker.length);
    }

    // Add to RouteNames
    final routeNamesMarker =
        '// ============== ADD YOUR ROUTE NAMES ==============';
    var routeNamesIndex = content.indexOf(routeNamesMarker);
    if (routeNamesIndex != -1) {
      content = content.substring(0, routeNamesIndex) +
          routeNames +
          '\n  $routeNamesMarker' +
          content.substring(routeNamesIndex + routeNamesMarker.length);
    }

    await routeNamesFile.writeAsString(content);
    _log('   ✓ Updated route_names.dart');
  }

  Future<void> _updateAppRouter() async {
    final appRouterFile = File('$projectPath/lib/navigation/app_router.dart');
    if (!appRouterFile.existsSync()) {
      _log('   ⚠️ app_router.dart not found');
      return;
    }

    var content = await appRouterFile.readAsString();

    if (content.contains('${schema.pascalCase}') && !force) {
      _log('   ⚠️ Routes already exist in app_router.dart');
      return;
    }

    // Add imports
    final imports = RouteSchemaTemplates.pageImports(schema, projectName);
    final importRegex = RegExp(r"import '[^']+';");
    final matches = importRegex.allMatches(content).toList();
    if (matches.isNotEmpty) {
      final lastImportEnd = matches.last.end;
      content =
          '${content.substring(0, lastImportEnd)}\n$imports${content.substring(lastImportEnd)}';
    }

    // Add routes
    final routes = schema.addToBottomNav
        ? RouteSchemaTemplates.shellRouteEntries(schema)
        : RouteSchemaTemplates.standaloneRouteEntries(schema);

    if (schema.addToBottomNav) {
      // Add to ShellRoute (MainShell)
      content = _addToShellRoute(content, routes);
    } else {
      // Add before error routes
      content = _addBeforeErrorRoutes(content, routes);
    }

    await appRouterFile.writeAsString(content);
    _log('   ✓ Updated app_router.dart');
  }

  String _addToShellRoute(String content, String routes) {
    final mainShellStart = content.indexOf('MainShell(child: child)');
    if (mainShellStart == -1) return _addBeforeErrorRoutes(content, routes);

    final routesStart = content.indexOf('routes: [', mainShellStart);
    if (routesStart == -1) return _addBeforeErrorRoutes(content, routes);

    // Find the closing bracket
    var bracketCount = 0;
    var inRoutes = false;
    var routesEnd = -1;

    for (var i = routesStart; i < content.length; i++) {
      if (content[i] == '[') {
        inRoutes = true;
        bracketCount++;
      } else if (content[i] == ']') {
        bracketCount--;
        if (bracketCount == 0 && inRoutes) {
          routesEnd = i;
          break;
        }
      }
    }

    if (routesEnd == -1) return _addBeforeErrorRoutes(content, routes);

    final insertPoint = content.lastIndexOf('),', routesEnd);
    if (insertPoint != -1 && insertPoint > routesStart) {
      content = content.substring(0, insertPoint + 2) +
          '\n$routes' +
          content.substring(insertPoint + 2);
    }

    return content;
  }

  String _addBeforeErrorRoutes(String content, String routes) {
    final errorRouteIndex = content.indexOf('// ============== ERROR ROUTES');
    if (errorRouteIndex != -1) {
      var insertPoint = errorRouteIndex;
      for (var i = errorRouteIndex - 1; i >= 0; i--) {
        if (i + 2 <= content.length && content.substring(i, i + 2) == '),') {
          insertPoint = i + 2;
          break;
        }
      }

      content = content.substring(0, insertPoint) +
          '\n\n        // ============== ${schema.pascalCase.toUpperCase()} ROUTES ==============\n' +
          routes +
          content.substring(insertPoint);
    }
    return content;
  }

  // ==================== NAVIGATION ====================

  Future<void> _updateNavigation() async {
    final navFile =
        File('$projectPath/lib/navigation/role_based_navigator.dart');
    if (!navFile.existsSync()) {
      _log('   ⚠️ role_based_navigator.dart not found');
      return;
    }

    var content = await navFile.readAsString();

    if (content.contains("route: '/${schema.snakeCase}'") && !force) {
      _log('   ⚠️ Nav item already exists');
      return;
    }

    // Add NavItem
    final navItem = RouteSchemaTemplates.navItem(schema);
    final navItemsPattern = RegExp(
      r'static const List<NavItem> _userNavItems = \[',
      multiLine: true,
    );

    final match = navItemsPattern.firstMatch(content);
    if (match != null) {
      final listStart = match.end;
      var bracketCount = 1;
      var listEnd = listStart;

      for (var i = listStart; i < content.length; i++) {
        if (content[i] == '[')
          bracketCount++;
        else if (content[i] == ']') {
          bracketCount--;
          if (bracketCount == 0) {
            listEnd = i;
            break;
          }
        }
      }

      final lastNavItemEnd = content.lastIndexOf('),', listEnd);
      if (lastNavItemEnd != -1 && lastNavItemEnd >= listStart) {
        content = content.substring(0, lastNavItemEnd + 2) +
            '\n$navItem' +
            content.substring(lastNavItemEnd + 2);
      }
    }

    // Add to public routes
    final publicRoutesPattern = RegExp(
      r"const publicRoutes = \[\s*'[^']+',",
      multiLine: true,
    );

    final publicMatch = publicRoutesPattern.firstMatch(content);
    if (publicMatch != null) {
      final listStart = publicMatch.start;
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

      final lastRouteEnd = content.lastIndexOf("',", listEnd);
      if (lastRouteEnd != -1 && lastRouteEnd >= listStart) {
        content = content.substring(0, lastRouteEnd + 2) +
            "\n      '/${schema.snakeCase}'," +
            content.substring(lastRouteEnd + 2);
      }
    }

    await navFile.writeAsString(content);
    _log('   ✓ Updated role_based_navigator.dart');
  }

  // ==================== API ENDPOINTS ====================

  Future<void> _updateApiEndpoints() async {
    final apiFile = File('$projectPath/lib/core/constants/api_endpoints.dart');
    if (!apiFile.existsSync()) {
      _log('   ⚠️ api_endpoints.dart not found');
      return;
    }

    var content = await apiFile.readAsString();

    if (content.contains('${schema.camelCase}s') && !force) {
      _log('   ⚠️ API endpoints already exist');
      return;
    }

    var endpoint = '';

    if (schema.apiEndpoints.isNotEmpty) {
      endpoint +=
          '  // ============== ${schema.pascalCase.toUpperCase()} (Custom) ==============';
      for (final ep in schema.apiEndpoints) {
        final name = ep['name'] as String;
        final path = ep['path'] as String;
        endpoint += '\n  static const String $name = \'$path\';';
      }
      endpoint += '\n';
    } else {
      endpoint = '''
  // ============== ${schema.pascalCase.toUpperCase()} ==============
  static const String ${schema.camelCase}s = '/${schema.snakeCase}s';
  static const String ${schema.camelCase}ById = '/${schema.snakeCase}s/{id}';
''';
    }

    final marker = '// ============== ADD YOUR ENDPOINTS ==============';
    final markerIndex = content.indexOf(marker);
    if (markerIndex != -1) {
      content = content.substring(0, markerIndex) +
          endpoint +
          '\n  $marker' +
          content.substring(markerIndex + marker.length);
    } else {
      final classEnd = content.lastIndexOf('}');
      if (classEnd != -1) {
        content = content.substring(0, classEnd) +
            endpoint +
            content.substring(classEnd);
      }
    }

    await apiFile.writeAsString(content);
    _log('   ✓ Updated api_endpoints.dart');
  }

  // ==================== HELPERS ====================

  Future<void> _writeFile(String path, String content) async {
    final file = File(path);

    if (file.existsSync() && !force) {
      _log('   ⚠️ Skipped (exists): ${path.replaceFirst(projectPath, '')}');
      return;
    }

    await file.writeAsString(content);
    _log('   ✓ Created ${path.replaceFirst(projectPath, '')}');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  void _printSummary() {
    print('');
    print('📊 Generation Summary:');
    print('   Usecases: ${_usecaseConfigs.length}');
    for (final uc in _usecaseConfigs) {
      print('     • ${uc.useCaseClassName} (${uc.type.description})');
    }
    print('   Screens: ${schema.screens.length}');
    for (final screen in schema.screens) {
      print('     • ${screen.name} (${screen.type.value})');
    }
  }
}
