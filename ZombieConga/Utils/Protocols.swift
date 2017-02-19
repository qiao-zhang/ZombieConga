//
// Created by Qiao Zhang on 2/18/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit.SKScene

protocol MyScene: class {
  var scene: SKScene { get }
}

extension MyScene where Self: SKScene {
  var scene: SKScene {
    return self as SKScene
  }
}