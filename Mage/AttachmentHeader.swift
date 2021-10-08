//
//  AttachmentHeader.swift
//  MAGE
//
//  Created by Daniel Barela on 6/23/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class AttachmentHeader: UIView {
    var didSetupConstraints = false;
    var scheme: MDCContainerScheming?;
    
    private lazy var headerLabel: UILabel = {
        let label: UILabel = UILabel(forAutoLayout: ());
        label.text = "ATTACHMENTS";
        return label;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        buildView();
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        headerLabel.font = scheme?.typographyScheme.overline;
        headerLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
    }
    
    func buildView() {
        self.addSubview(headerLabel);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            headerLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16));
        }
        super.updateConstraints();
    }
}
