import UIKit
import SwiftUI

//@MainActor
public protocol DataSourceDefinition: ObservableObject {
    var mappable: Bool { get }
    var color: UIColor { get }
    var imageName: String? { get }
    var systemImageName: String? { get }
    var image: UIImage? { get }
    var key: String { get }
    var name: String { get }
    var fullName: String { get }
    var imageScale: CGFloat { get }
}

public extension DataSourceDefinition {
    var imageScale: CGFloat {
        1.0
    }

    var image: UIImage? {
        if let imageName = imageName {
            return UIImage(named: imageName)
        } else if let systemImageName = systemImageName {
            return UIImage(systemName: systemImageName)
        }
        return nil
    }
}
