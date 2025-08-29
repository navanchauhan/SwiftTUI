import Foundation

/// A simple picker control that cycles through a set of options.
///
/// Modes:
/// - String options: provide an array of titles (and optional tag mapping).
/// - Builder options: provide option content via a @ViewBuilder; the selected
///   option's view is rendered between angle brackets.
///
/// Keyboard: use left/right arrows or h/l to change the selection.
/// Rendering: shows "< option >" and an optional leading label.
public struct Picker<Label: View, Options: View>: View, PrimitiveView, LayoutRootView {
  // Common
  let selection: Binding<Int>
  let label: VStack<Label>?
  @Environment(\.isEnabled) private var isEnabled: Bool

  // String-based options (mutually exclusive with optionsContent)
  let optionsTitles: [String]?

  // Builder-based options
  let optionsContent: VStack<Options>?

  // MARK: - Initializers (String-based options)

  /// Picker with a custom label view (string options)
  public init(selection: Binding<Int>, options: [String], @ViewBuilder label: () -> Label) where Options == EmptyView {
      self.selection = selection
      self.optionsTitles = options
      self.label = VStack(content: label())
      self.optionsContent = nil
  }

  /// Picker with a text label (string options)
  public init(_ title: String, selection: Binding<Int>, options: [String]) where Label == Text, Options == EmptyView {
      self.selection = selection
      self.optionsTitles = options
      self.label = VStack(content: Text(title))
      self.optionsContent = nil
  }

  /// Picker without a label (string options)
  public init(selection: Binding<Int>, options: [String]) where Label == EmptyView, Options == EmptyView {
      self.selection = selection
      self.optionsTitles = options
      self.label = nil
      self.optionsContent = nil
  }


  // MARK: - Tag-based selection (Binding<T>) convenience for string options

  /// Picker with a custom label view and tag-based selection mapping (string options).
  /// Provide options as an array of (title, tag) pairs; selection binds to the tag type.
  public init<T: Equatable>(selection: Binding<T>, options: [(String, T)], @ViewBuilder label: () -> Label) where Options == EmptyView {
      let titles = options.map { $0.0 }
      let tags = options.map { $0.1 }
      let indexBinding = Binding<Int>(
          get: {
              if let idx = tags.firstIndex(where: { $0 == selection.wrappedValue }) { return idx }
              return 0
          },
          set: { newIndex in
              let idx = max(0, min(newIndex, tags.count - 1))
              selection.wrappedValue = tags[idx]
          }
      )
      self.selection = indexBinding
      self.optionsTitles = titles
      self.label = VStack(content: label())
      self.optionsContent = nil
  }

  /// Picker with a text label and tag-based selection mapping (string options).
  public init<T: Equatable>(_ title: String, selection: Binding<T>, options: [(String, T)]) where Label == Text, Options == EmptyView {
      let titles = options.map { $0.0 }
      let tags = options.map { $0.1 }
      let indexBinding = Binding<Int>(
          get: {
              if let idx = tags.firstIndex(where: { $0 == selection.wrappedValue }) { return idx }
              return 0
          },
          set: { newIndex in
              let idx = max(0, min(newIndex, tags.count - 1))
              selection.wrappedValue = tags[idx]
          }
      )
      self.selection = indexBinding
      self.optionsTitles = titles
      self.label = VStack(content: Text(title))
      self.optionsContent = nil
  }

  /// Picker without a label and tag-based selection mapping (string options).
  public init<T: Equatable>(selection: Binding<T>, options: [(String, T)]) where Label == EmptyView, Options == EmptyView {
      let titles = options.map { $0.0 }
      let tags = options.map { $0.1 }
      let indexBinding = Binding<Int>(
          get: {
              if let idx = tags.firstIndex(where: { $0 == selection.wrappedValue }) { return idx }
              return 0
          },
          set: { newIndex in
              let idx = max(0, min(newIndex, tags.count - 1))
              selection.wrappedValue = tags[idx]
          }
      )
      self.selection = indexBinding
      self.optionsTitles = titles
      self.label = nil
      self.optionsContent = nil
  }

  // MARK: - Builder-based options (index selection)

  /// Picker with a custom label view and builder-provided options.
  public init(selection: Binding<Int>, @ViewBuilder options: () -> Options, @ViewBuilder label: () -> Label) where Options: View {
      self.selection = selection
      self.optionsTitles = nil
      self.optionsContent = VStack(content: options())
      self.label = VStack(content: label())
  }

  /// Picker with a text label and builder-provided options.
  public init(_ title: String, selection: Binding<Int>, @ViewBuilder options: () -> Options) where Label == Text, Options: View {
      self.selection = selection
      self.optionsTitles = nil
      self.optionsContent = VStack(content: options())
      self.label = VStack(content: Text(title))
  }

  /// Picker without a label and builder-provided options.
  public init(selection: Binding<Int>, @ViewBuilder options: () -> Options) where Label == EmptyView, Options: View {
      self.selection = selection
      self.optionsTitles = nil
      self.optionsContent = VStack(content: options())
      self.label = nil
  }

