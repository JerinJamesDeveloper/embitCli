Here is the updated README documentation for **Embit CLI v0.7.0**, incorporating the new `usecase` command features, auto-wiring capabilities, and updated workflow.

***

# Embit CLI Documentation

## Version 0.8.0

[![Version](https://img.shields.io/badge/version-0.7.0-blue.svg)](https://github.com/JerinJamesDeveloper/embitCli)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [What's New in 0.7.0](#whats-new-in-070)
- [Installation](#installation)
- [Commands](#commands)
  - [init](#init)
  - [feature](#feature)
  - [usecase](#usecase)
  - [build](#build)
  - [clean](#clean)
- [Feature Command Deep Dive](#feature-command-deep-dive)
- [UseCase Command Deep Dive](#usecase-command-deep-dive)
- [Examples](#examples)
- [Configuration](#configuration)
- [Changelog](#changelog)
- [Troubleshooting](#troubleshooting)

---

## Overview

**Embit CLI** is a powerful command-line interface tool designed to accelerate Flutter/Dart development by automating project scaffolding, feature generation, and enforcing Clean Architecture principles.

---

## What's New in 0.7.0

### 🚀 New Features

| Feature | Description |
|---------|-------------|
| **Granular UseCase Generation** | Create individual use cases for existing features without regenerating the whole module |
| **Automatic Architecture Wiring** | Automatically registers new use cases in **DI** (`injection_container`) and **BLoC** |
| **Smart Templates** | Pre-built templates for `get`, `get-list`, `create`, `update`, `delete`, and `custom` types |
| **Event Auto-Generation** | Optionally generate BLoC events and handlers automatically via `--with-event` |
| **Interactive Mode** | Updated interactive prompts for granular component creation |

### 🔄 Changes from 0.6.0

```diff
+ Added 'usecase' top-level command
+ Added --with-event flag to auto-generate BLoC events
+ Added --type option to specify use case template (get, create, etc.)
+ Improved DI injection logic to handle dynamic insertions
+ Updated feature generator to align with new use case structures
```

---

## Installation

### Via Dart Pub

```bash
dart pub global activate embit
```

### Verify Installation

```bash
embit --version
# Output: embit 0.8.0
```

---

## Commands

### init

Initialize a new Embit project or configure an existing Flutter project.

```bash
embit init [options]
```

### feature

Generate a new feature module with complete architecture and optional navigation.

```bash
embit feature --name <feature_name> [options]
```

See [Feature Command Deep Dive](#feature-command-deep-dive) for details.

### usecase

**[NEW]** Create a specific use case for an existing feature and wire it into the architecture.

```bash
embit usecase --feature <feature_name> --name <usecase_name> [options]
```

See [UseCase Command Deep Dive](#usecase-command-deep-dive) for details.

### build

Run build commands with Embit enhancements.

```bash
embit build [options]
```

### clean

Clean project build artifacts and generated files.

```bash
embit clean [options]
```

---

## Feature Command Deep Dive

Generate a new feature module.

```bash
embit feature --name <feature_name> [options]
```

#### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--name` | `-n` | Feature name (required) | — |
| `--nav-bar` | — | Include in navigation bar | `false` |
| `--icon` | `-i` | Nav bar icon | `Icons.circle_outlined` |
| `--label` | `-l` | Nav bar label | Feature Name |
| `--interactive` | `-i` | Guided mode | `false` |

---

## UseCase Command Deep Dive

The `usecase` command allows you to expand existing features by adding specific business logic units. It handles the tedious work of creating files, updating the repository interface, registering in Dependency Injection, and injecting into the BLoC.

```bash
embit usecase --feature <feature> --name <name> [options]
```

#### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--feature` | `-f` | Target feature name (required) | — |
| `--name` | `-n` | Use case name (snake_case) (required) | — |
| `--type` | `-t` | Template type (`get`, `get-list`, `create`, `update`, `delete`, `custom`) | `custom` |
| `--with-event` | — | Generate corresponding BLoC event | `false` |
| `--interactive` | `-i` | Guided creation mode | `false` |
| `--dry-run` | — | Preview changes without writing files | `false` |

#### Supported Types

| Type | Description |
|------|-------------|
| `get` | Fetches a single entity by ID |
| `get-list` | Fetches a list of entities (NoParams) |
| `create` | Accepts params to create an entity |
| `update` | Accepts ID and nullable fields for update |
| `delete` | Accepts ID to delete an entity |
| `custom` | Generic template with TODOs |

#### Example: Creating an Archive UseCase

```bash
embit usecase -f products -n archive_product --type update --with-event
```

**Output:**
```
🚀 Creating usecase: archive_product
   Feature: products
   Type: Update
   Event: ✓ Will generate

📝 Generated:
   ✓ lib/features/products/domain/usecases/archive_product_usecase.dart
   ✓ Added event to products_event.dart

🔧 Updated:
   ✓ lib/core/di/injection_container.dart (Registered UseCase)
   ✓ lib/features/products/presentation/bloc/products_bloc.dart (Injected dependency)

📋 Next steps:
   1. Add repository method in products_repository.dart
   2. Implement in products_repository_impl.dart
   3. Add event handler in products_bloc.dart
```

---

## Examples

### Complete Workflow Example

```bash
# 1. Initialize new project
embit init --name ecommerce_app --template clean

# 2. Create core features
embit feature --name products --nav-bar --label "Products"
embit feature --name cart --nav-bar --label "Cart"

# 3. Add specific business logic to 'products' feature
# Create a usecase to get featured products
embit usecase -f products -n get_featured_products -t get-list

# Create a usecase to archive a product, with BLoC event wiring
embit usecase -f products -n archive_product -t update --with-event

# 4. Interactive mode for complex logic
embit usecase -f cart -n validate_coupon --interactive
```

### Quick Commands Reference

```bash
# Standard Feature
embit feature -n orders

# Granular UseCase (Get Single)
embit usecase -f orders -n get_order_details -t get

# Granular UseCase (Custom Logic)
embit usecase -f auth -n verify_biometrics -t custom --with-event
```

---

## Configuration

### embit.yaml

Project-level configuration file.

```yaml
version: 0.7.0

project:
  name: my_app
  org: com.example

architecture:
  pattern: clean
  state_management: bloc

features:
  default_path: lib/features/
  
usecases:
  auto_register_di: true    # Automatically update injection_container.dart
  auto_update_bloc: true    # Automatically inject into BLoC constructor
```

---

## Changelog

### Version 0.7.0 (Latest)

#### Added
- ✨ **New `usecase` command**: Generate individual use cases.
- ✨ **Auto-Wiring**: The CLI now modifies `injection_container.dart` and `_bloc.dart` files to inject new use cases automatically.
- ✨ **Templates**: Added specific templates for CRUD operations.
- ✨ **Event Generation**: Added `--with-event` flag to create BLoC events for new use cases.

#### Changed
- 📦 `feature` command now generates a more modular DI structure to support dynamic insertion.
- 📦 Updated validation logic to ensure features exist before adding use cases.

### Version 0.6.0

- ✨ Navigation bar integration.
- ✨ Custom icons and labels support.

---

## Troubleshooting

### Common Issues

**Issue: "Feature does not exist"**
```bash
# You must create the feature before adding a usecase
embit feature -n my_feature
embit usecase -f my_feature -n my_usecase
```

**Issue: "UseCase already exists"**
```bash
# Use --force to overwrite an existing usecase file
embit usecase -f products -n get_products --force
```

**Issue: "DI Injection failed"**
```bash
# Embit relies on specific markers (comments) in your code to inject dependencies.
# If you deleted comments like "// ========== Use Cases ==========", 
# the CLI might print manual instructions instead of auto-updating.
```

---

## Support

- 📖 [Documentation](https://embit.dev/docs)
- 🐛 [Issue Tracker](https://github.com/embit-cli/issues)

---

## Made with ❤️ by the Embit Team