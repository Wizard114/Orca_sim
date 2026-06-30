# AGENTS.md

This file guides coding agents working in this repository.

## 1) Project summary

Orca Sim is a Flutter app for service providers to:
- authenticate with Firebase/Auth (email+password and Google Sign-In)
- register company profile and app settings
- create, edit, list, approve/reject budgets (orcamentos)
- generate and share PDF budget documents
- generate monthly financial report PDFs

Main language: Dart (Flutter).
Main backend: Firebase Auth + Cloud Firestore.

## 2) Source map

Primary app code is in `lib/`:
- `lib/main.dart`: app bootstrap, Firebase init, locale init, theme notifier
- `lib/injection.dart`: GetIt service/repository/usecase/controller registration
- `lib/app/pages/`: current presentation layer views/controllers
  - `splash/`, `login/`, `home/`, `company/`, `budget/`, `report/`, `pdf_preview/`
- `lib/domain/`: contracts, entities, and use cases
  - repositories, services, usecases, entities
- `lib/data/`: implementations for services and repositories
  - `lib/data/services/auth_service.dart`
  - `lib/data/services/firestore_service.dart`
  - `lib/data/services/pdf_service.dart`

Legacy root folders `lib/pages/`, `lib/services/`, and `lib/firestore_service.dart` were removed in migration.

Platform folders (`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`) are mostly Flutter generated shell code.

## 3) Data model (Firestore)

Current active service expects:

Collection path:
- `usuarios/{uid}` (account + workspace link)
- `empresas/{cnpj_normalizado}` (company workspace)

User document keys used by migration:
- `email` (String)
- `cnpj` (String formatted)
- `cnpj_normalizado` (String, 14 digits)
- `ultima_sessao` (Timestamp)

Company/settings keys:
- `nome_empresa` (String)
- `cnpj` (String)
- `cnpj_normalizado` (String)
- `telefone` (String)
- `endereco` (String)
- `logo_local_path` (String?)
- `validade_orcamento` (int)
- `tema_app` (String: `Claro`, `Escuro`, or `Sistema`)
- `cor_pdf` (String with int-like color value)
- `dia_fechamento` (int 1-31)

Subcollection path:
- `empresas/{cnpj_normalizado}/orcamentos/{docId}`
- `empresas/{cnpj_normalizado}/produtos/{nome_normalizado}`

Budget document keys used by current pages/services:
- `cliente_nome` (String)
- `cliente_cpf_cnpj` (String)
- `nome_obra` (String)
- `observacoes` (String)
- `data` (Timestamp/DateTime)
- `total` (num)
- `status` (String: `Pendente`, `Aprovado`, `Recusado`)
- `itens` (List<Map>) with keys:
  - `descricao`
  - `quantidade`
  - `unidade`
  - `valor`
  - `produto_key` (optional)

Product document keys:
- `nome`
- `nome_normalizado`
- `unidade`
- `preco_centavos`
- `preco` (compatibility mirror)
- `usage_count`
- `created_at`
- `updated_at`

Important: keep field names consistent with `lib/data/services/firestore_service.dart` and app pages/controllers.

## 4) Critical workflows

Auth flow:
1. `main.dart` initializes Firebase.
2. `SplashView` checks current user.
3. If logged in, preload product catalog and navigate to `HomeView`; otherwise navigate to `LoginView`.
4. `LoginView` supports password recovery (`recuperarSenha`) through usecase/repository/service chain.

Budget flow:
1. Create/edit in `NewBudgetView`.
2. Persist through `FirestoreService.salvarOrcamento`.
3. Sync products through `FirestoreService.sincronizarProdutosAoSalvarOrcamento`.
4. Item modal suggests products from local in-memory cache and autofills unit/value.
5. Item modal uses add-session behavior: "Adicionar Item" keeps modal open, "Finalizar" closes and returns a list of items.
6. Edit mode in item modal returns a single updated item.
7. Generate bytes with `PdfService.gerarPdfOrcamentoBytes`.
8. Show/share via `PdfPreviewView`.

Financial report flow:
1. `ReportView` computes cycle using `dia_fechamento`.
2. Fetches approved budgets in period from company workspace.
3. Computes "most used products" from that selected month's budget items (`itens`), not from catalog lifetime counters.
4. Calls `PdfService.gerarRelatorioFinanceiro`.
5. Opens `PdfPreviewView` for sharing.

Theme/config flow:
1. User edits in `CompanyView`.
2. Saved to Firestore company doc + local image path.
3. App theme switched via `themeNotifier` in `main.dart` with support for `ThemeMode.system`.

## 5) Commands for agents

Install deps:
- `flutter pub get`

Static checks:
- `flutter analyze`

