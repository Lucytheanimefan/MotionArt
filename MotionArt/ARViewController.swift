//
//  ARViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/16/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import ReplayKit
import ARKit
import CoreMotion

//The green axis represents Y (take a mental note, Y points up)
//The red axis represents X
//The blue axis represents Z

//This position is relative to the camera. Positive x is to the right. Negative x is to the left.
//Positive y is up. Negative y is down. Positive z is backward. Negative z is forward.
class ARViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    var configuration: ARWorldTrackingConfiguration!
    
    var activityManager:CMMotionActivityManager!
    var motionManager:CMMotionManager!
    
    var nodes:[SCNNode] = [SCNNode]()
    var light:SCNLight!
    
    let recorder = RPScreenRecorder.shared()
    
    var option:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        self.activityManager = CMMotionActivityManager()
        self.motionManager = CMMotionManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startSession()
        self.createLight()
        
        self.createRings(numRings: Constants.NUM_RINGS, separationDistance: Constants.RING_SEPARATION)
        self.beginMotionData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: Scene setup
    func setupSceneView(){
        self.sceneView.scene = SCNScene()
        self.sceneView.delegate = self
        #if DEBUG
            self.sceneView.showsStatistics = true
            self.sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        #endif
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
    }
    
    func startSession() {
        configuration = ARWorldTrackingConfiguration()
        configuration!.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        sceneView.session.delegate = self
        sceneView.session.run(configuration!, options: [ARSession.RunOptions.removeExistingAnchors,
                                                        ARSession.RunOptions.resetTracking])
    }
    
    // MARK: Recording
    @IBAction func startRecording(_ sender: UIBarButtonItem) {
        startRecording()
    }
    
    
    @IBAction func stopRecording(_ sender: UIBarButtonItem) {
        stopRecording()
    }
    
    func startRecording(){
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        
        recorder.startRecording { (error) in
            guard error == nil else {
                print("There was an error starting the recording: \(error.debugDescription)")
                return
            }
        }
    }
    
    func stopRecording(){
        recorder.stopRecording { (preview, error) in
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            
            let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording suffessfully deleted.")
                })
            })
            
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
            })
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    //MARK: SceneKit objects
    func createLight(){
        self.light = SCNLight()
        light.type = .omni
        light.castsShadow = true
        light.shadowRadius = 2
        self.sceneView.pointOfView?.light = light
    }
    
    func addBox(){
        let boxNode = createBox()
        addNode(node: boxNode)
    }
    
    func createBox(name:String? = nil)->SCNNode{
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        if (option == "anime"){
            box.setImage(image: #imageLiteral(resourceName: "penguinCucumber"))
        }
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0, 0, -0.2)
        if let name = name{
            boxNode.name = name
        }
        return boxNode
    }
    
    func createSphere()->SCNNode{
        let sphere = SCNSphere(radius: 0.1)
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    func createRings(numRings:Int, separationDistance:Float){
        for i in -numRings/2 ..< numRings/2{
            addRing(y: Float(i)*separationDistance, name:"ring_\(i)")
        }
    }
    
    func addRing(nodes:[SCNNode]? = nil, x:Float? = nil, y:Float? = nil, z:Float? = nil, name:String? = nil){
        var myNodes = [SCNNode]()
        if let nodes = nodes{
            myNodes = nodes
        }
        else{
            for _ in 0 ..< Constants.NUM_NODES{
                myNodes.append(createBox(name: name))
            }
        }
        
        let incrementAngle = (4*Float.pi) / Float(myNodes.count)
        //print("Increment angle: \(incrementAngle)")
        for (i, node) in myNodes.enumerated(){
            let xN = Float(cos(Float(i/2) * incrementAngle))/3 //TODO: change radius
            let zN = Float(sin(Float(i/2) * incrementAngle))/3
            let yN = zN
            if let x = x{
                node.position = SCNVector3Make(x, yN, zN)
            }
            else if let y = y{
                node.position = SCNVector3Make(xN, y, zN)
            }
            else if let z = z{
                node.position = SCNVector3Make(xN, yN, z)
            }
            else{
                node.position = SCNVector3Make(Float(xN), 0, Float(zN))
            }
            addNode(node: node)
        }
    }
    
    func addNode(node:SCNNode){
        self.nodes.append(node)
        self.sceneView.addNode(node: node)
    }
    
    func beginMotionData(){
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (deviceMotion, error) in
            guard error == nil && deviceMotion != nil else{
                print(error.debugDescription)
                return
            }
            
            let (xAccel, yAccel, zAccel) = (deviceMotion?.normalizedAcceleration())!
            
            let (roll, pitch, yaw) = (deviceMotion?.rollPitchYaw())!
            
            #if DEBUG
                //print("Acceleration: \(xAccel),\(yAccel),\(zAccel)")
            #endif
            
            let (xGravity, yGravity, zGravity) = (deviceMotion?.absGravity())!
            
            let (xPosGravity, yPosGravity, zPosGravity) = (deviceMotion?.positionGravity())!
            
            self.nodes.forEach({ (node) in
                if let geometry = node.geometry as? SCNBox{
                    let minDimension = min(geometry.height, geometry.width, geometry.length)/2
                    geometry.chamferRadius = CGFloat(yGravity)*minDimension
                }
                
                if (self.option == "motion"){
                    let accelColor = UIColor(red: xAccel, green: yAccel, blue: zAccel, alpha: 1)
                    node.geometry?.setColor(color: accelColor)
                }
                if let ringIndex = node.ringIndex(){
                    //print(ringIndex)
                    switch ringIndex{
                    case 0: // top ring
                        node.rotation = SCNVector4Make(roll, pitch, yaw, xPosGravity)
                    case 1:
                        node.rotation = SCNVector4Make(roll*10, pitch*10, yaw*10, zPosGravity)
                    case 2:
                        node.rotation = SCNVector4Make(roll, pitch, yaw, yPosGravity)
                    default:
                        node.rotation = SCNVector4Make(0, 0, 0, 0)
                        print("Not one of the 3 rings")
                    }
                }
            })
        }
    }
    
    func addVector3(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
    }
    
    func subtractVector3(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x - rhv.x, lhv.y - rhv.y, lhv.z - rhv.z)
    }
    
    func withinBounds(position1:SCNVector3, position2:SCNVector3) -> Bool{
        return (abs(position1.x - position2.x) < Constants.BOUNDS &&
            abs(position1.y - position2.y) < Constants.BOUNDS &&
            abs(position1.z - position2.z) < Constants.BOUNDS)
    }
    
    func cleanScene() {
        for (i, node) in self.nodes.enumerated() {
            if node.presentation.position.y < -1*(Float(Constants.NUM_RINGS/2) * Constants.RING_SEPARATION) {
                print("Remove a node")
                node.removeFromParentNode()
                self.nodes.remove(at: i)
            }
        }
    }
    
}

