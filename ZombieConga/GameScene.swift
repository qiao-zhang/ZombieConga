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
  let zombieRotateRadiansPerSec: CGFloat = tao * 2.0
  var zombieMovingDirection = CGPoint.zero
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

    updateZombie()
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
  private func move(sprite: SKSpriteNode,
                    to location: CGPoint,
                    pointsPerSec: CGFloat) {
    let offset = location - sprite.position
    let distance = (location - sprite.position).length
    let distanceCanMove = pointsPerSec * CGFloat(dt)
    if distance < distanceCanMove {
      sprite.position = location
    } else {
      sprite.position += offset.normalized() * distanceCanMove
    }
  }
  
  private func rotate(sprite: SKSpriteNode,
                      to angle: CGFloat,
                      radiansPerSec: CGFloat) {
    let dAngle = shortestAngleBetween(startAngle: sprite.zRotation,
                                      endAngle: angle)
    let radiansCanRotate = radiansPerSec * CGFloat(dt)
    if abs(dAngle) < radiansCanRotate {
      sprite.zRotation = angle
    } else {
      sprite.zRotation += dAngle.sign * radiansCanRotate
    }
  }
  
  private func updateZombie() {
    rotate(sprite: zombie, to: zombieMovingDirection.angle,
           radiansPerSec: zombieRotateRadiansPerSec)
    moveZombie()
    boundsCheckZombie()
  }
  
  private func moveZombie() {
    guard let target = lastTouchLocation else { return }
    let distance = (target - zombie.position).length
    let distanceCanMove = zombieMovePointsPerSec * CGFloat(dt)
    if distance < distanceCanMove {
      zombie.position = target
    } else {
      zombie.position += zombieMovingDirection * distanceCanMove
    }
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
