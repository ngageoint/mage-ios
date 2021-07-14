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

class FeedItemSummary : CommonSummaryView<FeedItem> {
    private var didSetUpConstraints = false;
    
    private lazy var noContentView: UIView = {
        let view = UIView(forAutoLayout: ());
        let label = UILabel(forAutoLayout: ());
        label.text = "No Content";
        label.font = UIFont.systemFont(ofSize: 32, weight: .regular);
        label.textColor = UIColor.black.withAlphaComponent(0.60);
        view.addSubview(label);
        label.autoCenterInSuperview();
        return view;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(imageOverride: UIImage? = nil) {
        super.init(imageOverride: imageOverride);
        isUserInteractionEnabled = false;
        layoutView();
    }
    
    @objc public func populate(feedItem: FeedItem) {
        let processor = DownsamplingImageProcessor(size: CGSize(width: 40, height: 40))
        itemImage.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0);
        let image = UIImage(named: "observations");
        let iconUrl = feedItem.iconURL;
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
        
        if (!feedItem.hasContent()) {
            noContentView.isHidden = false;
            return;
        }
        noContentView.isHidden = true;
        primaryField.text = feedItem.primaryValue ?? " ";
        secondaryField.text = feedItem.secondaryValue;
        if (feedItem.feed?.itemTemporalProperty == nil) {
            timestamp.isHidden = true;
        } else {
            if let itemDate: NSDate = feedItem.timestamp as NSDate? {
                timestamp.text = itemDate.formattedDisplay();
            } else {
                timestamp.text = " ";
            }
            timestamp.isHidden = false;
        }
    }
    
    func layoutView() {
        self.addSubview(noContentView);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            noContentView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
}
