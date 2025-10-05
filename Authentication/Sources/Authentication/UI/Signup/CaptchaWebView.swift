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
    
    static func htmlTemplate(imageSrc: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
          <style>
            html, body { margin:0; padding:0; background:transparent; }
            body { -webkit-touch-callout:none; -webkit-user-select:none; user-select:none; }
            .wrap {
              display:flex; align-items:center; justify-content:center;
              width:100%; padding:0; margin:0;
            }
            img {
              display:block;
              width:100%;          /* fill the web view width */
              max-width: 420px;    /* avoid growing too large on iPad */
              height:auto;         /* preserve aspect ratio */
              border-radius:8px;
              image-rendering:-webkit-optimize-contrast;
              image-rendering:pixelated; /* keeps thin lines reasonably crisp */
            }
          </style>
        </head>
        <body>
          <div class="wrap">
            <img alt="captcha" src="\(imageSrc)">
          </div>
        </body>
        </html>
        """
    }
}

extension CaptchaWebView {
    static func html(fromBase64Image b64: String) -> String {
        let src = b64.hasPrefix("data:") ? b64 : "data:image/png;base64," + b64
        return htmlTemplate(imageSrc: src)
    }
    
    static func html(fromDataURL dataURL: String) -> String {
        return htmlTemplate(imageSrc: dataURL)
    }
}
