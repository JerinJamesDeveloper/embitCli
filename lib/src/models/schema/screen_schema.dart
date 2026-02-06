/// Screen Schema Model
/// 
/// Represents a screen definition from JSON schema.
library;

import 'action_schema.dart';
import 'widget_schema.dart';

/// Screen type enumeration
enum ScreenType {
  /// Static content screen
  static_('static'),
  
  /// Infinite scrolling list
  infiniteList('infinite_list'),
  
  /// Form screen
  form('form'),
  
  /// Detail screen
  detail('detail'),
  
  /// Grid layout
  grid('grid');

  final String value;
  const ScreenType(this.value);

  static ScreenType fromString(String value) {
    return ScreenType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScreenType.static_,
    );
  }
}

/// Screen schema - data orchestration + layout composition
class ScreenSchema {
  /// Screen name in PascalCase
  final String name;
  
  /// Route path (relative to feature)
  final String route;
  
  /// Screen type
  final ScreenType type;
  
  /// Main data source (usecase name)
  final String? dataSource;
  
  /// State fields for this screen
  final List<StateField> state;
  
  /// Widgets on this screen
  final List<WidgetSchema> widgets;
  
  /// Whether this screen supports pull-to-refresh
  final bool pullToRefresh;
  
  /// Whether this screen has search functionality
  final bool hasSearch;
  
  /// App bar configuration
  final AppBarConfig? appBar;

  const ScreenSchema({
    required this.name,
    required this.route,
    this.type = ScreenType.static_,
    this.dataSource,
    this.state = const [],
    this.widgets = const [],
    this.pullToRefresh = false,
    this.hasSearch = false,
    this.appBar,
  });

  /// Parse from JSON
  factory ScreenSchema.fromJson(Map<String, dynamic> json) {
    final stateJson = json['state'] as List<dynamic>? ?? [];
    final widgetsJson = json['widgets'] as List<dynamic>? ?? [];

    return ScreenSchema(
      name: json['name'] as String,
      route: json['route'] as String? ?? '/${_toSnakeCase(json['name'] as String)}',
      type: ScreenType.fromString(json['type'] as String? ?? 'static'),
      dataSource: json['dataSource'] as String?,
      state: stateJson.map((s) {
        if (s is String) {
          return StateField(name: s);
        }
        return StateField.fromJson(s as Map<String, dynamic>);
      }).toList(),
      widgets: widgetsJson
          .map((w) => WidgetSchema.fromJson(w as Map<String, dynamic>))
          .toList(),
      pullToRefresh: json['pullToRefresh'] as bool? ?? false,
      hasSearch: json['hasSearch'] as bool? ?? false,
      appBar: json['appBar'] != null 
          ? AppBarConfig.fromJson(json['appBar'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'route': route,
    'type': type.value,
    'dataSource': dataSource,
    'state': state.map((s) => s.toJson()).toList(),
    'widgets': widgets.map((w) => w.toJson()).toList(),
    'pullToRefresh': pullToRefresh,
    'hasSearch': hasSearch,
    'appBar': appBar?.toJson(),
  };

  /// Get snake_case name
  String get snakeCase => _toSnakeCase(name);
  
  /// Get camelCase name
  String get camelCase => _toCamelCase(name);

  static String _toSnakeCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  static String _toCamelCase(String input) {
    if (input.isEmpty) return '';
    return '${input[0].toLowerCase()}${input.substring(1)}';
  }

  @override
  String toString() => 'ScreenSchema(name: $name, type: ${type.value})';
}

/// State field definition
class StateField {
  final String name;
  final String type;
  final dynamic defaultValue;
  final bool isLoading;
  final bool isError;

  const StateField({
    required this.name,
    this.type = 'dynamic',
    this.defaultValue,
    this.isLoading = false,
    this.isError = false,
  });

  factory StateField.fromJson(Map<String, dynamic> json) {
    return StateField(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'dynamic',
      defaultValue: json['default'],
      isLoading: json['isLoading'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'default': defaultValue,
    'isLoading': isLoading,
    'isError': isError,
  };
}

/// App bar configuration
class AppBarConfig {
  final String? title;
  final bool showBack;
  final List<AppBarAction> actions;

  const AppBarConfig({
    this.title,
    this.showBack = true,
    this.actions = const [],
  });

  factory AppBarConfig.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List<dynamic>? ?? [];
    return AppBarConfig(
      title: json['title'] as String?,
      showBack: json['showBack'] as bool? ?? true,
      actions: actionsJson
          .map((a) => AppBarAction.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'showBack': showBack,
    'actions': actions.map((a) => a.toJson()).toList(),
  };
}

/// App bar action button
class AppBarAction {
  final String icon;
  final String? tooltip;
  final ActionSchema? action;

  const AppBarAction({
    required this.icon,
    this.tooltip,
    this.action,
  });

  factory AppBarAction.fromJson(Map<String, dynamic> json) {
    return AppBarAction(
      icon: json['icon'] as String,
      tooltip: json['tooltip'] as String?,
      action: json['action'] != null
          ? ActionSchema.fromJson(json['action'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'icon': icon,
    'tooltip': tooltip,
    'action': action?.toJson(),
  };
}

// // Forward declaration
// class ActionSchema {
//   final String type;
//   final String? name;
//   final List<String> params;
//   final NavigationAction? onSuccess;
//   final NavigationAction? onError;

//   const ActionSchema({
//     required this.type,
//     this.name,
//     this.params = const [],
//     this.onSuccess,
//     this.onError,
//   });

//   factory ActionSchema.fromJson(Map<String, dynamic> json) {
//     return ActionSchema(
//       type: json['type'] as String,
//       name: json['name'] as String?,
//       params: (json['params'] as List<dynamic>?)
//           ?.map((e) => e.toString())
//           .toList() ?? [],
//       onSuccess: json['onSuccess'] != null
//           ? NavigationAction.fromJson(json['onSuccess'] as Map<String, dynamic>)
//           : null,
//       onError: json['onError'] != null
//           ? NavigationAction.fromJson(json['onError'] as Map<String, dynamic>)
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'type': type,
//     'name': name,
//     'params': params,
//     'onSuccess': onSuccess?.toJson(),
//     'onError': onError?.toJson(),
//   };
// }

class NavigationAction {
  final String? navTo;
  final String? showDialog;
  final String? showSnackbar;
  final bool pop;

  const NavigationAction({
    this.navTo,
    this.showDialog,
    this.showSnackbar,
    this.pop = false,
  });

  factory NavigationAction.fromJson(Map<String, dynamic> json) {
    return NavigationAction(
      navTo: json['navTo'] as String?,
      showDialog: json['showDialog'] as String?,
      showSnackbar: json['showSnackbar'] as String?,
      pop: json['pop'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'navTo': navTo,
    'showDialog': showDialog,
    'showSnackbar': showSnackbar,
    'pop': pop,
  };
}