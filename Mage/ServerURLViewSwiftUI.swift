//
//  ServerURLViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

@objcMembers
public class ServerURLViewWrapper: NSObject {
    @objc(setServerURLViewWithDelegate:scheme:)
    public static func setServertURLView(delegate: ServerURLDelegate, scheme: AppContainerScheming?) -> UIViewController {
        return UIHostingController(rootView: ServerURLViewSwiftUI(delegate: delegate, scheme: scheme))
    }
}

struct ServerURLViewSwiftUI: View {
    @ObservedObject var viewModel: ServerURLViewModel
    @FocusState private var isFocused: Bool
    
    init(delegate: ServerURLDelegate, scheme: AppContainerScheming?) {
        self.viewModel = ServerURLViewModel(delegate: delegate, scheme: scheme)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                // TODO: Brent - This image needs to be fixed
                Text("🔮")
                    .font(.system(size: 50))
                Text("MAGE")
                    .font(.custom("GondolaMageregular", size: 52))
                    .baselineOffset(6)
            }
            
            Text("Set MAGE Server URL")
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextField("MAGE Server URL", text: $viewModel.serverURL)
                .keyboardType(.URL)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(viewModel.showError ? Color.red : .gray, lineWidth: 1)
            )
                .submitLabel(.go)
                .onSubmit {
                    viewModel.submit()
                }
            
            if viewModel.showError {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("This URL does not appear to be a MAGE server.")
                            .foregroundColor(.secondary)
                        
                        if let info = viewModel.additionalErrorMessage {
                            Button("more info") {
                                viewModel.showErrorDetails = true
                            }
                            .font(.footnote)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
            
            HStack {
                if viewModel.showCancelButton {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                }
                
                Button("OK") {
                    viewModel.submit()
                }
                .disabled(viewModel.serverURL.isEmpty)
            }
            .padding(.top, 10)
        }
        .padding()
        .alert("Error", isPresented: $viewModel.showErrorDetails, presenting: viewModel.additionalErrorMessage) { _ in
            Button("Close", role: .cancel) {}
        } message: { info in
            Text(info)
        }
        .onAppear {
            isFocused = true
        }
    }
}
