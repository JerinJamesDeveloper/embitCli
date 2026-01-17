import 'dart:io';
import 'package:args/args.dart';
import 'commands/init_command.dart';
import 'commands/feature_command.dart';
import 'commands/usecase_command.dart';

void run(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false)
    ..addFlag('version', abbr: 'v', help: 'Show version', negatable: false)
    ..addFlag('verbose', help: 'Show detailed logs', negatable: false);

  final commands = {
    'init': InitCommand(),
    'feature': FeatureCommand(),
    'usecase': UseCaseCommand(),
  };

  for (final entry in commands.entries) {
    parser.addCommand(entry.key, entry.value.argParser);
  }

  try {
    final results = parser.parse(arguments);
    final verbose = results['verbose'] == true;

    if (results['help'] == true) {
      _printHelp(parser);
      return;
    }

    if (results['version'] == true) {
      print('Embit CLI v0.7.0');
      print('Architecture enforcement for Flutter');
      return;
    }

    if (results.command == null) {
      stderr.writeln('Error: No command provided\n');
      _printHelp(parser);
      exit(1);
    }

    final command = commands[results.command!.name];
    if (command == null) {
      stderr.writeln('Error: Unknown command "${results.command!.name}"');
      exit(1);
    }

    command.execute(results.command!, verbose: verbose);
  } catch (e) {
    stderr.writeln('❌ Fatal error: $e');
    exit(1);
  }
}

void _printHelp(ArgParser parser) {
  print('''
╔════════════════════════════════════════╗
║            Embit CLI v0.7.0            ║
║    Architecture Enforcement Tool        ║
╚════════════════════════════════════════╝

Usage: embit <command> [options]

Commands:
  init      Initialize project with full architecture
  feature   Create new feature with DI, Bloc, and routing
  usecase   Create new usecase for existing feature 

Options:
  -h, --help    Show this help
  -v, --version Show version
  --verbose     Show detailed logs

Examples:
  embit init --force
  embit feature --name auth --verbose
  embit feature -n profile --with-example
  embit usecase -f products -n archive_product -t update
  embit usecase -f auth -n verify_otp --with-event 

Run 'embit <command> --help' for command-specific help.
''');
}