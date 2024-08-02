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
    
    var viewModel: ObservationFormViewModel
    var selectedAttachment: (_ attachmentUri: URL) -> Void
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
                            Text(field.title)
                                .secondaryText()
                            switch (field.type) {
                            case FieldType.password.key:
                                Text(viewModel.fieldStringValue(fieldName: field.name) ?? "")
                                    .privacySensitive()
                                    .padding(.bottom, 8)
                            case FieldType.checkbox.key:
                                if (viewModel.fieldStringValue(fieldName: field.name) ?? "false") == "true" {
                                    Image(systemName:"checkmark.square.fill")
                                        .foregroundStyle(Color.primaryColorVariant)
                                } else {
                                    Image(systemName:"square")
                                        .foregroundStyle(Color.primaryColorVariant)
                                }
                            case FieldType.attachment.key:
                                AttachmentFieldViewSwiftUI(viewModel: AttachmentFieldViewModel(observationUri: viewModel.form.observationId, observationFormId: viewModel.form.id, fieldName: field.name))
                            case FieldType.geometry.key:
                                if let observationUri = viewModel.form.observationId {
                                    ObservationLocationFieldView(
                                        observationUri: observationUri,
                                        observationFormId: viewModel.form.id,
                                        fieldName: field.name
                                    )
                                }
                            default:
                                Text(viewModel.fieldStringValue(fieldName: field.name) ?? "")
                                    .padding(.bottom, 8)
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
