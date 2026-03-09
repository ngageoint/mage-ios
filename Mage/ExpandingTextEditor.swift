//
//  ExpandingTextEditor.swift
//  MAGE
//
//  Created by Daniel Benner on 2/18/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ExpandingTextEditor: View {
    var title: String
    var field: [String: Any]
    var delegate: (ObservationFormFieldListener & FieldSelectionDelegate)?
    @State var text: String
    @State var workingText: String
    @State private var showSheet = false
    @State private var showRequiredError: Bool = false
    
    private var isRequiredField: Bool {
        return (field[FieldKey.required.key] as? Bool) == true
    }
    
    init(field: [String: Any] = [:], value: String, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.title = field[FieldKey.name.key] as? String ?? "Text Area"
        self.field = field
        self.delegate = delegate
        self.text = value
        self.workingText = value
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text("\(title)" + (isRequiredField ? "*" : ""))
                        .font(.subtitle1)
                        .foregroundStyle(text.isEmpty && isRequiredField ? .red : .secondary)
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
                    .frame(minHeight: 55, maxHeight: 650)
            }
            .padding(.bottom, 8)
            .onChange(of: text) { newValue in
                if !newValue.isEmpty {
                    showRequiredError = false
                } else {
                    showRequiredError = true
                }
                delegate?.fieldValueChanged(field, value: newValue)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(showRequiredError && isRequiredField ? Color.red : Color.gray, lineWidth: 1)
            )
            Text("\(title) is required")
                .foregroundColor(.red)
                .font(.caption)
                .padding(.leading, 10)
                .opacity(showRequiredError && isRequiredField ? 1 : 0)
        }
        .listRowSeparator(.hidden)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                 VStack {
                     TextEditor(text: $workingText)
                         .tint(.onSurfaceColor)
                         .cornerRadius(16)
                         .toolbar {
                             ToolbarItem(placement: .topBarLeading) {
                                 Button(action: {
                                     showSheet = false
                                 }) {
                                     Image(systemName: "xmark")
                                 }
                             }
                             // TODO: add undo/redo
     //                        ToolbarItem(placement: .principal) {
     //                            HStack(spacing: 16) {
     //                                Button(action: {
     //                                    undoManager?.undo()
     //                                }) {
     //                                    Image(systemName: "arrow.uturn.backward.circle")
     //                                }
     //                                .disabled(undoManager?.canUndo == false)
     //                                Button(action: {
     //                                    undoManager?.redo()
     //                                }) {
     //                                    Image(systemName: "arrow.uturn.forward.circle")
     //                                }
     //                                .disabled(undoManager?.canRedo == false)
     //                            }
     //                        }
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
