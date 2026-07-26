# مدير بطاقات الفاوتشر — Voucher Manager (Flutter macOS)

Production-ready Flutter **macOS desktop** app for importing Wi-Fi/Internet
voucher cards from PDF batches and selling them via WhatsApp (quick copy)
or manual SMS (compact floating display), with atomic stock control so a
voucher can never be sold twice.

## Getting started

```bash
flutter create --platforms=macos --project-name voucher_manager .   # if macos/ needs re-generating on your machine
flutter pub get
flutter run -d macos
```

> The `macos/Runner/*.entitlements` files included here already grant the
> two permissions the app needs inside the App Sandbox: picking a PDF via
> the native Open Panel, and read/write access for its own SQLite file
> under Application Support.

## Architecture (Clean Architecture)

```
lib/
  core/                    # cross-cutting: constants, regex, theme, exceptions
  data/
    models/                # Voucher, Batch — entity + SQLite (de)serialization
    datasources/           # DatabaseHelper — sqflite_common_ffi schema & connection
    services/               # PdfParserService — Syncfusion PDF text extraction + pairing
    repositories/           # VoucherRepositoryImpl — atomic transactions, business rules
  domain/
    repositories/           # VoucherRepository (abstract contract) + DTOs
  presentation/
    providers/               # Riverpod: repository provider, StateNotifier, immutable state
    screens/                  # MainScreen (dashboard), CompactFloatingScreen
    widgets/                  # StockIndicator, VoucherDisplayPanel, QuickActionChips, dialogs
  main.dart                  # window_manager bootstrap + app root
```

The presentation layer never touches SQLite directly — it only knows
`VoucherRepository` (the abstract contract in `domain/`). This means the
storage engine (currently `sqflite_common_ffi`) could be swapped for Isar
without touching a single widget or provider.

## How double-selling is prevented

Every mutating operation — **import**, **dispense**, **undo**, **void** —
runs inside a single `db.transaction()` block in
`VoucherRepositoryImpl`. For dispense specifically:

1. Inside the transaction, select the first *N* rows where
   `status = 'AVAILABLE'` for the active batch.
2. If fewer than *N* rows come back, throw `InsufficientStockException`
   and the transaction rolls back — nothing is written.
3. Otherwise, update all *N* rows to `SOLD` (with a shared
   `transactionId` and timestamp) and increment the batch's
   `soldVouchers` counter, all before the transaction commits.

Because SQLite serializes writers within a transaction, two dispense
calls firing at the same moment cannot both claim the same rows — one
will simply see fewer `AVAILABLE` rows once the first transaction
commits.

A unique index on `(batchId, username, password)` additionally guards
against importing duplicate cards from a PDF with repeated OCR
artifacts.

## Feature-to-file map

| Feature | Where |
|---|---|
| PDF import & parsing | `data/services/pdf_parser_service.dart` |
| Atomic batch dispense | `data/repositories/voucher_repository_impl.dart` → `dispenseVouchers` |
| Clipboard message | `voucher_repository_impl.dart` → `_buildClipboardMessage` |
| Compact always-on-top window | `presentation/screens/compact_floating_screen.dart` + `window_manager` calls in `main_screen.dart` |
| Quick chips `[1][2][5][10][20]` + custom | `presentation/widgets/quick_action_chips.dart` |
| Undo / refund | `undoLastTransaction()` in repository + `canUndo` timeout logic |
| Void a card | `voidVoucher()` |
| Batch completion dialog + duration | `presentation/widgets/batch_completion_dialog.dart` |
| Daily summary dashboard | `getDailySummary()` + `_DailySummaryCard` in `main_screen.dart` |

## Edge cases handled

- **Empty PDF / no matches** → `EmptyPdfException` / `RegexMismatchException`,
  surfaced as a SnackBar; the batch import is aborted before any DB write.
- **Regex mismatch** (username with no adjacent password) → that token is
  simply skipped by the tokenizer/pairing walk in `PdfParserService`.
- **DB lock / busy** → wrapped as `DatabaseOperationException` with a
  friendly Arabic message.
- **Undo timeout** → `undoLastTransaction()` checks
  `AppConstants.undoTimeoutSeconds` (default 120s) and throws
  `UndoNotAvailableException` once expired; the Undo button also
  disables itself proactively via `canUndo`.
- **Zero remaining stock** → quick-action chips disable themselves
  (`enabled: maxAvailable >= n`), and hitting exactly zero triggers the
  `BatchCompletionDialog` with sell-through duration and an import CTA.
- **Concurrent/duplicate imports** → unique index at the DB layer plus
  `ConflictAlgorithm.ignore` on insert.

## Suggested next steps for production

- Add `sqflite_common_ffi`'s encryption wrapper (SQLCipher) if voucher
  data is sensitive.
- Add a settings screen to make `undoTimeoutSeconds` and quick-dispense
  presets user-configurable.
- Add automated tests around `PdfParserService._extractPairsFromText`
  (already isolated from PDF I/O for testability) and around the
  repository's transaction logic using an in-memory `databaseFactoryFfi`.
