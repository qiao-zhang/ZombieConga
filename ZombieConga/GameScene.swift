//
//  GameScene.swift
//  ZombieConga
//
//  Created by Qiao Zhang on 2/11/17.
//  Copyright © 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  
  let zombie = SKSpriteNode(imageNamed: "zombie1")
  
  override func didMove(to view: SKView) {
//    super.didMove(to: view)
    backgroundColor = SKColor.black
    let background = SKSpriteNode(imageNamed: "background1")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    background.zPosition = -1
    addChild(background)
    
    // add the zombie
    zombie.position = CGPoint(x: 400, y: 400)
    zombie.setScale(2)
    addChild(zombie)
  }
}
