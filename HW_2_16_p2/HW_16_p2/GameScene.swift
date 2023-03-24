import UIKit
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate { //SKPhysicsContactDelegate - реакция на контакт
 
    //MARK: - дорога из секций и секции препятствий
    var bricks = [SKShapeNode]() // дорожка
    var brickSize = CGSize(width: 40.0, height: 40.0) // размер секции дороги
    
    var roadLenght = 0 // всего кубиков сгенерировано (будем сюда считать), количество в массиве брать не верно, так как там невидимые кубики удаляются
    var roadPlayer = 0 // кубики, пройденные игроком (roadLenght - с корректировкой на непройденные 3/4 экрана, тк игрок стоит на 1/4 пути)
    
    var scrollSpeed: CGFloat = 5.0 // скорость движения (будем увеличивать)
    let startingScrollSpeed: CGFloat = 5.0 // начальная скорость
    
    let gravitySpeed: CGFloat = 1.5 // гравитация (как быстро объекты падают на землю)
    
    //MARK: - время последнего вызова для метода обновления
    var lastUpdateTime: TimeInterval? // будем рассчитывать сколько времени прошло с обновления, чтобы движения было плавным (сцена обновляется 30 раз в секунду)
    
    //MARK: - player
    let player = Player(rectOf: CGSize(width: 40.0, height: 40.0))
    
    //MARK: - didMove
    override func didMove(to view: SKView) {

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0) // направление гравитации (нет гравитации по горизонтали, умеренная гравитация по вертикали. Обычная земная гравитация -9.8)
        
        physicsWorld.contactDelegate = self // делегат физического мира
        
        scene?.backgroundColor = .darkGray
        anchorPoint = CGPoint.zero // (0, 0) - точка привязки левый нижний угол
        
        player.strokeColor = .black
        player.fillColor = .green
        
        // создаем игрока и добавляем его к сцене
        player.setupPhysicsBody()
        
    //    resetPlayer()
        addChild(player)
        
        // Распознаватель жестов
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        startGame()
    }
    
    //MARK: - resetPlayer (начальное положение игрока)
    func resetPlayer() {
        let playerX = frame.midX / 2.0 // 1/4 длины сцены
        let playerY = brickSize.height + player.frame.height
        
        player.position = CGPoint(x: playerX, y: playerY)
        player.zPosition = 10 // по умолчанию z-позиция в самом низу, берем 10 чтобы было запасных 9 слоем для других объектов
        player.minimumY = playerY
        
        player.zRotation = 0.0
        player.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        player.physicsBody?.angularVelocity = 0.0
    }
    
    //MARK: - начало игры
    func startGame() {
        
        roadLenght = 0 // обнулим кубики
        roadPlayer = 0 // обнулим путь игрока
        resetPlayer()
        
        scrollSpeed = startingScrollSpeed
        lastUpdateTime = nil
        
        for brick in bricks {
            brick.removeFromParent()
        }
        
        bricks.removeAll(keepingCapacity: true)
    }

    //MARK: - конец игры
    func gameOver() {
        
       gameScore = roadPlayer // сохраним счет игрока
        
        // переход на сцену GameOver
        let scene = GameOverScene(size: size) // передадим размер, чтобы он знал свой размер  (это делаем в конструкторе)
        let reveal = SKTransition.flipVertical(withDuration: 1.0) // анимация, с которой будет показываться экран
        view?.presentScene(scene, transition: reveal) // переход на сцену с анимацией
    }
    
    //MARK: - создание секций дороги
    func spawnBrick(atPosition position: CGPoint) -> SKShapeNode { // atPosition - более читабельно (мы сразу видим, что секция появится в определенном месте
        
        //создаем секции и добавляем их к секции
        let brick = SKShapeNode(rectOf: CGSize(width: brickSize.width, height: brickSize.height))
        brick.position = position
//        brick.position.x = position.x
//        brick.position.y = position.y + 30.0
        brick.zPosition = 8
        brick.strokeColor = .black
        brick.fillColor = .blue
        addChild(brick)
        
        // добавляем новую секцию к массиву
        bricks.append(brick)
        
        // считаем пройденный путь
        roadLenght += 1
      
        // настройка физического тела секции
     //   let center = brick.inputView!.center
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size) // присоединим физическое тело к ноду
        brick.physicsBody?.affectedByGravity = false // на плитки не действует гравитация (земля не падает вниз)
        
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick // сообщает SpriteKit к какому типу объекта принадлежит данное тело
        brick.physicsBody?.collisionBitMask = 0 // 0 - секции не сталкиваются с чем-либо еще (остаются там, где есть)
        
        return brick
    }
    
    //MARK: - обновление положений секций дороги
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        
        // Отслеживайте самое большое положение по оси X для всех существующих секций
        var farthestRightBricksX: CGFloat = 0.0 // cамые дальние кирпичи
        
        for brick in bricks {
            let newX = brick.position.x - currentScrollAmount // currentScrollAmount - текущее смещение - рассчитываем новое положение секции
            
            // если секция сместилась слишком влево за пределы экрана - удалить ее
            if newX < -brickSize.width { // нельзя проверять  if newX < 0.0, так как это середина спрайта и при 0.0 половина спрайта на экране. Если положение секции меньше -brickSize.width, то секция полностью за пределами экрана
                
                brick.removeFromParent() // удаляем невидимую секцию, чтобы не занимать память
                
                if let brickIndex = bricks.firstIndex(of: brick) { // проверим находится ли удаленная секция в массиве секций (поиск по индексу)
                    bricks.remove(at: brickIndex) // исключим из массива секцию  этим индексом
                }
            } else {  // здесь работаем с оставшимися секциями на экране
                
                // для секции, оставшейся на экране, обновляем положение
                brick.position = CGPoint(x: newX, y: brick.position.y) // на основе рассчитанного newX
                
                //обновляем значение currentScrollAmount для крайней правой секции
                if brick.position.x > farthestRightBricksX {
                    farthestRightBricksX = brick.position.x
                }
            }
        }
        
        // цикл while, обеспечивающий постоянное наполнение экрана секциями
        while farthestRightBricksX < frame.width { // так как мы знаем положение самой правой секции относительно Х, то добавляем новую секцию, как только значение положения самой правой секции меньше ширины сцены
            
            let brickX = farthestRightBricksX + brickSize.width + 0.0 // добавим к самому правому значению х новую секцию через небольшой промежуток (если 0, то дорожка сплошная - не видно движения)
            var brickY = brickSize.height
            
            // препятствия на дороге

            let randomNumber = arc4random_uniform(99) // рандомное число до 99

            if randomNumber < 5 { // % шанс возникновения препятствия
                brickY += brickY  // добавим препятствие
            }

            // добавляем новую секцию и обновляем положение самой правой
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBricksX = newBrick.position.x // так как секция добавлена, то изменится и положение farthestRightBricksX
            // после того как сцена наполнилась секциями - цикл прекратит работу
        }
    }
    
    //MARK: - гравитация для кубика = возврат на землю после прыжка
    func updatePlayer() {
        
        // определяем находится ли кубик на дороге
        if let velocityY = player.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                player.isOnGround = false
            }
        }
        
        // проверим должна ли игра закончится
        let isOffScreen = player.position.y < 0.0 || player.position.x < 0.0

        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        let isTappedOver = player.zRotation > maxRotation || player.zRotation < -maxRotation
        
        if isOffScreen || isTappedOver {
            
            print("Кубиков отобразилось (сложено в массив): \(roadLenght)")
            
            let roadBrickFrame: Int = Int(frame.width / brickSize.width)
            print("Кубиков на экране за один раз (постоянная величина): \(roadBrickFrame)")
            
            let roadBrickCorrect: Int = roadBrickFrame / 4 * 3
            print("Кубиков на экране перед игроком - непройденных (постоянная величина): \(roadBrickCorrect)")
            
            roadPlayer = roadLenght - roadBrickCorrect
            print("Кубиков пройдено игроком (сложено в массив за минусом кооректировки непройденного пути): \(roadPlayer)")
            
            gameOver()
        }
        
