import Foundation
import UIKit
import SpriteKit
import GameplayKit

class GameOverScene: SKScene {
   
    var label = SKLabelNode()
    
    //MARK: - сообщение о проигрыше
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Распознаватель жестов
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        label = SKLabelNode(text: "Game Over! You have passed \(gameScore) cubes!")
        
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.fontSize = 36
        
        addChild(label)
    }
    
    //MARK: - распознаватель жестов (прыжки)
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {

        let scene = GameScene(size: size)
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5) 
        view?.presentScene(scene, transition: reveal)
    }
}
