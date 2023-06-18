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
    @Binding var loggedIn: Bool

    
    var body: some View {
        VStack {
            LoginWebView(request: $request, parsedUserHTML: $parsedUserHTML,
                    divemeetsID: $divemeetsID, password: $password,
                         loginSuccessful: $loginSuccessful, loggedIn: $loggedIn)
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
    @Binding var loggedIn: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        // Create a new web configuration with a new website data store to clear cache
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = pagePrefs
        
        let websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.websiteDataStore = websiteDataStore
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        return webView
    }

    // From SwiftUI to UIKit
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: request) else { return }
        
        // Create a new web configuration with a new website data store to clear cache
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = pagePrefs
        
        let websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.websiteDataStore = websiteDataStore
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        uiView.removeFromSuperview()
        uiView.navigationDelegate = nil
        
        uiView.addSubview(webView)
        uiView.navigationDelegate = webView.navigationDelegate
        
        webView.load(URLRequest(url: url))
    }
    
    // From UIKit to SwiftUI
    func makeCoordinator() -> Coordinator {
        return Coordinator(html: $parsedUserHTML, divemeetsID: $divemeetsID, password: $password, loginSuccessful: $loginSuccessful, loggedIn: $loggedIn)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let htmlParser: HTMLParser = HTMLParser()
        @Binding var parsedUserHTML: String
        @Binding var divemeetsID: String
        @Binding var password: String
        @Binding var loginSuccessful: Bool
        @Binding var loggedIn: Bool
        
        init(html: Binding<String>, divemeetsID: Binding<String>, password: Binding<String>,loginSuccessful: Binding<Bool>, loggedIn: Binding<Bool>) {
            self._parsedUserHTML = html
            self._divemeetsID = divemeetsID
            self._password = password
            self._loginSuccessful = loginSuccessful
            self._loggedIn = loggedIn
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
                var usernameInput = document.querySelector('input[name="username"]');
                var passwordInput = document.querySelector('input[name="passwd"]');
                usernameInput.value = '\(divemeetsID)';
                passwordInput.value = '\(password)';
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
            webView.evaluateJavaScript(
                "document.querySelector('input[type=\"submit\"][value=\"Log in\"]').click()") { _, _ in
                    self.checkIfLoggedIn(webView)
            }
            resetLoginForm(webView) // Add this line to reset the form
        }
        
        func resetLoginForm(_ webView: WKWebView) {
            let resetJs = """
                var usernameInput = document.querySelector('input[name="username"]');
                var passwordInput = document.querySelector('input[name="passwd"]');
                usernameInput.value = '';
                passwordInput.value = '';
            """
            webView.evaluateJavaScript(resetJs, completionHandler: nil)
        }
        
        func checkIfLoggedIn(_ webView: WKWebView) {
            webView.evaluateJavaScript("document.body.innerHTML") { [weak self] result, error in
                guard let html = result as? String, error == nil else {
                    self?.loginSuccessful = false
                    print("Error getting HTML:", error ?? "unknown error")
                    return
                }
                self?.loginSuccessful = false
                self?.parsedUserHTML = html
                if html.contains("there is a countdown timer") {
                    self?.loginSuccessful = true
                } else {
                    print("Was not able to login")
                    self?.loginSuccessful = false
                }
            }
        }
    }
}