  static var size: Int? { 1 }

  func buildNode(_ node: Node) {
     setupEnvironmentProperties(node: node)
      var childIndex = 0
      if let label {
          node.addNode(at: childIndex, Node(view: label.view))
          childIndex += 1
      }
      if let optionsContent {
          node.addNode(at: childIndex, Node(view: optionsContent.view))
          childIndex += 1
      }
      let control = PickerControl(selection: selection, options: optionsTitles)
      control.isEnabled = isEnabled
      // Attach label control as child 0 if present
      if let labelNode = node.children.first, label != nil {
          control.label = labelNode.control(at: 0)
          control.addSubview(control.label!, at: 0)
      }
      node.control = control
      if optionsContent != nil {
          refreshOptions(node: node, control: control)
      }
  }

  func updateNode(_ node: Node) {
      node.view = self
      var expectedChildren = 0
      // Update label node
      if let label {
          if node.children.count <= expectedChildren {
              node.addNode(at: expectedChildren, Node(view: label.view))
              (node.control as? PickerControl)?.label = node.children[expectedChildren].control(at: 0)
              if let labelCtrl = (node.control as? PickerControl)?.label {
                  node.control?.addSubview(labelCtrl, at: 0)
              }
          } else {
              node.children[expectedChildren].update(using: label.view)
          }
          expectedChildren += 1
      } else {
          // Remove existing label node if any
          if !node.children.isEmpty, (node.control as? PickerControl)?.label != nil {
              node.removeNode(at: 0)
              (node.control as? PickerControl)?.label = nil
          }
      }
      // Update options builder node
      if let optionsContent {
          if node.children.count <= expectedChildren {
              node.addNode(at: expectedChildren, Node(view: optionsContent.view))
          } else {
              node.children[expectedChildren].update(using: optionsContent.view)
          }
          if let control = node.control as? PickerControl {
              refreshOptions(node: node, control: control)
          }
          expectedChildren += 1
      } else {
          // If previously had an options node, remove it and clear options in control
          if node.children.count > expectedChildren {
              node.removeNode(at: expectedChildren)
          }
          if let control = node.control as? PickerControl { control.allOptionControls = []; control.installSelectedContent() }
      }
      if let control = node.control as? PickerControl {
          control.selection = selection
          control.options = optionsTitles
          control.isEnabled = isEnabled
          control.layer.invalidate()
      }
  }

  // MARK: - LayoutRootView hooks (builder variant)
  func loadData(node: Node) {
      if let control = node.control as? PickerControl, optionsContent != nil {
          refreshOptions(node: node, control: control)
      }
  }
  func insertControl(at index: Int, node: Node) {
      if let control = node.control as? PickerControl, optionsContent != nil {
          refreshOptions(node: node, control: control)
      }
  }
  func removeControl(at index: Int, node: Node) {
      if let control = node.control as? PickerControl, optionsContent != nil {
          refreshOptions(node: node, control: control)
      }
  }

  // Recompute builder options from the underlying content subtree
  private func refreshOptions(node: Node, control: PickerControl) {
      // Locate the builder content node: it follows the optional label node
      let optionsNodeIndex = (label == nil) ? 0 : 1
      guard node.children.indices.contains(optionsNodeIndex) else {
          control.allOptionControls = []
          control.installSelectedContent()
          return
      }
      let vStackNode = node.children[optionsNodeIndex]
      vStackNode.build()
      var optionControls: [Control] = []
      if let builderNode = vStackNode.children.first {
          for i in 0 ..< builderNode.size {
              optionControls.append(builderNode.control(at: i))
          }
      }
      control.allOptionControls = optionControls
      control.installSelectedContent()
  }

  private class PickerControl: Control {
      // String-based
      var options: [String]? = nil
      // Builder-based
      var allOptionControls: [Control] = []
      private var currentContent: Control? = nil

      var selection: Binding<Int>
      var label: Control? = nil
      private var highlighted = false
      var isEnabled: Bool = true

       init(selection: Binding<Int>, options: [String]?) {
           self.selection = selection
           self.options = options
       }

      // MARK: - Layout
      override func size(proposedSize: Size) -> Size {
          let lblSize = label?.size(proposedSize: proposedSize) ?? .zero
          let fieldWidth: Extended
          if let opts = options {
              let maxLen = opts.map { $0.count }.max() ?? 0
              fieldWidth = Extended(maxLen + 4) // "< " + text + " >"
          } else {
              // Builder: compute max width across option controls
              let optWidth = allOptionControls.map { $0.size(proposedSize: Size(width: .infinity, height: 1)).width }.max() ?? 0
              fieldWidth = optWidth + 4
          }
          var width = fieldWidth
          if lblSize.width > 0 { width += lblSize.width + 1 } // + space
          // Height is one line (picker renders single-line options)
          return Size(width: width, height: max(1, lblSize.height))
      }

