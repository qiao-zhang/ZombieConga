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
      gameScene.gameOver(wonOrNot: true)
    case .lost:
      gameScene.gameOver(wonOrNot: false)
    default:
      break
    }
  }

//if lives <= 0 && !gameOver {
//  gameOver = true
//  print("You lose!")
//  let gameOverScene = GameOverScene(size: size)
//  gameOverScene.scaleMode = scaleMode
//
//  let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
//
//  view?.presentScene(gameOverScene, transition: reveal)
//}
}