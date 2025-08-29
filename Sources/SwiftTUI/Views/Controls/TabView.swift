import Foundation

/// A simple TabView with a top tab bar and content switching.
///
/// API notes:
/// - This is a simplified variant of SwiftUI's TabView.
/// - Tabs are specified via titles and a selection binding.
/// - Content should provide the same number of child views as there are titles.
/// - Keyboard: use left/right (h/l) when the tab bar is focused to change selection.
/// - Mouse: click a tab title, then release to select it.
public struct TabView<Content: View>: View, PrimitiveView, LayoutRootView {
 let titles: [String]
 var selection: Binding<Int>
 let content: VStack<Content>
 @Environment(\.isEnabled) private var isEnabled: Bool
  @Environment(\.accentColor) private var accentColor: Color

 /// Create a TabView with titles and a selection binding.
 /// - Parameters:
 ///   - titles: Display titles for the tabs.
 ///   - selection: Index of the currently selected tab.
 ///   - content: Provide a view containing one child per tab (e.g., a tuple or ForEach in a VStack).
 public init(titles: [String], selection: Binding<Int>, @ViewBuilder content: () -> Content) {
     self.titles = titles
     self.selection = selection
     self.content = VStack(content: content())
 }

 static var size: Int? { 1 }

 func buildNode(_ node: Node) {
     setupEnvironmentProperties(node: node)
     // Build the underlying content subtree (wrapped in a VStack by the API)
     node.addNode(at: 0, Node(view: content.view))
     // Container draws tab bar and selected page only
     let c = TabViewControl(titles: titles, selection: selection)
     c.isEnabled = isEnabled
     c.accentColor = accentColor
     node.control = c
 }

 func updateNode(_ node: Node) {
     node.view = self
     node.children[0].update(using: content.view)

     guard let control = node.control as? TabViewControl else { return }
     control.titles = titles
     control.selection = selection
     control.isEnabled = isEnabled
     control.accentColor = accentColor
     refreshPages(node: node, control: control)
     control.layer.invalidate()
 }

 // MARK: - LayoutRootView hooks

 func loadData(node: Node) {
     if let control = node.control as? TabViewControl {
         refreshPages(node: node, control: control)
     }
 }

 func insertControl(at index: Int, node: Node) {
     if let control = node.control as? TabViewControl {
         refreshPages(node: node, control: control)
     }
 }

 func removeControl(at index: Int, node: Node) {
     if let control = node.control as? TabViewControl {
         refreshPages(node: node, control: control)
     }
 }

 // Recompute the list of page controls from the underlying content subtree and
 // ensure only the selected page is attached to our container.
 private func refreshPages(node: Node, control: TabViewControl) {
     guard !node.children.isEmpty else {
         control.allContentControls = []
         control.rebuildTabBar()
         control.installSelectedContent()
         return
     }
     let vStackNode = node.children[0]
     vStackNode.build()
     var pageControls: [Control] = []
     if let builderNode = vStackNode.children.first {
         for i in 0 ..< builderNode.size {
             pageControls.append(builderNode.control(at: i))
         }
     }
     control.allContentControls = pageControls
     control.rebuildTabBar()
     control.installSelectedContent()
 }

 private class TabViewControl: Control {
     var titles: [String]
     var selection: Binding<Int>
     var isEnabled: Bool = true
     var accentColor: Color = .blue

      // Child controls
      var allContentControls: [Control] = []
      private var currentContent: Control? = nil
      private var tabButtons: [TabButton] = []

      init(titles: [String], selection: Binding<Int>) {
          self.titles = titles
          self.selection = selection
      }

      // MARK: - Layout

      override func size(proposedSize: Size) -> Size {
          // Reserve one line for the tab bar
          let barHeight: Extended = 1
          let contentSize: Size
          if let content = selectedContentControl() {
              contentSize = content.size(proposedSize: Size(width: proposedSize.width, height: max(0, proposedSize.height - barHeight)))
          } else {
              contentSize = Size(width: 0, height: 0)
          }
          return Size(width: max(proposedSize.width, contentSize.width), height: contentSize.height + barHeight)
      }

      override func layout(size: Size) {
          super.layout(size: size)

          // Lay out tab buttons along the top row
          var x: Extended = 0
          for btn in tabButtons {
              let w = btn.size(proposedSize: Size(width: .infinity, height: 1)).width
              btn.layout(size: Size(width: w, height: 1))
              btn.layer.frame.position = Position(column: x, line: 0)
              x += w
              // 1 space separator
              x += 1
          }

          // Content area below the bar
          let contentHeight = max(0, size.height - 1)
          currentContent?.layout(size: Size(width: size.width, height: contentHeight))
          currentContent?.layer.frame.position = Position(column: 0, line: 1)
      }

      // MARK: - Behavior

      func selectedContentControl() -> Control? {
          let idx = max(0, min(selection.wrappedValue, allContentControls.count - 1))
          return allContentControls.indices.contains(idx) ? allContentControls[idx] : nil
      }

