/// Page Schema Templates
library;

import '../models/schema/feature_schema.dart';
import '../models/schema/screen_schema.dart';


class PageSchemaTemplates {
  PageSchemaTemplates._();

  static String generate(
    ScreenSchema screen,
    FeatureSchema feature,
    String projectName,
  ) {
    switch (screen.type) {
      case ScreenType.infiniteList:
        return _infiniteListPage(screen, feature, projectName);
      case ScreenType.detail:
        return _detailPage(screen, feature, projectName);
      case ScreenType.form:
        return _formPage(screen, feature, projectName);
      case ScreenType.static_:
      case ScreenType.grid:
      default:
        return _staticPage(screen, feature, projectName);
    }
  }

  static String _infiniteListPage(
    ScreenSchema screen,
    FeatureSchema feature,
    String projectName,
  ) {
    return '''
/// ${screen.name} Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:$projectName/core/di/injection_container.dart';
import '../bloc/${feature.snakeCase}_bloc.dart';
import '../widgets/${feature.snakeCase}_list_item.dart';
import '../widgets/${feature.snakeCase}_loading.dart';
import '../widgets/${feature.snakeCase}_error.dart';

/// ${screen.name} page with infinite scrolling list
class ${screen.name}Page extends StatelessWidget {
  const ${screen.name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<${feature.pascalCase}Bloc>()
        ..add(const ${feature.pascalCase}LoadRequested()),
      child: const _${screen.name}View(),
    );
  }
}

class _${screen.name}View extends StatefulWidget {
  const _${screen.name}View();

  @override
  State<_${screen.name}View> createState() => _${screen.name}ViewState();
}

class _${screen.name}ViewState extends State<_${screen.name}View> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      // Load more items
      // context.read<${feature.pascalCase}Bloc>().add(const ${feature.pascalCase}LoadMoreRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${screen.name}'),
        ${screen.appBar?.showBack == false ? "automaticallyImplyLeading: false," : ""}
      ),
      body: BlocBuilder<${feature.pascalCase}Bloc, ${feature.pascalCase}State>(
        builder: (context, state) {
          return switch (state) {
            ${feature.pascalCase}Initial() => const ${feature.pascalCase}Loading(message: 'Loading...'),
            ${feature.pascalCase}Loading() => const ${feature.pascalCase}Loading(),
            ${feature.pascalCase}ListLoaded(:final ${feature.camelCase}s) => ${screen.pullToRefresh ? '''RefreshIndicator(
              onRefresh: () async {
                context.read<${feature.pascalCase}Bloc>().add(const ${feature.pascalCase}RefreshRequested());
              },
              child: _buildList(${feature.camelCase}s),
            )''' : '_buildList(${feature.camelCase}s)'},
            ${feature.pascalCase}Error(:final message) => ${feature.pascalCase}Error(
              message: message,
              onRetry: () => context.read<${feature.pascalCase}Bloc>().add(const ${feature.pascalCase}LoadRequested()),
            ),
            _ => const SizedBox(),
          };
        },
      ),
    );
  }

  Widget _buildList(List<${feature.pascalCase}Entity> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ${feature.pascalCase}ListItem(
          item: item,
          onTap: () {
            context.push('${feature.route}/\${item.id}');
          },
        );
      },
    );
  }
}
''';
  }

