//
//  CircleImage.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import UIKit
import StringExtensions

class CircleImage: UIImage {
    // just have this draw the text at an offset fom the middle
    // based on the passed in image or maybe just a passed in size
    convenience init?(imageSize: CGSize, sideText: String, fontSize: CGFloat) {
        var rect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        let labelColor = UIColor.label

        // Color text
        let attributes = [ NSAttributedString.Key.foregroundColor: labelColor,
                           NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]

        let size = sideText.size(withAttributes: attributes)
        // expand the rect on both sides, to maintain the center, to fit the text
        let textWidth = 8 + size.width
        rect = CGRect(x: 0, y: 0, width: imageSize.width + (textWidth * 2), height: rect.size.height)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { _ in
            let center = CGPoint(x: (rect.width / 2.0), y: rect.height / 2.0)

            let textRect = CGRect(
                x: 4 + center.x + imageSize.width / 2,
                y: center.y - size.height / 2,
                width: rect.width,
                height: rect.height)
            sideText.draw(in: textRect, withAttributes: attributes)
        }
        guard  let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    convenience init?(
        color: UIColor,
        radius: CGFloat,
        fill: Bool = false,
        withoutScreenScale: Bool = false,
        arcWidth: CGFloat? = nil
    ) {
        let strokeWidth = arcWidth ?? 0.5
        let rect = CGRect(
            x: 0,
            y: 0,
            width: strokeWidth + radius * 2,
            height: strokeWidth + radius * 2)

        let renderer = {
            if withoutScreenScale {
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                return UIGraphicsImageRenderer(size: rect.size, format: format)
            }
            return UIGraphicsImageRenderer(size: rect.size)
        }()
        let image = renderer.image { _ in
            let circle = UIBezierPath()
            let center = CGPoint(x: (rect.width / 2.0), y: rect.height / 2.0)
            circle.addArc(withCenter: center, radius: radius,
                          startAngle: 0, endAngle: 360 * (CGFloat.pi / 180.0),
                          clockwise: true)
            circle.lineWidth = strokeWidth
            color.setStroke()
            circle.stroke()
            if fill {
                color.setFill()
                circle.fill()
            }
        }

        guard  let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    class func drawOuterBoundary(color: UIColor, diameter: CGFloat, width: CGFloat) {
        color.setStroke()
        let outerBoundary = UIBezierPath(
            ovalIn: CGRect(
                x: width / 2.0,
                y: width / 2.0,
                width: diameter + width,
                height: diameter + width )
        )
        outerBoundary.lineWidth = width / 4.0
        outerBoundary.stroke()
    }

    class func drawSectorPiece(
        sector: ImageSector,
        center: CGPoint,
        radius: CGFloat,
        strokeWidth: CGFloat,
        fill: Bool
    ) {
        let startAngle = CGFloat(sector.startDegrees) * (CGFloat.pi / 180.0)
        let endAngle = CGFloat(sector.endDegrees) * (CGFloat.pi / 180.0)

        let piePath = UIBezierPath()
        piePath.addArc(withCenter: center, radius: radius,
                       startAngle: startAngle, endAngle: endAngle,
                       clockwise: true)

        if fill {
            piePath.addLine(to: CGPoint(x: radius, y: radius))
            piePath.close()
            if sector.obscured {
                UIColor.lightGray.setFill()
            } else {
                sector.color.setFill()
            }
            piePath.fill()

        } else {
            if sector.obscured {
                piePath.setLineDash([3.0, 3.0], count: 2, phase: 0.0)
                piePath.lineWidth = strokeWidth / 2.0
                UIColor.lightGray.setStroke()
            } else {
                piePath.lineWidth = strokeWidth
                sector.color.setStroke()
            }
            piePath.stroke()
        }
    }

    class func drawSectorSeparators(
        sector: ImageSector,
        center: CGPoint,
        sectorDashLength: CGFloat
    ) {
        let dashColor = UIColor.label.withAlphaComponent(0.87)

        let sectorDash = UIBezierPath()
        sectorDash.move(to: center)

        sectorDash.addLine(to: CGPoint(x: center.x + sectorDashLength, y: center.y))
        sectorDash.apply(CGAffineTransform(translationX: -center.x, y: -center.y))
        sectorDash.apply(CGAffineTransform(rotationAngle: CGFloat(sector.startDegrees) * .pi / 180))
        sectorDash.apply(CGAffineTransform(translationX: center.x, y: center.y))

        sectorDash.lineWidth = 0.2
        let  dashes: [ CGFloat ] = [ 2.0, 1.0 ]
        sectorDash.setLineDash(dashes, count: dashes.count, phase: 0.0)
        sectorDash.lineCapStyle = .butt
        dashColor.setStroke()
        sectorDash.stroke()

        let sectorEndDash = UIBezierPath()
        sectorEndDash.move(to: center)

        sectorEndDash.addLine(to: CGPoint(x: center.x + sectorDashLength, y: center.y))
        sectorEndDash.apply(CGAffineTransform(translationX: -center.x, y: -center.y))
        sectorEndDash.apply(CGAffineTransform(rotationAngle: CGFloat(sector.endDegrees) * .pi / 180))
        sectorEndDash.apply(CGAffineTransform(translationX: center.x, y: center.y))

        sectorEndDash.lineWidth = 0.2
        sectorEndDash.setLineDash(dashes, count: dashes.count, phase: 0.0)
        sectorEndDash.lineCapStyle = .butt
        dashColor.setStroke()
        sectorEndDash.stroke()
    }

    class func drawSectorText(
        sector: ImageSector,
        center: CGPoint,
        radius: CGFloat,
        arcWidth: CGFloat?,
        fill: Bool
    ) {
        if let text = sector.text {
            // always use black letters when filled
            let color = fill ? UIColor.black : UIColor.label
            let attributes = [ NSAttributedString.Key.foregroundColor: color,
                               NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: arcWidth ?? 3)]
            let size = text.size(withAttributes: attributes)

            let endDegrees = sector.endDegrees > sector.startDegrees
            ? sector.endDegrees : sector.endDegrees + 360.0
            let midPointAngle = CGFloat(sector.startDegrees) + CGFloat(endDegrees - sector.startDegrees) / 2.0
            var textRadius = radius
            if let arcWidth = arcWidth {
                textRadius -= arcWidth * 1.75
            } else {
                textRadius -= size.height
            }
            text.drawWithBasePoint(
                basePoint: center,
                radius: textRadius,
                andAngle: (midPointAngle - 90) * .pi / 180,
                andAttributes: attributes
            )
        }
    }

    // sector degrees start at 0 at 3 o'clock
    convenience init?(
        suggestedFrame: CGRect,
        sectors: [ImageSector],
        outerStroke: UIColor? = nil,
        radius: CGFloat? = nil,
        fill: Bool = false,
        arcWidth: CGFloat? = nil,
        sectorSeparator: Bool = true
    ) {
        let strokeWidth = arcWidth ?? 2.0
        let outerStrokeWidth = strokeWidth / 4.0
        let rect = suggestedFrame
        let finalRadius = radius ?? min(rect.width / 2.0, rect.height / 2.0) - (outerStrokeWidth)
        let diameter = finalRadius * 2.0
        let sectorDashLength = min(rect.width / 2.0, rect.height / 2.0)

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { _ in
            if let outerStroke = outerStroke {
                CircleImage.drawOuterBoundary(color: outerStroke, diameter: diameter, width: outerStrokeWidth)
            }

            let center = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0)

            for sector in sectors {
                CircleImage.drawSectorPiece(
                    sector: sector,
                    center: center,
                    radius: finalRadius,
                    strokeWidth: strokeWidth,
                    fill: fill
                )

                if sectorSeparator && sector.endDegrees - sector.startDegrees < 360 {
                    CircleImage.drawSectorSeparators(
                        sector: sector,
                        center: center,
                        sectorDashLength: sectorDashLength
                    )
                }

                CircleImage.drawSectorText(
                    sector: sector,
                    center: center,
                    radius: finalRadius,
                    arcWidth: arcWidth,
                    fill: fill
                )
            }
        }

        guard  let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
}

public struct ImageSector: CustomStringConvertible {
    var startDegrees: Double
    var endDegrees: Double
    var color: UIColor
    var text: String?
    var obscured: Bool = false
    var range: Double?

    public var description: String {
        return """
        Sector starting at \(startDegrees - 90.0)\
        , going to \(endDegrees - 90.0) has color\
         \(color) is \(obscured ? "obscured" : "visible")\
         with range of \(range ?? -1)\n
        """
    }
}
