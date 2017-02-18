//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import Foundation

protocol GameUIOutput: class {
  func zombieBecameInvincible()
  func zombieBecameNormal()
}

protocol Game {
  var state: GameState { get }
  func zombieDidHitEnemy()
  func zombieDidCaptureACat()
}

enum GameState {
  case playing
  case won
  case lost
}

class GameImp: Game {

  weak var uiOutput: GameUIOutput?
  var lives = 5
  var zombieInvincible = false {
    didSet {
      if zombieInvincible {
        uiOutput?.zombieBecameInvincible()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
          [weak self] in
          self?.zombieInvincible = false
          self?.uiOutput?.zombieBecameNormal()
        }
      }
    }
  }
  var capturedCatsNum = 0
  private(set) var state: GameState = .playing

  func zombieDidHitEnemy() {
    lives -= 1
    loseCats(by: 2)
    zombieInvincible = true
    if lives <= 0 { state = .lost }
  }

  func zombieDidCaptureACat() {
    capturedCatsNum += 1
    if capturedCatsNum >= 15 { state = .won}
  }

  private func loseCats(by num: Int) {
    capturedCatsNum -= num
    if capturedCatsNum <= 0 { capturedCatsNum = 0 }
  }
}
