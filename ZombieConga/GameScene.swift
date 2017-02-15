//
//  GameScene.swift
//  ZombieConga
//
//  Created by Qiao Zhang on 2/11/17.
//  Copyright © 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit
import UIKit

class GameScene: SKScene {
  
  let playableRect: CGRect
  let zombie = SKSpriteNode(imageNamed: "zombie1")
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  let zombieMovePointsPerSec: CGFloat = 480.0
  var zombieMovingDirection = CGPoint.zero
  var zombieVelocity: CGPoint {
    return zombieMovingDirection * zombieMovePointsPerSec
  }
  var lastTouchLocation: CGPoint? = nil

  override init(size: CGSize) {
    let maxWidthHeightRatio: CGFloat = 16.0 / 9.0
    let playableHeight = size.width / maxWidthHeightRatio
    let playableMargin = (size.height - playableHeight) / 2.0
    playableRect = CGRect(x: 0, y: playableMargin,
                          width: size.width, height: playableHeight)
    super.init(size: size)
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("`init(coder:)` has not been implemented")
  }

  override func didMove(to view: SKView) {
//    super.didMove(to: view)
    backgroundColor = SKColor.black
    let background = SKSpriteNode(imageNamed: "background1")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    background.zPosition = -1
    addChild(background)
    
    // add the zombie
    zombie.position = CGPoint(x: 400, y: 400)
    addChild(zombie)
    
    debugDrawPlayableArea()
  }

  override func update(_ currentTime: TimeInterval) {
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime

    updateZombie(with: dt)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>,
                             with event: UIEvent!) {
    guard let touch = touches.first else { return }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  // Helper functions
  private func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = velocity * CGFloat(dt)
    print("Amount to move: \(amountToMove)")
    sprite.position += amountToMove
  }
  
  private func rotate(sprite: SKSpriteNode, direction: CGPoint) {
    sprite.zRotation = direction.angle
  }
  
  private func updateZombie(with dt: TimeInterval) {
    guard let target = lastTouchLocation else { return }
    
    let distance = (target - zombie.position).length
    if distance <= zombieMovePointsPerSec * CGFloat(dt) {
      zombie.position = target
      zombieMovingDirection = CGPoint.zero
    } else {
      rotate(sprite: zombie, direction: zombieMovingDirection)
      move(sprite: zombie, velocity: zombieVelocity)
    }
    boundsCheckZombie()
  }
  
  private func setZombieMovingDirection(towards location: CGPoint) {
    let offset = location - zombie.position
    zombieMovingDirection = offset.normalized()
  }
  
  private func sceneTouched(touchLocation: CGPoint) {
    setZombieMovingDirection(towards: touchLocation)
    lastTouchLocation = touchLocation
  }
  
  private func boundsCheckZombie() {
    let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
    let topRight = CGPoint(x: size.width, y: playableRect.maxY)
    
    if zombie.position.x <= bottomLeft.x {
      zombie.position.x = bottomLeft.x
      zombieMovingDirection.x = -zombieMovingDirection.x
    }
    if zombie.position.x >= topRight.x {
      zombie.position.x = topRight.x
      zombieMovingDirection.x = -zombieMovingDirection.x
    }
    if zombie.position.y <= bottomLeft.y {
      zombie.position.y = bottomLeft.y
      zombieMovingDirection.y = -zombieMovingDirection.y
    }
    if zombie.position.y >= topRight.y {
      zombie.position.y = topRight.y
      zombieMovingDirection.y = -zombieMovingDirection.y
    }
  }
  
  private func debugDrawPlayableArea() {
    let shape = SKShapeNode()
    let path = CGMutablePath()
    path.addRect(playableRect)
    shape.path = path
    shape.strokeColor = SKColor.red
    shape.lineWidth = 4.0
    addChild(shape)
  }
}
