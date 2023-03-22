//
//  SwiftUIWebView.swift
//  Divemeets-Parser
//
//  Created by Logan Sherwin on 3/13/23.
//

import SwiftUI
import WebKit

struct SwiftUIWebView: View {
    @State var request: String = "https://secure.meetcontrol.com/divemeets/system/memberlist.php"
    //    "https://secure.meetcontrol.com/divemeets/system/profile.php?number=51197"
    @State var parsedHTML: String = ""
    
    var body: some View {
        VStack {
            WebView(request: $request, parsedHTML: $parsedHTML)
        }
    }
}

struct WebView: UIViewRepresentable {
    let htmlParser: HTMLParser = HTMLParser()
    @Binding var request: String
    @Binding var parsedHTML: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView: WKWebView = {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            let config = WKWebViewConfiguration()
            config.defaultWebpagePreferences = pagePrefs
            let webview = WKWebView(frame: .zero,
                                    configuration: config)
            webview.translatesAutoresizingMaskIntoConstraints = false
            return webview
        }()
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    // from SwiftUI to UIKit
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: request) else { return }
        uiView.load(URLRequest(url: url))
    }
    
    // From UIKit to SwiftUI
    func makeCoordinator() -> Coordinator {
        return Coordinator(html: $parsedHTML)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let htmlParser: HTMLParser = HTMLParser()
        @Binding var parsedHTML: String
        var submitted: Bool = false
        
        init(html: Binding<String>) {
            self._parsedHTML = html
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let first = "'Logan'"
            let last = "'Sherwin'"
            let js = "document.getElementById('first').value = \(first); document.getElementById('last').value = \(last);"
//            print(submitted)
            if !submitted {
                /// Fill boxes with search values
                webView.evaluateJavaScript(js, completionHandler: nil)
                
                /// Click Submit
                webView.evaluateJavaScript("document.getElementsByTagName('input')[2].click()") { _, _ in
                    self.submitted = true
                }
            } else {
                /// Gets HTML after submitting request
                webView.evaluateJavaScript("document.body.innerHTML") { [weak self] result, error in
                    guard let html = result as? String, error == nil else { return }
                    self?.parsedHTML = html
//                    print(html)
                }
            }
        }
    }
}

//struct SwiftUIWebView_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIWebView()
//    }
//}
