//
// Created by Qiao Zhang on 2/15/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import Foundation
import CoreGraphics

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
  left = left + right
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func -= (left: inout CGPoint, right: CGPoint) {
  left = left - right
}

func * (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

func *= (left: inout CGPoint, right: CGPoint) {
  left = left * right
}

func * (vector2: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: vector2.x * scalar, y: vector2.y * scalar)
}

func *= (vector2: inout CGPoint, scalar: CGFloat) {
  vector2 = vector2 * scalar
}

func / (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x / right.x, y: left.y / right.y)
}

func /= (left: inout CGPoint, right: CGPoint) {
  left = left / right
}

func / (vector2: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: vector2.x / scalar, y: vector2.y / scalar)
}

func /= (vector2: inout CGPoint, scalar: CGFloat) {
  vector2 = vector2 / scalar
}

#if !(arch(x86_64) || arch(arm64))
func atan2(y: CGFloat, x: CGFloat) -> CGFloat {
  return CGFloat(atan2f(Float(y), Float(x)))
}

func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
  var length: CGFloat {
    return sqrt(x*x + y*y)
  }

  var angle: CGFloat {
    return atan2(y, x)
  }

  func normalized() -> CGPoint {
    return self / length
  }
}
