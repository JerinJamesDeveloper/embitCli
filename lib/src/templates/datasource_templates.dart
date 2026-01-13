import '../models/feature_config.dart';

class DataSourceTemplates {
  /// Remote data source template
  static String remoteDataSource(FeatureConfig config) => '''
/// ${config.pascalCase} Remote Data Source
///
/// Handles API calls for ${config.name} operations.
/// Communicates with the backend ${config.name} endpoints.
library;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/${config.snakeCase}_model.dart';

/// Abstract interface for ${config.name} remote data source
abstract class ${config.pascalCase}RemoteDataSource {
  /// Gets a ${config.name} by ID
  Future<${config.pascalCase}Model> get${config.pascalCase}(String id);

  /// Gets all ${config.name}s
  Future<List<${config.pascalCase}Model>> getAll${config.pascalCase}s();

  /// Creates a new ${config.name}
  Future<${config.pascalCase}Model> create${config.pascalCase}({
    required String name,
    String? description,
  });

  /// Updates an existing ${config.name}
  Future<${config.pascalCase}Model> update${config.pascalCase}({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  });

  /// Deletes a ${config.name}
  Future<void> delete${config.pascalCase}(String id);
}

/// Implementation of ${config.pascalCase}RemoteDataSource
class ${config.pascalCase}RemoteDataSourceImpl implements ${config.pascalCase}RemoteDataSource {
  final DioClient _dioClient;

  ${config.pascalCase}RemoteDataSourceImpl(this._dioClient);

  @override
  Future<${config.pascalCase}Model> get${config.pascalCase}(String id) async {
    try {
      final response = await _dioClient.get(
        '\${ApiEndpoints.get${config.camelCase}s}/\$id',
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return ${config.pascalCase}Model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get ${config.name}: \$e');
    }
  }

  @override
  Future<List<${config.pascalCase}Model>> getAll${config.pascalCase}s() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.getall${config.camelCase}s);

      final data = response.data as Map<String, dynamic>;
      final listData = data['data'] as List? ?? [];

      return listData
          .map((item) => ${config.pascalCase}Model.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get ${config.name}s: \$e');
    }
  }

  @override
  Future<${config.pascalCase}Model> create${config.pascalCase}({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.create${config.camelCase}s,
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return ${config.pascalCase}Model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to create ${config.name}: \$e');
    }
  }

  @override
  Future<${config.pascalCase}Model> update${config.pascalCase}({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _dioClient.put(
        '\${ApiEndpoints.update${config.camelCase}s}/\$id',
        data: updateData,
      );

      final data = response.data as Map<String, dynamic>;
      final itemData = data['data'] as Map<String, dynamic>? ?? data;

      return ${config.pascalCase}Model.fromJson(itemData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to update ${config.name}: \$e');
    }
  }

  @override
  Future<void> delete${config.pascalCase}(String id) async {
    try {
      await _dioClient.delete('\${ApiEndpoints.delete${config.camelCase}s}/\$id');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to delete ${config.name}: \$e');
    }
  }
}
''';

  /// Local data source template
  static String localDataSource(FeatureConfig config) => '''
/// ${config.pascalCase} Local Data Source
///
/// Handles local storage operations for ${config.name} data.
/// Uses LocalStorage for caching.
library;

import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/${config.snakeCase}_model.dart';

/// Storage key for ${config.name} cache
const String _${config.camelCase}CacheKey = 'cached_${config.snakeCase}s';

/// Abstract interface for ${config.name} local data source
abstract class ${config.pascalCase}LocalDataSource {
  /// Gets a cached ${config.name} by ID
  Future<${config.pascalCase}Model?> get${config.pascalCase}(String id);

  /// Gets all cached ${config.name}s
  Future<List<${config.pascalCase}Model>> getAll${config.pascalCase}s();

  /// Caches a ${config.name}
  Future<void> cache${config.pascalCase}(${config.pascalCase}Model ${config.camelCase});

  /// Caches all ${config.name}s
  Future<void> cacheAll${config.pascalCase}s(List<${config.pascalCase}Model> ${config.camelCase}s);

  /// Removes a cached ${config.name}
  Future<void> remove${config.pascalCase}(String id);
  
  /// Clears all cached ${config.name}s
  Future<void> clearCache();
}

/// Implementation of ${config.pascalCase}LocalDataSource
class ${config.pascalCase}LocalDataSourceImpl implements ${config.pascalCase}LocalDataSource {
  final LocalStorage _storage;

  ${config.pascalCase}LocalDataSourceImpl(this._storage);

  @override
  Future<${config.pascalCase}Model?> get${config.pascalCase}(String id) async {
    try {
      final all = await getAll${config.pascalCase}s();
      return all.where((item) => item.id == id).firstOrNull;
    } catch (e) {
      throw StorageException(message: 'Failed to get ${config.name}: \$e');
    }
  }

  @override
  Future<List<${config.pascalCase}Model>> getAll${config.pascalCase}s() async {
    try {
      final jsonString = await _storage.getString(_${config.camelCase}CacheKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ${config.pascalCase}Model.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageException(message: 'Failed to get ${config.name}s: \$e');
    }
  }

  @override
  Future<void> cache${config.pascalCase}(${config.pascalCase}Model ${config.camelCase}) async {
    try {
      final all = await getAll${config.pascalCase}s();
      final index = all.indexWhere((item) => item.id == ${config.camelCase}.id);
      
      if (index >= 0) {
        all[index] = ${config.camelCase};
      } else {
        all.add(${config.camelCase});
      }

      await _saveAll(all);
    } catch (e) {
      throw StorageException(message: 'Failed to cache ${config.name}: \$e');
    }
  }

  @override
  Future<void> cacheAll${config.pascalCase}s(List<${config.pascalCase}Model> ${config.camelCase}s) async {
    try {
      await _saveAll(${config.camelCase}s);
    } catch (e) {
      throw StorageException(message: 'Failed to cache ${config.name}s: \$e');
    }
  }

  @override
  Future<void> remove${config.pascalCase}(String id) async {
    try {
      final all = await getAll${config.pascalCase}s();
      all.removeWhere((item) => item.id == id);
      await _saveAll(all);
    } catch (e) {
      throw StorageException(message: 'Failed to remove ${config.name}: \$e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _storage.remove(_${config.camelCase}CacheKey);
    } catch (e) {
      throw StorageException(message: 'Failed to clear cache: \$e');
    }
  }

  Future<void> _saveAll(List<${config.pascalCase}Model> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _storage.setString(_${config.camelCase}CacheKey, jsonEncode(jsonList));
  }
}
''';
}