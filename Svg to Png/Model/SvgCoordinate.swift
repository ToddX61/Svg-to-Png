
// The inspiration for this code came from:
// https://github.com/exyte/Macaw/blob/master/Source/svg/SVGNodeLayout.swift
// Copyright (c) 2016 exyte <info@exyte.com> (MIT)

import Foundation

enum SvgCoordinate {
    case percent(Double)
    case pixels(Double)

    init(percent: Double) {
        self = .percent(percent)
    }

    init(pixels: Double) {
        self = .pixels(pixels)
    }

    func toPixels(total: Double) -> Double {
        switch self {
        case let .percent(percent):
            return total * percent / 100.0
        case let .pixels(pixels):
            return pixels
        }
    }
}

class SvgSize {
    let width: SvgCoordinate
    let height: SvgCoordinate

    public init(width: SvgCoordinate, height: SvgCoordinate) {
        self.width = width
        self.height = height
    }

    func toPixels(total: CGSize) -> CGSize {
        return CGSize(width: width.toPixels(total: Double(total.width)),
                      height: height.toPixels(total: Double(total.height)))
    }
}
