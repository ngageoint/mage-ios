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
        let wv = WKWebView(frame: .zero)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.backgroundColor = .clear
        return wv
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
    
    /// Build minimal HTML to display either inline SVG or a generic data-URI image
    static func makeHTML(from dataURI: String) -> String {
        /// SVG base64 (`data:image/svg+xml;base64,....`")
        if dataURI.hasPrefix("data:image/svg+xml;base64,") {
            let base64 = String(dataURI.dropFirst("data:image/svg+xml;base64,".count))
            let svg = Data(base64Encoded: base64).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            return """
<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/></head>
<body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center">
\(svg)
</body></html>
"""
        }
        
        /// SVG utf8 (`data:image/svg+xml;utf8,<svg ...>`)
        if dataURI.hasPrefix("data:image/svg+xml;utf8,") {
            let encoded = String(dataURI.dropFirst("data:image/svg+xml;utf8,".count))
            let svg = encoded.removingPercentEncoding ?? ""
            return """
<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/></head>
<body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center">
\(svg)
</body></html>
"""
        }
        
        // Fallback: just show the data URI via <img>
        let escaped = dataURI.replacingOccurrences(of: "'", with: "&apos;")
        return """
<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/></head>
<body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center">
<img src='\(escaped)' style="max-width:100%;height:auto"/>
</body></html>
"""
        
    }
    
    
}
