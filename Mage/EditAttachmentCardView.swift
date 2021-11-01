//
//  EditAttachmentCardView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/14/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import PureLayout


// for legacy servers add the attachment field to common
// TODO: This can be removed once all servers are upgraded
class EditAttachmentCardView: MDCCard {
    var didSetupConstraints = false;
    var observation: Observation;
    weak var viewController: UIViewController?;
    weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    var scheme: MDCContainerScheming?;
    var attachmentCreationCoordinator: AttachmentCreationCoordinator?;
    
    lazy var attachmentField: [String: Any] = {
        let attachmentField: [String: Any] =
            [FieldKey.name.key: "attachments",
             FieldKey.type.key: "attachment"
            ];
        return attachmentField;
    }()
    
    lazy var attachmentView: AttachmentFieldView = {
        attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: viewController, observation: observation, scheme:scheme);
        let attachmentView = AttachmentFieldView(field: attachmentField, delegate: self, value: observation.attachments, attachmentSelectionDelegate: attachmentSelectionDelegate, attachmentCreationCoordinator: attachmentCreationCoordinator);
        return attachmentView;
    }()
    
    init(observation: Observation, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, viewController: UIViewController) {
        self.observation = observation;
        self.viewController = viewController;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        buildView();
        self.accessibilityLabel = "Edit Attachment Card"
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        self.scheme = scheme;
        attachmentView.applyTheme(withScheme: scheme);
        attachmentCreationCoordinator?.applyTheme(withContainerScheme: scheme);
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
    
    func buildView() {
        self.addSubview(attachmentView);
    }
}

extension EditAttachmentCardView: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
//        fieldSelectionDelegate?.launchFieldSelectionViewController(viewController: viewController);
    }
}

extension EditAttachmentCardView: ObservationFormFieldListener {
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        let newProperties = self.observation.properties as? [String: Any];
        
        if (field[FieldKey.name.key] as! String == attachmentField[FieldKey.name.key] as! String) {
            self.observation.addAttachments(value as! Set<Attachment>);
        }
        self.observation.properties = newProperties;
    }
}

