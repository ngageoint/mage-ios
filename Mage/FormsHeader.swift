//
//  FormsHeaderCard.swift
//  MAGE
//
//  Created by Daniel Barela on 1/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class FormsHeader: UIView {
    var didSetupConstraints = false;
    var scheme: MDCContainerScheming?;
    
    private lazy var headerLabel: UILabel = {
        let label: UILabel = UILabel(forAutoLayout: ());
        label.text = "FORMS";
        return label;
    }()
    
    lazy var reorderButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = "reorder";
        button.accessibilityIdentifier = "reorder";
        button.setImage(UIImage(named: "reorder")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 40, height: 40));
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        return button;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        buildView();
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        headerLabel.font = scheme.typographyScheme.overline;
        headerLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        reorderButton.applyTextTheme(withScheme: scheme);
        reorderButton.tintColor = scheme.colorScheme.primaryColor;
    }
    
    func buildView() {
        self.addSubview(headerLabel);
        self.addSubview(reorderButton);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            headerLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
            headerLabel.autoAlignAxis(toSuperviewAxis: .horizontal);
            reorderButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 16), excludingEdge: .left);
        }
        super.updateConstraints();
    }
}
