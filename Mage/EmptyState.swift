//
//  EmptyState.swift
//  MAGE
//
//  Created by Daniel Barela on 4/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

class EmptyState: UIView {
    var didSetupConstraints = false;
    var scheme: MDCContainerScheming?
    var image: UIImage?
    var title: String?
    var emptyDescription: String?
    var buttonText: String?
    var tapHandler: AnyObject?
    var selector: Selector?
    
    let containerView: UIView = UIView.newAutoLayout()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.accessibilityLabel = "Empty Image"
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(forAutoLayout: ())
        label.accessibilityLabel = "Empty Title"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = title
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel(forAutoLayout: ())
        label.accessibilityLabel = "Empty Description"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = emptyDescription
        return label
    }()
    
    private lazy var button: MDCButton = {
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = buttonText;
        button.setTitle(buttonText, for: .normal);
        if let selector = selector {
            button.addTarget(tapHandler, action: selector, for: .touchUpInside)
        }
        button.clipsToBounds = true;
        return button;
    }()
    
    func configure(image: UIImage? = nil, title: String? = nil, description: String? = nil, buttonText: String? = nil, tapHandler: AnyObject? = nil, selector: Selector? = nil, scheme: MDCContainerScheming? = nil) {
        self.image = image
        self.title = title
        self.emptyDescription = description
        self.buttonText = buttonText
        self.scheme = scheme
        self.selector = selector
        self.tapHandler = tapHandler
        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        if buttonText != nil {
            containerView.addSubview(button)
        }
        applyTheme(withScheme: scheme)
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        backgroundColor = scheme?.colorScheme.surfaceColor
        titleLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.60)
        titleLabel.font = scheme?.typographyScheme.headline4
        descriptionLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.60)
        descriptionLabel.font = scheme?.typographyScheme.body1
        imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.45)
        if let scheme = scheme, button.superview != nil {
            button.applyContainedTheme(withScheme: scheme)
        }
    }
    
    override func didMoveToSuperview() {
        updateConstraints()
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            // accounts for the tab bar
            containerView.autoAlignAxis(.horizontal, toSameAxisOf: self, withOffset: -40)
            containerView.autoAlignAxis(toSuperviewAxis: .vertical)
            containerView.autoMatch(.width, to: .width, of: self, withOffset: -64)
            imageView.autoSetDimensions(to: CGSize(width: 200, height: 200))
            imageView.autoPinEdge(toSuperviewEdge: .top)
            imageView.autoAlignAxis(toSuperviewAxis: .vertical)
            titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 16)
            titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
            titleLabel.autoPinEdge(toSuperviewEdge: .left)
            titleLabel.autoPinEdge(toSuperviewEdge: .right)
            descriptionLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 8)
            descriptionLabel.autoAlignAxis(toSuperviewAxis: .vertical)
            descriptionLabel.autoPinEdge(toSuperviewEdge: .left)
            descriptionLabel.autoPinEdge(toSuperviewEdge: .right)
            if button.superview == nil {
                descriptionLabel.autoPinEdge(toSuperviewEdge: .bottom)
            } else {
                button.autoPinEdge(.top, to: .bottom, of: descriptionLabel, withOffset: 24)
                button.autoAlignAxis(toSuperviewAxis: .vertical)
                button.autoPinEdge(toSuperviewEdge: .bottom)
            }

            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
}
