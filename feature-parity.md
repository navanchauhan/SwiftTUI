This document is a living TODO list for SwiftUI feature parity and Linux compatibility. It’s based on the current source in `Sources/SwiftTUI` and the examples in `Examples`.

Legend

- [x] Implemented
- [ ] Not implemented
- [~] Partial or different from SwiftUI

## Views (TODO)

- [x] `Text` (string, and `AttributedString` with availability)
- [x] Styling via `.foregroundColor`, `.bold`, `.italic`, `.underline`, `.strikethrough`
- [x] `Button` (action + label)
- [x] Focus-based `onHover` callback (alias to `onFocusChange`, not pointer hover)
- [x] `TextField` (single line, action on Enter)
- [x] Placeholder + `Environment(\.placeholderColor)`; live `Binding<String>` editing supported (action-based submit also available)
- [x] `Divider` (uses stack orientation); `.style(...)`
- [x] `Spacer` (expands on parent axis)
- [x] `Color` as a view (ANSI/xterm/true color)
- [x] `ScrollView` (auto-scroll to focused control)
- [x] `GeometryReader`
- [x] `Group`
- [x] `ForEach` (diffing by `Identifiable` or custom `id:`)
- [x] `VStack`, `HStack`, `ZStack` (alignment, spacing)
- [x] `EmptyView`
- [x] Conditionals/optionals via `@ViewBuilder`, `_ConditionalView`, `Optional` support

## Modifiers (TODO)
- [~] `.opacity(_:)` (approximate; values < 1 render using terminal “faint” intensity)
- [x] `.tint(_:)` (alias to `.accentColor(_:)`)
- [~] Opacity: terminals have no alpha blending; `.opacity(_:)` maps to low-intensity (faint) when value < 1 and does not fully hide at 0.

- [x] `.padding(_:)`, `.padding(_:_: )` (edges/length; `Int`/`Extended`)
- [x] `.frame(width:height:alignment:)` (fixed)
- [x] `.frame(minWidth:maxWidth:minHeight:maxHeight:alignment:)` (flexible; `Extended.infinity`)
- [x] `.border(_ color?, style:)` (default/rounded/heavy/double)
- [x] `.foregroundColor(_:)`
- [x] `.background(_ color:)` and `.background(_ view:)`
- [x] `.overlay(_ view:, alignment:)`
- [x] `.cornerRadius(_:)` (via `clipShape(RoundedRectangle)`)
- [x] `.bold()`, `.italic()`, `.underline()`, `.strikethrough()`
- [x] `.onAppear { ... }`
- [x] `.onDisappear { ... }`
- [x] `.onFocusChange { isFocused in ... }`
- [x] `.onSubmit { ... }` (for TextField/SecureField binding mode)
- [x] `.disabled(_:)` (disables interaction for view subtree; disabled controls are non-selectable and ignore input; visual dimming via terminal faint where applicable)

Environment keys employed:

- [x] `foregroundColor`, `bold`, `italic`, `underline`, `strikethrough`
- [x] `dividerStyle`, `placeholderColor`
- [x] `stackOrientation` (internal for stacks/spacer/divider)
- [x] `accentColor` (used by selected TabView tabs, ProgressView fill, and ScrollView indicators)

## State & Data Flow (TODO)

- [x] `@State`
- [x] `@Binding`
- [x] `@Environment`
- [x] `@ObservedObject` (Combine/OpenCombine)
- [x] `@StateObject`
- [x] `@EnvironmentObject`
- [x] `@FocusState`

## Input, Focus, Scrolling (TODO)

- [x] Keyboard activation for `Button` (Enter/Space)
- [x] Focus movement with arrow keys (and vim keys h/j/k/l)
- [x] `ScrollView` auto-focus scrolling and manual keyboard scroll fallback (arrows): when focus can’t move, arrow keys scroll the nearest enclosing ScrollView by one line/column; axis parameter supported

## Differences vs SwiftUI (keep in mind)

- [~] `ScrollView` axis is supported; keeps focused control visible. Minimal scroll indicators are available via `.scrollIndicators(_:)` (automatic/hidden/visible). Indicators are drawn as a lightweight overlay thumb (no track), tuned for TUI. When focus moves isn’t possible, arrows first attempt to scroll a containing `ScrollView` before being mapped to vim-keys for the focused control.
- [~] `TextField`: supports both action-on-Enter (clears) and live `Binding<String>` editing (onCommit does not clear)
- [~] `Button` exposes `hover` closure on focus changes
- [~] `.background(_:)` supports both `Color` and view variants; the view variant composes behind content
- [~] Fonts: `.fontWeight(_:)` and `.font(.system(size:weight:design:))` map weight to bold; size/design currently ignored

