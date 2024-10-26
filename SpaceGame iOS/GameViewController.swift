//
//  GameViewController.swift
//  SpaceGame iOS
//
//  Created by Rafael Niebles on 10/26/24.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        // Get the view as an SKView, make it fill the view, and present it
        
        if let view = self.view as! SKView? {
            
            let scene = GameScene(size: view.bounds.size)
            
            scene.scaleMode = .resizeFill;
            
            view.presentScene(scene);
            
        }
    }
}
