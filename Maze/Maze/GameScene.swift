//
//  GameScene.swift
//  Maze
//
//  Created by jhampac on 2/11/16.
//  Copyright (c) 2016 jhampac. All rights reserved.
//

enum CollisionType: UInt32
{
    case Player = 1
    case Wall = 2
    case Star = 4
    case Vortex = 8
    case Finish = 16
}

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var player: SKSpriteNode!
    var motionManager: CMMotionManager!
    var scoreLabel: SKLabelNode!
    var score: Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameOver = false
    
    override func didMoveToView(view: SKView)
    {
        // set background
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .Replace
        background.zPosition = -1
        addChild(background)
        
        // set label node for score
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .Left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        addChild(scoreLabel)
        
        // create core motion object
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        // load level, create player, turn off gravity
        loadLevel()
        createPlayer()
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
       
    }
    
    func didBeginContact(contact: SKPhysicsContact)
    {
        if contact.bodyA.node == player
        {
            playerCollideWithNode(contact.bodyB.node!)
        }
        else if contact.bodyB.node == player
        {
            playerCollideWithNode(contact.bodyA.node!)
        }
        
    }
   
    override func update(currentTime: CFTimeInterval)
    {
        if !gameOver
        {
            if let accelerometerData = motionManager.accelerometerData
            {
                physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
            }
        }
    }
    
    // building a level off a text file;
    func loadLevel()
    {
        if let levelPath = NSBundle.mainBundle().pathForResource("level1", ofType: "txt")
        {
            if let levelString = try? String(contentsOfFile: levelPath, usedEncoding: nil)
            {
                let lines = levelString.componentsSeparatedByString("\n")
                
                for (row,line) in lines.reverse().enumerate()
                {
                    for (column, letter) in line.characters.enumerate()
                    {
                        let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                        
                        if letter == "x"
                        {
                            let node = SKSpriteNode(imageNamed: "block")
                            node.position = position
                            node.physicsBody = SKPhysicsBody(rectangleOfSize: node.size)
                            node.physicsBody!.categoryBitMask = CollisionType.Wall.rawValue
                            node.physicsBody!.dynamic = false
                            addChild(node)
                        }
                        else if letter == "v"
                        {
                            let node = SKSpriteNode(imageNamed: "vortex")
                            node.name = "vortext"
                            node.position = position
                            node.runAction(SKAction.repeatActionForever(SKAction.rotateByAngle(CGFloat(M_PI), duration: 1)))
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody!.dynamic = false
                            node.physicsBody!.categoryBitMask = CollisionType.Vortex.rawValue
                            node.physicsBody!.contactTestBitMask = CollisionType.Player.rawValue
                            node.physicsBody!.collisionBitMask = 0
                            addChild(node)
                        }
                        else if letter == "s"
                        {
                            let node = SKSpriteNode(imageNamed: "star")
                            node.name = "star"
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody!.dynamic = false
                            
                            node.physicsBody!.categoryBitMask = CollisionType.Star.rawValue
                            node.physicsBody!.contactTestBitMask = CollisionType.Player.rawValue
                            node.physicsBody!.collisionBitMask = 0
                            node.position = position
                            addChild(node)
                        }
                        else if letter == "f"
                        {
                            let node = SKSpriteNode(imageNamed: "finish")
                            node.name = "finish"
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody!.dynamic = false
                            
                            node.physicsBody!.categoryBitMask = CollisionType.Finish.rawValue
                            node.physicsBody!.contactTestBitMask = CollisionType.Player.rawValue
                            node.physicsBody!.collisionBitMask = 0
                            node.position = position
                            addChild(node)
                        }
                    }
                }
            }
        }
    }
    
    func createPlayer()
    {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.linearDamping = 0.75
        player.physicsBody!.categoryBitMask = CollisionType.Player.rawValue
        player.physicsBody!.contactTestBitMask = CollisionType.Star.rawValue | CollisionType.Vortex.rawValue | CollisionType.Finish.rawValue
        player.physicsBody!.collisionBitMask = CollisionType.Wall.rawValue
        addChild(player)
    }
    
    func playerCollideWithNode(node: SKNode)
    {
        if node.name == "vortext"
        {
            player.physicsBody!.dynamic = false
            gameOver = true
            score -= 1
            
            let move = SKAction.moveTo(node.position, duration: 0.25)
            let scale = SKAction.scaleTo(0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.runAction(sequence) { [unowned self] in
                self.createPlayer()
                self.gameOver = false
            }
        }
        else if node.name == "star"
        {
            node.removeFromParent()
            score += 1
            
            let scoredLabel = SKLabelNode(fontNamed: "Chalkduster")
            scoredLabel.text = "SCORE +1"
            scoredLabel.fontSize = 60
            scoredLabel.position = CGPoint(x: 512, y: 384)
            addChild(scoredLabel)
            scoredLabel.runAction(SKAction.fadeOutWithDuration(0.75)) { [unowned self] in
                scoredLabel.removeFromParent()
            }
            
            
        }
        else if node.name == "finish"
        {
            let finishLabel = SKLabelNode(fontNamed: "Chalkduster")
            finishLabel.text = "YOU WIN!!!"
            finishLabel.fontSize = 40
            finishLabel.position = CGPoint(x: 512, y: 384)
            addChild(finishLabel)
            gameOver = true
            
        }
    }
}
