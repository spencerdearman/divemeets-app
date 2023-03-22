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
            //            let prefs = WKPreferences()
            //            prefs.javaScriptEnabled = true
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            let config = WKWebViewConfiguration()
            //            config.preferences = prefs
            config.defaultWebpagePreferences = pagePrefs
            let webview = WKWebView(frame: .zero,
                                    configuration: config)
            webview.translatesAutoresizingMaskIntoConstraints = false
            return webview
        }()
        
        return webView
    }
    
    // from SwiftUI to UIKit
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: request) else { return }
        uiView.load(URLRequest(url: url))
//        parsedHTML = htmlParser.parse(html: request)
    }
    
    // From UIKit to SwiftUI
    func makeCoordinator() -> Coordinator {
        return Coordinator(html: $parsedHTML)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let htmlParser: HTMLParser = HTMLParser()
        @Binding var parsedHTML: String
        
        init(html: Binding<String>) {
            self._parsedHTML = html
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Fill First Name
            // document.getElementById('first').value = 'Logan'
            
            // Fill Last Name
            // document.getElementById('last').value = 'Sherwin'
            
            // Hit Submit button
            // document.getElementsByTagName('input')[2].click()
            let first = "Logan"
            let last = "Sherwin"
            let js = "document.getElementById('first').value = \(first); document.getElementById('last').value = \(last); document.getElementsByTagName('input')[2].click(); "
            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let html = result as? String, error == nil else { return }
                var res = self?.htmlParser.parse(html: html) ?? []
                
            }
            webView.evaluateJavaScript("document.body.innerHTML;") { [weak self] result, error in
                guard let html = result as? String, error == nil else { print("Failed to get HTML"); return
                }
                self?.htmlParser.parse(html: html)
            }
        }

    }
}

func desktopDirectoryJSONURL() -> URL {
    do {
        let documentDirectory = try FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return documentDirectory.appendingPathComponent("test.json")
    } catch {
        fatalError("Couldn't create URL")
    }
}


func writeToFile(value: String) {
    do{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(value)
        try jsonData.write(to: desktopDirectoryJSONURL())
    } catch {
        print(error)
    }
}


struct SwiftUIWebView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIWebView()
    }
}
