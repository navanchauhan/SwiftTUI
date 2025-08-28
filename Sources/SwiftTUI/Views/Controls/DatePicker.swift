import Foundation

public struct DatePickerComponents: OptionSet, Sendable {
  public let rawValue: Int
  public init(rawValue: Int) { self.rawValue = rawValue }
  public static let date = DatePickerComponents(rawValue: 1 << 0)
  public static let hourAndMinute = DatePickerComponents(rawValue: 1 << 1)
}

/// A simple date/time picker.
///
/// Keyboard:
/// - h / - : decrement current component
/// - l / + : increment current component
/// - j      : move to next component (cycles through active fields)
/// - k      : move to previous component
public struct DatePicker<Label: View>: View, PrimitiveView {
  let selection: Binding<Date>
  let displayedComponents: DatePickerComponents
  let label: VStack<Label>?

  public init(_ title: String, selection: Binding<Date>, displayedComponents: DatePickerComponents = [.date]) where Label == Text {
      self.selection = selection
      self.displayedComponents = displayedComponents
      self.label = VStack(content: Text(title))
  }

  public init(selection: Binding<Date>, displayedComponents: DatePickerComponents = [.date], @ViewBuilder label: () -> Label) {
      self.selection = selection
      self.displayedComponents = displayedComponents
      self.label = VStack(content: label())
  }

  public init(selection: Binding<Date>, displayedComponents: DatePickerComponents = [.date]) where Label == EmptyView {
      self.selection = selection
      self.displayedComponents = displayedComponents
      self.label = nil
  }

  static var size: Int? { 1 }

  func buildNode(_ node: Node) {
      if let label { node.addNode(at: 0, Node(view: label.view)) }
      let control = DatePickerControl(selection: selection, displayedComponents: displayedComponents)
      if let labelNode = node.children.first {
          control.label = labelNode.control(at: 0)
          control.addSubview(control.label!, at: 0)
      }
      node.control = control
  }

  func updateNode(_ node: Node) {
      node.view = self
      if let label {
          if node.children.isEmpty {
              node.addNode(at: 0, Node(view: label.view))
              (node.control as? DatePickerControl)?.label = node.children[0].control(at: 0)
              if let lbl = (node.control as? DatePickerControl)?.label { node.control?.addSubview(lbl, at: 0) }
          } else {
              node.children[0].update(using: label.view)
          }
      } else if !node.children.isEmpty {
          node.removeNode(at: 0)
          (node.control as? DatePickerControl)?.label = nil
      }
      if let control = node.control as? DatePickerControl {
          control.selection = selection
          control.displayedComponents = displayedComponents
          control.layer.invalidate()
      }
  }

  private class DatePickerControl: Control {
      var selection: Binding<Date>
      var displayedComponents: DatePickerComponents
      var label: Control? = nil

      private enum Field { case year, month, day, hour, minute }
      private var active: Field
      private var highlighted = false

      private var calendar: Calendar = {
          var cal = Calendar(identifier: .gregorian)
          cal.locale = Locale(identifier: "en_US_POSIX")
          // Avoid .gmt (macOS 13+); use GMT by seconds offset or abbreviation fallback
          cal.timeZone = TimeZone(secondsFromGMT: 0) ?? (TimeZone(abbreviation: "GMT") ?? .current)
          return cal
      }()

      init(selection: Binding<Date>, displayedComponents: DatePickerComponents) {
          self.selection = selection
          self.displayedComponents = displayedComponents
          // Default active field: day when date is present, otherwise minute for time-only
          self.active = displayedComponents.contains(.date) ? .day : .minute
      }

      override func size(proposedSize: Size) -> Size {
          // Label width + formatted string length
          let lbl = label?.size(proposedSize: proposedSize) ?? .zero
          let str = formattedDate()
          let width = lbl.width + (lbl.width > 0 ? 1 : 0) + Extended(str.count)
          return Size(width: width, height: max(1, lbl.height))
      }

      override func layout(size: Size) {
          super.layout(size: size)
          if let label {
              let lblSize = label.size(proposedSize: size)
              label.layout(size: lblSize)
              label.layer.frame.position = Position(column: 0, line: 0)
          }
      }

      override var selectable: Bool { true }

      override func becomeFirstResponder() {
          super.becomeFirstResponder()
          highlighted = true
          layer.invalidate()
      }

