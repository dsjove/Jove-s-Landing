//
//  WebView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/27/21.
//

import SwiftUI
import WebKit

enum WebContent: Equatable {
	case unload
	case request(URLRequest)
	case html(String)
}

extension WKWebView {
	func load(_ content: WebContent) {
		switch content {
		case .request(let request):
			self.load(request)
		case .html(let html):
			self.loadHTMLString(html, baseURL: nil)
		case .unload:
			self.evaluateJavaScript("document.body.remove()")
		}
	}
}

struct ContentWebView : UIViewRepresentable {
	let content: WebContent
	
	func makeCoordinator() -> ContentWebViewDelegate {
		ContentWebViewDelegate()
	}
	
	func makeUIView(context: Context) -> WKWebView  {
		let wb = WKWebView()
		wb.isOpaque = false
		wb.backgroundColor = UIColor.clear
		wb.navigationDelegate = context.coordinator
		wb.scrollView.isScrollEnabled = false
		return wb
	}
	
	func updateUIView(_ uiView: WKWebView, context: Context) {
		if self.content != context.coordinator.content {
			context.coordinator.content = self.content
			uiView.load(self.content)
		}
	}
}

class ContentWebViewDelegate: NSObject, WKNavigationDelegate {
	var content: WebContent = .unload
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
		webView.evaluateJavaScript(jscript)
	}
	
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		webView.load(.html("Nothing"))
	}
}