//        if !player.isOnGround {
//
//            // новое значение скорости кубика с учетом гравитации
//            let velocityY = player.velocity.y - gravitySpeed // по мере удаления от земли при прыжке скорость будет снижаться из-за гравитации. После того как гравитация станет отрицательной кубик начнет падать на землю
//            player.velocity = CGPoint(x: player.velocity.x, y: velocityY) // скорректируем скорость кубика на новое значение
//
//            // новое положение кубика по y на основе скорости
//            let newPlayerY: CGFloat = player.position.y + player.velocity.y
//            player.position = CGPoint(x: player.position.x, y: newPlayerY) // новое положение кубика
//
//            // проверим приземлился ли кубик
//            if player.position.y < player.minimumY { // если кубик на земле
//
//                player.position.y = player.minimumY // установим позицию земли (чтобы не провалился сквозь землю
//                player.velocity = CGPoint.zero // скорость 0 (земля остановила падение кубика)
//                player.isOnGround = true // положение на земле из которого можно прыгать снова
//            }
//        }
    }
    
    //MARK: - update
    override func update(_ currentTime: TimeInterval) {
        
        // медленно увеличиваем scrollSpeed по мере развития игры
        scrollSpeed += 0.01
        
        // определим время, прошедшее с последнего вызова update (обнволения сцены)
        var elapsedTime: TimeInterval = 0.0 // отслеживание временных интервалов в секундах
        if let lastTimeStamp = lastUpdateTime { // распаковывает lastUpdateTime, если он существует (при первом вызове от будет nil, тк в начале игры не существует времени обнволения)
            elapsedTime = currentTime - lastTimeStamp // расчет времени, прошедшего с последнего вызова update(_ :)
        }
        
        lastUpdateTime = currentTime // благодаря этому наша переменная lastUpdateTime будет содержать точное значение
        
        // корректировка скорости перемещения
        let expectedElapsedTime: TimeInterval = 1.0 / 20.0 // ожидаемая задержка времени 1/20 секунды (скорость работы на реальном устройстве 60 кадров в секунду)
        
        // рассчитываем насколько далеко должны сдвинуться объекты при данном обновлении
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime) // чтобы рассчитать корректировку смещения, нужно разделить реально прошедшее время на ожидаемое время (если в реальности прошло больше времени (более 1/60), то корректировка будет больше 1. Если меньше ожидаемого, то корректировка меньше 1
        let currentScrollAmount = scrollSpeed * scrollAdjustment // чему равна скорость перемещения для очередного обновления (умножаем на корректировку)
        
        updateBricks(withScrollAmount: currentScrollAmount) // обновление положения секций
        
        updatePlayer()
    }
    
    //MARK: - распознаватель жестов (прыжки)
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        
        //кубик прыгает при нажатии на экран, только если он на земле
        if player.isOnGround {
            player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
//            player.velocity = CGPoint(x: 0.0, y: player.jumpSpeed) // скорость по Y = изначальной скорости
//            player.isOnGround = false // во время прыжка кубик не на земле
        }
    }
    
    //MARK: - SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        // проверим есть ли контакт между игроком и секцией или препятствием
        if contact.bodyA.categoryBitMask == PhysicsCategory.player && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            
            player.isOnGround = true
        }
    }
}
