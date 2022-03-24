//
//  UIImageCollectionViewCell.swift
//  MAGE
//
//  Created by Daniel Barela on 9/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import MaterialComponents

class UIImageCollectionViewCell: UICollectionViewCell {
    let imageView: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        return titleLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        self.addSubview(titleLabel)
        titleLabel.autoPinEdge(toSuperviewEdge: .top)
        titleLabel.autoSetDimension(.height, toSize: 16)
        imageView.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 4)
        titleLabel.autoMatch(.width, to: .width, of: imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell(image: UIImage?, title: String?, scheme: MDCContainerScheming?) {
        imageView.image = image
        titleLabel.text = title
        if let scheme = scheme {
            titleLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            let smallFont = scheme.typographyScheme.body1.withSize(scheme.typographyScheme.body1.pointSize * 0.8)
            titleLabel.font = smallFont
            imageView.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.13)
        }
    }
}
