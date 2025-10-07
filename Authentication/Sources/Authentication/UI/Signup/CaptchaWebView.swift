//
//  CaptchaWebView.swift
//  Authentication
//
//  Created by Brent Michalski on 9/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import WebKit

struct CaptchaWebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false
        // Avoid caching across runs and keep view isolated
        config.websiteDataStore = .nonPersistent()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .clear
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

extension CaptchaWebView {
    
    /// Wrap provided BODY markup inside a minimal HTML doc with safe styling.
    private static func wrapHTML(body: String) -> String {
        """
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
            <style>
              html,body{margin:0;padding:0;background:transparent;}
              .wrap{display:flex;align-items:center;justify-content:center;width:100%;padding:0;margin:0;}
              img,svg,object{display:block;width:100%;max-width:320px;height:auto;border-radius:8px;}
            </style>
          </head>
          <body>
            <div class="wrap">
              \(body)
            </div>
          </body>
        </html>
        """
    }
  
    /// HTML document that displays a data-URL image (PNG/JPEG/SVG).
    static func html(fromDataURL dataURL: String) -> String {
        wrapHTML(body: #"<img alt="captcha" src="\#(dataURL)"/>"#)
    }
    
    static func html(fromInlineSVG svgXML: String) -> String {
        wrapHTML(body: svgXML)
    }
}
