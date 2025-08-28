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
- [x] `.onFocusChange { isFocused in ... }`
- [x] `.onSubmit { ... }` (for TextField/SecureField binding mode)

Environment keys employed:

- [x] `foregroundColor`, `bold`, `italic`, `underline`, `strikethrough`
- [x] `dividerStyle`, `placeholderColor`
- [x] `stackOrientation` (internal for stacks/spacer/divider)

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
- [~] `ScrollView` auto-focus scrolling only; now supports axis parameter

## Differences vs SwiftUI (keep in mind)

- [~] `ScrollView` has no indicators; axis is supported; keeps focused control visible. A no-op `.scrollIndicators(_:)` modifier is provided for source parity.
- [~] `TextField`: supports both action-on-Enter (clears) and live `Binding<String>` editing (onCommit does not clear)
- [~] `Button` exposes `hover` closure on focus changes
- [~] `.background(_:)` supports both `Color` and view variants; the view variant composes behind content
- [~] Fonts: `.fontWeight(_:)` and `.font(.system(size:weight:design:))` map weight to bold; size/design currently ignored

- [~] `onFocusChange` fires when focus enters or leaves the subtree; moves within the subtree may trigger an exit+enter pair in quick succession (terminal simplification)

- [~] `Picker` simplified: string options with h/l to cycle; optional label; supports tag-based selection via `(title, tag)` options; no custom content builder yet

- [~] Arrow keys vs focus: Arrow keys primarily move focus across controls. When a focus move isn’t possible, arrow keys are forwarded to the focused control using vim-key equivalents (← h, → l, ↑ k, ↓ j) so single-focus controls (e.g. `Picker`) can react.
- [~] `List` simplified: vertical only, implemented as `ScrollView` + `VStack`; row separators available via `.listSeparators(style:)`
- [~] `Image` is terminal-oriented: ASCII and Color-matrix initializers; no file/asset decoding
## Missing, Common SwiftUI APIs (TODO)

- Layout/containers
- [x] `List`
- [x] Row separators: Available via `.listSeparators(style:color:)` (global) and per-row via `.listRowSeparator(style:color:)`. Styles supported: plain/heavy/double/none (use `.none` to hide a row’s separator). Still basic overall (no per-section customization).
- [~] `LazyVStack`/`LazyHStack` (implemented as plain stacks; not lazy)
- [~] `NavigationView`/`NavigationStack` (minimal push/pop via NavigationStack + NavigationLink; `NavigationLink(isActive:)` supported for programmatic navigation; `NavigationView` is a thin wrapper around `NavigationStack`)
- [~] `TabView` (titles + selection; simplified tab bar; when a tab button is focused, h/l change selection; Enter/Space activates the focused tab)
- Controls
- [x] `Toggle`  
- [x] `Slider`
- [x] `Picker` (now supports tag-based selection via `(title, tag)` options)
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