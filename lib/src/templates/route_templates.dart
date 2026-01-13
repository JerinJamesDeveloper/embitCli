import '../models/feature_config.dart';

class RouteTemplates {
  /// Route paths to add to route_names.dart
  static String routePaths(FeatureConfig config) => '''
  
  // ============== ${config.pascalCase.toUpperCase()} ROUTES ==============
  static const String ${config.camelCase} = '/${config.snakeCase}';
  static const String ${config.camelCase}Detail = '/${config.snakeCase}/:${config.camelCase}Id';
''';

  /// Route names to add to route_names.dart  
  static String routeNames(FeatureConfig config) => '''
  
  // ${config.pascalCase}
  static const String ${config.camelCase} = '${config.camelCase}';
  static const String ${config.camelCase}Detail = '${config.camelCase}Detail';
''';

  /// GoRoute entries to add to app_router.dart
  static String goRouteEntries(FeatureConfig config) => '''
        
        // ============== ${config.pascalCase.toUpperCase()} ROUTES ==============
        GoRoute(
          path: RoutePaths.${config.camelCase},
          name: RouteNames.${config.camelCase},
          builder: (context, state) => const ${config.pascalCase}Page(),
          routes: [
            GoRoute(
              path: ':${config.camelCase}Id',
              name: RouteNames.${config.camelCase}Detail,
              builder: (context, state) {
                final ${config.camelCase}Id = state.pathParameters['${config.camelCase}Id'] ?? '';
                return ${config.pascalCase}DetailPage(id: ${config.camelCase}Id);
              },
            ),
          ],
        ),
''';

  /// Import to add to app_router.dart
  static String pageImport(FeatureConfig config, String projectName) => '''
import 'package:${projectName}/features/${config.snakeCase}/presentation/pages/${config.snakeCase}_page.dart';
import 'package:${projectName}/features/${config.snakeCase}/presentation/pages/${config.snakeCase}_detail_page.dart';
''';

  /// API endpoints to add
  static String apiEndpoint(FeatureConfig config) => '''
  
  // ================= ${config.pascalCase}  ============================

  static const String get${config.camelCase}s = '/api/${config.snakeCase}s/get';
  static const String getall${config.camelCase}s = '/api/${config.snakeCase}s/getall';
  static const String create${config.camelCase}s = '/api/${config.snakeCase}s/create';
  static const String delete${config.camelCase}s = '/api/${config.snakeCase}s/delete';
  static const String update${config.camelCase}s = '/api/${config.snakeCase}s/update';
''';
}