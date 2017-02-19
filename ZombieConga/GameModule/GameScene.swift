//
//  GameSceneImp.swift
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
  func didWrapUp(wonOrNot: Bool)
}

protocol GameScene: MyScene {
  var output: GameSceneOutput? { get set }
  func zombieSpriteStartsBlinking()
  func zombieSpriteStopsBlinking()
  func wrapUp(wonOrNot: Bool)
}

class GameSceneImp: SKScene, GameScene {
  
  var output: GameSceneOutput?
  
  let playableRect: CGRect
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  var lastTouchLocation: CGPoint? = nil

  let cameraNode = SKCameraNode()
  let cameraMovePointsPerSec: CGFloat = 200.0
  var cameraRect: CGRect {
    return CGRect(
      origin: CGPoint(x: camera!.position.x - playableRect.size.width/2,
                      y: camera!.position.y - playableRect.size.height/2),
      size: playableRect.size)
  }

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
    // play BGM
    playBackgroundMusic(filename: "backgroundMusic.mp3")
    
    // add background
    backgroundColor = SKColor.black
    for i in 0...1 {
      let background = makeBackgroundNode()
      background.name = "background"
      background.anchorPoint = CGPoint.zero
      background.zPosition = -1
      background.position = CGPoint(x: CGFloat(i) * background.size.width,
                                    y: 0)
      addChild(background)
    }
    
    // add zombie sprite
    zombieSprite.position = CGPoint(x: 400, y: 400)
    zombieSprite.zPosition = 100
    addChild(zombieSprite)
    
    // spawn enemy sprites
    run(SKAction.repeatForever(SKAction.sequence([
      SKAction.run { self.spawnEnemySprite() },
      SKAction.wait(forDuration: 2.0)
    ])))
    run(SKAction.repeatForever(SKAction.sequence([
      SKAction.run { self.spawnCatSprite() }, 
      SKAction.wait(forDuration: 1.0)
    ])))

//    addChild(cameraNode)
    camera = cameraNode
    camera!.position = CGPoint(x: size.width/2, y: size.height/2)
    
    debugDrawPlayableArea()
  }

  override func update(_ currentTime: TimeInterval) {
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime

    updateZombieSprite()
    moveTrain()
    moveCamera()
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

  func wrapUp(wonOrNot: Bool) {
    backgroundMusicPlayer.stop()
    output?.didWrapUp(wonOrNot: wonOrNot)
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
  
  private func move(sprite: SKSpriteNode,
                    in direction: CGPoint,
                    pointsPerSec: CGFloat) {
    sprite.position += direction * pointsPerSec * CGFloat(dt)
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
  
  private func updateZombieSprite() {
    rotate(sprite: zombieSprite, to: zombieSpriteMovingDirection.angle,
           radiansPerSec: zombieSpriteRotateRadiansPerSec)
    move(sprite: zombieSprite, in: zombieSpriteMovingDirection,
         pointsPerSec: zombieSpriteMovePointsPerSec)
    boundsCheckZombieSprite()
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
  
  private func boundsCheckZombieSprite() {
    let bottomLeft = CGPoint(x: cameraRect.minX,
                             y: cameraRect.minY)
    let topRight = CGPoint(x: cameraRect.maxX,
                           y: cameraRect.maxY)
    
    if zombieSprite.position.x <= bottomLeft.x {
      zombieSprite.position.x = bottomLeft.x
      zombieSpriteMovingDirection.x = abs(zombieSpriteMovingDirection.x)
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
    cat.position = CGPoint(x: CGFloat.random(min: cameraRect.minX,
                                             max: cameraRect.maxX),
                           y: CGFloat.random(min: cameraRect.minY,
                                             max: cameraRect.maxY))
    cat.zPosition = 50
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
  
  private func makeBackgroundNode() -> SKSpriteNode {
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPoint.zero
    backgroundNode.name = "background"
    
    let background1 = SKSpriteNode(imageNamed: "background1")
    background1.anchorPoint = CGPoint.zero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)

    let background2 = SKSpriteNode(imageNamed: "background2")
    background2.anchorPoint = CGPoint.zero
    background2.position = CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)
    
    backgroundNode.size = CGSize(
      width: background1.size.width + background2.size.width,
      height: background1.size.height)
    return backgroundNode
  }
  
  private func moveCamera() {
    let cameraVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
    let amountToMove = cameraVelocity * CGFloat(dt)
    camera?.position += amountToMove
    
    enumerateChildNodes(withName: "background") { [weak self] node, _ in
      guard let strongSelf = self else { return }
      let background = node as! SKSpriteNode
      if background.position.x + background.size.width 
           < strongSelf.cameraRect.origin.x {
        background.position = CGPoint(
          x: background.position.x + background.size.width*2,
          y: background.position.y)
      }
    }
  }
}
