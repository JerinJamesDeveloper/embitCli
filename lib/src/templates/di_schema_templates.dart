/// DI Schema Templates
library;

import '../models/schema/feature_schema.dart';
import '../models/usecase_config.dart';

class DISchemaTemplates {
  DISchemaTemplates._();

  static String imports(
    FeatureSchema schema,
    List<UseCaseConfig> usecases,
    String projectName,
  ) {
    final usecaseImports = usecases.map((uc) =>
      "import 'package:$projectName/features/${schema.snakeCase}/domain/usecases/${uc.useCaseSnakeCase}_usecase.dart';"
    ).join('\n');

    return '''
// ${schema.pascalCase} Feature
import 'package:$projectName/features/${schema.snakeCase}/data/datasources/${schema.snakeCase}_remote_datasource.dart';
import 'package:$projectName/features/${schema.snakeCase}/data/datasources/${schema.snakeCase}_local_datasource.dart';
import 'package:$projectName/features/${schema.snakeCase}/data/repositories/${schema.snakeCase}_repository_impl.dart';
import 'package:$projectName/features/${schema.snakeCase}/domain/repositories/${schema.snakeCase}_repository.dart';
$usecaseImports
import 'package:$projectName/features/${schema.snakeCase}/presentation/bloc/${schema.snakeCase}_bloc.dart';
''';
  }

  static String featureRegistration(
    FeatureSchema schema,
    List<UseCaseConfig> usecases,
    String projectName,
  ) {
    final usecaseRegistrations = usecases.map((uc) => '''
  sl.registerLazySingleton<${uc.useCaseClassName}>(
    () => ${uc.useCaseClassName}(sl()),
  );''').join('\n\n');

    final blocUsecaseParams = usecases.map((uc) =>
      '      ${uc.useCaseCamelCase}UseCase: sl(),'
    ).join('\n');

    return '''
/// Initialize ${schema.pascalCase} feature
void _init${schema.pascalCase}Feature() {
  // ========== Data Sources ==========
  sl.registerLazySingleton<${schema.pascalCase}RemoteDataSource>(
    () => ${schema.pascalCase}RemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<${schema.pascalCase}LocalDataSource>(
    () => ${schema.pascalCase}LocalDataSourceImpl(sl()),
  );

  // ========== Repository ==========
  sl.registerLazySingleton<${schema.pascalCase}Repository>(
    () => ${schema.pascalCase}RepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // ========== Use Cases ==========
$usecaseRegistrations

  // ========== BLoC ==========
  sl.registerFactory<${schema.pascalCase}Bloc>(
    () => ${schema.pascalCase}Bloc(
$blocUsecaseParams
    ),
  );
}
''';
  }
}