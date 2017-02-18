//
// Created by Qiao Zhang on 2/18/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit

protocol MainMenuSceneOutput {
  func mainMenuSceneTapped()
}

protocol MainMenuScene: class {
  var scene: SKScene { get }
  var output: MainMenuSceneOutput? { get set}
}

class MainMenuSceneImp: SKScene, MainMenuScene {
  var output: MainMenuSceneOutput?
  override var scene: SKScene {
    return self as SKScene
  }

  override func didMove(to view: SKView) {
    super.didMove(to: view)
    // show background
    let background = SKSpriteNode(imageNamed: "MainMenu.png")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    background.zPosition = -1
    addChild(background)
  }

  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    guard let _ = touches.first else { return }
    sceneTapped()
  }
  
  private func sceneTapped() {
    output?.mainMenuSceneTapped()
  }
}