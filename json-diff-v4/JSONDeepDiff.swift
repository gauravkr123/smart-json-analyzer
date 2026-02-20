import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var pendingDroppedContents: [String?]?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.center()
        win.title = "JSON Diff v4"
        win.minSize = NSSize(width: 600, height: 400)

        let wv = WKWebView(frame: win.contentView!.bounds)
        wv.autoresizingMask = [.width, .height]
        wv.navigationDelegate = self
        win.contentView?.addSubview(wv)

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: nil) {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        window = win
        webView = wv
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let jsonUrls = urls.filter { $0.pathExtension.lowercased() == "json" }
        guard !jsonUrls.isEmpty else { return }
        var contents: [String?] = [nil, nil]
        for (i, url) in jsonUrls.prefix(2).enumerated() {
            contents[i] = try? String(contentsOf: url, encoding: .utf8)
        }
        pendingDroppedContents = contents
        injectDroppedContentsIfReady()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        injectDroppedContentsIfReady()
    }

    private func injectDroppedContentsIfReady() {
        guard let pending = pendingDroppedContents else { return }
        let arr: [Any] = pending.map { ($0 ?? NSNull()) as Any }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: arr),
              let jsonStr = String(data: jsonData, encoding: .utf8) else { return }
        let script = "window.__droppedFileContents = \(jsonStr);"
        webView.evaluateJavaScript(script) { [weak self] _, _ in
            self?.pendingDroppedContents = nil
        }
    }
}