      func installSelectedContent() {
          // Ensure content subview matches current selection
          let newContent = selectedContentControl()
          if currentContent !== newContent {
              if let currentContent { removeSubviewMatching(currentContent) }
              currentContent = newContent
              if let newContent { addSubview(newContent, at: children.count) }
          }
          // Update visual states on tabs
          for (i, btn) in tabButtons.enumerated() {
              btn.isSelected = (i == normalizedSelection())
          }
      }

      private func normalizedSelection() -> Int {
          if titles.isEmpty { return 0 }
          return max(0, min(selection.wrappedValue, titles.count - 1))
      }

      func rebuildTabBar() {
          // Remove existing tab buttons first
          let existing = tabButtons
          tabButtons.removeAll()
          for btn in existing {
              if let idx = children.firstIndex(where: { $0 === btn }) {
                  removeSubview(at: idx)
              }
          }

          // Recreate based on current titles
          for (idx, title) in titles.enumerated() {
              let btn = TabButton(title: title) { [weak self] in
                  guard let self else { return }
                  if self.selection.wrappedValue != idx {
                      self.selection.wrappedValue = idx
                      self.installSelectedContent()
                      self.layer.invalidate()
                  }
              }
              btn.isEnabled = isEnabled
              btn.isSelected = (idx == normalizedSelection())
              btn.accentColor = accentColor
              tabButtons.append(btn)
              addSubview(btn, at: children.count)
          }
      }

      private func removeSubviewMatching(_ control: Control) {
          if let i = children.firstIndex(where: { $0 === control }) {
              removeSubview(at: i)
          }
      }

      override func handleEvent(_ char: Character) {
          // Forward events to current content unless the tab bar is focused
          // Allow cycling with h/l when focus is on the container itself
          if char == "h" {
              if selection.wrappedValue > 0 { selection.wrappedValue -= 1 }
              installSelectedContent()
              layer.invalidate()
              return
          } else if char == "l" {
              if selection.wrappedValue < max(0, titles.count - 1) { selection.wrappedValue += 1 }
              installSelectedContent()
              layer.invalidate()
              return
          }
          currentContent?.handleEvent(char)
      }
 }

 private class TabButton: Control {
     let title: String
     var isSelected: Bool = false
     private let onSelect: () -> Void
     private var highlighted: Bool = false
     var isEnabled: Bool = true
     var accentColor: Color = .blue

     init(title: String, onSelect: @escaping () -> Void) {
         self.title = title
         self.onSelect = onSelect
     }

     override func size(proposedSize: Size) -> Size {
         // One space padding on each side
         return Size(width: Extended(title.count + 2), height: 1)
     }

     override func layout(size: Size) { super.layout(size: size) }

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

     override func handleEvent(_ char: Character) {
         guard isEnabled else { return }
         if char == "\n" || char == "\r" || char == " " { onSelect(); return }
         // While a tab button is focused, allow 'h'/'l' to change selection
         if char == "h" {
             if let tv = parent as? TabViewControl {
                 if tv.selection.wrappedValue > 0 { tv.selection.wrappedValue -= 1 }
                 tv.installSelectedContent()
                 tv.layer.invalidate()
             }
             return
         }
         if char == "l" {
             if let tv = parent as? TabViewControl {
                 if tv.selection.wrappedValue < max(0, tv.titles.count - 1) { tv.selection.wrappedValue += 1 }
                 tv.installSelectedContent()
                 tv.layer.invalidate()
             }
             return
         }
     }

     override func cell(at position: Position) -> Cell? {
         guard position.line == 0 else { return nil }
         let w = layer.frame.size.width.intValue
         guard w > 0 else { return nil }

         // Left padding
         if position.column.intValue == 0 { return cellWithAttributes(" ") }
         if position.column.intValue == w - 1 { return cellWithAttributes(" ") }

         let idx = position.column.intValue - 1
         if idx < title.count {
             let cidx = title.index(title.startIndex, offsetBy: idx)
             return cellWithAttributes(String(title[cidx]))
         }
         return cellWithAttributes(" ")
     }

     private func cellWithAttributes(_ s: String) -> Cell {
         var cell = Cell(char: s.first ?? " ")
         if isSelected { cell.attributes.inverted = true; cell.foregroundColor = accentColor }
         if highlighted { cell.attributes.bold = true }
         if !isEnabled { cell.attributes.faint = true }
         return cell
     }
 }

 // Helper to read environment values from the node chain.
 private static func readEnvironment<T>(_ keyPath: KeyPath<EnvironmentValues, T>, from node: Node) -> T {
     var chain: [Node] = []
     var cur: Node? = node
     while let c = cur { chain.append(c); cur = c.parent }
     chain.reverse()
     var env = EnvironmentValues()
     for n in chain { n.environment?(&env) }
     return env[keyPath: keyPath]
 }
}
