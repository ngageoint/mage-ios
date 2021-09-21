//
//  GeoPackageFeatureBottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 9/20/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

class GeoPackageFeatureBottomSheetView: UIView {
    
    private var didSetUpConstraints = false;
    private var actionsDelegate: FeatureActionsDelegate?;
    private var featureItem: GeoPackageFeatureItem;
    var scheme: MDCContainerScheming?;
    
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
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(geoPackageFeatureItem: GeoPackageFeatureItem, actionsDelegate: FeatureActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        featureItem = geoPackageFeatureItem;
        super.init(frame: CGRect.zero);
        
        self.addSubview(stackView)
        stackView.addArrangedSubview(summaryView);
        
        stackView.addArrangedSubview(featureActionsView);
        stackView.addArrangedSubview(mediaCollection);
        stackView.addArrangedSubview(propertyStack);
        populateView();
        applyTheme(withScheme: self.scheme);
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        textView.textColor = scheme.colorScheme.onSurfaceColor;
        textView.font = scheme.typographyScheme.body1;
        summaryView.applyTheme(withScheme: scheme);
        mediaCollection.backgroundColor = scheme.colorScheme.surfaceColor;
    
        self.scheme = scheme;
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func populateView() {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.summaryView.populate(item: self.featureItem);
            self.featureActionsView.populate(location: self.featureItem.coordinate, title: nil, delegate: self.actionsDelegate);
            self.mediaCollection.isHidden = (self.featureItem.mediaRows?.count ?? 0) == 0
            self.mediaCollection.reloadData();
            self.addProperties();
        }, completion: nil);
    }
    
    func addProperties() {
        for view in self.propertyStack.arrangedSubviews {
            view.removeFromSuperview();
        }
        
        guard let featureRowData = featureItem.featureRowData else {
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
                    if let dataType = featureItem.featureDataTypes?[key] {
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
}

extension GeoPackageFeatureBottomSheetView : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.featureItem.mediaRows?.count ?? 0;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? UIImageCollectionViewCell else {
            fatalError("Could not dequeue an image cell")
        }
        
        if let mediaRow = self.featureItem.mediaRows?[indexPath.row] {
            cell.setupCell(image: mediaRow.dataImage());
        } else {
            cell.setupCell(image: nil);
        }
        return cell;
    }
}

