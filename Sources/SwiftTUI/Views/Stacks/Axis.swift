import Foundation

/// Public axis for user-facing APIs like ScrollView.
public enum Axis {
   case horizontal
   case vertical
}

enum StackOrientation {
    case horizontal
    case vertical
}

private struct StackOrientationEnvironmentKey: EnvironmentKey {
    static var defaultValue: StackOrientation { .vertical }
}

extension EnvironmentValues {
    /// This is used by views like `Spacer`, the appearance of which depends
    /// on the orientation of the stack they are in.
    var stackOrientation: StackOrientation {
        get { self[StackOrientationEnvironmentKey.self] }
        set { self[StackOrientationEnvironmentKey.self] = newValue }
    }
}
