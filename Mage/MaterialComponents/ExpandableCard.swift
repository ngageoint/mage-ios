//
//  ObservationFormCardCell.swift
//  MAGE
//
//  Created by Daniel Barela on 5/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import UIKit
import PureLayout

class ExpandableCard: UIView {
    private var didSetUpConstraints = false
    private var container: UIView?
    private var expandedView: UIView?
    private var imageTint: UIColor?
    var showExpanded: Bool = true
    
    private let exclamation = UIImageView(image: UIImage(systemName: "exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight:.semibold)))
    
    private lazy var errorShapeLayer: CAShapeLayer = {
        let path = CGMutablePath()
        let heightWidth = 25
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x:0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth, y:0))
        path.addLine(to: CGPoint(x:0, y:0))
        
        let shape = CAShapeLayer()
        shape.path = path
        
        return shape
    }()
    
    private lazy var errorBadge: UIView = {
        let view = UIView(forAutoLayout: ())
        view.layer.insertSublayer(errorShapeLayer, at: 0)
        view.addSubview(exclamation)
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ())
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()
    
    private lazy var titleArea: UIView = {
        let titleArea = UIView(forAutoLayout: ())
        return titleArea
    }()
    
    private lazy var thumbnail: UIImageView = {
        let imageView = UIImageView(forAutoLayout: ())
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var titleText: UILabel = {
        let label = UILabel(forAutoLayout: ())
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var headerText: UILabel = {
        let label = UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var subhead: UILabel = {
        let label = UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var expandAction: UIButton = {
        let expandAction = UIButton(type: .custom)
        expandAction.accessibilityLabel = "expand"
        expandAction.setImage(UIImage(systemName: "chevron.up")?.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal)
        expandAction.setImage(UIImage(systemName: "chevron.down")?.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .selected)
        expandAction.addTarget(self, action: #selector(expandButtonPressed), for: .touchUpInside)
        return expandAction
    }()
    
    private lazy var expandableView: UIView = {
        let expandableView = UIView(forAutoLayout: ())
        expandableView.accessibilityLabel = "expandableArea"
        expandableView.isAccessibilityElement = true
        expandableView.isHidden = !self.showExpanded
        return expandableView
    }()
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else { return }
        
        // Card appearance (match MDCCard look)
        backgroundColor = scheme.colorScheme.surfaceColor ?? .systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        thumbnail.tintColor = imageTint ?? scheme.colorScheme.primaryColor
        expandAction.applySecondaryTheme(withScheme: scheme)
        expandAction.setImageTintColor(scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6), for: .normal)
        expandAction.setImageTintColor(scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6), for: .selected)

        titleText.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        titleText.font = scheme.typographyScheme.headline6Font

        headerText.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.87)
        headerText.font = scheme.typographyScheme.headline5Font

        subhead.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        subhead.font = scheme.typographyScheme.subtitle1Font

        errorShapeLayer.fillColor = scheme.colorScheme.errorColor?.cgColor
        exclamation.tintColor = .white
    }
    
    @objc func expandButtonPressed() {
        expanded = !self.expanded
    }
    
    var title: String? {
        get { titleText.text }
        set {
            titleText.isHidden = newValue == nil
            titleText.text = newValue?.uppercased()
        }
    }
    
    var header: String? {
        get { headerText.text }
        set {
            headerText.isHidden = newValue == nil
            headerText.text = newValue
        }
    }
    
    var subheader: String? {
        get { subhead.text }
        set {
            subhead.isHidden = newValue == nil
            subhead.text = newValue
        }
    }
    
    var expanded: Bool {
        get { showExpanded }
        set {
            showExpanded = newValue
            if expandableView.isHidden == showExpanded {
                UIView.animate(withDuration: 0.2) { [self] in
                    expandedView?.isHidden = !showExpanded
                    expandableView.isHidden = !showExpanded
                }
            }
            expandAction.isSelected = !newValue
        }
    }
    
    convenience init(header: String? = nil, subheader: String? = nil, imageName: String? = nil, systemImageName: String? = nil, title: String? = nil, imageTint: UIColor? = nil, expandedView: UIView? = nil) {
        self.init(frame: .zero)
        self.configure(header: header, subheader: subheader, imageName: imageName, systemImageName: systemImageName, title: title, imageTint: imageTint, expandedView: expandedView)
    }
    
    func configure(header: String?, subheader: String?, imageName: String?, systemImageName: String?, title: String? = nil, imageTint: UIColor? = nil, expandedView: UIView?) {
        if let imageName {
            thumbnail.image = UIImage(named: imageName)
            thumbnail.accessibilityLabel = imageName
        } else if let systemImageName {
            thumbnail.image = UIImage(systemName: systemImageName)
            thumbnail.accessibilityLabel = systemImageName
        }
        
        self.header = header
        self.subheader = subheader
        self.title = title
        self.expandedView = expandedView
        self.imageTint = imageTint
        
        constructCard()
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
            if (thumbnail.superview != nil) {
                thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 0), excludingEdge: .right)
                thumbnail.autoSetDimensions(to: CGSize(width: 24, height: 24))
            }
            titleText.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 32))
            
            errorBadge.autoSetDimensions(to: CGSize(width: 25, height: 25))
            errorBadge.autoPinEdge(toSuperviewEdge: .top)
            errorBadge.autoPinEdge(toSuperviewEdge: .left)
            
            exclamation.contentMode = .scaleAspectFit
            exclamation.autoSetDimensions(to: CGSize(width: 14, height: 14))
            exclamation.autoPinEdge(toSuperviewEdge: .top, withInset: 1)
            exclamation.autoPinEdge(toSuperviewEdge: .left)
            
            if expandedView != nil {
                expandAction.autoSetDimensions(to: CGSize(width: 36, height: 36))
                expandAction.autoPinEdge(toSuperviewEdge: .top, withInset: 8)
                expandAction.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
                expandedView?.autoPinEdgesToSuperviewEdges()
            }
            didSetUpConstraints = true
        }
        super.updateConstraints()
    }
    
    private func constructCard() {
        addSubview(stackView)

        if thumbnail.image != nil {
            titleArea.addSubview(thumbnail)
        }
        
        titleArea.addSubview(titleText)
        
        stackView.addArrangedSubview(titleArea)
        stackView.addArrangedSubview(headerText)
        stackView.setCustomSpacing(4, after: headerText)
        stackView.addArrangedSubview(subhead)

        let spacerView = UIView(forAutoLayout: ())
        spacerView.autoSetDimension(.height, toSize: 8)
        stackView.addArrangedSubview(spacerView)
        
        if let expandedView {
            addSubview(expandAction)
            expandableView.addSubview(expandedView)
            stackView.addArrangedSubview(expandableView)
        }
        
        addSubview(errorBadge)
        errorBadge.isHidden = true
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public func markValid(_ valid: Bool = true) {
        errorBadge.isHidden = valid
    }
}
