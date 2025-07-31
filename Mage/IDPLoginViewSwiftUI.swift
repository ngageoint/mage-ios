//
//  IDPLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/31/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct IDPLoginViewSwiftUI: View {
    @ObservedObject var viewModel: IDPLoginViewModel
    
    var body: some View {
        Button(action: {
            viewModel.signin()
        }) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                Text(viewModel.displayName)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(.vertical, 12)
    }
}


// MARK: - Mock Delegate for Preview
class MockIDPLoginDelegate: NSObject, IDPLoginDelegate {
    func signinForStrategy(_ strategy: [String : Any]) {
        print("Sign in tapped for strategy: \(strategy)")
    }
}


// MARK: - Preview
struct IDPLoginViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        let mockStrategy: [String: Any] = [
            "identifier": "idp",
            "name": "Sign in with Google",
            "url": "https://example.com/oauth"
        ]
        let mockDelegate = MockIDPLoginDelegate()
        let viewModel = IDPLoginViewModel(strategy: mockStrategy, delegate: mockDelegate)
        return IDPLoginViewSwiftUI(viewModel: viewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
