This document is a living TODO list for SwiftUI feature parity and Linux compatibility. It’s based on the current source in `Sources/SwiftTUI` and the examples in `Examples`.

Legend

- [x] Implemented
- [ ] Not implemented
- [~] Partial or different from SwiftUI

## Views (TODO)

- [x] `Text` (string, and `AttributedString` with availability)
 - [x] Styling via `.foregroundColor`, `.bold`, `.italic`, `.underline`, `.strikethrough`
- [x] `Button` (action + label)
 - [~] Focus “hover” callback (not pointer hover)
- [x] `TextField` (single line, action on Enter)
 - [~] Placeholder + `Environment(\.placeholderColor)`; no live `Binding<String>` editing
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

- [x] `.padding(_:)`, `.padding(_:_:)` (edges/length; `Int`/`Extended`)
- [x] `.frame(width:height:alignment:)` (fixed)
- [x] `.frame(minWidth:maxWidth:minHeight:maxHeight:alignment:)` (flexible; `Extended.infinity`)
- [x] `.border(_ color?, style:)` (default/rounded/heavy/double)
- [x] `.foregroundColor(_:)`
- [x] `.background(_ color:)` (note: Color only)
- [x] `.bold()`, `.italic()`, `.underline()`, `.strikethrough()`
- [x] `.onAppear { ... }`

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
- [ ] `@FocusState`

## Input, Focus, Scrolling (TODO)

- [x] Keyboard activation for `Button` (Enter/Space)
- [x] Focus movement with arrow keys (and vim keys h/j/k/l)
- [~] `ScrollView` auto-focus scrolling only (no explicit axis/APIs)

## Differences vs SwiftUI (keep in mind)

- [~] `ScrollView` has no explicit axis/indicators; keeps focused control visible
- [~] `TextField` fires action on Enter and clears; no live `Binding<String>` editing
- [~] `Button` exposes `hover` closure on focus changes
- [~] `.background(_:)` supports `Color` only (no view backgrounds)
- [ ] No font/size APIs yet

## Missing, Common SwiftUI APIs (TODO)

- Layout/containers
 - [ ] `List`
 - [ ] `LazyVStack`/`LazyHStack`
 - [ ] `NavigationView`/`NavigationStack`
 - [ ] `TabView`
- Controls
 - [x] `Toggle`  
 - [x] `Slider`
 - [ ] `Picker`
 - [ ] `Stepper`
 - [ ] `DatePicker`
 - [x] `ProgressView`
 - [x] `SecureField`
- Rendering
 - [ ] `Image`
 - [ ] Shapes, clipping, masking
- Interaction/other
 - [ ] Animations, transitions, gestures
 - [ ] Accessibility hooks

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
- [ ] Verify UTF-8 handling when stdin provides invalid sequences on Linux

Docs/README

- [x] Document Linux prerequisites (Swift version, terminals tested)
- [x] Note macOS-only features (`RunLoopType.cocoa`)

If you add or change APIs in `Sources/SwiftTUI`, please update the relevant TODO items above.