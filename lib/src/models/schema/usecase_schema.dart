/// UseCase Schema Model
///
/// Represents a usecase extracted from the JSON schema.
library;

import '../usecase_config.dart';
import 'action_schema.dart';

/// UseCase extracted from schema
class UseCaseSchema {
  /// UseCase name (e.g., getOrders, createOrder)
  final String name;

  /// Inferred type based on naming convention
  final UseCaseType type;

  /// Parameters for this usecase
  final List<UseCaseParam> params;

  /// Source of this usecase (dataSource, action, onTap)
  final String source;

  /// Whether this usecase should generate a BLoC event
  final bool generateEvent;

  const UseCaseSchema({
    required this.name,
    required this.type,
    this.params = const [],
    this.source = 'custom',
    this.generateEvent = true,
  });

  /// Parse from JSON
  factory UseCaseSchema.fromJson(Map<String, dynamic> json) {
    final paramsJson = json['params'] as List<dynamic>? ?? [];
    return UseCaseSchema(
      name: json['name'] as String,
      type: UseCaseType.fromString(json['type'] as String? ?? 'custom'),
      params: paramsJson
          .map((p) => UseCaseParam.fromJson(p as Map<String, dynamic>))
          .toList(),
      source: json['source'] as String? ?? 'json',
      generateEvent: json['generateEvent'] as bool? ?? true,
    );
  }

  /// Infer usecase type from name
  static UseCaseType inferType(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.startsWith('get') &&
        (lowerName.endsWith('s') ||
            lowerName.contains('all') ||
            lowerName.contains('list'))) {
      return UseCaseType.getList;
    } else if (lowerName.startsWith('get') ||
        lowerName.startsWith('fetch') ||
        lowerName.startsWith('load')) {
      return UseCaseType.get;
    } else if (lowerName.startsWith('create') ||
        lowerName.startsWith('add') ||
        lowerName.startsWith('insert')) {
      return UseCaseType.create;
    } else if (lowerName.startsWith('update') ||
        lowerName.startsWith('edit') ||
        lowerName.startsWith('modify')) {
      return UseCaseType.update;
    } else if (lowerName.startsWith('delete') ||
        lowerName.startsWith('remove')) {
      return UseCaseType.delete;
    } else {
      return UseCaseType.custom;
    }
  }

  /// Create from a dataSource string
  factory UseCaseSchema.fromDataSource(String dataSource) {
    return UseCaseSchema(
      name: dataSource,
      type: inferType(dataSource),
      source: 'dataSource',
      generateEvent: true,
    );
  }

  /// Create from an action schema
  factory UseCaseSchema.fromAction(ActionSchema action, String widgetName) {
    final params = action.params
        .map((p) => UseCaseParam(
              name: p,
              type: 'String', // Default type, can be overridden
              isRequired: true,
            ))
        .toList();

    return UseCaseSchema(
      name: action.name ?? widgetName,
      type: inferType(action.name ?? widgetName),
      params: params,
      source: 'action',
      generateEvent: true,
    );
  }

  @override
  String toString() => 'UseCaseSchema(name: $name, type: ${type.value})';
}

/// Parameter for a usecase
class UseCaseParam {
  final String name;
  final String type;
  final bool isRequired;
  final String? defaultValue;

  const UseCaseParam({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.defaultValue,
  });

  /// Parse from JSON
  factory UseCaseParam.fromJson(Map<String, dynamic> json) {
    return UseCaseParam(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'String',
      isRequired:
          json['required'] as bool? ?? json['isRequired'] as bool? ?? true,
      defaultValue:
          json['default'] as String? ?? json['defaultValue'] as String?,
    );
  }
}
