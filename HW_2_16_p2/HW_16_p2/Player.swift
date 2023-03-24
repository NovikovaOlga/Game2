
import SpriteKit

class Player: SKShapeNode {
    
    var velocity = CGPoint.zero // скорость
    var minimumY: CGFloat = 0.0 // положение для прыжков
    var jumpSpeed: CGFloat = 20.0 // скорость прыжка
    var isOnGround = true // на земле (может прыгать, если на земле)
    
    func setupPhysicsBody() {
        
        if let playerBody = path {
            physicsBody = SKPhysicsBody(rectangleOf: playerBody.boundingBox.size)
            physicsBody?.isDynamic = true // движения объекта управляются физическим движком
            physicsBody?.density = 6.0 // плотность (масса) = как ведет себя при столкновении
            physicsBody?.allowsRotation = true // может вращаться или поворачиваться
            physicsBody?.angularDamping = 1.0 // угловая амплитуда (сопротивление физического тела вращению)
            
            physicsBody?.categoryBitMask = PhysicsCategory.player // соответствие между категорий игрока и физической категорией игрока
            physicsBody?.collisionBitMask = PhysicsCategory.brick  // на игрока влияет столкновение с секциями и он может от них отталкиваться
            physicsBody?.contactTestBitMask = PhysicsCategory.brick  // хотим знать когда у игрока возникнет контакт с кирпичом или препятствием ( | - пайп (от анг pipe - труба) позволяет сохранять множество значений в одном свойстве)
        }
    }
}
