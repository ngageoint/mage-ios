//
//  DisclaimerView.swift
//  MAGE
//
//  Created by Daniel Benner on 11/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

@objc public class DisclaimerViewHoster: NSObject {
    /// Returns a ready-to-use UIHostingController containing the SwiftUI login view.
    @objc public static func hostingController(delegate: DisclaimerDelegate?) -> UIViewController {
        let swiftUIView = DisclaimerView(delegate: delegate)
        let hostingController = UIHostingController(rootView: swiftUIView)
        return hostingController
    }
}

@objc public protocol DisclaimerDelegate {
    @objc func disclaimerAgree()
    @objc func disclaimerDisagree()
}

public struct DisclaimerView: View {
    @Environment(\.dismiss) var dismiss
    let delegate: DisclaimerDelegate?
    let disclaimer: String = UserDefaults.standard.disclaimerText ?? "no disclaimer available"
    
    public var body: some View {
        VStack(alignment: .center) {
            Image("LogoClear")
                .resizable()
                .scaledToFit()
                .padding([.top, .leading, .trailing], 16)
            Text("Consent to Monitoring")
                .font(.title)
                .padding()
            Text(disclaimer)
                .font(.body1)
                .foregroundStyle(.primary)
                .padding(36)
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Button("Disagree") {
                    delegate?.disclaimerDisagree()
                    dismiss()
                }
                .frame(width: 80)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary)
                )
                Spacer()
                Button("Agree") {
                    delegate?.disclaimerAgree()
                    dismiss()
                }
                .frame(width: 80)
                .padding()
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                Spacer()
            }
            .opacity(delegate != nil ? 1 : 0)
            Spacer()
        }
    }
}

#Preview {
    DisclaimerView(delegate: nil)
}
