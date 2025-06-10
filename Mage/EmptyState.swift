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
    var didSetupConstraints = false
    var scheme: AppContainerScheming?
    var image: UIImage?
    var title: String?
    var emptyDescription: String?
    var attributedDescription: NSAttributedString?
    var buttonText: String?
    var tapHandler: AnyObject?
    var selector: Selector?
    
    let containerView: UIView = UIView.newAutoLayout()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ())
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.accessibilityLabel = "Empty Image"
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(forAutoLayout: ())
        titleLabel.accessibilityLabel = "Empty Title"
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.text = title
        return titleLabel
    }()
    
    lazy var descriptionLabel: UITextView = {
        let descriptionLabel = UITextView(forAutoLayout: ())
        descriptionLabel.accessibilityLabel = "Empty Description"
        descriptionLabel.textAlignment = .center
        descriptionLabel.isScrollEnabled = false
        descriptionLabel.isEditable = false
        if let attributedDescription = attributedDescription {
            descriptionLabel.attributedText = attributedDescription
        }
        if let emptyDescription = emptyDescription {
            descriptionLabel.text = emptyDescription
        }
        return descriptionLabel
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.accessibilityLabel = buttonText
        button.setTitle(buttonText, for: .normal)
        if let selector = selector {
            button.addTarget(tapHandler, action: selector, for: .touchUpInside)
        }
        button.clipsToBounds = true
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    var isActivityIndicatorHidden: Bool {
        get {
            return activityIndicator.isHidden
        }
        set {
            UIView.animate(withDuration: 0.45, delay: 0, options: [], animations: { [weak self] in
                self?.activityIndicator.alpha = newValue ? 0 : 1
            }, completion: { [weak self] _ in
                if newValue {
                    self?.activityIndicator.stopAnimating()
                } else {
                    self?.activityIndicator.startAnimating()
                }
                
                self?.activityIndicator.isHidden = newValue
            })
        }
    }
    
    var isButtonHidden: Bool {
        get {
            return button.isHidden
        }
        set {
            UIView.animate(withDuration: 0.45, delay: 0, options: [], animations: { [weak self] in
                self?.button.alpha = newValue ? 0 : 1
            }, completion: { [weak self] _ in
                self?.button.isHidden = newValue
            })
        }
    }
        
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(stackView)
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(button)

        applyTheme(withScheme: scheme)
    }
    
    func toggleVisible(_ visible: Bool = true, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.45, delay: 0, options: [], animations: { [weak self] in
            self?.alpha = visible ? 1 : 0
        }, completion: { [weak self] success in
            if success {
                self?.isHidden = !visible
            }
            completion?(success)
        })
    }
    
    func configure(image: UIImage? = nil, title: String? = nil, description: String? = nil, attributedDescription: NSAttributedString? = nil, showActivityIndicator: Bool? = false, buttonText: String? = nil, tapHandler: AnyObject? = nil, selector: Selector? = nil, scheme: AppContainerScheming? = nil) {
        UIView.transition(with: self, duration: 0.45, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.image = image
            self?.title = title
            self?.emptyDescription = description
            self?.attributedDescription = attributedDescription
            self?.buttonText = buttonText
            self?.scheme = scheme
            self?.selector = selector
            self?.tapHandler = tapHandler
        
            self?.button.accessibilityLabel = buttonText
            self?.button.setTitle(buttonText, for: .normal)
            if let selector = selector {
                self?.button.addTarget(tapHandler, action: selector, for: .touchUpInside)
            }
            
            if let attributedDescription = self?.attributedDescription {
                self?.descriptionLabel.attributedText = attributedDescription
            }
            if let emptyDescription = self?.emptyDescription {
                self?.descriptionLabel.text = emptyDescription
            }
        
            self?.titleLabel.text = title
            self?.titleLabel.accessibilityLabel = title
        
            self?.imageView.image = image
            self?.button.isHidden = buttonText == nil
            self?.activityIndicator.isHidden = !(showActivityIndicator ?? false)
        }, completion: nil)
        applyTheme(withScheme: scheme)
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme else { return }
        self.scheme = scheme
        
        backgroundColor = scheme.colorScheme.surfaceColor
        titleLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.60)
        titleLabel.font = scheme.typographyScheme.headline4Font
        descriptionLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.60)
        descriptionLabel.font = scheme.typographyScheme.bodyFont
        descriptionLabel.backgroundColor = .clear
        imageView.tintColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.45)
        
//        if let scheme = scheme {
//            button.applyContainedTheme(withScheme: scheme)
//        }
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
//            if button.superview == nil {
//                descriptionLabel.autoPinEdge(toSuperviewEdge: .bottom)
//            } else {
            stackView.autoPinEdge(.top, to: .bottom, of: descriptionLabel, withOffset: 24)
            stackView.autoAlignAxis(toSuperviewAxis: .vertical)
            stackView.autoPinEdge(toSuperviewEdge: .bottom)
//            }

            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
