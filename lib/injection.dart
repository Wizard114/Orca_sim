import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orca_sim/app/pages/budget/new_budget_controller.dart';
import 'package:orca_sim/app/pages/company/company_controller.dart';
import 'package:orca_sim/app/pages/home/home_controller.dart';
import 'package:orca_sim/app/pages/login/login_controller.dart';
import 'package:orca_sim/app/pages/pdf_preview/pdf_preview_controller.dart';
import 'package:orca_sim/app/pages/products/products_controller.dart';
import 'package:orca_sim/app/pages/report/report_controller.dart';
import 'package:orca_sim/app/pages/splash/splash_controller.dart';
import 'package:orca_sim/data/repositories/auth_repository.dart';
import 'package:orca_sim/data/repositories/budget_repository.dart';
import 'package:orca_sim/data/repositories/company_repository.dart';
import 'package:orca_sim/data/repositories/pdf_repository.dart';
import 'package:orca_sim/data/services/auth_service.dart';
import 'package:orca_sim/data/services/firestore_service.dart';
import 'package:orca_sim/data/services/pdf_service.dart';
import 'package:orca_sim/domain/repositories/auth_repository.dart';
import 'package:orca_sim/domain/repositories/budget_repository.dart';
import 'package:orca_sim/domain/repositories/company_repository.dart';
import 'package:orca_sim/domain/repositories/pdf_repository.dart';
import 'package:orca_sim/domain/services/auth_service.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';
import 'package:orca_sim/domain/services/pdf_service.dart';
import 'package:orca_sim/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/login_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/logout_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/recover_password_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/register_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/delete_budget_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/get_budgets_by_period_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/save_budget_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/stream_budgets_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/update_budget_status_usecase.dart';
import 'package:orca_sim/domain/usecases/company/get_company_data_usecase.dart';
import 'package:orca_sim/domain/usecases/company/save_company_data_usecase.dart';
import 'package:orca_sim/domain/usecases/pdf/generate_budget_pdf_usecase.dart';
import 'package:orca_sim/domain/usecases/pdf/generate_financial_report_pdf_usecase.dart';

final getIt = GetIt.instance;

void inject() {
  _injectServices();
  _injectRepositories();
  _injectUseCases();
  _injectControllers();
}

