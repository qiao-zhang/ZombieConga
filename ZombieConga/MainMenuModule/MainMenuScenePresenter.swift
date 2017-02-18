//
// Created by Qiao Zhang on 2/18/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import Foundation

class MainMenuScenePresenter: MainMenuSceneOutput {
  unowned let mainMenuScene: MainMenuScene
  
  init(mainMenuScene: MainMenuScene) {
    self.mainMenuScene = mainMenuScene
  }

  func mainMenuSceneTapped() {
    Router.revealGameScene(from: mainMenuScene)
  }

}