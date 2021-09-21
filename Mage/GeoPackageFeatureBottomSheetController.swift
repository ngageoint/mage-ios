//
//  GeoPackageFeatureBottomSheetController.swift
//  MAGE
//
//  Created by Daniel Barela on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class GeoPackageFeatureBottomSheetController: UIViewController {
    
    private var didSetUpConstraints = false;
    private var actionsDelegate: FeatureActionsDelegate?;
    private var featureItems: [GeoPackageFeatureItem] = [];
    var scheme: MDCContainerScheming?;
    private var rightConstraint: NSLayoutConstraint?;
    private var leftConstraint: NSLayoutConstraint?;
    
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
    
    lazy var propertyStack: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        return stackView;
    }()
    
    private lazy var mediaCollection: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150, height: 150)
        layout.scrollDirection = .horizontal
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.dataSource = self;
        collection.autoSetDimension(.height, toSize: 150);
        collection.register(UIImageCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collection.backgroundColor = .clear;
        return collection;
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
    
    @objc public lazy var textView: UITextView = {
        let textView = UITextView();
        textView.isScrollEnabled = false;
        textView.dataDetectorTypes = .all;
        textView.isEditable = false;
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8);
        return textView;
    }()
    
    private lazy var summaryView: GeoPackageFeatureSummaryView = {
        let view = GeoPackageFeatureSummaryView()
        return view;
    }()
    
    private lazy var featureActionsView: FeatureActionsView = {
        let view = FeatureActionsView(location: nil, title: nil, featureActionsDelegate: actionsDelegate, scheme: scheme);
        return view;
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(geoPackageFeatureItem: [GeoPackageFeatureItem], actionsDelegate: FeatureActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        featureItems = geoPackageFeatureItem;
        pageControl.numberOfPages = featureItems.count
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.view.backgroundColor = scheme.colorScheme.surfaceColor;
        textView.textColor = scheme.colorScheme.onSurfaceColor;
        textView.font = scheme.typographyScheme.body1;
        summaryView.applyTheme(withScheme: scheme);
        
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
    
    override func viewDidLoad() {
        if (featureItems.count > 1) {
            stackView.addArrangedSubview(pageControlHolder);
        } else {
            stackView.addArrangedSubview(dragHandleView);
        }
        stackView.addArrangedSubview(summaryView);

        stackView.addArrangedSubview(featureActionsView);
        stackView.addArrangedSubview(mediaCollection);
        stackView.addArrangedSubview(propertyStack);
        scrollView.addSubview(stackView);
        self.view.addSubview(scrollView);
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    
        populateView();
        
        view.setNeedsUpdateConstraints();
    }
    
    func populateView() {
        UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.pageNumberLabel.text = "\(self.pageControl.currentPage+1) of \(self.pageControl.numberOfPages)";
            self.summaryView.populate(item: self.featureItems[self.pageControl.currentPage]);
            self.featureActionsView.populate(location: self.featureItems[self.pageControl.currentPage].coordinate, title: nil, delegate: self.actionsDelegate);
            self.mediaCollection.isHidden = (self.featureItems[self.pageControl.currentPage].mediaRows?.count ?? 0) == 0
            self.mediaCollection.reloadData();
            self.addProperties();
        }, completion: nil);
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.view.setNeedsUpdateConstraints()
    }
    
    func addProperties() {
        for view in self.propertyStack.arrangedSubviews {
            view.removeFromSuperview();
        }
        
        guard let featureRowData = featureItems[pageControl.currentPage].featureRowData else {
            return;
        }
                
        let geometryColumn: String? = featureRowData.geometryColumn()
        if let values = featureRowData.values() as? [String : Any] {
            for (key, value) in values.sorted(by: { $0.0 < $1.0 }) {
                if key != geometryColumn {
                    let keyLabel = UILabel(forAutoLayout: ());
                    keyLabel.text = "\(key)";
                    keyLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
                    if let font = scheme?.typographyScheme.body1 {
                        keyLabel.font = font.withSize(font.pointSize * 0.8);
                    }
                    
                    let valueTextView = UITextView();
                    valueTextView.isScrollEnabled = false;
                    valueTextView.dataDetectorTypes = .all;
                    valueTextView.isEditable = false;
                    valueTextView.textContainerInset = UIEdgeInsets(top: 2, left: -4, bottom: 0, right: 0);
                    if let dataType = featureItems[pageControl.currentPage].featureDataTypes?[key] {
                        let gpkgDataType = GPKGDataTypes.fromName(dataType)
                        if (gpkgDataType == GPKG_DT_BOOLEAN) {
                            valueTextView.text = "\((value as? Int) == 0 ? "true" : "false")"
                        } else if (gpkgDataType == GPKG_DT_DATE) {
                            let dateDisplayFormatter = DateFormatter();
                            dateDisplayFormatter.dateFormat = "yyyy-MM-dd";
                            dateDisplayFormatter.timeZone = TimeZone(secondsFromGMT: 0);

                            if let date = value as? Date {
                                valueTextView.text = "\(dateDisplayFormatter.string(from: date))"
                            }
                        } else if (gpkgDataType == GPKG_DT_DATETIME) {
                            valueTextView.text = "\((value as? NSDate)?.formattedDisplay() ?? value)";
                        } else {
                            valueTextView.text = "\(value)"
                        }
                    } else {
                        valueTextView.text = "\(value)"
                    }
                    valueTextView.textColor = scheme?.colorScheme.onSurfaceColor;
                    valueTextView.font = scheme?.typographyScheme.body1;
                    
                    self.propertyStack.addArrangedSubview(keyLabel);
                    self.propertyStack.addArrangedSubview(valueTextView);
                    self.propertyStack.setCustomSpacing(14, after: valueTextView);
                }
            }
        }
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
}

extension GeoPackageFeatureBottomSheetController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.featureItems[self.pageControl.currentPage].mediaRows?.count ?? 0;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? UIImageCollectionViewCell else {
            fatalError("Could not dequeue an image cell")
        }
        
        if let mediaRow = self.featureItems[self.pageControl.currentPage].mediaRows?[indexPath.row] {
            cell.setupCell(image: mediaRow.dataImage());
        } else {
            cell.setupCell(image: nil);
        }
        return cell;
    }
}
