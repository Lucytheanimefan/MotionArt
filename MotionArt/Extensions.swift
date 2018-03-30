//
//  Extensions.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/28/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import CoreMotion
import Foundation
import ARKit

// MARK: Extensions
extension CMDeviceMotion{
    
    // accelerometer is in units of g-force (g = 9.8 m/s/s)
    // Let's assume the max acceleration of the human is 1.5g <- normalize to this
    func normalizedAcceleration()->(CGFloat, CGFloat, CGFloat){
        return (CGFloat(abs(self.userAcceleration.x))/1.5,
                CGFloat(abs(self.userAcceleration.y))/1.5,
                CGFloat(abs(self.userAcceleration.z))/1.5)
    }
    
    func absGravity()->(CGFloat, CGFloat, CGFloat){
        return (CGFloat(abs((self.gravity.x))),
                CGFloat(abs((self.gravity.y))),
                CGFloat(abs((self.gravity.z))))
    }
    
    func positionGravity()->(Float, Float, Float){
        return (Float(self.gravity.x),
                Float(self.gravity.y),
                Float(self.gravity.z))
    }
    
    func rotationRate()->(CGFloat, CGFloat, CGFloat){
        return (CGFloat(self.rotationRate.x),
                CGFloat(self.rotationRate.y),
                CGFloat(self.rotationRate.z))
    }
    
    func rollPitchYaw()->(Float, Float, Float){
        return (Float(self.attitude.roll), Float(self.attitude.pitch), Float(self.attitude.yaw))
    }
}

extension ARSCNView{
    func addNode(node:SCNNode){
        self.scene.rootNode.addChildNode(node)
    }
}

extension SCNNode{
    func ringIndex()->Int?{
        if let name = self.name{
            return Int(String(describing: name.last!))
        }
        return nil
    }
}

extension SCNGeometry{
    func setColor(color:UIColor){
        self.firstMaterial?.diffuse.contents = color
    }
    
    func setImage(image:UIImage){
        self.firstMaterial?.diffuse.contents = image
    }
}

extension SCNVector3{
    func signValue()->SCNVector3 {
        return SCNVector3Make((self.x>0 ? 1:-1), (self.y>0 ? 1:-1), (self.z>0 ? 1:-1))
    }
    
    func description()->String{
        return "(" + String(self.x) + ", " + String(self.y) + ", " + String(self.z) + ")"
    }
}

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}