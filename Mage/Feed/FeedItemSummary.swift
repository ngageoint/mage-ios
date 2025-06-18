//
//  FeedItemSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 6/29/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher

class FeedItemSummary : CommonSummaryView<FeedItem, FeedItemActionsDelegate> {
    private var didSetUpConstraints = false;
    
    private lazy var noContentView: UIView = {
        let view = UIView(forAutoLayout: ());
        let label = UILabel(forAutoLayout: ());
        label.text = "No Content";
        label.font = UIFont.systemFont(ofSize: 32, weight: .regular);
        label.textColor = UIColor.black.withAlphaComponent(0.60);
        view.addSubview(label);
        label.autoAlignAxis(toSuperviewAxis: .horizontal);
        label.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
//        label.autoCenterInSuperview();
        return view;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(imageOverride: UIImage? = nil, hideImage: Bool = false) {
        super.init(imageOverride: imageOverride, hideImage: hideImage);
        isUserInteractionEnabled = false;
        layoutView();
    }
    
    override func populate(item: FeedItem, actionsDelegate: FeedItemActionsDelegate? = nil) {
        let processor = DownsamplingImageProcessor(size: CGSize(width: 40, height: 40))
        itemImage.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0);
        let image = UIImage(named: "observations");
        let iconUrl = item.iconURL;
        itemImage.kf.indicatorType = .activity
        itemImage.kf.setImage(
            with: iconUrl,
            placeholder: image,
            options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            
            switch result {
            case .success(_):
                self.setNeedsLayout()
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
        
        if (!item.hasContent()) {
            noContentView.isHidden = false;
            primaryField.isHidden = true;
            secondaryField.isHidden = true;
            timestamp.isHidden = true;
            return;
        }
        noContentView.isHidden = true;
        primaryField.isHidden = false;
        secondaryField.isHidden = false;
        primaryField.text = item.primaryValue ?? " ";
        secondaryField.text = item.secondaryValue;
        if let itemTemporalProperty = item.feed?.itemTemporalProperty {
            timestamp.text = item.valueForKey(key: itemTemporalProperty)
            timestamp.isHidden = false;
        } else {
            timestamp.isHidden = true;
        }
    }
    
    func layoutView() {
        self.addSubview(noContentView);
        primaryField.numberOfLines = 1;
        primaryField.lineBreakMode = .byTruncatingTail
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            noContentView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
}
