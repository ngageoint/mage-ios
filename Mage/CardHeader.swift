//
//  CardHeader.swift
//  MAGE
//
//  Created by Daniel Barela on 6/23/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class CardHeader: UIView {
    var didSetupConstraints = false;
    var scheme: MDCContainerScheming?;
    var headerText: String?;
    
    private lazy var headerLabel: UILabel = {
        let label: UILabel = UILabel(forAutoLayout: ());
        label.text = headerText;
        return label;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame);
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public convenience init(headerText: String?) {
        self.init(frame: CGRect.zero)
        self.headerText = headerText
        buildView();
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