      override func layout(size: Size) {
          super.layout(size: size)
          if let label {
              let lblSize = label.size(proposedSize: size)
              label.layout(size: lblSize)
              label.layer.frame.position = Position(column: 0, line: 0)
          }
          // Install selected content if using builder options
          installSelectedContent()
          // Layout current content next to the left bracket
          if let content = currentContent, options == nil {
              let lblWidth = label?.layer.frame.size.width ?? 0
              let hasLabel = (label != nil && lblWidth > 0)
              let startCol: Extended = hasLabel ? (lblWidth + 1) : 0
              // Allow content to take as much as available between brackets
              let optWidth = content.size(proposedSize: Size(width: .infinity, height: 1)).width
              content.layout(size: Size(width: optWidth, height: 1))
              content.layer.frame.position = Position(column: startCol + 2, line: 0)
              if !children.contains(where: { $0 === content }) {
                  addSubview(content, at: children.count)
              }
          }
      }

      func installSelectedContent() {
          guard options == nil else { return }
          let count = allOptionControls.count
          guard count > 0 else {
              if let cur = currentContent { removeSubviewMatching(cur); currentContent = nil }
              return
          }
          let idx = normalizedIndex(count: count)
          let newContent = allOptionControls[idx]
          if currentContent !== newContent {
              if let cur = currentContent { removeSubviewMatching(cur) }
              currentContent = newContent
              // Will be attached in layout()
              layer.invalidate()
          }
      }

      private func removeSubviewMatching(_ control: Control) {
          if let i = children.firstIndex(where: { $0 === control }) { removeSubview(at: i) }
      }

      private func normalizedIndex(count: Int) -> Int {
          if count == 0 { return 0 }
          return max(0, min(selection.wrappedValue, count - 1))
      }

      // MARK: - Selection
      override var selectable: Bool { isEnabled }

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

      // MARK: - Events
      override func handleEvent(_ char: Character) {
          guard isEnabled else { return }
          let count = (options?.count) ?? allOptionControls.count
          guard count > 0 else { return }
          if char == "h" || char == "\u{1b}" { /* esc prefix for arrows ignored here */ }
          switch char {
          case "h": decrement(count: count)
          case "l": increment(count: count)
          default:
              break
          }
      }

      private func increment(count: Int) {
          guard count > 0 else { return }
          let idx = (selection.wrappedValue + 1) % count
          selection.wrappedValue = idx
          installSelectedContent()
          layer.invalidate()
      }

      private func decrement(count: Int) {
          guard count > 0 else { return }
          let idx = (selection.wrappedValue - 1 + count) % count
          selection.wrappedValue = idx
          installSelectedContent()
          layer.invalidate()
      }

      // MARK: - Drawing
      override func cell(at position: Position) -> Cell? {
          guard position.line == 0 else { return nil }

          let lblWidth = label?.layer.frame.size.width ?? 0
          let hasLabel = (label != nil && lblWidth > 0)
          let startCol: Extended = hasLabel ? (lblWidth + 1) : 0 // space after label

          // Only draw in the field area
          guard position.column >= startCol else { return nil }

          if let opts = options {
              // String mode
              let text = currentText(opts: opts)
              let width = Extended(text.count + 4) // < + space + text + space + >
              let i = position.column - startCol
              guard i >= 0 && i < width else { return nil }

              var ch: Character = " "
              if i == 0 { ch = "<" }
              else if i == width - 1 { ch = ">" }
              else if i == 1 { ch = " " }
              else if i == width - 2 { ch = " " }
              else {
                  let ti = i - 2
                  let idx = text.index(text.startIndex, offsetBy: ti.intValue)
                  ch = text[idx]
              }

              var cell = Cell(char: ch)
              if highlighted { cell.attributes.inverted = true }
              if !isEnabled { cell.attributes.faint = true }
              return cell
          } else {
              // Builder mode: draw brackets/spaces and forward interior to selected option content.
              let optWidth = (currentContent?.size(proposedSize: Size(width: .infinity, height: 1)).width) ?? 0
              let width = optWidth + 4
              let i = position.column - startCol
              guard i >= 0 && i < width else { return nil }
              if i == 0 || i == width - 1 || i == 1 || i == width - 2 {
                  let ch: Character = (i == 0 ? "<" : (i == width - 1 ? ">" : " "))
                  var cell = Cell(char: ch)
                  if highlighted { cell.attributes.inverted = true }
                  if !isEnabled { cell.attributes.faint = true }
                  return cell
              }
              // interior: let the child render, but apply highlight/disabled attributes for parity
              if let inner = currentContent?.cell(at: Position(column: i - 2, line: 0)) {
                  var cell = inner
                  if highlighted { cell.attributes.inverted = true }
                  if !isEnabled { cell.attributes.faint = true }
                  return cell
              }
              return Cell(char: " ")
          }
      }

      private func currentText(opts: [String]) -> String {
          guard !opts.isEmpty else { return "" }
          let idx = min(max(selection.wrappedValue, 0), opts.count - 1)
          return opts[idx]
      }
  }
}