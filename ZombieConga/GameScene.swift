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
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  var lastTouchLocation: CGPoint? = nil
  var gameOver = false

  var lives = 5
  let zombie = SKSpriteNode(imageNamed: "zombie1")
  let zombieMovePointsPerSec: CGFloat = 480.0
  let zombieRotateRadiansPerSec: CGFloat = tao * 2.0
  var zombieMovingDirection = CGPoint.zero
  let zombieAnimation: SKAction
  var zombieInvincible = false {
    didSet {
      if zombieInvincible {
        zombie.run(zombieBlinkAction) { [weak self] in
          self?.zombieInvincible = false
        }
      } else {
        zombie.isHidden = false
      }
    }
  }
  let zombieBlinkAction: SKAction = {
    let blinkTimes = 10.0
    let duration = 3.0
    let slice = duration / blinkTimes
    let blinkAction = SKAction.customAction(withDuration: duration) {
      node, elapsedTime in
      let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice) 
      node.isHidden = (remainder > slice / 2)
    }
    return blinkAction
  }()
  
  var catMovePointsPerSec: CGFloat {
    return zombieMovePointsPerSec
  }
  let catTurningGreenAction: SKAction = {
    let duration = 0.2
    let action = SKAction.colorize(with: UIColor.green,
                                   colorBlendFactor: 1,
                                   duration: duration)
    return action
  }()
  let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
      "hitCat.wav", waitForCompletion: false)
  let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
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
    zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
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
    zombie.zPosition = 100
    addChild(zombie)
//    zombie.run(SKAction.repeatForever(zombieAnimation))
    
    // spawn enemies
    run(SKAction.repeatForever(SKAction.sequence([
        SKAction.run { [weak self] in
        self?.spawnEnemy()
        },
        SKAction.wait(forDuration: 2.0)
    ])))
    run(SKAction.repeatForever(SKAction.sequence([
        SKAction.run { [weak self] in
          self?.spawnCat()
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
//    checkCollisions()
    if lives <= 0 && !gameOver {
      gameOver = true
      print("You lose!")
    }
  }
  
  override func didEvaluateActions() {
    checkCollisions()
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
    if let target = lastTouchLocation {
      moveZombieToward(target)
    }
    boundsCheckZombie()
  }
  
  private func moveZombieToward(_ target: CGPoint) {
    let distance = (target - zombie.position).length
    let distanceCanMove = zombieMovePointsPerSec * CGFloat(dt)
    if distance < distanceCanMove {
      zombie.position = target
      stopZombieWalkingAnimation()
    } else {
      zombie.position += zombieMovingDirection * distanceCanMove
    }
  }
  
  private func setZombieMovingDirection(towards location: CGPoint) {
    let offset = location - zombie.position
    zombieMovingDirection = offset.normalized()
  }
  
  private func sceneTouched(touchLocation: CGPoint) {
    startZombieWalkingAnimation()
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
  
  private func spawnEnemy() {
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
    guard zombie.action(forKey: "animation") == nil else { return }
    zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
  }
  
  private func stopZombieWalkingAnimation() {
    zombie.removeAction(forKey: "animation")
  }
  
  private func spawnCat() {
    let cat = SKSpriteNode(imageNamed: "cat")
    cat.name = "cat"
    cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX,
                                             max: playableRect.maxX),
                           y: CGFloat.random(min: playableRect.minY,
                                             max: playableRect.maxY))
    cat.setScale(0)
    addChild(cat)
    
    let appear = SKAction.scale(to: 1.0, duration: 0.5)
//    let wait = SKAction.wait(forDuration: 10.0)
    cat.zRotation = -tao / 32.0
    let leftWiggle = SKAction.rotate(byAngle: tao/16.0, duration: 0.5)
    let rightWiggle = leftWiggle.reversed()
    let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
//    let wiggleWait = SKAction.repeat(fullWiggle, count: 10)
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
    cat.run(catTurningGreenAction)
    run(catCollisionSound)
  }
  
  private func zombieHit(enemy: SKSpriteNode) {
//    enemy.removeFromParent()
    run(enemyCollisionSound)
    loseCats()
    lives -= 1
    zombieInvincible = true
  }
  
  private func checkCollisions() {
//    var hitCats: [SKSpriteNode] = []
    enumerateChildNodes(withName: "cat") { [weak self] node, _ in
      guard let strongSelf = self else { return }
      let cat = node as! SKSpriteNode
      if cat.frame.intersects(strongSelf.zombie.frame) {
        strongSelf.zombieHit(cat: cat)
      }
    }
//    for cat in hitCats { zombieHit(cat: cat) }
    
    guard !zombieInvincible else { return }
    
//    var hitEnemies: [SKSpriteNode] = []
    enumerateChildNodes(withName: "enemy") { [weak self] node, _ in
      guard let strongSelf = self else { return }
      let enemy = node as! SKSpriteNode
      if node.frame.insetBy(dx: 20, dy: 20).intersects(strongSelf.zombie.frame) {
        strongSelf.zombieHit(enemy: enemy)
//        hitEnemies.append(enemy)
      }
    }
//    for enemy in hitEnemies { zombieHit(enemy: enemy) }
  }
  
  private func moveTrain() {
    var trainCount = 0
    var targetPosition = zombie.position
    
    enumerateChildNodes(withName: "train") { [weak self] node, stop in
      guard let strongSelf = self else { return }
      trainCount += 1
      if !node.hasActions() {
        let offset = targetPosition - node.position
        let distance = offset.length
        let actionDuration = TimeInterval(
            distance / strongSelf.catMovePointsPerSec)
        let moveAction = SKAction.move(to: targetPosition,
                                       duration: actionDuration)
        node.run(moveAction)
      }
      targetPosition = node.position
    }
    
    if trainCount >= 15 && !gameOver {
      gameOver = true
      print("You win!")
    }
  }
  
  private func loseCats() {
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
      if loseCount >= 2 {
        stop[0] = true
      }
    }
  }
}
