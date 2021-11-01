//
//  UIImageCollectionViewCell.swift
//  MAGE
//
//  Created by Daniel Barela on 9/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

class UIImageCollectionViewCell: UICollectionViewCell {
    let imageView: UIImageView = UIImageView();
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView);
        imageView.contentMode = .scaleAspectFit;
        imageView.autoPinEdgesToSuperviewEdges();
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell(image: UIImage?) {
        self.imageView.image = image
    }
}