  static String _detailPage(
    ScreenSchema screen,
    FeatureSchema feature,
    String projectName,
  ) {
    return '''
/// ${screen.name} Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$projectName/core/di/injection_container.dart';
import '../bloc/${feature.snakeCase}_bloc.dart';
import '../widgets/${feature.snakeCase}_loading.dart';
import '../widgets/${feature.snakeCase}_error.dart';

/// ${screen.name} page showing detail view
class ${screen.name}Page extends StatelessWidget {
  final String id;

  const ${screen.name}Page({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<${feature.pascalCase}Bloc>()
        ..add(${feature.pascalCase}GetRequested(id: id)),
      child: _${screen.name}View(id: id),
    );
  }
}

class _${screen.name}View extends StatelessWidget {
  final String id;

  const _${screen.name}View({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${screen.appBar?.title ?? screen.name}'),
      ),
      body: BlocBuilder<${feature.pascalCase}Bloc, ${feature.pascalCase}State>(
        builder: (context, state) {
          return switch (state) {
            ${feature.pascalCase}Initial() => const ${feature.pascalCase}Loading(),
            ${feature.pascalCase}Loading() => const ${feature.pascalCase}Loading(),
            ${feature.pascalCase}Loaded(:final ${feature.camelCase}) => _buildContent(context, ${feature.camelCase}),
            ${feature.pascalCase}Error(:final message) => ${feature.pascalCase}Error(
              message: message,
              onRetry: () => context.read<${feature.pascalCase}Bloc>().add(${feature.pascalCase}GetRequested(id: id)),
            ),
            _ => const SizedBox(),
          };
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ${feature.pascalCase}Entity item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: \${item.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Created: \${item.createdAt}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          // TODO: Add more fields
        ],
      ),
    );
  }
}
''';
  }

  static String _formPage(
    ScreenSchema screen,
    FeatureSchema feature,
    String projectName,
  ) {
    return '''
/// ${screen.name} Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:$projectName/core/di/injection_container.dart';
import '../bloc/${feature.snakeCase}_bloc.dart';

/// ${screen.name} form page
class ${screen.name}Page extends StatelessWidget {
  const ${screen.name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<${feature.pascalCase}Bloc>(),
      child: const _${screen.name}View(),
    );
  }
}

class _${screen.name}View extends StatefulWidget {
  const _${screen.name}View();

  @override
  State<_${screen.name}View> createState() => _${screen.name}ViewState();
}

class _${screen.name}ViewState extends State<_${screen.name}View> {
  final _formKey = GlobalKey<FormState>();
  // TODO: Add form controllers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${screen.name}'),
      ),
      body: BlocConsumer<${feature.pascalCase}Bloc, ${feature.pascalCase}State>(
        listener: (context, state) {
          if (state is ${feature.pascalCase}OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.pop();
          } else if (state is ${feature.pascalCase}Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ${feature.pascalCase}Loading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // TODO: Add form fields
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Dispatch create/update event
    }
  }
}
''';
  }

  static String _staticPage(
    ScreenSchema screen,
    FeatureSchema feature,
    String projectName,
  ) {
    return '''
/// ${screen.name} Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$projectName/core/di/injection_container.dart';
import '../bloc/${feature.snakeCase}_bloc.dart';
import '../widgets/${feature.snakeCase}_loading.dart';
import '../widgets/${feature.snakeCase}_error.dart';

/// ${screen.name} page
class ${screen.name}Page extends StatelessWidget {
  const ${screen.name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<${feature.pascalCase}Bloc>()
        ..add(const ${feature.pascalCase}LoadRequested()),
      child: const _${screen.name}View(),
    );
  }
}

class _${screen.name}View extends StatelessWidget {
  const _${screen.name}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${screen.name}'),
      ),
      body: BlocBuilder<${feature.pascalCase}Bloc, ${feature.pascalCase}State>(
        builder: (context, state) {
          return switch (state) {
            ${feature.pascalCase}Initial() => const ${feature.pascalCase}Loading(),
            ${feature.pascalCase}Loading() => const ${feature.pascalCase}Loading(),
            ${feature.pascalCase}Loaded(:final ${feature.camelCase}) => _buildContent(context, ${feature.camelCase}),
            ${feature.pascalCase}ListLoaded(:final ${feature.camelCase}s) => _buildListContent(context, ${feature.camelCase}s),
            ${feature.pascalCase}Error(:final message) => ${feature.pascalCase}Error(
              message: message,
              onRetry: () => context.read<${feature.pascalCase}Bloc>().add(const ${feature.pascalCase}LoadRequested()),
            ),
            _ => const Center(child: Text('${screen.name}')),
          };
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ${feature.pascalCase}Entity item) {
    return Center(
      child: Text('Item: \${item.id}'),
    );
  }

  Widget _buildListContent(BuildContext context, List<${feature.pascalCase}Entity> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Item \${items[index].id}'),
        );
      },
    );
  }
}
''';
  }
}