void _injectServices() {
  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(
      () => FirebaseAuth.instance,
    );
  }

  if (!getIt.isRegistered<GoogleSignIn>()) {
    getIt.registerLazySingleton<GoogleSignIn>(
      () => GoogleSignIn(),
    );
  }

  if (!getIt.isRegistered<IAuthService>()) {
    getIt.registerLazySingleton<IAuthService>(
      () => AuthService(
        auth: getIt(),
        googleSignIn: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<IAuthService>()) {
    getIt.registerLazySingleton<IAuthService>(
      () => AuthService(),
    );
  }

  if (!getIt.isRegistered<IFirestoreService>()) {
    getIt.registerLazySingleton<IFirestoreService>(() => FirestoreService());
  }

  if (!getIt.isRegistered<IPdfService>()) {
    getIt.registerLazySingleton<IPdfService>(
      () => PdfService(getIt<IFirestoreService>()),
    );
  }
}

void _injectRepositories() {
  if (!getIt.isRegistered<IAuthRepository>()) {
    getIt.registerLazySingleton<IAuthRepository>(
      () => AuthRepository(getIt<IAuthService>()),
    );
  }

  if (!getIt.isRegistered<ICompanyRepository>()) {
    getIt.registerLazySingleton<ICompanyRepository>(
      () => CompanyRepository(getIt<IFirestoreService>()),
    );
  }

  if (!getIt.isRegistered<IBudgetRepository>()) {
    getIt.registerLazySingleton<IBudgetRepository>(
      () => BudgetRepository(getIt<IFirestoreService>()),
    );
  }

  if (!getIt.isRegistered<IPdfRepository>()) {
    getIt.registerLazySingleton<IPdfRepository>(
      () => PdfRepository(getIt<IPdfService>()),
    );
  }
}

void _injectUseCases() {
  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<IAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<RegisterUseCase>()) {
    getIt.registerLazySingleton<RegisterUseCase>(
      () => RegisterUseCase(getIt<IAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<RecoverPasswordUseCase>()) {
    getIt.registerLazySingleton<RecoverPasswordUseCase>(
      () => RecoverPasswordUseCase(getIt<IAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignInWithGoogleUseCase>()) {
    getIt.registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(getIt<IAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCurrentUserUseCase>()) {
    getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt<IAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LogoutUseCase>()) {
    getIt.registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(getIt<IAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCompanyDataUseCase>()) {
    getIt.registerLazySingleton<GetCompanyDataUseCase>(
      () => GetCompanyDataUseCase(getIt<ICompanyRepository>()),
    );
  }

  if (!getIt.isRegistered<SaveCompanyDataUseCase>()) {
    getIt.registerLazySingleton<SaveCompanyDataUseCase>(
      () => SaveCompanyDataUseCase(getIt<ICompanyRepository>()),
    );
  }

  if (!getIt.isRegistered<StreamBudgetsUseCase>()) {
    getIt.registerLazySingleton<StreamBudgetsUseCase>(
      () => StreamBudgetsUseCase(getIt<IBudgetRepository>()),
    );
  }

  if (!getIt.isRegistered<SaveBudgetUseCase>()) {
    getIt.registerLazySingleton<SaveBudgetUseCase>(
      () => SaveBudgetUseCase(getIt<IBudgetRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateBudgetStatusUseCase>()) {
    getIt.registerLazySingleton<UpdateBudgetStatusUseCase>(
      () => UpdateBudgetStatusUseCase(getIt<IBudgetRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteBudgetUseCase>()) {
    getIt.registerLazySingleton<DeleteBudgetUseCase>(
      () => DeleteBudgetUseCase(getIt<IBudgetRepository>()),
    );
  }

  if (!getIt.isRegistered<GetBudgetsByPeriodUseCase>()) {
    getIt.registerLazySingleton<GetBudgetsByPeriodUseCase>(
      () => GetBudgetsByPeriodUseCase(getIt<IBudgetRepository>()),
    );
  }

  if (!getIt.isRegistered<GenerateBudgetPdfUseCase>()) {
    getIt.registerLazySingleton<GenerateBudgetPdfUseCase>(
      () => GenerateBudgetPdfUseCase(getIt<IPdfRepository>()),
    );
  }

  if (!getIt.isRegistered<GenerateFinancialReportPdfUseCase>()) {
    getIt.registerLazySingleton<GenerateFinancialReportPdfUseCase>(
      () => GenerateFinancialReportPdfUseCase(getIt<IPdfRepository>()),
    );
  }
}

void _injectControllers() {
  if (!getIt.isRegistered<LoginController>()) {
    getIt.registerFactory<LoginController>(
      () => LoginController(
        getIt<LoginUseCase>(),
        getIt<RegisterUseCase>(),
        getIt<RecoverPasswordUseCase>(),
        getIt<SignInWithGoogleUseCase>(),
        getIt<IFirestoreService>(),
      ),
    );
  }

  if (!getIt.isRegistered<SplashController>()) {
    getIt.registerFactory<SplashController>(
      () => SplashController(
        getIt<GetCurrentUserUseCase>(),
        getIt<IFirestoreService>(),
      ),
    );
  }

  if (!getIt.isRegistered<HomeController>()) {
    getIt.registerFactory<HomeController>(
      () => HomeController(
        getIt<GetCurrentUserUseCase>(),
        getIt<LogoutUseCase>(),
        getIt<GetCompanyDataUseCase>(),
        getIt<StreamBudgetsUseCase>(),
        getIt<UpdateBudgetStatusUseCase>(),
        getIt<DeleteBudgetUseCase>(),
        getIt<GenerateBudgetPdfUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<CompanyController>()) {
    getIt.registerFactory<CompanyController>(
      () => CompanyController(
        getIt<GetCompanyDataUseCase>(),
        getIt<SaveCompanyDataUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<NewBudgetController>()) {
    getIt.registerFactory<NewBudgetController>(
      () => NewBudgetController(
        getIt<SaveBudgetUseCase>(),
        getIt<GenerateBudgetPdfUseCase>(),
        getIt<IFirestoreService>(),
      ),
    );
  }

  if (!getIt.isRegistered<ReportController>()) {
    getIt.registerFactory<ReportController>(
      () => ReportController(
        getIt<GetCompanyDataUseCase>(),
        getIt<GetBudgetsByPeriodUseCase>(),
        getIt<GenerateFinancialReportPdfUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<PdfPreviewController>()) {
    getIt.registerFactory<PdfPreviewController>(
      () => PdfPreviewController(),
    );
  }

  if (!getIt.isRegistered<ProductsController>()) {
    getIt.registerFactory<ProductsController>(
      () => ProductsController(getIt<IFirestoreService>()),
    );
  }
}
