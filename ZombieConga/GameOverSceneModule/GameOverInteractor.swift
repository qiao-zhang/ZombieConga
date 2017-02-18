//
// Created by Qiao Zhang on 2/17/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import Foundation

protocol GameOverInteractorOutput: class {
  func newGame()
}

protocol GameOverInteractorInput {
  var result: Bool { get }
  func startCountDown()
}

class GameOverInteractor: GameOverInteractorInput {
  weak var uiOutput: GameOverInteractorOutput?
  private let won: Bool
  init(won: Bool) { self.won = won }
  
  var result: Bool {
    return won
  }
  
  func startCountDown() {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
      [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.uiOutput?.newGame()
    }
  }

}