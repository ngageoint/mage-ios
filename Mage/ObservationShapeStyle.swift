//
//  ObservationShapeStyle.m
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

@objc class ObservationShapeStyle: NSObject {
    @objc var lineWidth: CGFloat = 1.0
    @objc var strokeColor: UIColor?
    @objc var fillColor: UIColor?
    
    override init() {
        super.init()
        setLineWidth(lineWidth: CGFloat(UserDefaults.standard.float(forKey: "fill_default_line_width")))
        
        if let defaultLineColor = UserDefaults.standard.string(forKey: "line_default_color") {
            strokeColor = UIColor(hex: defaultLineColor)?.withAlphaComponent(CGFloat(UserDefaults.standard.float(forKey: "line_default_color_alpha") / 255.0))
        }
        
        if let defaultFillColor = UserDefaults.standard.string(forKey: "fill_default_color") {
            fillColor = UIColor(hex: defaultFillColor)?.withAlphaComponent(CGFloat(UserDefaults.standard.float(forKey: "fill_default_color_alpha") / 255.0))
        }
    }
    
    func setLineWidth(lineWidth: CGFloat) {
        self.lineWidth = lineWidth / UIScreen.main.scale
    }
}
