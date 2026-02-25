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
    @State var text: String
    @State var workingText: String
    @State private var showSheet = false
    
    init(title: [String: Any] = [:], text: String = "") {
        self.title = title[FieldKey.name.key] as? String ?? "Text Area"
        self.text = text
        self.workingText = text
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.subtitle1)
                    .foregroundStyle(.secondary)
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
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray, lineWidth: 1)
        )
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
    ExpandingTextEditor()
}
