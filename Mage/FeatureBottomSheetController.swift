//
//  FeatureBottomSheetController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class FeatureBottomSheetController: UIViewController {
    
    private var didSetUpConstraints = false;
    private var annotation: StaticPointAnnotation?;
    private var featureDetail: String?;
    private var coordinate: CLLocationCoordinate2D?;
    private var featureTitle: String?;
    private var actionsDelegate: FeatureActionsDelegate?;
    var scheme: MDCContainerScheming?;
    
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
//        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0);
        return textView;
    }()
    
    private lazy var featureActionsView: FeatureActionsView = {
        
        if (annotation != nil) {
            let view = FeatureActionsView(location: annotation?.coordinate, title: annotation?.title, featureActionsDelegate: actionsDelegate, scheme: scheme);
            return view;
        } else {
            let view = FeatureActionsView(location: coordinate, title: featureTitle, featureActionsDelegate: actionsDelegate, scheme: scheme);
            return view;
        }
    }()
    
    private lazy var detailsButton: MDCButton = {
        let detailsButton = MDCButton(forAutoLayout: ());
        detailsButton.accessibilityLabel = "More Details";
        detailsButton.setTitle("More Details", for: .normal);
        detailsButton.clipsToBounds = true;
        detailsButton.addTarget(self, action: #selector(detailsButtonTapped), for: .touchUpInside);
        return detailsButton;
    }()
    
    private lazy var detailsButtonView: UIView = {
        let view = UIView();
//        view.addSubview(detailsButton);
//        detailsButton.autoAlignAxis(toSuperviewAxis: .vertical);
//        detailsButton.autoMatch(.width, to: .width, of: view, withMultiplier: 0.9);
        return view;
    }()
    
    private lazy var expandView: UIView = {
        let view = UIView(forAutoLayout: ());
        view.setContentHuggingPriority(.defaultLow, for: .vertical);
        return view;
    }();
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(featureDetail: String, coordinate: CLLocationCoordinate2D, featureTitle: String?, actionsDelegate: FeatureActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.actionsDelegate = actionsDelegate;
        self.featureDetail = featureDetail;
        self.featureTitle = featureTitle;
        self.coordinate = coordinate;
        self.scheme = scheme;
    }
    
    @objc public convenience init(annotation: StaticPointAnnotation, actionsDelegate: FeatureActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.actionsDelegate = actionsDelegate;
        self.annotation = annotation;
        self.scheme = scheme;
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let safeScheme = scheme else {
            return;
        }
        self.view.backgroundColor = safeScheme.colorScheme.surfaceColor;
        textView.textColor = self.scheme?.colorScheme.onSurfaceColor;
        detailsButton.applyContainedTheme(withScheme: safeScheme);
    }
    
    override func viewDidLoad() {
        stackView.addArrangedSubview(dragHandleView);
        stackView.addArrangedSubview(featureActionsView);
        stackView.addArrangedSubview(textView);
        stackView.addArrangedSubview(detailsButtonView);
        scrollView.addSubview(stackView);
        self.view.addSubview(scrollView);
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
        
        view.setNeedsUpdateConstraints();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        textView.attributedText = getAttributedMessage();
//        textView.isScrollEnabled = true;
    }
    
    override func updateViewConstraints() {
        if (!didSetUpConstraints) {
            scrollView.autoPinEdgesToSuperviewEdges();
            stackView.autoPinEdgesToSuperviewEdges();
            stackView.autoMatch(.width, to: .width, of: view);
            didSetUpConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    func getAttributedMessage() -> NSAttributedString {
        if (featureDetail != nil) {
            let data = Data(featureDetail!.utf8);
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                return attributedString
            }
        }
        guard let safeAnnotation = self.annotation else {
            return NSAttributedString(string:"");
        }
        
        let data = Data(safeAnnotation.detailTextForAnnotation().utf8);
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return attributedString
        }
        return NSAttributedString(string: "");
    }
    
    func refresh() {
        textView.attributedText = getAttributedMessage();
    }
    
    @objc func detailsButtonTapped() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.actionsDelegate?.viewUser?(safeUser);
            }
    }
}
