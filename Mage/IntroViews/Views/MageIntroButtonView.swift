//
//  MageIntroButtonView.swift
//  MAGE
//
//  Created by James McDougall on 8/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct MageIntroButtonView: View {
    @Binding var isIntroViewsShown:Bool
    
    var body: some View {
        HStack {
            Text("Have questions?")
            Spacer()
            Button {
                isIntroViewsShown.toggle()
            } label: {
                Text("Take a Tour")
                    .foregroundStyle(.blue)
            }
            .sheet(isPresented: $isIntroViewsShown) {
                IntroTabView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }

        }
        .frame(height: 50)
    }
}

struct MageIntroButtonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(viewModel: PreviewLoginViewModel())
                .previewDisplayName("Default")
            LoginView(viewModel: {
                let vm = PreviewLoginViewModel()
                vm.errorMessage = "Bad username or password!"
                return vm
            }())
            .previewDisplayName("With Error")
            LoginView(viewModel: {
                let vm = PreviewLoginViewModel()
                vm.isLoading = true
                return vm
            }())
            .previewDisplayName("Loading State")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
