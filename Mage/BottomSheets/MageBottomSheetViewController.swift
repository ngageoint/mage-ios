//
//  MageBottomSheetViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 9/20/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc protocol BottomSheetDelegate {
    @objc optional func bottomSheetItemShowing(_ item: BottomSheetItem);
}

@objc class BottomSheetItem: NSObject {
    @objc public var item: Any
    @objc public var annotationView: MKAnnotationView?
    @objc public var actionDelegate: Any?
    
    @objc public init(item: Any, actionDelegate: Any? = nil, annotationView: MKAnnotationView? = nil) {
        self.item = item;
        self.actionDelegate = actionDelegate;
        self.annotationView = annotationView;
    }
}

@objc class MageBottomSheetViewController: UIViewController {
    
    private var didSetUpConstraints = false;
    private var items: [BottomSheetItem] = [];
    var scheme: MDCContainerScheming?;
    private var rightConstraint: NSLayoutConstraint?;
    private var leftConstraint: NSLayoutConstraint?;
    var currentBottomSheetView: BottomSheetView?
    private var bottomSheetDelegate: BottomSheetDelegate?
    
    @objc public lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.newAutoLayout();
        scrollView.accessibilityIdentifier = "feature bottom sheet";
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        return scrollView;
    }()
    
    private lazy var stackView: PassThroughStackView = {
        let stackView = PassThroughStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill;
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl();
        pageControl.currentPage = 0;
        pageControl.hidesForSinglePage = true;
        pageControl.addTarget(self, action: #selector(pageControlChangedValue), for: .valueChanged)
        return pageControl;
    }()
    
    private lazy var pageNumberLabel: UILabel = {
        let pageNumberLabel = UILabel();
        pageNumberLabel.textAlignment = .center;
        return pageNumberLabel;
    }()
    
    private lazy var pageControlHolder: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(pageNumberLabel);
        view.addSubview(leftButton);
        view.addSubview(pageControl);
        view.addSubview(rightButton);
        
        leftButton.autoPinEdge(.right, to: .left, of: pageControl);
        leftButton.autoPinEdge(toSuperviewEdge: .bottom);
        leftButton.autoPinEdge(toSuperviewEdge: .top, withInset: 7);
        pageControl.autoAlignAxis(toSuperviewAxis: .vertical);
        pageControl.autoAlignAxis(.horizontal, toSameAxisOf: leftButton);
        rightButton.autoPinEdge(.left, to: .right, of: pageControl);
        rightButton.autoPinEdge(toSuperviewEdge: .bottom);
        rightButton.autoPinEdge(toSuperviewEdge: .top, withInset: 7);
        
        pageNumberLabel.autoAlignAxis(.vertical, toSameAxisOf: pageControl);
        pageControl.autoPinEdge(.top, to: .bottom, of: pageNumberLabel, withOffset: -4);
        
        return view;
    }()
    
    private lazy var leftButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = "previous_feature";
        button.setImage(UIImage(named: "navigate_before")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 40, height: 40));
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        button.addTarget(self, action: #selector(leftButtonTap), for: .touchUpInside);
        return button;
    }()
    
    private lazy var rightButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = "next_feature";
        button.setImage(UIImage(named: "navigate_next")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 40, height: 40));
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        button.addTarget(self, action: #selector(rightButtonTap), for: .touchUpInside);
        return button;
    }()
    
    private lazy var dragHandleView: UIView = {
        let drag = UIView(forAutoLayout: ());
        drag.autoSetDimensions(to: CGSize(width: 50, height: 7));
        drag.clipsToBounds = true;
        drag.backgroundColor = .black.withAlphaComponent(0.37);
        drag.layer.cornerRadius = 3.5;
        
        let view = UIView(forAutoLayout: ());
        view.addSubview(drag);
        drag.autoAlignAxis(toSuperviewAxis: .vertical);
        drag.autoPinEdge(toSuperviewEdge: .bottom);
        drag.autoPinEdge(toSuperviewEdge: .top, withInset: 7);
        return view;
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(items: [BottomSheetItem], scheme: MDCContainerScheming?, bottomSheetDelegate: BottomSheetDelegate? = nil) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.items = items;
        self.bottomSheetDelegate = bottomSheetDelegate;
        pageControl.numberOfPages = items.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (items.count > 1) {
            stackView.addArrangedSubview(pageControlHolder);
        } else {
            stackView.addArrangedSubview(dragHandleView);
        }
        
        scrollView.addSubview(stackView);
        self.view.addSubview(scrollView);
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
        
        populateView();
        
        view.setNeedsUpdateConstraints();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.view.backgroundColor = scheme.colorScheme.surfaceColor;
        
        leftButton.applyTextTheme(withScheme: scheme);
        leftButton.tintColor = scheme.colorScheme.primaryColor;
        rightButton.applyTextTheme(withScheme: scheme);
        rightButton.tintColor = scheme.colorScheme.primaryColor;
        
        pageControl.pageIndicatorTintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        pageControl.currentPageIndicatorTintColor = scheme.colorScheme.primaryColor;
        pageNumberLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        pageNumberLabel.font = scheme.typographyScheme.caption;
        self.scheme = scheme;
    }
    
    @objc func leftButtonTap() {
        // allow MDCButton ink ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.pageControl.currentPage = self.pageControl.currentPage - 1
            self.populateView()
        }
    }
    
    @objc func rightButtonTap() {
        // allow MDCButton ink ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.pageControl.currentPage = self.pageControl.currentPage + 1
            self.populateView()
        }
    }
    
    @objc func pageControlChangedValue() {
        self.populateView()
    }
    
    override func updateViewConstraints() {
        if (!didSetUpConstraints) {
            scrollView.autoPinEdge(toSuperviewEdge: .top);
            scrollView.autoPinEdge(toSuperviewEdge: .bottom);
            
            stackView.autoPinEdgesToSuperviewEdges();
            stackView.autoMatch(.width, to: .width, of: scrollView);
            didSetUpConstraints = true;
        }
        
        leftConstraint?.autoRemove();
        rightConstraint?.autoRemove();
        if (self.traitCollection.horizontalSizeClass == .regular) {
            leftConstraint = scrollView.autoPinEdge(toSuperviewMargin: .left);
            rightConstraint = scrollView.autoPinEdge(toSuperviewMargin: .right);
        } else {
            leftConstraint = scrollView.autoPinEdge(toSuperviewEdge: .left);
            rightConstraint = scrollView.autoPinEdge(toSuperviewEdge: .right);
        }
        
        super.updateViewConstraints();
    }
    
    func populateView() {
        UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            if self.currentBottomSheetView?.superview != nil {
                self.currentBottomSheetView?.removeFromSuperview();
            }
            self.pageNumberLabel.text = "\(self.pageControl.currentPage+1) of \(self.pageControl.numberOfPages)";
            
            let item = self.items[self.pageControl.currentPage];
            if let bottomSheetItem = item.item as? GeoPackageFeatureItem {
                self.currentBottomSheetView = GeoPackageFeatureBottomSheetView(geoPackageFeatureItem: bottomSheetItem, actionsDelegate: item.actionDelegate as? FeatureActionsDelegate, scheme: self.scheme);
                self.stackView.addArrangedSubview(self.currentBottomSheetView!);
            } else if let bottomSheetItem = item.item as? Observation {
                self.currentBottomSheetView = ObservationBottomSheetView(observation: bottomSheetItem, actionsDelegate: item.actionDelegate as? ObservationActionsDelegate, scheme: self.scheme);
                self.stackView.addArrangedSubview(self.currentBottomSheetView!);
            } else if let bottomSheetItem = item.item as? User {
                self.currentBottomSheetView = UserBottomSheetView(user: bottomSheetItem, actionsDelegate: item.actionDelegate as? UserActionsDelegate, scheme: self.scheme);
                self.stackView.addArrangedSubview(self.currentBottomSheetView!);
            } else if let bottomSheetItem = item.item as? FeatureItem {
                self.currentBottomSheetView = FeatureBottomSheetView(featureItem: bottomSheetItem, actionsDelegate: item.actionDelegate as? FeatureActionsDelegate, scheme: self.scheme);
                self.stackView.addArrangedSubview(self.currentBottomSheetView!);
            }
            self.stackView.arrangedSubviews[0].backgroundColor = self.currentBottomSheetView?.getHeaderColor();
            self.view.setNeedsUpdateConstraints();
            self.bottomSheetDelegate?.bottomSheetItemShowing?(item)
        }, completion: nil);
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.view.setNeedsUpdateConstraints()
    }
}
