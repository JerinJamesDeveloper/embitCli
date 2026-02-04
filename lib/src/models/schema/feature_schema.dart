// /// Feature Schema Model
// ///
// /// Represents a feature definition from JSON schema.
// library;

// import 'screen_schema.dart';

// /// Feature schema - navigation + domain boundary
// class FeatureSchema {
//   /// Feature name in snake_case
//   final String name;

//   /// Base route for the feature
//   final String route;

//   /// Whether to add to bottom navigation
//   final bool addToBottomNav;

//   /// Icon name (Material Icons)
//   final String? icon;

//   /// Display label for navigation
//   final String? label;

//   /// Screens within this feature
//   final List<ScreenSchema> screens;

//   const FeatureSchema({
//     required this.name,
//     required this.route,
//     this.addToBottomNav = false,
//     this.icon,
//     this.label,
//     this.screens = const [],
//   });

//   /// Parse from JSON
//   factory FeatureSchema.fromJson(Map<String, dynamic> json) {
//     final featureJson = json['feature'] as Map<String, dynamic>? ?? json;
//     final screensJson = json['screens'] as List<dynamic>? ?? [];

//     return FeatureSchema(
//       name: featureJson['name'] as String,
//       route: featureJson['route'] as String? ?? '/${featureJson['name']}',
//       addToBottomNav: featureJson['addToBottomNav'] as bool? ?? false,
//       icon: featureJson['icon'] as String?,
//       label: featureJson['label'] as String?,
//       screens: screensJson
//           .map((s) => ScreenSchema.fromJson(s as Map<String, dynamic>))
//           .toList(),
//     );
//   }

//   /// Convert to JSON
//   Map<String, dynamic> toJson() => {
//     'feature': {
//       'name': name,
//       'route': route,
//       'addToBottomNav': addToBottomNav,
//       'icon': icon,
//       'label': label,
//     },
//     'screens': screens.map((s) => s.toJson()).toList(),
//   };

//   /// Get PascalCase name
//   String get pascalCase => _toPascalCase(name);

//   /// Get camelCase name
//   String get camelCase => _toCamelCase(name);

//   /// Get snake_case name (same as name)
//   String get snakeCase => name;

//   static String _toPascalCase(String input) {
//     return input.split('_').map((word) {
//       if (word.isEmpty) return '';
//       return '${word[0].toUpperCase()}${word.substring(1)}';
//     }).join();
//   }

//   static String _toCamelCase(String input) {
//     final pascal = _toPascalCase(input);
//     if (pascal.isEmpty) return '';
//     return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
//   }

//   @override
//   String toString() => 'FeatureSchema(name: $name, screens: ${screens.length})';
// }

/// Feature Schema Model
///
/// Represents a feature definition from JSON schema.
library;

import '../field_definition.dart' show FieldDefinition;
import 'action_schema.dart';
import 'screen_schema.dart';
import 'usecase_schema.dart';
import 'entity_schema.dart';
import '../usecase_config.dart';
import 'widget_schema.dart';

/// Feature schema - navigation + domain boundary
class FeatureSchema {
  /// Feature name in snake_case
  final String name;

  /// Base route for the feature
  final String route;

  /// Whether to add to bottom navigation
  final bool addToBottomNav;

  /// Icon name (Material Icons)
  final String? icon;

  /// Display label for navigation
  final String? label;

  /// Screens within this feature
  final List<ScreenSchema> screens;

  /// Entity definition (custom fields)
  final EntitySchema? entity;

  /// Explicit usecases array
  final List<UseCaseSchema> usecases;

  /// Custom bottom sheets
  final List<Map<String, dynamic>> bottomSheets;

  /// Custom API endpoints
  final List<Map<String, dynamic>> apiEndpoints;

  const FeatureSchema({
    required this.name,
    required this.route,
    this.addToBottomNav = false,
    this.icon,
    this.label,
    this.screens = const [],
    this.entity,
    this.usecases = const [],
    this.bottomSheets = const [],
    this.apiEndpoints = const [],
  });

