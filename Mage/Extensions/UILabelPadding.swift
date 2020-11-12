//
//  UILabelPadding.swift
//  MAGE
//
//  Created by Daniel Barela on 11/11/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout

class UILabelPadding: UILabel {
    var padding: UIEdgeInsets!
    
    convenience init(padding: UIEdgeInsets) {
        self.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.padding = padding;
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + padding.left + padding.right
        let heigth = superContentSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
}
