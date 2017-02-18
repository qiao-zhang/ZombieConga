//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import Foundation

class GameOverScenePresenter: GameOverSceneOutput, GameOverInteractorOutput {
  unowned let gameOverScene: GameOverScene
  let gameOverInteractor: GameOverInteractorInput
  
  
  init(gameOverScene: GameOverScene,
       gameOverInteractor: GameOverInteractorInput) {
    self.gameOverScene = gameOverScene
    self.gameOverInteractor = gameOverInteractor
  }
  
  func gameOverSceneDidMoveToView(_ scene: GameOverScene) {
    let result = gameOverInteractor.result
    scene.displayResult(result)
  }
  
  func gameOverSceneDidDisplayResult(_ scene: GameOverScene) {
    gameOverInteractor.startCountDown()
  }

  func newGame() {
    Router.revealGameScene(from: gameOverScene)
  }

}
