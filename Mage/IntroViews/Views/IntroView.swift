//
//  IntroView.swift
//  MAGE
//
//  Created by James McDougall on 8/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct IntroView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let description: String
    let imageName: String
    let isEndOfIntroViews: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.blue.gradient)
            
            Text(description)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
            
            if isEndOfIntroViews {
                Button {
                   dismiss()
                } label: {
                    Text("Let's Go!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: UIScreen.screenWidth - 20, height: 50)
                        .background(.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top)

            }
        }
        .frame(width: UIScreen.screenWidth - 20, height: 675)
    }
}

#Preview {
    NavigationStack {
        IntroView(title: "Welcome to MAGE!", description: "Connect to a team server to sync and share field data.", imageName: "ExamplePhotoOne", isEndOfIntroViews: true)
    }
}
