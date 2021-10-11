//
//  CommonSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class CommonSummaryView<T, V>: UIView {
    
    var imageOverride: UIImage?;
    private var didSetUpConstraints = false;
    
    lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0;
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.isUserInteractionEnabled = false;
        return stack;
    }()
    
    lazy var timestamp: UILabel = {
        let timestamp = UILabel(forAutoLayout: ());
        timestamp.numberOfLines = 0;
        timestamp.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return timestamp;
    }()
    
    lazy var itemImage: UIImageView = {
        let itemImage = UIImageView(forAutoLayout: ());
        itemImage.contentMode = .scaleAspectFit;
        return itemImage;
    }()
    
    lazy var primaryField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        primaryField.setContentHuggingPriority(.defaultLow, for: .vertical)
        primaryField.numberOfLines = 0;
        return primaryField;
    }()
    
    lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        secondaryField.numberOfLines = 0;
        secondaryField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        secondaryField.lineBreakMode = .byWordWrapping
        secondaryField.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return secondaryField;
    }()
    
    // this is for sublcases to add extra to to the secondary field area
    lazy var secondaryContainer: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 8;
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.isUserInteractionEnabled = false;
        stack.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return stack;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(imageOverride: UIImage? = nil) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.imageOverride = imageOverride;
        stack.addArrangedSubview(timestamp);
        stack.setCustomSpacing(12, after: timestamp);
        stack.addArrangedSubview(primaryField);
        stack.setCustomSpacing(8, after: primaryField);
        secondaryContainer.addArrangedSubview(secondaryField);
        stack.addArrangedSubview(secondaryContainer);
        
        self.addSubview(stack);
        self.addSubview(itemImage);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stack.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
            itemImage.autoSetDimensions(to: CGSize(width: 48, height: 48));
            itemImage.autoPinEdge(.left, to: .right, of: stack, withOffset: 8);
            itemImage.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
            itemImage.autoPinEdge(toSuperviewEdge: .top, withInset: 16);
            itemImage.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16, relation: .greaterThanOrEqual);
            self.autoSetDimension(.height, toSize: 90, relation: .greaterThanOrEqual)
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func populate(item: T, actionsDelegate: V? = nil) {
        preconditionFailure("This method must be overridden");
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        timestamp.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        timestamp.font = scheme.typographyScheme.overline;
        timestamp.autoSetDimension(.height, toSize: timestamp.font.pointSize);
        primaryField.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        primaryField.font = scheme.typographyScheme.headline6;
        primaryField.autoSetDimension(.height, toSize: primaryField.font.pointSize, relation: .greaterThanOrEqual);
        secondaryField.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        secondaryField.font = scheme.typographyScheme.subtitle2;
        secondaryContainer.autoSetDimension(.height, toSize: secondaryField.font.pointSize + 2)
        secondaryField.autoSetDimension(.height, toSize: secondaryField.font.pointSize + 2);
    }
}
