//
//  ObservationFormCardCell.swift
//  MAGE
//
//  Created by Daniel Barela on 5/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import UIKit
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import PureLayout

class ExpandableCard: MDCCard {
    private var didSetUpConstraints = false;
    private var container: UIView?;
    private var expandedView: UIView?;
    private var imageTint: UIColor?;
    var showExpanded: Bool = true;
    
    private let exclamation = UIImageView(image: UIImage(named: "exclamation"));
    
    private lazy var errorShapeLayer: CAShapeLayer = {
        let path = CGMutablePath()
        let heightWidth = 25
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x:0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth, y:0))
        path.addLine(to: CGPoint(x:0, y:0))
        
        let shape = CAShapeLayer()
        shape.path = path
        
        return shape;
    }()
    
    private lazy var errorBadge: UIView = {
        let errorBadge = UIView(forAutoLayout: ());
        let heightWidth = 25
        
        errorBadge.layer.insertSublayer(errorShapeLayer, at: 0)
        errorBadge.addSubview(exclamation);
        
        return errorBadge;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .fill;
        stackView.distribution = .fill;
        stackView.axis = .vertical;
        stackView.spacing = 0;
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
    
    private lazy var titleText: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var headerText: UILabel = {
        let label = UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var subhead: UILabel = {
        let label = UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var expandAction: MDCButton = {
        let expandAction = MDCButton();
        expandAction.accessibilityLabel = "expand";
        expandAction.setImage(UIImage(named: "collapse")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        expandAction.setImage(UIImage(named: "expand")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .selected);
        expandAction.addTarget(self, action: #selector(expandButtonPressed), for: .touchUpInside)
        expandAction.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        expandAction.inkMaxRippleRadius = 30;
        expandAction.inkStyle = .unbounded;
        expandAction.autoSetDimensions(to: CGSize(width: 36, height: 36))
        return expandAction;
    }()
    
    private lazy var expandableView: UIView = {
        let expandableView = UIView(forAutoLayout: ());
        expandableView.accessibilityLabel = "expandableArea"
        expandableView.isAccessibilityElement = true;
        expandableView.isHidden = !self.showExpanded;
        return expandableView;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        thumbnail.tintColor = self.imageTint ?? scheme.colorScheme.primaryColor;
        expandAction.applyTextTheme(withScheme: scheme);
        expandAction.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        expandAction.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .selected);
        titleText.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        titleText.font = scheme.typographyScheme.overline;
        headerText.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        headerText.font = scheme.typographyScheme.headline6;
        subhead.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        subhead.font = scheme.typographyScheme.subtitle2;
        
        errorShapeLayer.fillColor = scheme.colorScheme.errorColor.cgColor
        exclamation.tintColor = UIColor.white;
    }
    
    @objc func expandButtonPressed() {
        expanded = !self.expanded;
    }
    
    var title: String? {
        get {
            return titleText.text
        }
        set(title) {
            titleText.isHidden = title == nil
            titleText.text = title?.uppercased()
        }
    }
    
    var header: String? {
        get {
            return headerText.text
        }
        set(header) {
            headerText.isHidden = header == nil
            headerText.text = header
        }
    }
    
    var subheader: String? {
        get {
            return subhead.text
        }
        set(subheader) {
            subhead.isHidden = subheader == nil
            subhead.text = subheader
        }
    }
    
    var expanded: Bool {
        get {
            return self.showExpanded
        }
        set(expanded) {
            self.showExpanded = expanded;
            self.expandableView.isHidden = !self.showExpanded;
            expandAction.isSelected = !expanded;
        }
    }
    
    deinit {
        self.expandedView = nil;
    }
    
    convenience init(header: String? = nil, subheader: String? = nil, imageName: String? = nil, title: String? = nil, imageTint: UIColor? = nil, expandedView: UIView? = nil) {
        self.init(frame: .zero);
        self.configureForAutoLayout();
        self.configure(header: header, subheader: subheader, imageName: imageName, title: title, imageTint: imageTint, expandedView: expandedView);
    }
    
    func configure(header: String?, subheader: String?, imageName: String?, title: String? = nil, imageTint: UIColor? = nil, expandedView: UIView?) {
        if let safeImageName = imageName {
            self.thumbnail.image  = UIImage(named: safeImageName)
            self.thumbnail.accessibilityLabel = safeImageName;
        }
        self.header = header;
        self.subheader = subheader;
        self.title = title;
        self.expandedView = expandedView;
        self.imageTint = imageTint;
        constructCard();
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
            if (thumbnail.superview != nil) {
                thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 0), excludingEdge: .right);
                thumbnail.autoSetDimensions(to: CGSize(width: 24, height: 24));
            }
            titleText.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 32));
            
            errorBadge.autoSetDimensions(to: CGSize(width: 25, height: 25));
            errorBadge.autoPinEdge(toSuperviewEdge: .top);
            errorBadge.autoPinEdge(toSuperviewEdge: .left);
            
            exclamation.autoSetDimensions(to: CGSize(width: 14, height: 14));
            exclamation.autoPinEdge(toSuperviewEdge: .top, withInset: 1);
            exclamation.autoPinEdge(toSuperviewEdge: .left);
            
            if expandedView != nil {
                expandAction.autoPinEdge(toSuperviewEdge: .top, withInset: 8);
                expandAction.autoPinEdge(toSuperviewEdge: .right, withInset: 8);
//                expandAction.autoSetDimensions(to: CGSize(width: 24, height: 24));
                expandedView?.autoPinEdgesToSuperviewEdges();
            }
        }
        super.updateConstraints();
    }
    
    private func constructCard() {
        self.container?.addSubview(self);
        self.addSubview(stackView);

        if (self.thumbnail.image != nil) {
            titleArea.addSubview(thumbnail);
        }
        
        titleArea.addSubview(titleText);
        
        stackView.addArrangedSubview(titleArea);
        stackView.addArrangedSubview(headerText)
        stackView.setCustomSpacing(4, after: headerText)
        stackView.addArrangedSubview(subhead);

        let spacerView = UIView(forAutoLayout: ());
        spacerView.autoSetDimension(.height, toSize: 8);
        stackView.addArrangedSubview(spacerView);
        if expandedView != nil {
            self.addSubview(expandAction);
            
            expandableView.addSubview(expandedView!);
            stackView.addArrangedSubview(expandableView);
        }
        
        self.addSubview(errorBadge);
        errorBadge.isHidden = true;
    }
    
    public func markValid(_ valid: Bool = true) {
        errorBadge.isHidden = valid;
    }
}
