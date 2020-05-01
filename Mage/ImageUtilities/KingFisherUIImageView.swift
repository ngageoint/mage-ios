//
//  KingFisherUIImageView.swift
//  MAGE
// This class is just to be used as a bridge to Swift until we can migrate to all Swift
//
//  Created by Daniel Barela on 4/20/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class KingFisherUIImageView: UIImageView {
    var imageSize: Int!

    override init(image: UIImage?) {
        super.init(image: image)
        self.imageSize = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageSize = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.imageSize = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
    }
    
    @objc override func setImageWith(_ url: URL) {
        self.kf.setImage(with: url);
    }
}

