import UIKit
import AVKit

extension UIImage {

    public func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    public func aspectResize(to size: CGSize) -> UIImage {
        let scaledRect = AVMakeRect(
            aspectRatio: self.size,
            insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height)
        )
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: scaledRect)
        }
    }

    public func aspectResizeJpeg(to size: CGSize) -> Data? {
        let scaledRect = AVMakeRect(
            aspectRatio: self.size,
            insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height)
        )
        return UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 1.0) { _ in

            draw(in: scaledRect)
        }
    }

    public func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }

    public func combineCentered(image1: UIImage?, image2: UIImage?) -> UIImage? {
        guard let image1 = image1 else {
            return image2
        }
        guard let image2 = image2 else {
            return image1
        }
        let maxSize = CGSize(width: max(image1.size.width, image2.size.width),
                             height: max(image1.size.height, image2.size.height))
        UIGraphicsBeginImageContextWithOptions(maxSize, false, image1.scale)
        _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(
            x: (maxSize.width - image1.size.width) / 2.0,
            y: (maxSize.height - image1.size.height) / 2.0
        )
        image1.draw(at: origin)
        let origin2 = CGPoint(
            x: (maxSize.width - image2.size.width) / 2.0,
            y: (maxSize.height - image2.size.height) / 2.0
        )
        image2.draw(at: origin2)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }

    public func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)

        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}

