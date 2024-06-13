import UIKit
import AVKit
import DebugUtilities

extension UIImage {

    public static func getSizeOfImageFile(fileUrl: URL) -> CGSize {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0

        if let imageSource = CGImageSourceCreateWithURL(fileUrl as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {

                if let fileWidth = imageProperties[kCGImagePropertyPixelWidth] as? Int {
                    width = CGFloat(fileWidth)
                }
                if let fileHeight = imageProperties[kCGImagePropertyPixelHeight] as? Int {
                    height = CGFloat(fileHeight)
                }
            }
        }
        return CGSize(width: width, height: height)
    }

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

    public func hasNonTransparentPixelInBounds(minPoint: CGPoint, maxPoint: CGPoint) -> Bool {
        let watch = WatchDog(named: "hasNonTransparentPixelInBounds")
        var pixelData: [UInt8] = [0]
        guard let context = CGContext(data: &pixelData,
                                      width: 1,
                                      height: 1,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 1,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
        else {
            return false
        }
        for y in Int(minPoint.y)...Int(maxPoint.y) {
            for x in Int(minPoint.x)...Int(maxPoint.x) {
                // check if the pixel is not transparent
                UIGraphicsPushContext(context)
                self.draw(at: CGPoint(x: -x, y: -y))
                UIGraphicsPopContext()
                let alpha = Double(pixelData[0]) / 255.0
                let transparent = alpha < 0.01
                if !transparent {
                    return true
                }
            }
        }
        return false
    }
}
