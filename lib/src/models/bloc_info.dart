/// BLoC Information
///
/// Contains metadata about a BLoC for selection purposes.
class BlocInfo {
  /// BLoC class name (e.g., "CheckBloc", "NewcheckBloc")
  final String name;

  /// Absolute path to BLoC file
  final String path;

  /// Display name for user selection (e.g., "CheckBloc (Main feature BLoC)")
  final String displayName;

  /// Whether this is a model-specific BLoC or main feature BLoC
  final bool isModelBloc;

  /// Snake case name for file operations (e.g., "check", "newcheck")
  final String snakeName;

  const BlocInfo({
    required this.name,
    required this.path,
    required this.displayName,
    required this.isModelBloc,
    required this.snakeName,
  });

  @override
  String toString() => displayName;
}