// MARK: ARViewController Extensions
extension ARViewController: SCNPhysicsContactDelegate{
}

extension ARViewController:RPPreviewViewControllerDelegate{
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ARViewController:ARSessionDelegate{
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentPosition = frame.camera.transform.position()
        //print("Current position: \(currentPosition)")
        
        for (i, node) in self.nodes.enumerated(){
        //self.nodes.forEach { (node) in
            let nodePosition = node.position
            
            //let difference = subtractVector3(lhv: currentPosition, rhv: nodePosition)
            //print("Position difference: \(difference)")
            
            // Collision detected
            if self.withinBounds(position1: nodePosition, position2: currentPosition){
                print("--Within bounds!!!!")
                //print("Node position: \(nodePosition)")
                
                // Move it out a bit
                let signValues = nodePosition.signValue()
                
                // Create collision nodes
                if let collisionParticleSystem = SCNParticleSystem(named: "Collision", inDirectory: nil){
                    node.addParticleSystem(collisionParticleSystem)
                    
                    let rand = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
                    let action = SCNAction.move(by: SCNVector3Make(signValues.x * Constants.INCREMENT * Float(rand) , 0, signValues.z * Constants.INCREMENT * Float(rand) ), duration: 1.5)
                    action.timingMode = .easeInEaseOut
    
                    node.runAction(action, completionHandler: {
                        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                        
                    })
                }
                
            }
        }
    }
}

extension ARViewController:ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        cleanScene()
    }
    
}

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
    
//    func incrementedPosition(xIncrementValue:Float=0, yIncrementValue:Float=0, zIncrementValue:Float=0)->SCNVector3 {
//
//    }
}

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}
