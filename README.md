# Embit CLI Documentation

## Version 0.9.3

[![Version](https://img.shields.io/badge/version-0.9.3-blue.svg)](https://github.com/JerinJamesDeveloper/embitCli)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview-section)
  - [What's New in 0.9.3](#whats-new-in-093)
  - [What's New in 0.9.2](#whats-new-in-092)
  - [What's New in 0.9.1](#whats-new-in-091)
  - [What's New in 0.9.0](#whats-new-in-090)
  - [What's New in 0.8.0](#whats-new-in-080)
- [Installation](#installation)
- [Commands](#commands)
  - [init](#init)
  - [feature](#feature)
  - [usecase](#usecase)
  - [generate](#generate)
  - [build](#build)
  - [clean](#clean)
- [Feature Command Deep Dive](#feature-command-deep-dive)
- [UseCase Command Deep Dive](#usecase-command-deep-dive)
- [Generate Command Deep Dive](#generate-command-deep-dive)
- [JSON Schema Reference](#json-schema-reference)
- [Examples](#examples)
- [Configuration](#configuration)
- [Changelog](#changelog)
- [Troubleshooting](#troubleshooting)

---

## Overview Section

**Embit CLI** is a powerful command-line interface tool designed to accelerate Flutter/Dart development by automating project scaffolding, feature generation, and enforcing Clean Architecture principles.

### Key Features

- 🏗️ **Clean Architecture Scaffolding** - Generate features with proper layer separation
- 🔌 **Auto-Wiring** - Automatic DI registration, routing, and BLoC integration
- 📄 **JSON Schema Generation** - Define features declaratively in JSON
- ⚡ **Smart Templates** - Pre-built templates for common patterns
- 🧭 **Navigation Integration** - Automatic bottom nav and routing setup


---

## Installation

### Via Direct Git Repo

```bash
dart pub global activate --source git https://github.com/JerinJamesDeveloper/embitCli.git

```

### Via Dart Pub

```bashg
dart pub global activate embit
```

### Verify Installation

```bash
embit --version
# Output: embit 0.9.0
```

---

## What's New in 0.9.3

### 🎯 Model-Specific BLoC Generation

Completely refactored how BLoCs are generated for models! Instead of appending states to the main feature BLoC (which caused chaos with mixed concerns), `embit model --with-state` now creates **dedicated BLoCs** for each model.

#### New Structure

```bash
embit model -f check -n Newcheck --string name --with-state
```

**Creates:**
```
lib/features/check/
└── presentation/
    └── bloc/
        ├── check_bloc.dart (Main feature BLoC)
        ├── check_event.dart
        ├── check_state.dart
        └── models/  ← NEW!
            ├── newcheck_bloc.dart
            ├── newcheck_event.dart
            └── newcheck_state.dart
```

#### Interactive BLoC Selection for UseCases

When using `embit usecase --with-event`, the CLI now detects all available BLoCs and prompts you to select which one should receive the event handler:

```bash
embit usecase -f check -n archive --with-event

📋 Multiple BLoCs detected. Select target:
  1. CheckBloc (Main feature BLoC)
  2. NewcheckBloc (Model BLoC)
  3. Skip event generation (manual)

Choice [1-3]: 2
```

**Non-Interactive Mode:**
```bash
embit usecase -f check -n archive --with-event --target-bloc=newcheck
```

#### Benefits
- ✅ **Separation of Concerns** - Each model has its own BLoC
- ✅ **Cleaner Code** - No more repetitive `_getCurrentItems()` methods with different prefixes
- ✅ **Auto DI Registration** - Model BLoCs automatically registered in `injection_container.dart`
- ✅ **Better Maintainability** - Easy to locate and modify model-specific logic

---

## What's New in 0.9.2

### 🚀 Local Data Source Generation

Added automatic generation of local data sources when creating models. This provides a ready-to-use implementation for caching data using `LocalStorage`.

```bash
embit model -f products -n Product --string name
```

This will now also generate:
- `lib/features/products/data/datasources/product_local_datasource.dart` containing `ProductLocalDataSource` and `ProductLocalDataSourceImpl`.

---

## What's New in 0.9.1

### 🚀 Auto-state Generation for Models

Added the ability to automatically generate BLoC states when creating a new model. This streamlines the process of adding new data entities to an existing feature.

```bash
embit model -f products -n Product --string name --with-state
```

This will:
1. Generate Entity and Model files.
2. Automatically append `ProductLoading`, `ProductLoaded`, etc., to your BLoC state file.
3. Automatically import the new Entity in your BLoC file.

---

## What's New in 0.9.0

### 🚀 JSON-Based Behavioral Compiler

The biggest update yet! Define your entire feature using a JSON schema, and Embit will generate everything automatically.

```
┌─────────────────────────────────────────────────────────────┐
│  📄 JSON Schema (templates/products.json)                   │
│  ↓                                                          │
│  🔍 Schema Parser → Validates & Extracts UseCases           │
│  ↓                                                          │
│  ⚡ Feature Generator → Complete Clean Architecture         │
│  ↓                                                          │
│  ✅ Ready-to-use Feature with all layers wired!             │
└─────────────────────────────────────────────────────────────┘
```

### ✨ New Features

| Feature | Description |
|---------|-------------|
| **`generate` Command** | Generate complete features from JSON schema files |
| **Schema Parser** | Validates and parses JSON schemas with helpful error messages |
| **UseCase Extraction** | Automatically extracts usecases from `dataSource` and `action` fields |
| **Type Inference** | Infers usecase types (get, get-list, create, update, delete) from naming |
| **Entity Generation** | Generates entity from schema-defined fields |
| **Multi-Screen Support** | Define multiple screens per feature with different types |
| **Widget Templates** | Pre-built widget templates (CardList, GridView, Form, etc.) |
| **Bottom Sheet Support** | Define reusable bottom sheets in schema |
| **API Endpoint Generation** | Auto-generates API endpoint constants |

### 🔄 Changes from 0.8.1

```diff
+ Added 'generate' command for JSON schema-based generation
+ Added templates/ folder creation during 'init'
+ Added example.json template during 'init'
+ Added FeatureSchema, ScreenSchema, WidgetSchema, ActionSchema models
+ Added UseCaseSchema extraction from JSON
+ Added SchemaParser with validation and warnings
+ Added SchemaFeatureGenerator integrating with UseCaseTypeTemplates
+ Added screen type templates (infinite_list, detail, form, static, grid)
+ Added bottomSheets support in schema
+ Added entity field definitions in schema
+ Added explicit usecases array support in schema
+ Updated init command to create templates folder with examples
```

### 📝 Quick Example

**1. Create a schema file:**

```json
// templates/orders.json
{
  "feature": {
    "name": "orders",
    "route": "/orders",
    "addToBottomNav": true,
    "icon": "receipt",
    "label": "Orders"
  },
  "screens": [
    {
      "name": "OrderList",
      "type": "infinite_list",
      "route": "/orders",
      "dataSource": "getOrders",
      "pullToRefresh": true,
      "widgets": [
        {
          "name": "orderList",
          "template": "CardList",
          "dataSource": "getOrders",
          "onTap": {
            "type": "navigation",
            "navTo": "/orders/{id}"
          }
        }
      ]
    },
    {
      "name": "OrderDetail",
      "type": "detail",
      "route": "/orders/:orderId",
      "dataSource": "getOrderById"
    }
  ]
}
```

**2. Generate the feature:**

```bash
embit generate -s templates/orders.json
```

**3. Result:** Complete feature with 2 screens, 2 usecases, full BLoC, DI wiring, and routing!

---

## What's New in 0.8.0

### 🚀 Custom Params Fields

| Feature | Description |
|---------|-------------|
| **Custom Params Fields** | Define custom fields using `--string`, `--int`, `--double`, `--bool`, `--datetime` |
| **Field Syntax** | Support for required (`fieldName`) and nullable (`fieldName?`) fields |
| **Auto-Validation** | Automatically generates validation code for required String fields |
| **Full Stack Support** | Custom fields propagate to BLoC events, repository methods, and data source |

### 📝 Usage Example

```bash
embit usecase -f products -n create_product -t custom \
  --string productName \
  --string "description?" \
  --double price \
  --int quantity \
  --with-event
```
---

## Commands

### init

Initialize a new Embit project or configure an existing Flutter project.

```bash
embit init [options]
```

**New in 0.9.0:** Creates `templates/` folder with example JSON schemas.

| Option | Description | Default |
|--------|-------------|---------|
| `--force` | Force initialization | `false` |
| `--skip-pubspec` | Skip updating pubspec.yaml | `false` |

### feature

Generate a new feature module with complete architecture.

```bash
embit feature --name <feature_name> [options]
```

See [Feature Command Deep Dive](#feature-command-deep-dive).

### usecase

Create a specific use case for an existing feature.

```bash
embit usecase --feature <feature_name> --name <usecase_name> [options]
```

See [UseCase Command Deep Dive](#usecase-command-deep-dive).

### generate

**[NEW in 0.9.0]** Generate complete feature from JSON schema.

```bash
embit generate --schema <path_to_schema.json> [options]
```

See [Generate Command Deep Dive](#generate-command-deep-dive).

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

Generate a new feature module with the standard structure.

```bash
embit feature --name <feature_name> [options]
```

#### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--name` | `-n` | Feature name in snake_case (required) | — |
| `--nav-bar` | — | Add to bottom navigation bar | `false` |
| `--icon` | — | Navigation bar icon | `Icons.folder_outlined` |
| `--label` | — | Navigation bar label | Feature name |
| `--force` | `-f` | Force overwrite existing | `false` |
| `--dry-run` | — | Preview without creating | `false` |
| `--interactive` | `-i` | Guided creation mode | `false` |

#### Generated Structure

```
lib/features/<feature_name>/
├── data/
│   ├── datasources/
│   │   ├── <feature>_remote_datasource.dart
│   │   └── <feature>_local_datasource.dart
│   ├── models/
│   │   └── <feature>_model.dart
│   └── repositories/
│       └── <feature>_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── <feature>_entity.dart
│   ├── repositories/
│   │   └── <feature>_repository.dart
│   └── usecases/
│       ├── get_<feature>_usecase.dart
│       └── ...
└── presentation/
    ├── bloc/
    │   ├── <feature>_bloc.dart
    │   ├── <feature>_event.dart
    │   └── <feature>_state.dart
    ├── pages/
    │   └── <feature>_page.dart
    └── widgets/
        └── ...
```

---

## UseCase Command Deep Dive

Add specific business logic to existing features with automatic architecture wiring.

```bash
embit usecase --feature <feature> --name <name> [options]
```

#### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--feature` | `-f` | Target feature name (required) | — |
| `--name` | `-n` | UseCase name in snake_case (required) | — |
| `--type` | `-t` | Template type | `custom` |
| `--with-event` | `-e` | Generate BLoC event & handler | `false` |
| `--string` | — | Add String field to Params | — |
| `--int` | — | Add int field to Params | — |
| `--double` | — | Add double field to Params | — |
| `--bool` | — | Add bool field to Params | — |
| `--datetime` | — | Add DateTime field to Params | — |
| `--force` | — | Force overwrite existing | `false` |
| `--dry-run` | — | Preview without creating | `false` |

#### Supported Types

| Type | Description | Generated Pattern |
|------|-------------|-------------------|
| `get` | Fetch single entity | `getEntityById(id)` |
| `get-list` | Fetch list of entities | `getEntities(page, limit, ...)` |
| `create` | Create new entity | `createEntity(params)` |
| `update` | Update existing entity | `updateEntity(id, params)` |
| `delete` | Delete entity | `deleteEntity(id)` |
| `custom` | Custom logic | Generic template |

#### Auto-Wiring

The usecase command automatically:
- ✅ Creates usecase file with proper template
- ✅ Updates repository interface with method signature
- ✅ Updates repository implementation with method body
- ✅ Updates remote data source with API call
- ✅ Registers in DI container (`injection_container.dart`)
- ✅ Injects into BLoC constructor
- ✅ Adds BLoC event and handler (if `--with-event`)
- ✅ Updates state operation enum (if `--with-event`)

---

## Generate Command Deep Dive

**[NEW in 0.9.0]** The most powerful command! Generate complete features from JSON schema files.

```bash
embit generate --schema <path> [options]
```

#### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--schema` | `-s` | Path to JSON schema file (required) | — |
| `--force` | `-f` | Force overwrite existing | `false` |
| `--dry-run` | — | Preview without creating | `false` |
| `--skip-di` | — | Skip DI container update | `false` |
| `--skip-routes` | — | Skip route updates | `false` |
| `--verbose` | — | Detailed output | `false` |

#### How It Works

```
1. Parse JSON schema
2. Extract feature configuration
3. Extract all screens
4. Extract usecases from:
   - screen.dataSource
   - widget.dataSource
   - widget.action (type: "usecase")
   - widget.onTap (type: "usecase")
5. Infer usecase types from naming
6. Generate complete feature using templates
7. Wire everything (DI, routes, navigation)
```

#### What Gets Generated

| Layer | Files |
|-------|-------|
| **Domain** | Entity, Repository interface, All UseCases |
| **Data** | Model, Remote DataSource, Local DataSource, Repository Impl |
| **Presentation** | BLoC (with all events/states), Pages (per screen), Widgets |
| **Wiring** | DI registration, Routes, Navigation bar, API endpoints |

#### Example Usage

```bash
# Basic generation
embit generate -s templates/products.json

# Preview first
embit generate -s templates/products.json --dry-run

# Force overwrite
embit generate -s templates/products.json --force

# Verbose output
embit generate -s templates/products.json --verbose
```

---

## JSON Schema Reference

### Schema Structure

```json
{
  "feature": { ... },        // Feature configuration
  "entity": { ... },         // Entity fields (optional)
  "screens": [ ... ],        // Screen definitions
  "bottomSheets": { ... },   // Reusable bottom sheets (optional)
  "usecases": [ ... ],       // Explicit usecase definitions (optional)
  "apiEndpoints": { ... }    // API endpoint mappings (optional)
}
```

### Feature Configuration

```json
{
  "feature": {
    "name": "products",           // Required: snake_case name
    "route": "/products",         // Base route path
    "addToBottomNav": true,       // Add to bottom navigation
    "icon": "shopping_bag",       // Material icon name
    "label": "Products"           // Navigation label
  }
}
```

### Entity Definition

```json
{
  "entity": {
    "name": "Product",
    "fields": [
      { "name": "id", "type": "String", "required": true },
      { "name": "name", "type": "String", "required": true },
      { "name": "description", "type": "String", "nullable": true },
      { "name": "price", "type": "double", "required": true },
      { "name": "stock", "type": "int", "default": "0" },
      { "name": "isActive", "type": "bool", "default": "true" },
      { "name": "tags", "type": "List<String>", "default": "const []" },
      { "name": "createdAt", "type": "DateTime", "required": true }
    ]
  }
}
```

### Screen Types

| Type | Description | Use Case |
|------|-------------|----------|
| `static` | Fixed content | Settings, About pages |
| `infinite_list` | Paginated scrolling list | Product list, Feed |
| `detail` | Single item display | Product detail, Profile |
| `form` | Input form | Create/Edit screens |
| `grid` | Grid layout | Gallery, Categories |

### Screen Definition

```json
{
  "screens": [
    {
      "name": "ProductList",
      "type": "infinite_list",
      "route": "/products",
      "dataSource": "getProducts",      // → Creates getProducts usecase
      "pullToRefresh": true,
      "hasSearch": true,
      "appBar": {
        "title": "Products",
        "showBack": false,
        "actions": [
          {
            "icon": "search",
            "action": { "type": "navigation", "navTo": "/search" }
          }
        ]
      },
      "state": [
        { "name": "searchQuery", "type": "String", "default": "''" },
        { "name": "sortBy", "type": "String", "default": "'newest'" }
      ],
      "widgets": [ ... ]
    }
  ]
}
```

### Widget Templates

| Template | Description | Props |
|----------|-------------|-------|
| `CardList` | Vertical card list | `itemTemplate`, `dataSource` |
| `GridView` | Grid layout | `crossAxisCount`, `childAspectRatio` |
| `HorizontalScroller` | Horizontal scroll list | `height`, `itemWidth` |
| `ListView` | Simple list | `itemTemplate` |
| `SearchField` | Search input | `placeholder`, `autofocus` |
| `TextField` | Text input | `label`, `maxLength`, `maxLines` |
| `Button` | Action button | `label`, `icon`, `style` |
| `FilterChips` | Filter options | `options` |
| `Carousel` | Image carousel | `height`, `showIndicators` |
| `ExpansionTile` | Expandable section | `title`, `initiallyExpanded` |
| `EmptyState` | Empty placeholder | `icon`, `title`, `message` |

### Widget Definition

```json
{
  "name": "productGrid",
  "template": "GridView",
  "dataSource": "getProducts",
  "props": {
    "crossAxisCount": 2,
    "childAspectRatio": 0.7
  },
  "itemTemplate": "ProductCard",
  "onTap": {
    "type": "navigation",
    "navTo": "/products/{id}"
  },
  "onLongPress": {
    "type": "bottomSheet",
    "name": "quickActions"
  },
  "visibleWhen": "products.isNotEmpty",
  "enabledWhen": "!isLoading"
}
```

### Action Types

| Type | Description | Properties |
|------|-------------|------------|
| `navigation` | Navigate to route | `navTo`, `navReplace` |
| `usecase` | Call a usecase | `name`, `params`, `onSuccess`, `onError` |
| `event` | Emit BLoC event | `name`, `params` |
| `setState` | Update local state | `name`, value mapping |
| `bottomSheet` | Show bottom sheet | `name` |
| `dialog` | Show dialog | `name` |
| `share` | Share content | `params` |
| `snackbar` | Show snackbar | `message`, `type` |

### Action Definition

```json
{
  "action": {
    "type": "usecase",
    "name": "addToCart",
    "params": ["productId", "quantity"],
    "confirmation": {
      "title": "Add to Cart?",
      "message": "Add this item to your cart?",
      "confirmLabel": "Add",
      "cancelLabel": "Cancel"
    },
    "onSuccess": {
      "showSnackbar": {
        "message": "Added to cart!",
        "type": "success"
      },
      "navTo": "/cart"
    },
    "onError": {
      "showSnackbar": {
        "message": "Failed to add",
        "type": "error"
      }
    }
  }
}
```

### Explicit UseCase Definition

```json
{
  "usecases": [
    {
      "name": "getProducts",
      "type": "get-list",
      "params": [
        { "name": "page", "type": "int", "nullable": true },
        { "name": "limit", "type": "int", "nullable": true },
        { "name": "search", "type": "String", "nullable": true }
      ],
      "generateEvent": true
    },
    {
      "name": "addToCart",
      "type": "custom",
      "params": [
        { "name": "productId", "type": "String", "required": true },
        { "name": "quantity", "type": "int", "default": "1" }
      ],
      "generateEvent": true
    }
  ]
}
```

### Bottom Sheets

```json
{
  "bottomSheets": {
    "productFilters": {
      "title": "Filter Products",
      "widgets": [
        {
          "name": "priceRange",
          "template": "RangeSlider",
          "props": { "label": "Price", "min": 0, "max": 1000 }
        },
        {
          "name": "applyButton",
          "template": "Button",
          "props": { "label": "Apply Filters" },
          "action": { "type": "event", "name": "applyFilters" }
        }
      ]
    }
  }
}
```

---

## Examples

### Complete Workflow Example

```bash
# 1. Initialize project
embit init

# 2. Create feature via JSON schema
embit generate -s templates/products.json

# 3. Add additional usecase to existing feature
embit usecase -f products -n archive_product -t update --with-event

# 4. Create simple feature without schema
embit feature -n settings

# 5. Add usecase with custom fields
embit usecase -f settings -n update_preferences -t update \
  --string theme \
  --bool "notifications?" \
  --with-event
```

### Quick Reference

```bash
# Generate from schema
embit generate -s templates/orders.json

# Preview generation
embit generate -s templates/orders.json --dry-run

# Create simple feature
embit feature -n profile --nav-bar

# Add usecase to feature
embit usecase -f profile -n update_avatar -t update --with-event

# Usecase with custom fields
embit usecase -f orders -n create_order -t create \
  --string customerId \
  --double totalAmount \
  --with-event
```

### Sample Schema Files

After running `embit init`, check `templates/` folder for:
- `example.json` - Basic example schema
- `README.md` - Schema documentation

---

## Configuration

### embit.yaml

Project-level configuration file.

```yaml
version: 0.9.4

project:
  name: my_app
  org: com.example

architecture:
  pattern: clean
  state_management: bloc

features:
  default_path: lib/features/
  
usecases:
  auto_register_di: true
  auto_update_bloc: true

generate:
  templates_path: templates/
  auto_extract_usecases: true
  generate_events: true
```

---

## Changelog

### Version 0.9.4 (Latest)

#### Changed
- 🔄 **BLoC/State Separation**: `embit model --with-state` now creates **only** states file, no longer creates BLoC or events
- 🔄 **Clear Responsibilities**: Model command focuses on state structure, UseCase command handles BLoC and events with `--with-event`
- ♻️ **Removed Conflicts**: Eliminates generation conflicts between model and usecase commands

---

### Version 0.9.2

#### Added
- ✨ **Local Data Source Generation**: `embit model` command now generates local data source files (e.g., `product_local_datasource.dart`) using `LocalStorage`.

---

### Version 0.9.3

#### Added
- ✨ **Model-Specific BLoC Generation**: `embit model --with-state` now creates dedicated BLoCs in `presentation/bloc/models/` instead of appending to feature BLoC
- ✨ **Interactive BLoC Selection**: `embit usecase --with-event` prompts to select target BLoC when multiple exist
- ✨ **`--target-bloc` Flag**: Non-interactive BLoC targeting for CI/CD workflows
- ✨ **Auto DI Registration**: Model BLoCs automatically registered in `injection_container.dart`

#### Changed
- 🔄 **BLoC Architecture**: Each model now has its own isolated BLoC with proper separation of concerns
- 🔄 **Event Naming**: Events now use correct BLoC prefix (e.g., `NewcheckArchiveRequested` instead of `CheckArchiveRequested`)

### Version 0.9.1

#### Added
- ✨ **Model State Generation**: New `--with-state` flag for `embit model` command to auto-generate BLoC states.
- ✨ **Auto-Import**: Automatically adds entity imports to BLoC files when using `--with-state`.

### Version 0.9.0

#### Added
- ✨ **`generate` Command**: Generate complete features from JSON schema files
- ✨ **Schema Parser**: Validates JSON schemas with helpful error messages and warnings
- ✨ **UseCase Extraction**: Automatically extracts usecases from `dataSource` and `action` fields
- ✨ **Type Inference**: Infers usecase types from naming conventions
- ✨ **Entity Generation**: Generates entity from schema-defined fields
- ✨ **Multi-Screen Support**: Define multiple screens with different types per feature
- ✨ **Widget Templates**: Pre-built templates (CardList, GridView, Form, etc.)
- ✨ **Bottom Sheet Support**: Define reusable bottom sheets in schema
- ✨ **Screen Types**: `static`, `infinite_list`, `detail`, `form`, `grid`
- ✨ **Templates Folder**: `embit init` now creates `templates/` with examples
- ✨ **Explicit UseCases**: Optional `usecases` array for precise control
- ✨ **API Endpoints**: Auto-generates endpoint constants

#### Changed
- 📦 `init` command now creates `templates/` folder with `example.json`
- 📦 Improved error messages with suggestions
- 📦 Better validation for all commands

### Version 0.8.1

#### Added
- ✨ Custom Params fields (`--string`, `--int`, `--double`, `--bool`, `--datetime`)
- ✨ Field syntax for required/nullable fields
- ✨ Auto-validation for required String fields

### Version 0.8.0

- ✨ Model command improvements
- ✨ Enhanced template generation

### Version 0.7.0

- ✨ `usecase` command with auto-wiring
- ✨ BLoC event generation (`--with-event`)
- ✨ CRUD templates

### Version 0.6.0

- ✨ Navigation bar integration
- ✨ Custom icons and labels

---

## Troubleshooting

### Common Issues

**Issue: "Schema file not found"**
```bash
# Ensure path is correct (relative to project root)
embit generate -s templates/products.json  # ✓
embit generate -s ./templates/products.json  # ✓
```

**Issue: "Invalid JSON"**
```bash
# Validate your JSON syntax
# Use a JSON validator or IDE with JSON support
# Common issues:
#   - Trailing commas
#   - Missing quotes on keys
#   - Single quotes instead of double
```

**Issue: "Feature already exists"**
```bash
# Use --force to overwrite
embit generate -s templates/products.json --force
```

**Issue: "UseCase type inference failed"**
```bash
# Use explicit usecases array in schema
{
  "usecases": [
    { "name": "myUseCase", "type": "custom", ... }
  ]
}
```

**Issue: "DI injection failed"**
```bash
# Ensure injection_container.dart has required markers:
# "// ==================== END OF FEATURE ===================="
# If markers are missing, CLI will print manual instructions
```

**Issue: "Route update failed"**
```bash
# Ensure route_names.dart has markers:
# "// ============== ADD YOUR ROUTES =============="
# "// ============== ADD YOUR ROUTE NAMES =============="
```

### Debug Mode

```bash
# Use --verbose for detailed output
embit generate -s templates/products.json --verbose

# Use --dry-run to preview without creating files
embit generate -s templates/products.json --dry-run
```

---

## Support

- 📖 [Documentation](https://embit.dev/docs)
- 🐛 [Issue Tracker](https://github.com/embit-cli/issues)
- 💬 [Discussions](https://github.com/embit-cli/discussions)

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Made with ❤️ by the Embit Team
```

---

## Summary of 0.9.0 Changes

| Area | What's New |
|------|------------|
| **Command** | New `generate` command for JSON schema generation |
| **Schema** | Complete JSON schema format for features |
| **Extraction** | Auto-extracts usecases from dataSource/actions |
| **Inference** | Infers usecase types from naming conventions |
| **Templates** | Pre-built widget templates |
| **Screens** | Multiple screen types (list, detail, form, etc.) |
| **Init** | Creates templates folder with examples |
| **Wiring** | Complete auto-wiring (DI, routes, nav, endpoints) |