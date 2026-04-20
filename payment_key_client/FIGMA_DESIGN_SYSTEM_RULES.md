# Figma Design System Rules — payment_key_client

This document describes the **design system structure** of the payment_key_client Flutter project so that Figma designs can be aligned with code via the Model Context Protocol (MCP). Use it when mapping Figma tokens/components to Flutter and when generating or updating UI from designs.

---

## 1. Design System Structure

### 1.1 Token Definitions

**Current state:** There is **no dedicated design-tokens file**. The example app uses Flutter’s built-in theme and inline values.

- **Where tokens would go:** Define design tokens in a single place so Figma variables map cleanly:
  - **Recommended:** `example/lib/theme/app_theme.dart` (or `example/lib/design_system/tokens.dart`) for the example app; for a shared design system across apps, use a package like `payment_key_client_ui` with `lib/src/theme/tokens.dart`.
- **Format/structure:** Use Dart constants and `ThemeData` / `ColorScheme` / `TextTheme` so one source of truth drives the app.

**Example structure to add:**

```dart
// example/lib/theme/app_tokens.dart (to create)
class AppTokens {
  // Colors — map from Figma color variables
  static const Color primary = Color(0xFF4F46E5);      // indigo-600
  static const Color success = Color(0xFF059669);      // green-600
  static const Color error = Color(0xFFDC2626);        // red-600
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color errorSurface = Color(0xFFFEF2F2);

  // Spacing (align with Figma spacing scale)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  // Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
}
```

- **Transformation:** No token transformation system exists. If Figma exports JSON/CSS variables, add a small script or manual mapping from Figma token names to these Dart constants.

---

### 1.2 Component Library

**Current state:** There is **no separate component library**. All UI lives in `example/lib/main.dart` (one screen with form fields, buttons, and result message).

- **Where components are defined:** Currently only in `example/lib/main.dart` (e.g. `PaymentKeySampleApp`, `PaymentKeySampleScreen`). Reusable pieces (cards, inputs, buttons) are inline.
- **Recommended structure for Figma alignment:**
  - **Location:** `example/lib/widgets/` or `example/lib/components/` for app-specific components; for a shared library, a separate package (e.g. `payment_key_client_ui`) with `lib/src/components/`.
  - **Architecture:** Stateless widgets that take parameters and use `Theme.of(context)` or shared tokens. Match Figma component props to widget parameters.

**Example component pattern:**

```dart
// example/lib/widgets/result_message_card.dart (to create)
class ResultMessageCard extends StatelessWidget {
  const ResultMessageCard({
    super.key,
    required this.message,
    required this.isSuccess,
  });
  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: isSuccess ? AppTokens.successSurface : AppTokens.errorSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isSuccess ? AppTokens.success : AppTokens.error,
          width: 1,
        ),
      ),
      child: SelectableText(message, style: TextStyle(...)),
    );
  }
}
```

- **Documentation:** No Storybook or component docs. For Figma Code Connect, map Figma components to these widget files and widget names (e.g. `ResultMessageCard`).

---

### 1.3 Frameworks & Libraries

| Aspect | Technology |
|--------|------------|
| **UI framework** | **Flutter** (Dart SDK ^3.10.8) |
| **Design system** | **Material 3** (`useMaterial3: true`) |
| **Styling** | Flutter widgets + `ThemeData`; no CSS or separate styling framework |
| **Build** | `flutter build` (no separate bundler) |
| **Package** | `payment_key_client` is a **library** (no UI); the **example** app is the only Flutter app and uses Material |

**Relevant files:**

- `example/lib/main.dart` — `MaterialApp`, `ThemeData`, and all current UI.
- `pubspec.yaml` (package) — no `flutter:` assets; dependencies: `flutter`, `http`, `asn1lib`, `pointycastle`.
- `example/pubspec.yaml` — `flutter: uses-material-design: true`, `cupertino_icons`, `payment_key_client: path: ../`.

---

### 1.4 Asset Management

**Current state:**

- **Package (`payment_key_client`):** No `flutter:` section; no assets.
- **Example app:** No `assets:` in `example/pubspec.yaml`; only default Flutter web assets are used.

**Where assets are stored and referenced:**

