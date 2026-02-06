/// Schema Parser
/// 
/// Parses JSON schema files into schema models.
library;

import 'dart:convert';
import 'dart:io';

import '../models/schema/schema_models.dart';

/// Result of parsing a schema
class SchemaParseResult {
  final bool success;
  final FeatureSchema? schema;
  final List<String> errors;
  final List<String> warnings;

  const SchemaParseResult({
    required this.success,
    this.schema,
    this.errors = const [],
    this.warnings = const [],
  });

  factory SchemaParseResult.error(String message) {
    return SchemaParseResult(
      success: false,
      errors: [message],
    );
  }

  factory SchemaParseResult.success(FeatureSchema schema, [List<String> warnings = const []]) {
    return SchemaParseResult(
      success: true,
      schema: schema,
      warnings: warnings,
    );
  }
}

/// Schema parser
class SchemaParser {
  /// Parse a schema from a file path
  static Future<SchemaParseResult> parseFile(String filePath) async {
    final file = File(filePath);
    
    if (!file.existsSync()) {
      return SchemaParseResult.error('Schema file not found: $filePath');
    }

    try {
      final content = await file.readAsString();
      return parseJson(content);
    } catch (e) {
      return SchemaParseResult.error('Failed to read file: $e');
    }
  }

  /// Parse a schema from JSON string
  static SchemaParseResult parseJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return parseMap(json);
    } on FormatException catch (e) {
      return SchemaParseResult.error('Invalid JSON: ${e.message}');
    } catch (e) {
      return SchemaParseResult.error('Failed to parse JSON: $e');
    }
  }

  /// Parse a schema from a Map
  static SchemaParseResult parseMap(Map<String, dynamic> json) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate required fields
    if (!json.containsKey('feature')) {
      errors.add('Missing required field: "feature"');
    }

    final featureJson = json['feature'] as Map<String, dynamic>?;
    if (featureJson != null) {
      if (!featureJson.containsKey('name')) {
        errors.add('Missing required field: "feature.name"');
      }
    }

    // Validate screens
    final screensJson = json['screens'] as List<dynamic>?;
    if (screensJson == null || screensJson.isEmpty) {
      warnings.add('No screens defined in schema');
    } else {
      for (var i = 0; i < screensJson.length; i++) {
        final screen = screensJson[i] as Map<String, dynamic>;
        if (!screen.containsKey('name')) {
          errors.add('Screen at index $i missing required field: "name"');
        }
      }
    }

    if (errors.isNotEmpty) {
      return SchemaParseResult(
        success: false,
        errors: errors,
        warnings: warnings,
      );
    }

    try {
      final schema = FeatureSchema.fromJson(json);
      
      // Additional validation
      _validateSchema(schema, warnings);
      
      return SchemaParseResult.success(schema, warnings);
    } catch (e) {
      return SchemaParseResult.error('Failed to parse schema: $e');
    }
  }

  /// Validate schema for common issues
  static void _validateSchema(FeatureSchema schema, List<String> warnings) {
    // Check for duplicate screen names
    final screenNames = <String>{};
    for (final screen in schema.screens) {
      if (screenNames.contains(screen.name)) {
        warnings.add('Duplicate screen name: ${screen.name}');
      }
      screenNames.add(screen.name);

      // Check widgets
      _validateWidgets(screen.widgets, warnings, screen.name);
    }

    // Check for missing data sources
    for (final screen in schema.screens) {
      if (screen.type == ScreenType.infiniteList && screen.dataSource == null) {
        warnings.add('Screen "${screen.name}" is infinite_list but has no dataSource');
      }

      for (final widget in screen.widgets) {
        if (widget.isList && widget.dataSource == null) {
          warnings.add('Widget "${widget.name}" is a list but has no dataSource');
        }
      }
    }
  }

  static void _validateWidgets(
    List<WidgetSchema> widgets,
    List<String> warnings,
    String screenName,
  ) {
    final widgetNames = <String>{};
    
    for (final widget in widgets) {
      if (widgetNames.contains(widget.name)) {
        warnings.add('Duplicate widget name in screen "$screenName": ${widget.name}');
      }
      widgetNames.add(widget.name);

      // Check for controller naming
      if (widget.needsController && widget.controller == null) {
        warnings.add(
          'Widget "${widget.name}" in "$screenName" needs a controller but none specified',
        );
      }

      // Recursively check children
      if (widget.children.isNotEmpty) {
        _validateWidgets(widget.children, warnings, screenName);
      }
    }
  }
}