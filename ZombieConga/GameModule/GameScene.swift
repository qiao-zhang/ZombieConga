//
//  GameScene.swift
//  ZombieConga
//
//  Created by Qiao Zhang on 2/11/17.
//  Copyright © 2017 Qiao Zhang. All rights reserved.
//

import SpriteKit
import UIKit

protocol GameSceneOutput {
  func zombieSpriteDidHitEnemySprite()
  func zombieSpriteDidHitCatSprite()
  func checkGameState()
}

protocol GameSceneInput: class {
  func zombieSpriteStartsBlinking()
  func zombieSpriteStopsBlinking()
  func gameOver(wonOrNot: Bool)
}

class GameScene: SKScene, GameSceneInput {
  
  var output: GameSceneOutput?
  
  let playableRect: CGRect
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  var lastTouchLocation: CGPoint? = nil

  let zombieSprite = SKSpriteNode(imageNamed: "zombie1")
  let zombieSpriteMovePointsPerSec: CGFloat = 480.0
  let zombieSpriteRotateRadiansPerSec: CGFloat = tao * 2.0
  var zombieSpriteMovingDirection = CGPoint.zero
  let zombieSpriteWalkingAnimation: SKAction
  
  let zombieSpriteBlinkAction: SKAction = {
    let oneBlinkDuration: TimeInterval = 0.3
    let oneBlink = SKAction.customAction(withDuration: oneBlinkDuration) {
      node, elapsedTime in
      node.isHidden = (elapsedTime > CGFloat(oneBlinkDuration / 2))
    }
    return SKAction.repeatForever(oneBlink)
  }()

  var catSpriteMovePointsPerSec: CGFloat {
    return zombieSpriteMovePointsPerSec
  }
  let catSpriteTurningGreenAction: SKAction = {
    let duration = 0.2
    let action = SKAction.colorize(with: UIColor.green,
                                   colorBlendFactor: 1,
                                   duration: duration)
    return action
  }()
  
  let catSpriteCollisionSound: SKAction = SKAction.playSoundFileNamed(
      "hitCat.wav", waitForCompletion: false)
  let enemySpriteCollisionSound: SKAction = SKAction.playSoundFileNamed(
      "hitCatLady.wav", waitForCompletion: false)

  override init(size: CGSize) {
    let maxWidthHeightRatio: CGFloat = 16.0 / 9.0
    let playableHeight = size.width / maxWidthHeightRatio
    let playableMargin = (size.height - playableHeight) / 2.0
    playableRect = CGRect(x: 0, y: playableMargin,
                          width: size.width, height: playableHeight)
    var textures: [SKTexture] = []
    for i in 1...4 {
      textures.append(SKTexture(imageNamed: "zombie\(i)"))
    }
    textures.append(textures[2])
    textures.append(textures[1])
    zombieSpriteWalkingAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
    super.init(size: size)
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("`init(coder:)` has not been implemented")
  }

  override func didMove(to view: SKView) {
    // add background
    backgroundColor = SKColor.black
    let background = SKSpriteNode(imageNamed: "background1")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    background.zPosition = -1
    addChild(background)
    
    // add zombie sprite
    zombieSprite.position = CGPoint(x: 400, y: 400)
    zombieSprite.zPosition = 100
    addChild(zombieSprite)
    
    // spawn enemy sprites
    run(SKAction.repeatForever(SKAction.sequence([
        SKAction.run { [weak self] in
        self?.spawnEnemySprite()
        },
        SKAction.wait(forDuration: 2.0)
    ])))
    run(SKAction.repeatForever(SKAction.sequence([
        SKAction.run { [weak self] in
          self?.spawnCatSprite()
        },
        SKAction.wait(forDuration: 1.0)
    ])))
    
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
    moveTrain()
  }
  
