//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit
import CoreGraphics

class Router {
  
  static var initialScene: SKScene {
    return createMainMenuSceneAsInitialScene()
  }
  
  static func createMainMenuSceneAsInitialScene() -> SKScene {
    let mainMenuScene = MainMenuSceneImp(size: CGSize(width: 2048,
                                                      height: 1536))
    wireUp(mainMenuScene)
    return mainMenuScene.scene
  }
  
  static func createGameSceneWhenAppStarts() -> SKScene {
    let gameScene = GameSceneImp(size: CGSize(width: 2048, height: 1536))
    wireUp(gameScene)
    return gameScene.scene
  }
  
  static func revealGameScene(from myScene: MyScene) {
    let gameScene = GameSceneImp(size: myScene.scene.size)
    gameScene.scaleMode = myScene.scene.scaleMode
    wireUp(gameScene)
    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
    myScene.scene.view?.presentScene(gameScene, transition: reveal)
  }

  static func wireUp(_ mainMenuScene: MainMenuScene) {
    let presenter = MainMenuScenePresenter(
      mainMenuScene: mainMenuScene)
    mainMenuScene.output = presenter
  }
  
  static func wireUp(_ gameScene: GameScene) {
    let game = GameImp()
    let presenter = GameScenePresenter(
      gameScene: gameScene, game: game)
    gameScene.output = presenter
    game.uiOutput = presenter
  }
  
  
  static func revealGameOverScene(from myScene: MyScene, wonOrNot: Bool) {
    let gameOverScene = GameOverScene(size: myScene.scene.size)
    gameOverScene.scaleMode = myScene.scene.scaleMode
    let interactor = GameOverInteractor(won: wonOrNot)
    let presenter = GameOverScenePresenter(gameOverScene: gameOverScene,
                                           gameOverInteractor: interactor)
    gameOverScene.output = presenter
    interactor.uiOutput = presenter
    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
    myScene.scene.view?.presentScene(gameOverScene, transition: reveal)
  }
}
