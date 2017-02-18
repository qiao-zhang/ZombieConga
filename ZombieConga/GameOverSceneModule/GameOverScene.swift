//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit

protocol GameOverSceneOutput {
  func gameOverSceneDidMoveToView(_ scene: GameOverScene)
  func gameOverSceneDidDisplayResult(_ scene: GameOverScene)
}

protocol GameOverSceneInput: class {
  func displayResult(_ wonOrNot: Bool)
}

class GameOverScene: SKScene, GameOverSceneInput {
  var output: GameOverSceneOutput?
  
  override func didMove(to view: SKView) {
    output?.gameOverSceneDidMoveToView(self)
  }
  
  func displayResult(_ wonOrNot: Bool) {
    let (imageName, soundFileName) =
        wonOrNot ? ("YouWin", "win.wav") : ("YouLose", "lose.wav")
    let background = SKSpriteNode(imageNamed: imageName)
    let sound = SKAction.playSoundFileNamed(soundFileName,
                                            waitForCompletion: false)
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(background)
    run(sound)
    output?.gameOverSceneDidDisplayResult(self)
  }
}
