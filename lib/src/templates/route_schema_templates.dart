/// Route Schema Templates
library;

import '../models/schema/feature_schema.dart';


class RouteSchemaTemplates {
  RouteSchemaTemplates._();

  static String routePaths(FeatureSchema schema) {
    final screenRoutes = schema.screens.map((screen) {
      final snakeName = _toSnakeCase(screen.name);
      final camelName = _toCamelCase(screen.name);
      return "  static const String $camelName = '${screen.route}';";
    }).join('\n');

    return '''
  // ============== ${schema.pascalCase.toUpperCase()} ==============
  static const String ${schema.camelCase} = '${schema.route}';
$screenRoutes
''';
  }

  static String routeNames(FeatureSchema schema) {
    final screenRoutes = schema.screens.map((screen) {
      final camelName = _toCamelCase(screen.name);
      return "  static const String $camelName = '$camelName';";
    }).join('\n');

    return '''
  // ${schema.pascalCase}
  static const String ${schema.camelCase} = '${schema.camelCase}';
$screenRoutes
''';
  }

  static String pageImports(FeatureSchema schema, String projectName) {
    return schema.screens.map((screen) {
      final snakeName = _toSnakeCase(screen.name);
      return "import 'package:$projectName/features/${schema.snakeCase}/presentation/pages/${snakeName}_page.dart';";
    }).join('\n');
  }

  static String shellRouteEntries(FeatureSchema schema) {
    return schema.screens.map((screen) {
      final camelName = _toCamelCase(screen.name);
      return '''
            // ${screen.name}
            GoRoute(
              path: RoutePaths.$camelName,
              name: RouteNames.$camelName,
              pageBuilder: (context, state) => NoTransitionPage(
                child: const ${screen.name}Page(),
              ),
            ),''';
    }).join('\n');
  }

  static String standaloneRouteEntries(FeatureSchema schema) {
    return schema.screens.map((screen) {
      final camelName = _toCamelCase(screen.name);
      return '''
        GoRoute(
          path: RoutePaths.$camelName,
          name: RouteNames.$camelName,
          builder: (context, state) => const ${screen.name}Page(),
        ),''';
    }).join('\n');
  }

  static String navItem(FeatureSchema schema) {
    return '''
    NavItem(
      route: '${schema.route}',
      icon: Icons.${schema.icon ?? 'folder'}_outlined,
      activeIcon: Icons.${schema.icon ?? 'folder'},
      label: '${schema.label ?? schema.pascalCase}',
    ),''';
  }

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  static String _toCamelCase(String input) {
    if (input.isEmpty) return '';
    return '${input[0].toLowerCase()}${input.substring(1)}';
  }
}