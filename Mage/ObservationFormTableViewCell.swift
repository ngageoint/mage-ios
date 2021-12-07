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
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var secondaryLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
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
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        formNameLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        formNameLabel.font = scheme?.typographyScheme.overline;
        primaryLabel.textColor = scheme?.colorScheme.primaryColor.withAlphaComponent(0.87);
        primaryLabel.font = scheme?.typographyScheme.headline6;
        secondaryLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        secondaryLabel.font = scheme?.typographyScheme.subtitle2;
    }
    
    func configure(observationForm: [String : Any], eventForm: Form, scheme: MDCContainerScheming?) {
        
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryField = eventForm.primaryFeedField, let primaryFieldName = primaryField[FieldKey.name.key] as? String {
            if let obsfield = observationForm[primaryFieldName] {
                formPrimaryValue = Observation.fieldValueText(value: obsfield, field: primaryField)
            }
        }
        
        if let secondaryField = eventForm.secondaryFeedField, let secondaryFieldName = secondaryField[FieldKey.name.key] as? String {
            if let obsfield = observationForm[secondaryFieldName] {
                formSecondaryValue = Observation.fieldValueText(value: obsfield, field: secondaryField)
            }
        }
        
        thumbnail.image  = UIImage(named: "description")
        formName = eventForm.name
        primary = formPrimaryValue;
        secondary = formSecondaryValue;
        var tintColor: UIColor? = nil;
        if let color = eventForm.color {
            tintColor = UIColor(hex: color);
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        
        if let scheme = scheme {
            thumbnail.tintColor = tintColor ?? scheme.colorScheme.primaryColor;
            applyTheme(withScheme: scheme)
        }
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            self.contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 99999.0, height: 99999.0);
            stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 56, bottom: 8, right: 0))
            stackView.autoSetDimension(.height, toSize: 48, relation: .greaterThanOrEqual)
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
