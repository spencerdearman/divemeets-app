//
//  LoginWebView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/8/23.
//

import SwiftUI
import WebKit

struct LoginUIWebView: View {
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var parsedUserHTML: String
    @State var request: String =
    "https://secure.meetcontrol.com/divemeets/system/login.php"
    @Binding var loginSearchSubmitted: Bool
    @Binding var loginSuccessful: Bool

    
    var body: some View {
        VStack {
            LoginWebView(request: $request, parsedUserHTML: $parsedUserHTML,
                    divemeetsID: $divemeetsID, password: $password, loginSuccessful: $loginSuccessful)
        }
    }
}

struct LoginWebView: UIViewRepresentable {
    let htmlParser: HTMLParser = HTMLParser()
    @Binding var request: String
    @Binding var parsedUserHTML: String
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var loginSuccessful: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView: WKWebView = {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            let config = WKWebViewConfiguration()
            config.defaultWebpagePreferences = pagePrefs
            
            // Create a shared website data store to maintain the session
            let websiteDataStore = WKWebsiteDataStore.default()
            config.websiteDataStore = websiteDataStore
            
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
        return Coordinator(html: $parsedUserHTML, divemeetsID: $divemeetsID, password: $password, loginSuccessful: $loginSuccessful)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let htmlParser: HTMLParser = HTMLParser()
        @Binding var parsedUserHTML: String
        @Binding var divemeetsID: String
        @Binding var password: String
        @Binding var loginSuccessful: Bool
        
        init(html: Binding<String>, divemeetsID: Binding<String>, password: Binding<String>, loginSuccessful: Binding<Bool>) {
            self._parsedUserHTML = html
            self._divemeetsID = divemeetsID
            self._password = password
            self._loginSuccessful = loginSuccessful
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = "document.querySelector('input[name=\"username\"]').value = '\(divemeetsID)'; document.querySelector('input[name=\"passwd\"]').value = '\(password)'"
            webView.evaluateJavaScript(js, completionHandler: nil)
            webView.evaluateJavaScript("document.querySelector('input[type=\"submit\"][value=\"Log in\"]').click()") {
                _, _ in
                self.checkIfLoggedIn(webView)
            }
        }
        
        func checkIfLoggedIn(_ webView: WKWebView) {
            webView.evaluateJavaScript("document.body.innerHTML") { [weak self] result, error in
                guard let html = result as? String, error == nil else {
                    print("Error getting HTML:", error ?? "unknown error")
                    return
                }
                self?.parsedUserHTML = html
                //self?.parsedUserHTML = self?.htmlParser.parseReturnString(html: html) ?? ""
                print(self?.parsedUserHTML)
                
                // Check if the login was successful by looking for a "Welcome, [username]!" message
                if html.contains("Pool Deck") {
                    self?.loginSuccessful = true
                } else {
                    print("Was not able to login")
                }
            }
        }
    }
}

