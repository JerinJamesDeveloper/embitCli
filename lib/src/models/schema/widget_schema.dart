/// Widget Schema Model
/// 
/// Represents a widget definition from JSON schema.
library;

import 'action_schema.dart';

/// Widget template types (pre-built in starter kit)
enum WidgetTemplate {
  // Input widgets
  textField('TextField'),
  passwordField('PasswordField'),
  emailField('EmailField'),
  phoneField('PhoneField'),
  searchField('SearchField'),
  dropdown('Dropdown'),
  checkbox('Checkbox'),
  switchWidget('Switch'),
  datePicker('DatePicker'),
  timePicker('TimePicker'),
  
  // Display widgets
  text('Text'),
  image('Image'),
  avatar('Avatar'),
  icon('Icon'),
  badge('Badge'),
  chip('Chip'),
  divider('Divider'),
  spacer('Spacer'),
  
  // Container widgets
  card('Card'),
  listTile('ListTile'),
  expansionTile('ExpansionTile'),
  container('Container'),
  
  // List widgets
  cardList('CardList'),
  horizontalScroller('HorizontalScroller'),
  gridView('GridView'),
  listView('ListView'),
  
  // Action widgets
  button('Button'),
  textButton('TextButton'),
  iconButton('IconButton'),
  floatingActionButton('FloatingActionButton'),
  outlinedButton('OutlinedButton'),
  
  // Layout widgets
  row('Row'),
  column('Column'),
  wrap('Wrap'),
  stack('Stack'),
  
  // Feedback widgets
  loadingIndicator('LoadingIndicator'),
  emptyState('EmptyState'),
  errorState('ErrorState'),
  
  // Navigation widgets
  navIconGrid('NavIconGrid'),
  bottomSheet('BottomSheet'),
  dialog('Dialog'),
  
  // Composite widgets
  sectionHeader('SectionHeader'),
  searchBar('SearchBar'),
  filterChips('FilterChips'),
  tabBar('TabBar'),
  carousel('Carousel'),
  
  // Custom widget
  custom('Custom');

  final String value;
  const WidgetTemplate(this.value);

  static WidgetTemplate fromString(String value) {
    return WidgetTemplate.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WidgetTemplate.custom,
    );
  }
}

/// Widget schema - prebuilt template with configurable wiring
class WidgetSchema {
  /// Widget name/identifier
  final String name;
  
  /// Template type
  final WidgetTemplate template;
  
  /// Custom template name (if template is custom)
  final String? customTemplate;
  
  /// Data source (usecase or state field)
  final String? dataSource;
  
  /// Controller name (for input widgets)
  final String? controller;
  
  /// Action to perform
  final ActionSchema? action;
  
  /// On tap action
  final ActionSchema? onTap;
  
  /// On long press action
  final ActionSchema? onLongPress;
  
  /// Child widgets (for container widgets)
  final List<WidgetSchema> children;
  
  /// Widget properties
  final Map<String, dynamic> props;
  
  /// Validation rules (for input widgets)
  final ValidationRules? validation;
  
  /// Conditional visibility
  final String? visibleWhen;
  
  /// Conditional enable
  final String? enabledWhen;

  const WidgetSchema({
    required this.name,
    required this.template,
    this.customTemplate,
    this.dataSource,
    this.controller,
    this.action,
    this.onTap,
    this.onLongPress,
    this.children = const [],
    this.props = const {},
    this.validation,
    this.visibleWhen,
    this.enabledWhen,
  });

  /// Parse from JSON
  factory WidgetSchema.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];

    return WidgetSchema(
      name: json['name'] as String? ?? json['template'] as String,
      template: WidgetTemplate.fromString(
        json['template'] as String? ?? json['type'] as String? ?? 'Custom',
      ),
      customTemplate: json['customTemplate'] as String?,
      dataSource: json['dataSource'] as String?,
      controller: json['controller'] as String?,
      action: json['action'] != null
          ? ActionSchema.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      onTap: json['onTap'] != null
          ? ActionSchema.fromJson(json['onTap'] as Map<String, dynamic>)
          : null,
      onLongPress: json['onLongPress'] != null
          ? ActionSchema.fromJson(json['onLongPress'] as Map<String, dynamic>)
          : null,
      children: childrenJson
          .map((c) => WidgetSchema.fromJson(c as Map<String, dynamic>))
          .toList(),
      props: json['props'] as Map<String, dynamic>? ?? {},
      validation: json['validation'] != null
          ? ValidationRules.fromJson(json['validation'] as Map<String, dynamic>)
          : null,
      visibleWhen: json['visibleWhen'] as String?,
      enabledWhen: json['enabledWhen'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'template': template.value,
    'customTemplate': customTemplate,
    'dataSource': dataSource,
    'controller': controller,
    'action': action?.toJson(),
    'onTap': onTap?.toJson(),
    'onLongPress': onLongPress?.toJson(),
    'children': children.map((c) => c.toJson()).toList(),
    'props': props,
    'validation': validation?.toJson(),
    'visibleWhen': visibleWhen,
    'enabledWhen': enabledWhen,
  };

  /// Check if widget needs a controller
  bool get needsController {
    return template == WidgetTemplate.textField ||
           template == WidgetTemplate.passwordField ||
           template == WidgetTemplate.emailField ||
           template == WidgetTemplate.phoneField ||
           template == WidgetTemplate.searchField;
  }

  /// Check if widget is an input
  bool get isInput => needsController || 
      template == WidgetTemplate.dropdown ||
      template == WidgetTemplate.checkbox ||
      template == WidgetTemplate.switchWidget ||
      template == WidgetTemplate.datePicker;

  /// Check if widget is a list
  bool get isList => 
      template == WidgetTemplate.cardList ||
      template == WidgetTemplate.horizontalScroller ||
      template == WidgetTemplate.gridView ||
      template == WidgetTemplate.listView;

  /// Check if widget is a button
  bool get isButton =>
      template == WidgetTemplate.button ||
      template == WidgetTemplate.textButton ||
      template == WidgetTemplate.iconButton ||
      template == WidgetTemplate.floatingActionButton ||
      template == WidgetTemplate.outlinedButton;

  @override
  String toString() => 'WidgetSchema(name: $name, template: ${template.value})';
}

/// Validation rules for input widgets
class ValidationRules {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final String? patternMessage;
  final String? customValidator;

  const ValidationRules({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.patternMessage,
    this.customValidator,
  });

  factory ValidationRules.fromJson(Map<String, dynamic> json) {
    return ValidationRules(
      required: json['required'] as bool? ?? false,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      patternMessage: json['patternMessage'] as String?,
      customValidator: json['customValidator'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'required': required,
    'minLength': minLength,
    'maxLength': maxLength,
    'pattern': pattern,
    'patternMessage': patternMessage,
    'customValidator': customValidator,
  };
}