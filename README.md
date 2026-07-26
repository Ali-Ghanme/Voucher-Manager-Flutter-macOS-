<div align="center">

# 🎫 Voucher Manager
### مدير بطاقات الفاوتشر

**A production-ready Flutter macOS desktop app for managing and selling Wi-Fi/Internet voucher cards extracted from PDF batches.**

[![Flutter](https://img.shields.io/badge/Flutter-3.3%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-blueviolet)](#-architecture)
[![State Management](https://img.shields.io/badge/State-Riverpod-41D2A0)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](#-license)

[English](#-overview) • [العربية](#-نظرة-عامة)

</div>

---

## 📖 Overview

**Voucher Manager** streamlines the workflow of selling prepaid Wi-Fi/Internet
voucher cards. Batches of voucher codes are extracted directly from PDF
files, then sold one card (or many) at a time — either copied to the
clipboard for a WhatsApp message, or displayed in large, high-contrast
text in a compact always-on-top window for reading off a phone's SMS app.

The core design goal is **data integrity**: every sale is an atomic
database transaction, so a voucher can never be sold twice, even under
rapid consecutive sales.

<!-- 📸 Add a screenshot or GIF of the app here -->
<!-- ![screenshot](docs/screenshot.png) -->

---

## ✨ Features

- 📄 **PDF Import** — extract username/password voucher pairs directly from PDF batch files using layout-agnostic regex pairing
- ⚡ **One-click bulk dispense** — quick chips for `1 / 2 / 5 / 10 / 20` cards or a custom quantity
- 🔒 **Atomic, transaction-safe sales** — SQLite transactions guarantee no voucher is ever sold twice, even with rapid clicks
- 📋 **Instant clipboard copy** — a ready-to-send Arabic message is generated and copied automatically for WhatsApp
- 🪟 **Compact always-on-top window** — large, high-contrast, tap-to-copy username/password display for manually retyping into SMS apps
- ↩️ **Undo / refund** — revert the last sale within a configurable time window
- 🚫 **Void damaged cards** — mark individual vouchers as unusable without affecting stock accuracy
- 📊 **Daily summary dashboard** — sales today, completed batches, active stock, at a glance
- 🔁 **Batch reset & delete** — wipe a batch's sales back to zero, or remove it entirely
- 🎉 **Sell-through analytics** — automatic "sold out in X days, Y hours" reporting when a batch completes

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.3.0 or later, with macOS desktop support enabled
- Xcode (for building/signing the macOS app)
- CocoaPods (`sudo gem install cocoapods`)

### Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/voucher-manager.git
cd voucher-manager

# If the macos/ platform folder needs to be (re)generated for your machine:
flutter create --platforms=macos .

# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d macos
```

> **Note:** The included `macos/Runner/*.entitlements` files grant the two
> App Sandbox permissions the app needs: picking a PDF via the native Open
> Panel, and read/write access for its own local SQLite database under
> Application Support. If you regenerate the `macos/` folder with
> `flutter create`, re-apply these entitlements afterward.

### Building a release

```bash
flutter build macos --release
```

The finished app bundle will be at:
```
build/macos/Build/Products/Release/voucher_manager.app
```

---

## 🏗️ Architecture

The project follows **Clean Architecture**, split into clearly separated
layers so business logic stays independent of any specific UI framework
or storage engine.

```
lib/
├── core/                     # Cross-cutting concerns
│   ├── constants/             # App-wide constants & tunables
│   ├── utils/                 # Regex extraction helpers
│   ├── theme/                 # App theming
│   └── error/                 # Typed exceptions
│
├── data/                      # Data layer
│   ├── models/                 # Voucher, Batch — entities + (de)serialization
│   ├── datasources/            # DatabaseHelper — sqflite_common_ffi schema & connection
│   ├── services/                # PdfParserService — PDF text extraction & pairing
│   └── repositories/            # VoucherRepositoryImpl — atomic transactions & business rules
│
├── domain/                    # Domain layer
│   └── repositories/            # VoucherRepository — abstract contract + DTOs
│
├── presentation/               # Presentation layer
│   ├── providers/                # Riverpod: repository provider, StateNotifier, immutable state
│   ├── screens/                   # MainScreen (dashboard), CompactFloatingScreen
│   └── widgets/                    # Reusable UI components & dialogs
│
└── main.dart                   # App entry point — window_manager bootstrap
```

**Key principle:** the presentation layer only ever depends on the
abstract `VoucherRepository` contract in `domain/` — never on SQLite
directly. This means the storage engine could be swapped (e.g. for Isar)
without touching a single widget or provider.

| Layer | Responsibility |
|---|---|
| **Domain** | Defines *what* the app can do (contracts), independent of *how* |
| **Data** | Implements *how* — SQLite persistence, PDF parsing, transaction logic |
| **Presentation** | Riverpod state management + UI, consumes only the domain contract |

---

## 🔐 How Double-Selling Is Prevented

Every state-mutating operation — **import**, **dispense**, **undo**,
**void**, **reset**, **delete** — runs inside a single
`db.transaction()` block in `VoucherRepositoryImpl`.

For a dispense operation specifically:

1. Inside the transaction, select the first *N* rows where
   `status = 'AVAILABLE'` for the active batch.
2. If fewer than *N* rows are available, an `InsufficientStockException`
   is thrown and the transaction is rolled back — nothing is written.
3. Otherwise, all *N* rows are updated to `SOLD` (tagged with a shared
   `transactionId` and timestamp), and the batch's `soldVouchers`
   counter is incremented, all before the transaction commits.

Because SQLite serializes writers within a transaction, two dispense
calls firing in quick succession can never claim the same rows — the
second call will simply see fewer `AVAILABLE` rows once the first
transaction commits.

A unique index on `(batchId, username, password)` additionally guards
against importing duplicate cards from a PDF with repeated entries.

---

## 🗺️ Feature-to-File Map

| Feature | Location |
|---|---|
| PDF import & parsing | `data/services/pdf_parser_service.dart` |
| Atomic batch dispense | `data/repositories/voucher_repository_impl.dart` → `dispenseVouchers()` |
| Clipboard message builder | `voucher_repository_impl.dart` → `_buildClipboardMessage()` |
| Compact always-on-top window | `presentation/screens/compact_floating_screen.dart` |
| Quick dispense chips | `presentation/widgets/quick_action_chips.dart` |
| Undo / refund | `undoLastTransaction()` + `canUndo` timeout logic |
| Void a card | `voidVoucher()` |
| Reset / delete a batch | `resetBatch()` / `deleteBatch()` |
| Batch completion dialog | `presentation/widgets/batch_completion_dialog.dart` |
| Daily summary dashboard | `getDailySummary()` + `_DailySummaryCard` |

---

## 🧯 Edge Cases Handled

| Scenario | Behavior |
|---|---|
| Empty PDF / no matches found | `EmptyPdfException` / `RegexMismatchException` — import aborted before any DB write |
| Username with no adjacent password | Skipped silently by the tokenizer/pairing walk |
| Database busy or locked | Wrapped as `DatabaseOperationException` with a user-facing message |
| Undo requested after timeout | `UndoNotAvailableException`; the Undo button also proactively disables via `canUndo` |
| Zero remaining stock | Quick-dispense chips disable automatically; `BatchCompletionDialog` triggers with sell-through duration |
| Duplicate or concurrent imports | Enforced via a unique DB index + `ConflictAlgorithm.ignore` |

---

## 📦 Tech Stack

| Purpose | Package |
|---|---|
| State management | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) |
| Local database | [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) |
| Window management | [`window_manager`](https://pub.dev/packages/window_manager) |
| PDF parsing | [`syncfusion_flutter_pdf`](https://pub.dev/packages/syncfusion_flutter_pdf) |
| File selection | [`file_picker`](https://pub.dev/packages/file_picker) |
| App icon generation | [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) |

---

## 🛣️ Roadmap / Suggested Next Steps

- [ ] Encrypt the local database (SQLCipher via `sqflite_common_ffi`) if voucher data is sensitive
- [ ] Settings screen for configurable undo timeout & quick-dispense presets
- [ ] Automated tests for `PdfParserService` pairing logic and repository transaction behavior
- [ ] Code signing & notarization workflow for public distribution
- [ ] Export daily/batch sales reports (CSV/PDF)

Contributions are welcome — feel free to open an issue or pull request.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<br>

<div align="center">

## 🇸🇦 نظرة عامة

</div>

**مدير بطاقات الفاوتشر** هو تطبيق سطح مكتب لنظام macOS مبني بـ Flutter،
مخصص لإدارة وبيع بطاقات فاوتشر الواي فاي/الإنترنت التي يتم استخراجها من
ملفات PDF. يتم استخراج البطاقات مباشرة من الملف، ثم بيعها (بطاقة واحدة أو
عدة بطاقات دفعة واحدة) — إما عبر نسخ الرسالة تلقائياً لإرسالها في واتساب،
أو عرضها بخط كبير وواضح في نافذة عائمة مصغّرة تبقى دائماً في المقدمة،
لتسهيل كتابتها يدوياً في تطبيق الرسائل (SMS).

الهدف الأساسي من التصميم هو **حماية البيانات من الأخطاء**: كل عملية بيع
هي عملية قاعدة بيانات ذرية (atomic transaction)، بحيث يستحيل بيع نفس
البطاقة مرتين، حتى مع الضغط السريع المتكرر.

### أبرز الميزات

- 📄 استيراد بطاقات الفاوتشر مباشرة من ملفات PDF
- ⚡ بيع سريع بضغطة واحدة: `1 / 2 / 5 / 10 / 20` بطاقة، أو عدد مخصص
- 🔒 عمليات بيع آمنة تماماً من التكرار (atomic transactions)
- 📋 نسخ تلقائي لرسالة جاهزة للإرسال عبر واتساب
- 🪟 نافذة عائمة مصغّرة دائمة الظهور، بخط كبير وواضح، مع نسخ بلمسة واحدة
- ↩️ إمكانية التراجع عن آخر عملية بيع خلال مدة زمنية محددة
- 🚫 تعليم البطاقات التالفة كـ "مبطلة"
- 📊 لوحة ملخص يومي: المبيعات، الدفعات المكتملة، المخزون النشط
- 🔁 إعادة ضبط أو حذف أي دفعة بالكامل
- 🎉 عرض تلقائي لمدة بيع كل دفعة عند اكتمالها بالكامل

### التشغيل

```bash
git clone https://github.com/<اسم-المستخدم>/voucher-manager.git
cd voucher-manager
flutter create --platforms=macos .   # إذا احتجت توليد مجلد macos من جديد
flutter pub get
flutter run -d macos
```

لمزيد من التفاصيل حول البنية المعمارية، ومنع تكرار البيع، وحالات الاستثناء
التي يتعامل معها التطبيق، راجع الأقسام الإنجليزية أعلاه — الكود والتعليقات
داخل المشروع موثّقة بالإنجليزية لتسهيل المساهمة من مطورين آخرين.
