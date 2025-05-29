import CoreGraphics
import UIKit

extension String {
    public func drawWithBasePoint(basePoint: CGPoint,
                           radius: CGFloat,
                           andAngle angle: CGFloat,
                           andAttributes attributes: [NSAttributedString.Key: Any]) {
        let size: CGSize = self.size(withAttributes: attributes)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        let translation: CGAffineTransform = CGAffineTransform(translationX: basePoint.x, y: basePoint.y)
        let rotation: CGAffineTransform = CGAffineTransform(rotationAngle: angle)
        context.concatenate(translation)
        context.concatenate(rotation)
        let rect = CGRect(x: -(size.width / 2), y: radius, width: size.width, height: size.height)
        self.draw(in: rect, withAttributes: attributes)
        context.concatenate(rotation.inverted())
        context.concatenate(translation.inverted())
    }
}