  /// Parse from JSON
  factory FeatureSchema.fromJson(Map<String, dynamic> json) {
    final featureJson = json['feature'] as Map<String, dynamic>? ?? json;
    final screensJson = json['screens'] as List<dynamic>? ?? [];
    final usecasesJson = json['usecases'] as List<dynamic>? ?? [];
    final bottomSheetsJson = json['bottomSheets'] as List<dynamic>? ?? [];
    final apiEndpointsJson = json['apiEndpoints'] as List<dynamic>? ?? [];

    return FeatureSchema(
      name: featureJson['name'] as String,
      route: featureJson['route'] as String? ?? '/${featureJson['name']}',
      addToBottomNav: featureJson['addToBottomNav'] as bool? ?? false,
      icon: featureJson['icon'] as String?,
      label: featureJson['label'] as String?,
      screens: screensJson
          .map((s) => ScreenSchema.fromJson(s as Map<String, dynamic>))
          .toList(),
      entity: json['entity'] != null
          ? EntitySchema.fromJson(json['entity'] as Map<String, dynamic>)
          : null,
      usecases: usecasesJson
          .map((u) => UseCaseSchema.fromJson(u as Map<String, dynamic>))
          .toList(),
      bottomSheets: bottomSheetsJson.cast<Map<String, dynamic>>(),
      apiEndpoints: apiEndpointsJson.cast<Map<String, dynamic>>(),
    );
  }

  // ==================== NAMING HELPERS ====================

  String get pascalCase => _toPascalCase(name);
  String get camelCase => _toCamelCase(name);
  String get snakeCase => name;

  static String _toPascalCase(String input) {
    return input.split('_').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join();
  }

  static String _toCamelCase(String input) {
    final pascal = _toPascalCase(input);
    if (pascal.isEmpty) return '';
    return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
  }

  // ==================== USECASE EXTRACTION ====================

  /// Extract all usecases from the schema
  List<UseCaseSchema> extractUseCases() {
    final map = <String, UseCaseSchema>{};

    // 1. Add explicit usecases from JSON (these take priority if names match)
    for (final uc in usecases) {
      map[uc.name] = uc;
    }

    // 2. Extract from screens and widgets
    for (final screen in screens) {
      // Screen-level dataSource
      if (screen.dataSource != null) {
        final name = screen.dataSource!;
        if (!map.containsKey(name)) {
          map[name] = UseCaseSchema.fromDataSource(name);
        }
      }

      // Widget-level dataSources and actions
      _extractFromWidgets(screen.widgets, map);
    }

    return map.values.toList();
  }

  void _extractFromWidgets(
    List<WidgetSchema> widgets,
    Map<String, UseCaseSchema> usecases,
  ) {
    for (final widget in widgets) {
      // Widget dataSource
      if (widget.dataSource != null) {
        final uc = UseCaseSchema.fromDataSource(widget.dataSource!);
        usecases[uc.name] = uc;
      }

      // Widget action
      if (widget.action != null &&
          widget.action!.type == ActionType.usecase &&
          widget.action!.name != null) {
        final uc = UseCaseSchema.fromAction(widget.action!, widget.name);
        usecases[uc.name] = uc;
      }

      // Widget onTap
      if (widget.onTap != null &&
          widget.onTap!.type == ActionType.usecase &&
          widget.onTap!.name != null) {
        final uc = UseCaseSchema.fromAction(widget.onTap!, widget.name);
        usecases[uc.name] = uc;
      }

      // Widget onLongPress
      if (widget.onLongPress != null &&
          widget.onLongPress!.type == ActionType.usecase &&
          widget.onLongPress!.name != null) {
        final uc = UseCaseSchema.fromAction(widget.onLongPress!, widget.name);
        usecases[uc.name] = uc;
      }

      // Recurse into children
      if (widget.children.isNotEmpty) {
        _extractFromWidgets(widget.children, usecases);
      }
    }
  }

  /// Convert usecase schema to usecase config
  UseCaseConfig toUseCaseConfig(
    UseCaseSchema usecase, {
    required String projectName,
    required String projectPath,
    bool force = false,
  }) {
    return UseCaseConfig(
      featureName: name,
      useCaseName: _toSnakeCase(usecase.name),
      type: usecase.type,
      projectName: projectName,
      projectPath: projectPath,
      force: force,
      withEvent: usecase.generateEvent,
      customEntityName: entity?.name,
      fields: usecase.params
          .map((p) => FieldDefinition(
                name: p.name,
                type: p.type,
                isRequired: p.isRequired,
                defaultValue: p.defaultValue,
              ))
          .toList(),
    );
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  @override
  String toString() => 'FeatureSchema(name: $name, screens: ${screens.length})';
}
