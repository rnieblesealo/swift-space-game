import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var score: Int = 0 {
        // Call this when the value is set
        // What an awesome fucking feature
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer: Timer!
    
    var possibleAliens = [ "alien", "alien2", "alien3" ]
    
    let alienCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory: UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    
    override func didMove(to view: SKView) {
        
        // Initialize particle emmitter
        starfield = SKEmitterNode(fileNamed: "Starfield")
        
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        
        // Add it to scene
        self.addChild(starfield)
        
        // Make it go behind everything
        starfield.zPosition = -1
        
        // Now do the player
        player = SKSpriteNode(imageNamed: "shuttle")
        
        player.position = CGPoint(x: self.frame.size.width / 2 , y: player.size.height / 2 + 20)
        
        self.addChild(player)
        
        // Eliminate gravity
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        // Make scene detect physics
        self.physicsWorld.contactDelegate = self
        
        // Do score label
        scoreLabel = SKLabelNode(text: "Score: 0")
        
        scoreLabel.position = CGPoint(x: 100, y: self.frame.size.height - 60)
        scoreLabel.fontName = "HelveticaNeue-Bold" // Get names at iosfonts.com
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        
        // Set score to 0
        score = 0
        
        self.addChild(scoreLabel)
        
        // Set up timer
        // #selector defines a method to be called later; the passed method should be marked @objc like below
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        // Setup accelerometer
        // MARK: Read up on the second call and what it does, it looks crazy!
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) {
            (data: CMAccelerometerData?, error: Error?) in if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x * 0.5 + self.xAcceleration * 0.25)
            }
        }
    }

    @objc func addAlien() {
        // Call a shared instance (singleton) randomizer, then return a shuffled instance of the possibleAliens array
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        // Generate a random distribution and grab an int from it as our random position
        let randomAlienPosition = GKRandomDistribution(lowestValue: 0, highestValue: 414)
        let position = CGFloat(randomAlienPosition.nextInt())
        
        // Give it to our alien
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        // Give it a dynamic (physics-responding) physics body
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        
        // Contact test sends a message when collision happens
        // Collision physically affects the object's movement
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration: TimeInterval = 6
        
        
        // Create an array of actions
        var actionArray = [SKAction]()
        
        // Append the action of moving from top to bottom and then being removed from scene
        // I assume SKActions work with a queue
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -alien.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        // Run the actions on the alien
        alien.run(SKAction.sequence(actionArray))
        
    }
    
    func fireTorpedo(){
        // Play sound
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        // Create torpedo with correct properties
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        
        // Give it physics body with correct properties
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        
        // Use precise hit detection
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        // Add to scene!
        self.addChild(torpedoNode)
        
        // Move it up
        
        let animationDuration: TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // Run collision detection
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Run torpedo + alien collision if the first body is the torpedo
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory != 0) {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
        
    func torpedoDidCollideWithAlien(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode){
        // Do an explosion at the hit alien's position
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        
        explosion.position = alienNode.position
        
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        // Remove the torpedo and alien node from the parent scene
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        // Remove the explosion after an amount of time
        // These completion blocks are awesome!
        self.run(SKAction.wait(forDuration: 0.3)) {
            explosion.removeFromParent()
        }
        
        // Give score!
        score += 5
    }
    
    override func didSimulatePhysics() {
        // Move the player based on acceleration
        player.position.x += xAcceleration * 50
        
        // Wrap if going off bounds
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
