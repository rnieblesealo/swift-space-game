import SpriteKit
import GameplayKit;

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
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
