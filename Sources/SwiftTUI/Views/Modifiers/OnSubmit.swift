import Foundation

private struct OnSubmitEnvironmentKey: EnvironmentKey {
  static var defaultValue: (() -> Void)? { nil }
}

public extension EnvironmentValues {
  /// Action invoked when a text-input control is submitted (Enter/Return).
  var onSubmit: (() -> Void)? {
      get { self[OnSubmitEnvironmentKey.self] }
      set { self[OnSubmitEnvironmentKey.self] = newValue }
  }
}

public extension View {
  /// Registers an action to perform when the user submits a value to this view.
  func onSubmit(_ action: @escaping () -> Void) -> some View {
      environment(\.onSubmit, action)
  }
}
