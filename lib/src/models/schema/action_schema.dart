/// Action Schema Model
/// 
/// Represents an action definition from JSON schema.
library;

/// Action type enumeration
enum ActionType {
  /// Call a usecase
  usecase('usecase'),
  
  /// Navigate to a route
  navigation('navigation'),
  
  /// Show a dialog
  dialog('dialog'),
  
  /// Show a bottom sheet
  bottomSheet('bottomSheet'),
  
  /// Call an API directly
  api('api'),
  
  /// Emit a bloc event
  event('event'),
  
  /// Update local state
  setState('setState'),
  
  /// Show snackbar
  snackbar('snackbar'),
  
  /// Copy to clipboard
  copy('copy'),
  
  /// Share
  share('share'),
  
  /// Open URL
  openUrl('openUrl'),
  
  /// Custom action
  custom('custom');

  final String value;
  const ActionType(this.value);

  static ActionType fromString(String value) {
    return ActionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActionType.custom,
    );
  }
}

/// Complete action schema with all possibilities
class ActionSchema {
  /// Action type
  final ActionType type;
  
  /// Usecase/event/api name
  final String? name;
  
  /// Parameters to pass
  final List<String> params;
  
  /// Parameter mapping (state field -> param name)
  final Map<String, String> paramMapping;
  
  /// On success handler
  final ActionResult? onSuccess;
  
  /// On error handler
  final ActionResult? onError;
  
  /// On loading handler
  final ActionResult? onLoading;
  
  /// Confirmation dialog before action
  final ConfirmationConfig? confirmation;
  
  /// Debounce duration in milliseconds
  final int? debounce;
  
  /// Throttle duration in milliseconds
  final int? throttle;

  const ActionSchema({
    required this.type,
    this.name,
    this.params = const [],
    this.paramMapping = const {},
    this.onSuccess,
    this.onError,
    this.onLoading,
    this.confirmation,
    this.debounce,
    this.throttle,
  });

  /// Parse from JSON
  factory ActionSchema.fromJson(Map<String, dynamic> json) {
    return ActionSchema(
      type: ActionType.fromString(json['type'] as String? ?? 'custom'),
      name: json['name'] as String?,
      params: (json['params'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      paramMapping: (json['paramMapping'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      onSuccess: json['onSuccess'] != null
          ? ActionResult.fromJson(json['onSuccess'] as Map<String, dynamic>)
          : null,
      onError: json['onError'] != null
          ? ActionResult.fromJson(json['onError'] as Map<String, dynamic>)
          : null,
      onLoading: json['onLoading'] != null
          ? ActionResult.fromJson(json['onLoading'] as Map<String, dynamic>)
          : null,
      confirmation: json['confirmation'] != null
          ? ConfirmationConfig.fromJson(json['confirmation'] as Map<String, dynamic>)
          : null,
      debounce: json['debounce'] as int?,
      throttle: json['throttle'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'name': name,
    'params': params,
    'paramMapping': paramMapping,
    'onSuccess': onSuccess?.toJson(),
    'onError': onError?.toJson(),
    'onLoading': onLoading?.toJson(),
    'confirmation': confirmation?.toJson(),
    'debounce': debounce,
    'throttle': throttle,
  };

  /// Check if this action calls a usecase
  bool get isUseCase => type == ActionType.usecase;
  
  /// Check if this action is navigation
  bool get isNavigation => type == ActionType.navigation;
  
  /// Check if this action shows a dialog
  bool get isDialog => type == ActionType.dialog;

  @override
  String toString() => 'ActionSchema(type: ${type.value}, name: $name)';
}

/// Action result handler
class ActionResult {
  /// Navigate to route
  final String? navTo;
  
  /// Navigate to route with replacement
  final String? navReplace;
  
  /// Pop current route
  final bool pop;
  
  /// Pop to specific route
  final String? popTo;
  
  /// Show dialog
  final String? showDialog;
  
  /// Show bottom sheet
  final String? showBottomSheet;
  
  /// Show snackbar
  final SnackbarConfig? showSnackbar;
  
  /// Update state field
  final Map<String, dynamic>? setState;
  
  /// Emit bloc event
  final String? emitEvent;
  
  /// Chain another action
  final ActionSchema? then;

  const ActionResult({
    this.navTo,
    this.navReplace,
    this.pop = false,
    this.popTo,
    this.showDialog,
    this.showBottomSheet,
    this.showSnackbar,
    this.setState,
    this.emitEvent,
    this.then,
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      navTo: json['navTo'] as String?,
      navReplace: json['navReplace'] as String?,
      pop: json['pop'] as bool? ?? false,
      popTo: json['popTo'] as String?,
      showDialog: json['showDialog'] as String?,
      showBottomSheet: json['showBottomSheet'] as String?,
      showSnackbar: json['showSnackbar'] != null
          ? SnackbarConfig.fromJson(json['showSnackbar'] as Map<String, dynamic>)
          : null,
      setState: json['setState'] as Map<String, dynamic>?,
      emitEvent: json['emitEvent'] as String?,
      then: json['then'] != null
          ? ActionSchema.fromJson(json['then'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'navTo': navTo,
    'navReplace': navReplace,
    'pop': pop,
    'popTo': popTo,
    'showDialog': showDialog,
    'showBottomSheet': showBottomSheet,
    'showSnackbar': showSnackbar?.toJson(),
    'setState': setState,
    'emitEvent': emitEvent,
    'then': then?.toJson(),
  };
}

/// Snackbar configuration
class SnackbarConfig {
  final String message;
  final String? actionLabel;
  final ActionSchema? action;
  final int durationMs;
  final String type; // success, error, warning, info

  const SnackbarConfig({
    required this.message,
    this.actionLabel,
    this.action,
    this.durationMs = 4000,
    this.type = 'info',
  });

  factory SnackbarConfig.fromJson(Map<String, dynamic> json) {
    if (json is String) {
      return SnackbarConfig(message: json.toString());
    }
    return SnackbarConfig(
      message: json['message'] as String,
      actionLabel: json['actionLabel'] as String?,
      action: json['action'] != null
          ? ActionSchema.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      durationMs: json['durationMs'] as int? ?? 4000,
      type: json['type'] as String? ?? 'info',
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'actionLabel': actionLabel,
    'action': action?.toJson(),
    'durationMs': durationMs,
    'type': type,
  };
}

/// Confirmation dialog configuration
class ConfirmationConfig {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const ConfirmationConfig({
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
  });

  factory ConfirmationConfig.fromJson(Map<String, dynamic> json) {
    return ConfirmationConfig(
      title: json['title'] as String,
      message: json['message'] as String,
      confirmLabel: json['confirmLabel'] as String? ?? 'Confirm',
      cancelLabel: json['cancelLabel'] as String? ?? 'Cancel',
      destructive: json['destructive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'confirmLabel': confirmLabel,
    'cancelLabel': cancelLabel,
    'destructive': destructive,
  };
}