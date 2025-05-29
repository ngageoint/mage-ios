//
//  UIColorExtensions.swift
//  Marlin
//
//  Created by Daniel Barela on 7/18/22.
//

import Foundation
import UIKit

public extension UIColor {
    convenience init(rgbValue: Int) {
        self.init(
            red: CGFloat((Float((rgbValue & 0xff0000) >> 16)) / 255.0),
            green: CGFloat((Float((rgbValue & 0x00ff00) >> 8)) / 255.0),
            blue: CGFloat((Float((rgbValue & 0x0000ff) >> 0)) / 255.0),
            alpha: 1.0)
    }

    convenience init(argbValue: Int) {
        self.init(
            red: CGFloat((Float((argbValue & 0x00ff0000) >> 16)) / 255.0),
            green: CGFloat((Float((argbValue & 0x0000ff00) >> 8)) / 255.0),
            blue: CGFloat((Float((argbValue & 0x000000ff) >> 0)) / 255.0),
            alpha: CGFloat((Float((argbValue & 0xff000000) >> 24)) / 255.0))
    }

    var redComponent: CGFloat {
        var red: CGFloat = 0.0
        getRed(&red, green: nil, blue: nil, alpha: nil)

        return red
    }

    var greenComponent: CGFloat {
        var green: CGFloat = 0.0
        getRed(nil, green: &green, blue: nil, alpha: nil)

        return green
    }

    var blueComponent: CGFloat {
        var blue: CGFloat = 0.0
        getRed(nil, green: nil, blue: &blue, alpha: nil)

        return blue
    }

    var alphaComponent: CGFloat {
        var alpha: CGFloat = 0.0
        getRed(nil, green: nil, blue: nil, alpha: &alpha)

        return alpha
    }
}
