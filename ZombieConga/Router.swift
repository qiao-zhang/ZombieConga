//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit
import CoreGraphics

class Router {
  static func createGameSceneWhenAppStarts() -> GameScene {
    let gameScene = GameScene(size: CGSize(width: 2048, height: 1536))
    wireUp(gameScene: gameScene)
    return gameScene
  }
  
  static func revealGameScene(from scene: SKScene) {
    let gameScene = GameScene(size: scene.size)
    gameScene.scaleMode = scene.scaleMode
    wireUp(gameScene: gameScene)
    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
    scene.view?.presentScene(gameScene, transition: reveal)
  }
  
  static func wireUp(gameScene: GameScene) {
    let game = GameImp()
    let presenter = GameScenePresenter(gameScene: gameScene,
                                       game: game)
    gameScene.output = presenter
    game.uiOutput = presenter
  }
  
  static func revealGameOverScene(from scene: GameScene, wonOrNot: Bool) {
    let gameOverScene = GameOverScene(size: scene.size)
    gameOverScene.scaleMode = scene.scaleMode
    let interactor = GameOverInteractor(won: wonOrNot)
    let presenter = GameOverScenePresenter(gameOverScene: gameOverScene,
                                           gameOverInteractor: interactor)
    gameOverScene.output = presenter
    interactor.uiOutput = presenter
    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
    scene.view?.presentScene(gameOverScene, transition: reveal)
  }
}