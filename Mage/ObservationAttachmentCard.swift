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
    var observation: Observation;
    var viewController: UIViewController;
    var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    
    lazy var attachmentField: [String: Any] = {
        let attachmentField: [String: Any] =
            [
             FieldKey.name.key: "attachments",
             FieldKey.type.key: "attachment"
            ];
        return attachmentField;
    }()
    
    lazy var attachmentView: AttachmentFieldView = {
        let attachmentView = AttachmentFieldView(field: attachmentField, editMode: false, value: observation.attachments, attachmentSelectionDelegate: attachmentSelectionDelegate);
        return attachmentView;
    }()
    
    init(observation: Observation, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, viewController: UIViewController) {
        self.observation = observation;
        self.viewController = viewController;
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
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        attachmentView.applyTheme(withScheme: scheme);
    }
    
    func buildView() {
        // for legacy servers add the attachment field to common
        if (MageServer.isServerVersion5()) {
            self.addSubview(attachmentView);
        }
    }
}

extension ObservationAttachmentCard: ObservationFormFieldListener {
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        var newProperties = self.observation.properties as? [String: Any];
        
        if (field[FieldKey.name.key] as! String == attachmentField[FieldKey.name.key] as! String) {
            self.observation.addAttachments(value as! Set<Attachment>);
        }
        self.observation.properties = newProperties;
    }
}

