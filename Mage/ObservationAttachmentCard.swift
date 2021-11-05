//
//  ObservationAttachmentCard.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import PureLayout

class ObservationAttachmentCard: MDCCard {
    var didSetupConstraints = false;
    weak var observation: Observation?;
    weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    
    lazy var attachmentField: [String: Any] = {
        let attachmentField: [String: Any] =
            [
             FieldKey.name.key: "attachments",
             FieldKey.type.key: "attachment"
            ];
        return attachmentField;
    }()
    
    lazy var attachmentView: AttachmentFieldView = {
        let attachmentView = AttachmentFieldView(field: attachmentField, editMode: false, value: observation?.attachments, attachmentSelectionDelegate: attachmentSelectionDelegate);
        return attachmentView;
    }()
    
    init(observation: Observation, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil) {
        self.observation = observation;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.accessibilityLabel = "Observation Attachment Card"
        buildView();
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            attachmentView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8));
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        attachmentView.applyTheme(withScheme: scheme);
    }
    
    func buildView() {
        self.addSubview(attachmentView);
    }
    
    func populate(observation: Observation? = nil) {
        if (observation != nil) {
            self.observation = observation;
            attachmentView.setValue(self.observation?.attachments);
        }
    }
}

extension ObservationAttachmentCard: ObservationFormFieldListener {
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        let newProperties = self.observation?.properties as? [String: Any];
        
        if (field[FieldKey.name.key] as! String == attachmentField[FieldKey.name.key] as! String) {
            if let attachments = value as? Set<Attachment> {
                self.observation?.addToAttachments(attachments);
            }
        }
        self.observation?.properties = newProperties;
    }
}

