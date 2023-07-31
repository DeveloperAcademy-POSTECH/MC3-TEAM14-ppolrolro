//
//  DartScene.swift
//  Shoong
//
//  Created by 금가경 on 2023/08/01.
//

import CoreMotion
import SpriteKit
import SwiftUI

// SKPhysicsContactDelegate : 충돌 감지에 필요한 프로토콜
final class DartScene: SKScene, SKPhysicsContactDelegate {
    
    // 화면 관련 변수
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    // 노드 관련 변수
    var darts: [SKSpriteNode] = []
    var dart : SKSpriteNode!
    var dartboard: SKSpriteNode!
    
    // 게임 진행 관련 변수
    var isDartThrown = false
    
    // 가속도 관련 변수
    private var motionManager = CMMotionManager()
    private var previousAcceleration: CMAcceleration?
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(.backGroundBeige)
        
        setUpPhysicsWorld()
        createDart()
        createDartboard()
        startDarting()
    }
    
    // 물리 세계 설정 : 중력 0
    func setUpPhysicsWorld() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
    }
    
    // 다트보드 생성
    func createDartboard() {
        dartboard = SKSpriteNode(imageNamed: "dart_wall")
        dartboard.position = CGPoint(x: screenWidth / 2, y: 702)
        dartboard.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: dartboard.size.width, height: dartboard.size.height))
        dartboard.physicsBody?.isDynamic = false
        dartboard.physicsBody?.categoryBitMask = PhysicsCategory.dartboard
        
        addChild(dartboard)
    }
    
    // 다트 생성
    func createDart() {
        dart = SKSpriteNode(imageNamed: "jiggy_02")
        
        dart.physicsBody?.affectedByGravity = false
        dart.position = CGPoint(x: screenWidth / 2, y: 100)
        dart.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: dart.size.width, height: dart.size.height))
        dart.physicsBody?.categoryBitMask = PhysicsCategory.dart
        dart.physicsBody?.contactTestBitMask = PhysicsCategory.dartboard
        dart.physicsBody?.collisionBitMask = PhysicsCategory.dartboard
        
        // 다트 배열에 넣은 뒤 마지막 값을 움직이게 만듬
        darts.append(dart)
        addChild(darts.last!)

    }
    
    
    // 다트 게임 시작
    private func startDarting() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let acceleration = data?.acceleration else { return }
                
                if let accelerationChange = self?.calculateAccelerationChange(currentAcceleration: acceleration) {
                    
                    if accelerationChange > 1.2 {
                        self?.startMotionManager(acceleration: acceleration)
                    }
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var collideBody = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            collideBody = contact.bodyB
        } else {
            collideBody = contact.bodyA
        }
        
        // 다트가 다트판에 꽂혔을 시 실행할 행동
        if collideBody.categoryBitMask == PhysicsCategory.dartboard {
            print("target!")
            darts.last?.physicsBody?.linearDamping = 1
            darts.last?.physicsBody?.isDynamic = false
        }
        
        // 충돌 시 새 다트 생성
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.darts.last?.physicsBody?.linearDamping = 0
            self.isDartThrown = true
            
            if self.isDartThrown {
                self.isDartThrown = false
                self.createDart()
            }
        }
    }
    
    // 핸드폰 움직임의 가속도를 받아오는 함수
    private func calculateAccelerationChange(currentAcceleration: CMAcceleration) -> Double? {
        guard let previousAcceleration = previousAcceleration else {
            self.previousAcceleration = currentAcceleration
            return nil
        }
        
        let deltaZ = currentAcceleration.z - previousAcceleration.z
        let accelerationChange = sqrt(deltaZ * deltaZ)
        
        self.previousAcceleration = currentAcceleration
        
        return accelerationChange
    }
    
    // 움직임 감지 시 가속도 추가
    private func startMotionManager(acceleration: CMAcceleration) {
        guard motionManager.isAccelerometerAvailable else {
            return
        }
        darts.last?.physicsBody?.isDynamic = true
        darts.last?.physicsBody?.applyImpulse(CGVector(dx: CGFloat(acceleration.y) * 30, dy: 100))
    }
}
