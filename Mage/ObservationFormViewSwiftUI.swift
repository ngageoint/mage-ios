//
//  ObservationFormViewSwiftUI.swift
//  MAGE
//
//  Created by Dan Barela on 7/30/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MaterialViews

struct ObservationFormViewSwiftUI: View {
    @State
    var expanded: Bool = true
    
    @EnvironmentObject
    var router: MageRouter
    
    var viewModel: ObservationFormViewModel
    var selectedUnsentAttachment: (_ localPath: String, _ contentType: String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(viewModel.formColor)
                    Text(viewModel.formName ?? "")
                        .overlineText()
                    Spacer()
                    Button {
                        withAnimation {
                            expanded.toggle()
                        }
                    } label: {
                        Label {
                            Text("")
                        } icon: {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        }
                    }
                }
                if let primaryFieldText = viewModel.primaryFieldText {
                    Text(primaryFieldText)
                        .primaryText()
                }
                if let secondaryFieldText = viewModel.secondaryFieldText {
                    Text(secondaryFieldText)
                        .secondaryText()
                }
            }
            if expanded {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.formFields) { field in
                            if viewModel.shouldDisplay(field: field) {
                                let fieldValue = viewModel.fieldStringValue(fieldName: field.name) ?? ""
                                
                                if field.type != FieldType.attachment.key {
                                    Text(field.title)
                                        .secondaryText()
                                }
                                
                                switch (field.type) {
                                case FieldType.password.key:
                                    Text(fieldValue)
                                        .privacySensitive()
                                        .padding(.bottom, 8)
                                case FieldType.checkbox.key:
                                    if fieldValue == "true" {
                                        Image(systemName:"checkmark.square.fill")
                                            .foregroundStyle(Color.primaryColorVariant)
                                            .padding(.bottom, 8)
                                    } else {
                                        Image(systemName:"square")
                                            .foregroundStyle(Color.primaryColorVariant)
                                            .padding(.bottom, 8)
                                    }
                                case FieldType.attachment.key:
                                    AttachmentFieldViewSwiftUI(
                                        viewModel: AttachmentFieldViewModel(
                                            observationUri: viewModel.form.observationId,
                                            observationFormId: viewModel.form.id,
                                            fieldName: field.name,
                                            fieldTitle: field.title
                                        ),
                                        selectedUnsentAttachment: selectedUnsentAttachment
                                    )
                                    .padding(.bottom, 8)
                                case FieldType.geometry.key:
                                    if let observationUri = viewModel.form.observationId { // This part is different from the file content
                                        ObservationLocationFieldView(
                                            observationUri: observationUri,
                                            observationFormId: viewModel.form.id,
                                            fieldName: field.name
                                        )
                                        .padding(.bottom, 8)
                                    }
                                default:
                                    Text(fieldValue)
                                        .padding(.bottom, 8)
                                }
                            }
                        }
                    }
                    .redacted(reason: .privacy)
                    Spacer()
                }
            }
        }

        .padding()
        .frame(maxWidth: .infinity)
        .card()
    }
}
