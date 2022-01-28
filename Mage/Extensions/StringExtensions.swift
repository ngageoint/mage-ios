//
//  StringExtensions.swift
//  MAGE
//
//  Created by Daniel Barela on 1/28/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension String {
    func htmlAttributedString(font: UIFont?, color: UIColor?) -> NSAttributedString? {
        let htmlTemplate = """
        <!doctype html>
        <html>
          <head>
            <style>
              body {
                font-family: \(font?.familyName ?? "-apple-system"), "-apple-system";
                font-size: \(font?.pointSize ?? 12)px;
              }
            </style>
          </head>
          <body>
            \(self)
          </body>
        </html>
        """
        
        guard let data = htmlTemplate.data(using: .utf16) else {
            return nil
        }
        
        guard let attributedString = try? NSMutableAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) else {
            return nil
        }
        
        if let color = color {
            attributedString.addAttribute(.foregroundColor, value: color, range: NSMakeRange(0, attributedString.length))
        }
        
        return attributedString
    }
}