Run tests:
- `flutter test`

Run app:
- `flutter run`

Build APK (release):
- `flutter build apk --release`

## 6) Known issues and pitfalls

1. Firestore workspace coupling:
- Company-scoped operations depend on valid `cnpj_normalizado` (14 digits) in `usuarios/{uid}`.
- If CNPJ is invalid/missing, company-scoped budget/product operations become no-op by design.

2. Transitional compatibility:
- `pegarDadosEmpresa` currently includes legacy fallback from `usuarios/{uid}`.
- Do not remove fallback unless migration/backfill strategy is done.

3. Firestore composite index risk:
- Queries combining `where` and `orderBy` may require Firestore indexes.
- If runtime asks for index creation, create it in Firebase console.

4. Firebase config files are not committed:
- `.gitignore` ignores `google-services.json`.
- Ensure local Firebase setup exists before running on device.

5. Android package duplication:
- Both paths exist:
  - `android/app/src/main/kotlin/com/aegisstudios/orcasim/MainActivity.kt`
  - `android/app/src/main/kotlin/com/example/orca_sim/MainActivity.kt`
- Active `applicationId` is `com.aegisstudios.orcasim`.

6. Side effects in build:
- `main.dart` still triggers theme load from inside build path.
- Be careful when refactoring; avoid repeated async calls causing UI churn.

## 7) Editing rules for agents

- Prefer minimal targeted changes.
- Do not edit generated platform files unless task requires it.
- Preserve Portuguese UX strings unless user requests copy rewrite.
- Keep controllers as logic owners; avoid moving business rules to views.
- Keep view state in controllers: views should consume controller-owned state (including `ValueNotifier`s and `TextEditingController`s).
- In `*_view.dart`, avoid mutable page state fields. Keep only the controller reference and pure UI helper methods.
- If a view needs a mutable value, add it to the corresponding controller first (including init/update/dispose lifecycle).
- When changing Firestore fields, update all impacted services/repositories/usecases/views in the same PR.
- For new feature fields, keep backward-safe defaults when reading old docs.

## 8) Controller-Owned State Contract

Current contract across pages in `lib/app/pages/`:
- `NewBudgetView` consumes form controllers and mutable state from `NewBudgetController` (`itens`, `produtoKeys`, `gerandoPdf`, customer/work text fields).
- `CompanyView` consumes all mutable form/theme/logo state from `CompanyController` (text fields, selected options, logo file/path, `uiTick`).
- `ProductsView` consumes `ProductsController` state (`produtos`, `carregando`, search field controller).
- `ReportView` consumes `ReportController` notifiers (`mesSelecionado`, `carregando`, `listaOrcamentos`, `totalFaturado`, `produtosMaisUsados`).
- `HomeView` consumes `HomeController` notifier and mutable visibility/config state.
- `LoginView` consumes `LoginController` for auth mode/loading/notifiers and email/password text fields.
- `SplashView` consumes `SplashController` for route decision, preload behavior, and splash animation objects.

Lifecycle requirements:
- Controllers that own `TextEditingController`, `ValueNotifier`, or animation objects must expose `dispose()` and release all owned resources.
- Views must call `controller.dispose()` in `State.dispose()` when using factory-scoped controllers.

## 9) Definition of done for code changes

Before finishing:
1. `flutter analyze` passes (or known unrelated warnings documented).
2. Core flow touched by change is manually smoke-tested.
3. Any Firestore schema changes are reflected in read+write paths.
4. PDF generation still works for budget and report screens.

## 10) Checkpoint status (2026-03-22)

- Step 1 completed: company-scoped settings/budgets wired in service layer.
- Step 2 completed: product cache preload and sync-on-budget-save implemented.
- Step 3 completed: budget item suggestions/autofill and optional `produto_key` persistence.
- Step 4 partial: rules/index files added; deploy and backfill execution still pending.
- Step 5 completed: password recovery flow added (login page + usecase/repository/service).
- Step 6 completed: financial report now includes most-used products for selected month based on monthly budgets.
- Step 7 completed: controller-first state migration finalized for pages under `lib/app/pages/`; view files consume controller-owned mutable state.
- Step 8 completed: text-input ownership migration finalized; page form `TextEditingController`s now live in controllers.

## 11) Suggested next tasks (optional)

- Deploy Firestore rules/indexes in Firebase project and validate with emulator/console.
- Execute backfill for legacy user-scoped budgets following runbook.
- Add unit tests for CNPJ/product normalization and centavos conversion.
- Add integration tests for budget save + product synchronization.
- Add tests for item modal list-return contract (add-many + finalize behavior).
- Add tests for report monthly product aggregation from budget items.
