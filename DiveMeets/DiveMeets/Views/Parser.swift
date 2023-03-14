//
//  Parser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/13/23.
//

import SwiftUI
import WebKit

struct HTMLView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

struct ParserView: View {
    let urlString = "https://www.google.com"
    
    var body: some View {
        VStack {
            HTMLView(urlString: urlString)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ParserView_Previews: PreviewProvider {
    static var previews: some View {
        ParserView()
    }
}
