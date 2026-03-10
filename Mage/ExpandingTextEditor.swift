//
//  ExpandingTextEditor.swift
//  MAGE
//
//  Created by Daniel Benner on 2/18/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

final class ExpandingTextEditorState: ObservableObject {
    @Published var showRequiredError: Bool = false
}

struct ExpandingTextEditor: View {
    var title: String
    var field: [String: Any]
    var delegate: (ObservationFormFieldListener & FieldSelectionDelegate)?
    @ObservedObject var state: ExpandingTextEditorState
    @State var text: String
    @State var workingText: String
    @State private var showSheet = false
    
    private var isRequiredField: Bool {
        return (field[FieldKey.required.key] as? Bool) == true
    }
    
    init(field: [String: Any] = [:], value: String, state: ExpandingTextEditorState = ExpandingTextEditorState(), delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.title = field[FieldKey.title.key] as? String ?? "Text Area"
        self.field = field
        self.delegate = delegate
        self.state = state
        self.text = value
        self.workingText = value
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text("\(title)" + (isRequiredField ? " *" : ""))
                        .font(text.isEmpty ? .subheadline : .caption)
                        .foregroundStyle(state.showRequiredError && isRequiredField ? .red : Color(.onSurface).opacity(0.6))
                        .padding(.leading, 8)
                    Spacer()
                    Button {
                        workingText = text
                        showSheet = true
                    } label: {
                        Image(systemName: "arrow.down.left.and.arrow.up.right")
                    }
                    .foregroundStyle(.primary)
                }
                .padding([.top, .trailing], 6)
                TextEditor(text: $text)
                    .tint(.onSurfaceColor)
                    .scrollContentBackground(.hidden) // this hides the special background color that only lives behind the text inside this area
                    .frame(minHeight: 55, maxHeight: 650)
                    .padding([.bottom], 12)
            }
            .background(Color(.onSurface).opacity(0.12)) // derived from MAGEScheme
            .onChange(of: text) { newValue in
                if !newValue.isEmpty {
                    state.showRequiredError = false
                }
                delegate?.fieldValueChanged(field, value: newValue)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(state.showRequiredError && isRequiredField ? Color.red : Color.gray, lineWidth: 1)
            )
            .padding([.bottom], 2)
            Text("\(title) is required")
                .foregroundColor(.red)
                .font(.caption)
                .padding([.leading, .bottom], 12)
                .opacity(state.showRequiredError && isRequiredField ? 1 : 0)
        }
        .listRowSeparator(.hidden)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                VStack {
                    TextEditor(text: $workingText)
                        .tint(.onSurfaceColor)
                        .scrollContentBackground(.hidden)
                        .background(Color(.onSurface).opacity(0.12))
                        .cornerRadius(16)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: {
                                    showSheet = false
                                }) {
                                    Image(systemName: "xmark")
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    showSheet = false
                                    text = workingText
                                    delegate?.fieldValueChanged(field, value: text)
                                }) {
                                    Image(systemName: "checkmark")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                        }
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.primary, for: .navigationBar)
                }
                .padding(20)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    ExpandingTextEditor(value: "NARF")
}