      override func resignFirstResponder() {
          super.resignFirstResponder()
          highlighted = false
          layer.invalidate()
      }

      override func handleEvent(_ char: Character) {
          ensureActiveValid()
          switch char {
          case "h", "-": adjust(-1)
          case "l", "+": adjust(+1)
          case "j": nextField()
          case "k": prevField()
          default: break
          }
      }

      override func cell(at position: Position) -> Cell? {
          guard position.line == 0 else { return nil }
          let lblW = label?.layer.frame.size.width ?? 0
          let hasLabel = (label != nil && lblW > 0)
          let startCol: Extended = hasLabel ? (lblW + 1) : 0
          guard position.column >= startCol else { return nil }

          let s = formattedDate()
          let idx = position.column - startCol
          guard idx >= 0 && idx < Extended(s.count) else { return nil }
          let cidx = s.index(s.startIndex, offsetBy: idx.intValue)
          var cell = Cell(char: s[cidx])

          // Underline the active component when focused
          if isFirstResponder {
              let ranges = componentRanges(in: s)
              if ranges[active]?.contains(idx.intValue) == true {
                  cell.attributes.underline = true
              }
          }
          return cell
      }

      // MARK: - Helpers

      private func formattedDate() -> String {
          let comps = calendar.dateComponents(in: calendar.timeZone, from: selection.wrappedValue)
          let y = comps.year ?? 1970
          let m = comps.month ?? 1
          let d = comps.day ?? 1
          let H = comps.hour ?? 0
          let M = comps.minute ?? 0
          let showDate = displayedComponents.contains(.date)
          let showTime = displayedComponents.contains(.hourAndMinute)
          switch (showDate, showTime) {
          case (true, true):
              return String(format: "%04d-%02d-%02d %02d:%02d", y, m, d, H, M)
          case (true, false):
              return String(format: "%04d-%02d-%02d", y, m, d)
          case (false, true):
              return String(format: "%02d:%02d", H, M)
          default:
              return String(format: "%04d-%02d-%02d", y, m, d)
          }
      }

      private func componentRanges(in s: String) -> [Field: Range<Int>] {
          var ranges: [Field: Range<Int>] = [:]
          let showDate = displayedComponents.contains(.date)
          let showTime = displayedComponents.contains(.hourAndMinute)
          if showDate && showTime {
              // yyyy-mm-dd HH:mm
              ranges[.year] = 0..<4
              ranges[.month] = 5..<7
              ranges[.day] = 8..<10
              ranges[.hour] = 11..<13
              ranges[.minute] = 14..<16
          } else if showDate {
              // yyyy-mm-dd
              ranges[.year] = 0..<4
              ranges[.month] = 5..<7
              ranges[.day] = 8..<10
          } else if showTime {
              // HH:mm
              ranges[.hour] = 0..<2
              ranges[.minute] = 3..<5
          }
          return ranges
      }

      private func orderedFields() -> [Field] {
          var out: [Field] = []
          if displayedComponents.contains(.date) { out.append(contentsOf: [.year, .month, .day]) }
          if displayedComponents.contains(.hourAndMinute) { out.append(contentsOf: [.hour, .minute]) }
          return out
      }

      private func ensureActiveValid() {
          let fields = orderedFields()
          if !fields.contains(where: { $0 == active }) {
              active = fields.last ?? .day
          }
      }

      private func nextField() {
          let fields = orderedFields()
          guard let idx = fields.firstIndex(where: { $0 == active }), !fields.isEmpty else { return }
          active = fields[(idx + 1) % fields.count]
          layer.invalidate()
      }

      private func prevField() {
          let fields = orderedFields()
          guard let idx = fields.firstIndex(where: { $0 == active }), !fields.isEmpty else { return }
          active = fields[(idx - 1 + fields.count) % fields.count]
          layer.invalidate()
      }

      private func adjust(_ delta: Int) {
          var comp: Calendar.Component
          switch active {
          case .year: comp = .year
          case .month: comp = .month
          case .day: comp = .day
          case .hour: comp = .hour
          case .minute: comp = .minute
          }
          if let newDate = calendar.date(byAdding: comp, value: delta, to: selection.wrappedValue) {
              selection.wrappedValue = newDate
              layer.invalidate()
          }
      }
  }
}
