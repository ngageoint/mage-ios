//
//  Triangle.swift
//  MAGE
//
//  Created by Dan Barela on 7/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ImageTriangle: View {
    var systemName: String?
    var uiImage: UIImage?
    var color: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Triangle()
                .frame(width: 25, height: 25)
                .foregroundColor(color)
            if let systemName = systemName {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .padding(1)
                    .frame(width: 14, height: 14)
                    .foregroundColor(.white)
            } else if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(1)
                    .frame(width: 14, height: 14)
                    .foregroundColor(.white)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
    }
}
