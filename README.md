# SmartWallet - Expense Tracker (Phase 3)

A feature-rich, offline-first personal expense tracker built with Flutter, focusing on multi-currency support and rich data visualization.

## Features
- **Multi-Currency Support:** Convert and display expenses in 15+ global currencies (PKR, USD, EUR, GBP, etc.).
- **Rich Data Visualization:** Interactive Pie and Bar charts using `fl_chart`.
- **Offline-First:** All data is stored locally using `hive`.
- **Budget Management:** Set a global monthly budget and track your spending progress.
- **Premium UI:** Dark/Light mode support with vibrant categorical color coding.

## Setup Instructions
1. Ensure you have the latest stable version of Flutter installed.
2. Clone or open the repository.
3. Run `flutter pub get` to fetch dependencies.
4. Run `flutter run` to build and launch the app on your preferred device/emulator.

## Architecture Overview
The application follows a Feature-First structure leaning towards Domain-Driven Design (DDD). State management is handled by `flutter_riverpod`, ensuring a reactive, testable, and clean UI.
- `lib/core/`: Application constants, theming, currency services, and routing.
- `lib/features/expenses/`: Core CRUD operations, models, and providers.
- `lib/features/dashboard/`: The main UI hub.
- `lib/features/analytics/`: Charting logic and data aggregation.
- `lib/features/settings/`: Currency selection and budget management.

## Currency Conversion Logic
The app maintains a robust `CurrencyService` with base conversion rates relative to USD.
When a user switches their global currency, the app instantly recalculates all historical expenses via `CurrencyService.convert()` and updates the UI through Riverpod's reactive providers without modifying the source-of-truth entries in Hive. Non-native entries also display an approximate converted value beneath the exact logged amount.

## Charting Library
This project uses `fl_chart`. It was chosen over `syncfusion_flutter_charts` due to its completely open-source nature, high customizability, and excellent support for interactive, smooth animations which are critical for a premium UX feel.
