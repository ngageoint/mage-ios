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
    
    init(field: [String: Any] = [:], value: String, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.title = field[FieldKey.title.key] as? String ?? "Text Area"
        self.field = field
        self.delegate = delegate
        self.text = value
        self.workingText = value
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color(.onSurface).opacity(0.6)) // derived from MAGEScheme
                    .padding(.leading, 8)
                Spacer()
                Button {
                    workingText = text
                    showSheet = true
                } label: {
                    Image(systemName: "arrow.down.left.and.arrow.up.right")
                }
            }
            .padding([.top, .trailing], 6)
            TextEditor(text: $text)
                .tint(.onSurfaceColor)
                .scrollContentBackground(.hidden) // this hides the special background color that only lives behind the text inside this area
                .frame(minHeight: 55, maxHeight: 650)
                .padding([.bottom], 12)
        }
        .background(Color(.onSurface).opacity(0.12)) // derived from MAGEScheme
        .onDisappear(perform: {
            delegate?.fieldValueChanged(field, value: text)
        })
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding([.bottom], 20)
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
