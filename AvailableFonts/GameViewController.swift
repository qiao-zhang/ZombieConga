//
//  GameViewController.swift
//  AvailableFonts
//
//  Created by Qiao Zhang on 2/19/17.
//  Copyright © 2017 Qiao Zhang. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    let skView = self.view as! SKView
    skView.showsFPS = true
    skView.showsNodeCount = true
    skView.ignoresSiblingOrder = true
    let scene = GameScene(size: CGSize(width: 2048, height: 1536))
    scene.scaleMode = .aspectFill
    skView.presentScene(scene)
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }
}
