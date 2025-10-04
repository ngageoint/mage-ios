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
    
    static func html(fromBase64Image b64: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
          <style>
            html, body { margin:0; padding:0; background:transparent; }
            .wrap {
              display:flex; align-items:center; justify-content:center;
              width:100%; padding:0; margin:0;
            }
            img {
              display:block;
              width:100%;          /* SCALE to container width */
              max-width:320px;     /* sane upper bound on big screens */
              height:auto;         /* keep aspect ratio */
              border-radius:8px;
              image-rendering:-webkit-optimize-contrast;
              image-rendering:crisp-edges;
              image-rendering:pixelated;
            }
          </style>
        </head>
        <body>
          <div class="wrap">
            <img alt="captcha" src="\(b64.hasPrefix("data:") ? b64 : "data:image/png;base64," + b64)">
          </div>
        </body>
        </html>
        """
    }
    
    static func htmlOLD(fromBase64Image base64OrDataURI: String) -> String {
        let trimmed = base64OrDataURI.trimmingCharacters(in: .whitespacesAndNewlines)
        let dataURI: String = {
            if trimmed.hasPrefix("data:image/") {
                return trimmed
            }
            
            // Default to PNG if not specified
            return "data:image/png;base64,\(trimmed)"
        }()
        
        return """
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
            <style>
              html, body { margin:0; padding:0; background:transparent; }
              .wrap { display:flex; align-items:center; justify-content:center; height:100vh; }
              img { max-width:100%; height:auto; image-rendering: -webkit-optimize-contrast; }
            </style>
          </head>
          <body>
            <div class="wrap">
              <img src="\(dataURI.replacingOccurrences(of: "\"", with: "&quot;"))" alt="captcha"/>
            </div>
          </body>
        </html>
        """
    }
    
    
//    
//    /// Build minimal HTML to display either inline SVG or a generic data-URI image
//    static func makeHTML(from dataURI: String) -> String {
//        /// SVG base64 (`data:image/svg+xml;base64,....`")
//        if dataURI.hasPrefix("data:image/svg+xml;base64,") {
//            let base64 = String(dataURI.dropFirst("data:image/svg+xml;base64,".count))
//            let svg = Data(base64Encoded: base64).flatMap { String(data: $0, encoding: .utf8) } ?? ""
//            return """
//<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/></head>
//<body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center">
//\(svg)
//</body></html>
//"""
//        }
//        
//        /// SVG utf8 (`data:image/svg+xml;utf8,<svg ...>`)
//        if dataURI.hasPrefix("data:image/svg+xml;utf8,") {
//            let encoded = String(dataURI.dropFirst("data:image/svg+xml;utf8,".count))
//            let svg = encoded.removingPercentEncoding ?? ""
//            return """
//<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/></head>
//<body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center">
//\(svg)
//</body></html>
//"""
//        }
//        
//        // Fallback: just show the data URI via <img>
//        let escaped = dataURI.replacingOccurrences(of: "'", with: "&apos;")
//        return """
//<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/></head>
//<body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center">
//<img src='\(escaped)' style="max-width:100%;height:auto"/>
//</body></html>
//"""
//        
//    }
    
    
}
