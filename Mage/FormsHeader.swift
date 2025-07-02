//
//  FormsHeaderCard.swift
//  MAGE
//
//  Created by Daniel Barela on 1/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class FormsHeader: UIView {
    var didSetupConstraints = false
    var scheme: AppContainerScheming?
    
    private lazy var headerLabel: UILabel = {
        let label: UILabel = UILabel(forAutoLayout: ())
        label.text = "FORMS"
        return label
    }()
    
    lazy var reorderButton: UIButton = {
        let button = UIButton()
        button.accessibilityLabel = "reorder"
        button.accessibilityIdentifier = "reorder"
        button.setImage(UIImage(systemName: "arrow.up.arrow.down")?.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal)
        button.autoSetDimensions(to: CGSize(width: 40, height: 40))
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming) {
        self.scheme = scheme
        headerLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.87)

        reorderButton.applyPrimaryTheme(withScheme: scheme)
        reorderButton.setTitleColor(scheme.colorScheme.primaryColorVariant, for: .normal)
        reorderButton.tintColor = scheme.colorScheme.primaryColorVariant
    }
    
    func buildView() {
        self.addSubview(headerLabel)
        self.addSubview(reorderButton)
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            headerLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            headerLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
            reorderButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 16), excludingEdge: .left)
        }
        super.updateConstraints()
    }
}
