//
//  ExpandingTextEditor.swift
//  MAGE
//
//  Created by Daniel Benner on 2/18/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ExpandingTextEditor: View {
    @Environment(\.undoManager) private var undoManager // TODO: not working
    
    var title: String
    @State var text: String
    @State private var showSheet = false
    
    init(title: String = "Text Area", text: String = "") {
        self.title = title
        self.text = text
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
                    showSheet = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
            }
            .padding([.top, .trailing], 6)
            TextEditor(text: $text)
                .frame(minHeight: 55, maxHeight: 650)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
        .sheet(isPresented: $showSheet) {
            NavigationView() { // nav required to use toolbar items
                TextEditor(text: $text)
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .toolbar {
                        ToolbarItemGroup() {
                            HStack {
                                Button(action: {
                                    showSheet = false
                                }) {
                                    Image(systemName: "xmark.circle")
                                }
                                Spacer()
                                Button(action: {
                                    undoManager?.undo()
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .imageScale(.large)
                                }
                                .disabled(undoManager?.canUndo == false)
                                Button(action: {
                                    undoManager?.redo()
                                }) {
                                    Image(systemName: "arrow.uturn.forward.circle")
                                        .imageScale(.large)
                                }
                                .disabled(undoManager?.canRedo == false)
                                Spacer()
                                Button(action: {
                                    showSheet = false
                                }) {
                                    Image(systemName: "checkmark.circle")
                                }
                            }
                        }
                    }
                    .toolbarBackground(.gray, for: .navigationBar)
            }
        }
    }
}

#Preview {
    ExpandingTextEditor(title: "testTitle", text: "test text")
}