- [~] Disabled visuals: Disabled controls use terminal low intensity (faint, SGR 2) when available; not all terminals render faint distinctly. The primary contract is non-interactiveness.

- [~] `onFocusChange` fires when focus enters or leaves the subtree; moves within the subtree may trigger an exit+enter pair in quick succession (terminal simplification)

- [~] `Picker` simplified: supports string options and builder-provided options (renders the selected option's view between brackets on a single line). Optional label; tag-based selection via `(title, tag)` is supported for string options. Cycling with h/l. Custom row interaction is not provided (only the selected option is rendered).

- [~] Arrow keys vs focus: Arrow keys primarily move focus across controls. When a focus move isn’t possible, arrow keys are forwarded to the focused control using vim-key equivalents (← h, → l, ↑ k, ↓ j) so single-focus controls (e.g. `Picker`) can react.
- [~] `List` simplified: vertical only, implemented as `ScrollView` + `VStack`; row separators available via `.listSeparators(style:)`
- [~] `Image` is terminal-oriented: ASCII and Color-matrix initializers; no file/asset decoding
- [~] Accent color: `.accentColor(_:)` influences common highlights (e.g., TabView selected tab, ProgressView fill, ScrollView indicators). Rendering uses terminal foreground color together with inversion where appropriate.
## Missing, Common SwiftUI APIs (TODO)

- Layout/containers
- [x] `List`
- [x] Row separators: Available via `.listSeparators(style:color:)` (global) and per-row via `.listRowSeparator(style:color:)`. Styles supported: plain/heavy/double/none (use `.none` to hide a row’s separator). Still basic overall (no per-section customization).
- [~] `LazyVStack`/`LazyHStack` (implemented as plain stacks; not lazy)
- [~] `NavigationView`/`NavigationStack` (minimal push/pop via NavigationStack + NavigationLink; `NavigationLink(isActive:)` supported for programmatic navigation; `NavigationView` is a thin wrapper around `NavigationStack`). Programmatic pop exposed via `EnvironmentValues.navigationPop`. Backspace pops when focus is not in a text input.
- [~] `TabView` (titles + selection; simplified tab bar; when a tab button is focused, h/l change selection; Enter/Space activates the focused tab; global shortcuts [ and ] switch tabs when focus is inside TabView content, excluding text inputs)
- Controls
- [x] `Toggle`  
- [x] `Slider`
- [x] `Picker` (tag-based selection via `(title, tag)` options, and builder-based options with index selection)
- [x] `Stepper`
- [~] `DatePicker` (date and hour/minute; Y/M/D and H/M with h/l +/- and j/k)
- [x] `ProgressView`
- [x] `SecureField`
- Rendering
- [x] `Image` (ASCII and Color-matrix; no external asset decoding)
- [~] Shapes, clipping (Rectangle, RoundedRectangle, Circle, Ellipse, Capsule with fill/stroke; `clipShape` for these)
- Interaction/other
- [x] Gestures: `onTapGesture` (Enter/Space/mouse release; count supported)
- [~] Animations, transitions (API stubs; immediate updates, no visual tweening yet)
- [~] Accessibility hooks (label, hint via Environment; not rendered yet)

## Linux Compatibility TODO

APIs and conditionals

- [x] Provide `@ObservedObject` support on Linux
- Implemented via OpenCombine fallback with cross-platform typealiases
- [x] Audit availability for `AttributedString`
- Ensure availability attributes don’t block Linux (or gate usages behind `#if canImport(Foundation)` and Swift version checks)

Runtime/IO

- [x] Use `Glibc` on Linux and `Darwin` elsewhere for termios/ioctl (already in `Application.swift`)
- [x] Dispatch-based run loop (works with swift-corelibs-libdispatch)
- [ ] Validate terminal mouse support across common Linux terminals (xterm, gnome-terminal, Alacritty, Kitty)
- [x] Verify UTF-8 handling when stdin provides invalid sequences on Linux
- Application decodes stdin lossily (invalid bytes replaced with U+FFFD) so parsers continue through invalid input. Unit tests cover parser behavior in presence of invalid bytes.
- [x] Add SWIFTTUI_DISABLE_MOUSE env toggle to disable mouse reporting at runtime (for terminals with limited mouse support)

Docs/README

- [x] Document Linux prerequisites (Swift version, terminals tested)
- [x] Note macOS-only features (`RunLoopType.cocoa`)

If you add or change APIs in `Sources/SwiftTUI`, please update the relevant TODO items above.