  override func didEvaluateActions() {
    checkCollisions()
    output?.checkGameState()
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

  func zombieSpriteStartsBlinking() {
    zombieSprite.run(zombieSpriteBlinkAction, withKey: "blink")
  }

  func zombieSpriteStopsBlinking() {
    zombieSprite.removeAction(forKey: "blink")
    zombieSprite.isHidden = false
  }

  func gameOver(wonOrNot: Bool) {
    print("in \(#function)")
    Router.revealGameOverScene(from: self, wonOrNot: wonOrNot)
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
    rotate(sprite: zombieSprite, to: zombieSpriteMovingDirection.angle,
           radiansPerSec: zombieSpriteRotateRadiansPerSec)
    if let target = lastTouchLocation {
      moveZombieToward(target)
    }
    boundsCheckZombie()
  }
  
  private func moveZombieToward(_ target: CGPoint) {
    let distance = (target - zombieSprite.position).length
    let distanceCanMove = zombieSpriteMovePointsPerSec * CGFloat(dt)
    if distance < distanceCanMove {
      zombieSprite.position = target
      stopZombieWalkingAnimation()
    } else {
      zombieSprite.position += zombieSpriteMovingDirection * distanceCanMove
    }
  }
  
  private func setZombieMovingDirection(towards location: CGPoint) {
    let offset = location - zombieSprite.position
    zombieSpriteMovingDirection = offset.normalized()
  }
  
  private func sceneTouched(touchLocation: CGPoint) {
    startZombieWalkingAnimation()
    setZombieMovingDirection(towards: touchLocation)
    lastTouchLocation = touchLocation
  }
  
  private func boundsCheckZombie() {
    let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
    let topRight = CGPoint(x: size.width, y: playableRect.maxY)
    
    if zombieSprite.position.x <= bottomLeft.x {
      zombieSprite.position.x = bottomLeft.x
      zombieSpriteMovingDirection.x = -zombieSpriteMovingDirection.x
    }
    if zombieSprite.position.x >= topRight.x {
      zombieSprite.position.x = topRight.x
      zombieSpriteMovingDirection.x = -zombieSpriteMovingDirection.x
    }
    if zombieSprite.position.y <= bottomLeft.y {
      zombieSprite.position.y = bottomLeft.y
      zombieSpriteMovingDirection.y = -zombieSpriteMovingDirection.y
    }
    if zombieSprite.position.y >= topRight.y {
      zombieSprite.position.y = topRight.y
      zombieSpriteMovingDirection.y = -zombieSpriteMovingDirection.y
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
  
  private func spawnEnemySprite() {
    let enemy = SKSpriteNode(imageNamed: "enemy")
    enemy.name = "enemy"
    enemy.position = CGPoint(
        x: size.width + enemy.size.width/2,
        y: CGFloat.random(min: playableRect.minY + enemy.size.height/2,
                          max: playableRect.maxY - enemy.size.height/2))
    addChild(enemy)
    
    let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
    let actionRemove = SKAction.removeFromParent()
    enemy.run(SKAction.sequence([actionMove, actionRemove]))
  }
  
  private func startZombieWalkingAnimation() {
    guard zombieSprite.action(forKey: "animation") == nil else { return }
    zombieSprite.run(SKAction.repeatForever(zombieSpriteWalkingAnimation),
                     withKey: "animation")
  }
  
  private func stopZombieWalkingAnimation() {
    zombieSprite.removeAction(forKey: "animation")
  }
  
  private func spawnCatSprite() {
    let cat = SKSpriteNode(imageNamed: "cat")
    cat.name = "cat"
    cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX,
                                             max: playableRect.maxX),
                           y: CGFloat.random(min: playableRect.minY,
                                             max: playableRect.maxY))
    cat.setScale(0)
    addChild(cat)
    
    let appear = SKAction.scale(to: 1.0, duration: 0.5)
    cat.zRotation = -tao / 32.0
    let leftWiggle = SKAction.rotate(byAngle: tao/16.0, duration: 0.5)
    let rightWiggle = leftWiggle.reversed()
    let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
    let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
    let scaleDown = scaleUp.reversed()
    let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
    let group = SKAction.group([fullScale, fullWiggle])
    let groupWait = SKAction.repeat(group, count: 10)
    let disappear = SKAction.scale(to: 0, duration: 0.5)
    let removeFromParent = SKAction.removeFromParent()
    let actions = [appear, groupWait, disappear, removeFromParent]
    cat.run(SKAction.sequence(actions))
  }
  
  private func zombieHit(cat: SKSpriteNode) {
    cat.name = "train"
    cat.removeAllActions()
    cat.setScale(1)
    cat.zRotation = 0
    cat.run(catSpriteTurningGreenAction)
    run(catSpriteCollisionSound)
    output?.zombieSpriteDidHitCatSprite()
  }

  private func zombieHit(enemy: SKSpriteNode) {
    run(enemySpriteCollisionSound)
    removeCatSprites(howMany: 2)
    output?.zombieSpriteDidHitEnemySprite()
  }
  
  private func checkCollisions() {
    enumerateChildNodes(withName: "cat") { [weak self] node, _ in
      guard let strongSelf = self else { return }
      let cat = node as! SKSpriteNode
      if cat.frame.intersects(strongSelf.zombieSprite.frame) {
        strongSelf.zombieHit(cat: cat)
      }
    }
    
    enumerateChildNodes(withName: "enemy") { [weak self] node, _ in
      guard let strongSelf = self else { return }
      if let _ = strongSelf.zombieSprite.action(forKey: "blink") { return }
      let enemy = node as! SKSpriteNode
      if node.frame.insetBy(dx: 20, dy: 20)
                   .intersects(strongSelf.zombieSprite.frame) {
        strongSelf.zombieHit(enemy: enemy)
      }
    }
  }
  
  private func moveTrain() {
    var targetPosition = zombieSprite.position
    
    enumerateChildNodes(withName: "train") { [weak self] node, stop in
      guard let strongSelf = self else { return }
      if !node.hasActions() {
        let offset = targetPosition - node.position
        let distance = offset.length
        let actionDuration = TimeInterval(
            distance / strongSelf.catSpriteMovePointsPerSec)
        let moveAction = SKAction.move(to: targetPosition,
                                       duration: actionDuration)
        node.run(moveAction)
      }
      targetPosition = node.position
    }
  }
  
  private func removeCatSprites(howMany num: Int) {
    var loseCount = 0
    enumerateChildNodes(withName: "train") { node, stop in
      var randomSpot = node.position
      
      randomSpot.x += CGFloat.random(min: -100, max: 100)
      randomSpot.y += CGFloat.random(min: -100, max: 100)
      
      node.name = ""
      node.run(
          SKAction.sequence([
            SKAction.group([
              SKAction.rotate(byAngle: tao*2, duration: 1.0),
              SKAction.move(to: randomSpot, duration: 1.0),
              SKAction.scale(to: 0, duration: 1.0)]),
            SKAction.removeFromParent()]))
      
      loseCount += 1
      if loseCount >= num {
        stop[0] = true
      }
    }
  }
}