- **Recommended:** `example/assets/` (e.g. `example/assets/images/`, `example/assets/icons/`). Declare in `example/pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

- **Reference in code:** `AssetImage('assets/images/logo.png')`, `Image.asset('assets/images/logo.png')`, or for package assets from example: path relative to the app that runs (e.g. `assets/...`).
- **Optimization:** Use Flutter’s asset resolution and, if needed, `flutter pub run flutter_native_splash` or similar for icons; no CDN in use for this project.

---

### 1.5 Icon System

**Current state:**

- **Icons:** Material Icons only in code (e.g. `Icons.key` in `example/lib/main.dart`).
- **Package:** `example/pubspec.yaml` includes `cupertino_icons: ^1.0.8` but the example does not use Cupertino icons in the provided code.
- **Custom icons:** No custom icon set or SVG pipeline.

**Where icons are stored / how they are used:**

- **Material/Cupertino:** Use `Icons.*` or `CupertinoIcons.*` from Flutter SDK; no local icon files required.
- **Custom icons:** If Figma provides custom icons, add them under `example/assets/icons/` (e.g. SVG or PNG) and reference via `Image.asset(...)` or use a package like `flutter_svg` for SVG.
- **Naming:** Prefer snake_case filenames (e.g. `ic_payment_success.svg`) and a single folder (e.g. `assets/icons/`) so Figma icon names can map to asset paths.

**Example:**

```dart
Image.asset('assets/icons/ic_key.png', width: 24, height: 24)
```

---

### 1.6 Styling Approach

- **Methodology:** Flutter widget tree + `ThemeData`; no CSS, no CSS Modules, no Styled Components.
- **Theme:** One `ThemeData` in `MaterialApp` in `example/lib/main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  useMaterial3: true,
),
```

- **Global styles:** Effectively provided by `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`, and Material component defaults. No separate global styles file.
- **Responsive design:** None yet. Use `LayoutBuilder`, `MediaQuery.of(context).size`, or `AdaptiveBuilder`/breakpoints if Figma specifies breakpoints; recommended place: `example/lib/theme/breakpoints.dart` and wrapper widgets in `example/lib/widgets/`.

**Figma → Flutter mapping:**

- Figma **fill** → `color`, `decoration: BoxDecoration(color: ...)`.
- Figma **text style** → `TextStyle(fontSize: ..., fontWeight: ..., color: ...)` or `Theme.of(context).textTheme.*`.
- Figma **spacing** → `EdgeInsets.all(tokens.spaceMd)`, `SizedBox(height: tokens.spaceLg)`.
- Figma **radius** → `BorderRadius.circular(tokens.radiusMd)`.

---

### 1.7 Project Structure

**Overall layout:**

```
payment_key_client/
├── lib/                          # Package public API (no UI)
│   ├── payment_key_client.dart    # Exports
│   └── src/
│       ├── card_encryption.dart
│       ├── payment_key_client.dart
│       ├── payment_key_exception.dart
│       ├── payment_key_request.dart
│       └── payment_key_response.dart
├── example/                      # Flutter app (only place with UI)
│   ├── lib/
│   │   └── main.dart             # All current UI and theme
│   ├── pubspec.yaml
│   └── (platform folders: android, ios, web, ...)
├── test/
├── pubspec.yaml
├── README.md
└── FIGMA_DESIGN_SYSTEM_RULES.md  # This file
```

**Recommendations for Figma-driven structure:**

- **Tokens:** `example/lib/theme/app_tokens.dart` (and optionally `app_theme.dart` that uses them in `ThemeData`).
- **Screens:** `example/lib/screens/` (e.g. `payment_key_sample_screen.dart` extracted from `main.dart`).
- **Widgets/components:** `example/lib/widgets/` (e.g. `result_message_card.dart`, `section_label.dart`, form field wrappers).
- **Assets:** `example/assets/images/`, `example/assets/icons/`.
- **Feature organization:** Keep payment-key flow in one feature folder if it grows (e.g. `example/lib/features/payment_key/` with screens + widgets).

---

## 2. Figma MCP Integration Notes

- **Code Connect:** When mapping a Figma selection to code, use the **example** app as the target: paths under `example/lib/`, widget names as they appear in Dart (e.g. `ResultMessageCard`, `PaymentKeySampleScreen`).
- **Component mapping:** Map Figma components to files under `example/lib/widgets/` (once created) and to the corresponding widget class names.
- **Tokens:** Map Figma variables (colors, spacing, radius) to the same names in `AppTokens` (or equivalent) so generated or hand-written code uses tokens instead of magic numbers.
- **Theme:** Any new `ThemeData` or `ColorScheme` should live in `example/lib/theme/` and be applied in `MaterialApp` in `main.dart`.

---

## 3. Summary Checklist

| Topic | Current state | Recommended for Figma |
|-------|----------------|------------------------|
| **Tokens** | None; inline values | `example/lib/theme/app_tokens.dart` |
| **Components** | Inline in `main.dart` | `example/lib/widgets/` (and optionally `lib/theme/app_theme.dart`) |
| **Framework** | Flutter, Material 3 | Keep; align Figma to Material 3 patterns |
| **Assets** | Default only | `example/assets/` + pubspec `assets:` |
| **Icons** | Material Icons | Keep; add `assets/icons/` for custom from Figma |
| **Styling** | ThemeData + inline | Centralize in theme + tokens; use in widgets |
| **Structure** | Single main.dart | Extract screens + widgets; add theme folder |

Use this document when generating or updating UI from Figma and when configuring Figma MCP (e.g. Code Connect) so that design tokens and components map consistently to this Flutter codebase.
