//
//  ObservationFormTableViewCell.swift
//  MAGE
//
//  Created by Daniel Barela on 1/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationFormTableViewCell: UITableViewCell {

    private var constructed = false;
    private var didSetUpConstraints = false;
    private var imageTint: UIColor?;
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .fill;
        stackView.distribution = .fill;
        stackView.axis = .vertical;
        stackView.spacing = 4;
        return stackView;
    }()
    
    private lazy var titleArea: UIView = {
        let titleArea = UIView(forAutoLayout: ());
        return titleArea;
    }();

    private lazy var thumbnail: UIImageView = {
        let imageView = UIImageView(forAutoLayout: ());
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var formNameLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var primaryLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());//UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var secondaryLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());//UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    var formName: String? {
        get {
            return formNameLabel.text
        }
        set(title) {
            formNameLabel.isHidden = title == nil
            formNameLabel.text = title?.uppercased()
        }
    }
    
    var primary: String? {
        get {
            return primaryLabel.text
        }
        set(header) {
            primaryLabel.isHidden = header == nil
            primaryLabel.text = header
        }
    }
    
    var secondary: String? {
        get {
            return secondaryLabel.text
        }
        set(subheader) {
            secondaryLabel.isHidden = subheader == nil
            secondaryLabel.text = subheader
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        construct()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        formNameLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        formNameLabel.font = scheme.typographyScheme.overline;
        primaryLabel.textColor = scheme.colorScheme.primaryColor.withAlphaComponent(0.87);
        primaryLabel.font = scheme.typographyScheme.headline6;
        secondaryLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        secondaryLabel.font = scheme.typographyScheme.subtitle2;
    }
    
    func configure(observationForm: [String : Any], eventForm: [String: Any], scheme: MDCContainerScheming?) {
        var formPrimaryValue: String? = nil;
        if let primaryField = eventForm["primaryField"] as! String? {
            if let obsfield = observationForm[primaryField] as! String? {
                formPrimaryValue = obsfield;
            }
        }
        
        var formSecondaryValue: String? = nil;
        if let secondaryField = eventForm["variantField"] as! String? {
            if let obsfield = observationForm[secondaryField] as! String? {
                formSecondaryValue = obsfield;
            }
        }
        
        thumbnail.image  = UIImage(named: "description")
        formName = eventForm["name"] as? String
        primary = formPrimaryValue;
        secondary = formSecondaryValue;
        var tintColor: UIColor? = nil;
        if let safeColor = eventForm["color"] as? String {
            tintColor = UIColor(hex: safeColor);
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        
        if let safeScheme = scheme {
            thumbnail.tintColor = tintColor ?? safeScheme.colorScheme.primaryColor;
            applyTheme(withScheme: safeScheme)
        }
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 56, bottom: 8, right: 0))
            if (thumbnail.superview != nil) {
                thumbnail.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
                thumbnail.autoSetDimensions(to: CGSize(width: 24, height: 24));
                thumbnail.autoAlignAxis(toSuperviewAxis: .horizontal);
                NSLayoutConstraint.autoSetPriority(.defaultLow) {
                    thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 0), excludingEdge: .right);
                }
            }
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func construct() {
        if (!constructed) {
            self.contentView.addSubview(stackView);
            
            self.contentView.addSubview(thumbnail);
            stackView.addArrangedSubview(formNameLabel);
            stackView.addArrangedSubview(primaryLabel)
            stackView.addArrangedSubview(secondaryLabel);
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
}
