# UI, Theming & Layout

*Requires `SKILL.md`.*

## Context Access
**`ContextExtensions` from `shared`** for all theme access. Project-specific dialogs do not belong here.
- `context.s` → `AppLocalizations` (non-nullable)
- `context.c` → `Theme.of(context).colorScheme`
- `context.t` → `Theme.of(context).textTheme`
- `context.showToast(String message, {SnackBarAction? action})`

## Colors
Material Design 3 (MD3) roles from the `ColorScheme` (`context.c.surfaceContainerLow`, `context.c.onSurfaceVariant`, …).
- No global `BrandColors` constants class.
- No hex literals (`Color(0xFF...)`) outside `app_theme.dart`.
- If the MD3 roles are not enough: a `ThemeExtension` class (with `copyWith` and `lerp`) in `core/theme/theme_extensions.dart`, registered via `ThemeData(extensions: [...])` in `app_theme.dart`, accessed through a getter in `ContextExtensions`:
  ```dart
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
  ```

## Typography
Only the MD3 type scale via `context.t`. No hardcoded `fontSize`.

## Spacing & Dimensions
Exclusively the `Spacing` class from `core/theme/spacing.dart`, private constructor `Spacing._()`.
- **Spacing steps:** `xxxs` (4), `xxs` (6), `xs` (8), `s` (12), `m` (16), `l` (20), `xl` (24), `xxl` (32), `xxxl` (48), `xxxxl` (64)
- **Border radius:** `radiusS` (8), `radiusM` (12), `radiusL` (16), `radiusXl` (20), `radiusXxl` (24), `radiusFull` (999 — `double.infinity` does not work in `BorderRadius.circular`)
- **Border width:** `borderWidthThin` (1), `borderWidthMedium` (2), `borderWidthThick` (3), `borderWidthHeavy` (4)
- **Icon sizes:** `iconS` (18), `iconM` (24), `iconL` (28), `iconXl` (32)
- **Elevations:** `elevationXs` (0.5), `elevationS` (1), `elevationM` (2)

## Widget Extraction (gradation)
1. Never builder methods (`Widget _buildHeader()`).
2. Private widget classes in the same file (`_Content`, `_ErrorView`) — default for screen-internal parts.
3. Own file (in `widgets/` where applicable) once it is reused, has its own state/hooks, or the file grows unwieldy (~100 lines as a guideline).
- `const` constructors wherever possible.

## Layout & Dependencies
- **Responsive design:** prefer the flex system (`Row`, `Column`, `Expanded`, `Flexible`, varying grid columns). `LayoutBuilder` and `MediaQuery` only when there is no more performant alternative.
- **UI packages:** no third-party (icon) packages, UI dependencies at the absolute minimum. When in doubt, ask.
- **Icons:** `Icons.*`. Only if the design ships custom icons: icon font under `assets/icon_fonts/` (`pubspec.yaml` → `fonts:`), exposed via `abstract final class AppIcons`. Do not set this up preemptively.
