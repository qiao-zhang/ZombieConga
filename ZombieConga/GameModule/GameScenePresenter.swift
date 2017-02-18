//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import Foundation

class GameScenePresenter: GameSceneOutput, GameUIOutput {
  unowned let gameScene: GameScene
  let game: Game

  init(gameScene: GameScene, game: Game) {
    self.gameScene = gameScene
    self.game = game
  }

  func zombieBecameInvincible() {
    gameScene.zombieSpriteStartsBlinking()
  }

  func zombieBecameNormal() {
    gameScene.zombieSpriteStopsBlinking()
  }

  func zombieSpriteDidHitEnemySprite() {
    game.zombieDidHitEnemy()
  }

  func zombieSpriteDidHitCatSprite() {
    game.zombieDidCaptureACat()
  }

  func checkGameState() {
    switch game.state {
    case .won:
      gameScene.wrapUp(wonOrNot: true)
    case .lost:
      gameScene.wrapUp(wonOrNot: false)
    default:
      break
    }
  }

  func didWrapUp(wonOrNot: Bool) {
    Router.revealGameOverScene(from: gameScene, wonOrNot: wonOrNot)
  }
}
