import SwiftUI

@main
struct imgApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear(perform: level)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification, object: nil)) { _ in
          for window in NSApplication.shared.windows {
            window.level = .floating
            window.orderFrontRegardless()
          }
        }
    }
    .commands {
      CommandGroup(replacing: .newItem, addition: { })
    }
    .windowStyle(.hiddenTitleBar)
  }

  func level() {
    for window in NSApplication.shared.windows {
      window.level = .floating
    }
  }
}
