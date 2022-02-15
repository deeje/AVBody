//
//  ARBodyViewController.swift
//  AVBodyExample
//
//  Created by deeje cooley on 12/7/21.
//

import UIKit
import SceneKit
import ARKit

class ARBodyViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
        
    @IBOutlet var sceneView: ARSCNView!
    
    var robotRoot: SCNNode!
    var robotNode: SCNNode!
    
    var recorder: AVBodyRecorderViewController!
    var playback: AVBodyPlaybackViewController?
    
    var configuration: ARBodyTrackingConfiguration!
    
    var currentMode: UIViewController? {
        willSet {
            if let child = currentMode {
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
        }
        didSet {
            if let child = currentMode {
                addChild(child)
                view.addSubview(child.view)
                child.didMove(toParent: self)
            }
        }
    }
    
    override func viewDidLoad() {
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("AR Body Tracking is only supported on devices with an A12 chip or better")
        }
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.showsStatistics = true
        
        sceneView.scene = SCNScene()
        sceneView.preferredFramesPerSecond = 30
        
        self.loadRobot()
        
        recorder = AVBodyRecorderViewController.instantiate { coder in
            return AVBodyRecorderViewController(coder: coder,
                                                arBodyViewController: self)
        }
        
        configuration = ARBodyTrackingConfiguration()
        configuration.environmentTexturing = .none
        configuration.isAutoFocusEnabled = true
        configuration.providesAudioData = true
        
        sceneView.session.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if currentMode == nil {
            currentMode = recorder
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - Robot
        
    func loadRobot() {
        guard let url = Bundle.main.url(forResource: "robot", withExtension: "usdz") else { fatalError() }
        
        let scene = try! SCNScene(url: url, options: [.checkConsistency: true])

        robotRoot = scene.rootNode
        
        let shapeParent = robotRoot.childNode(withName: "biped_robot_ace_skeleton", recursively: true)!
        
        // Hierarchy is a bit odd, two 'root' names. Taking the second one
        robotNode = shapeParent.childNode(withName: "root", recursively: false)?.childNode(withName: "root", recursively: false)
        
        self.sceneView.scene.rootNode.addChildNode(robotRoot)
    }
    
    // MARK: - ARBodyAnchor
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        recorder.session(session, didUpdate: frame)
    }
    
    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        recorder.session(session, didOutputAudioSampleBuffer: audioSampleBuffer)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if let isPlaying = playback?.isPlaying, isPlaying == true { return }
        
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
                         
            robotNode.transform = SCNMatrix4.init(bodyAnchor.transform)
            
            for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
                if let childNode = robotNode.childNode(withName: jointName, recursively: true) {
                    let joint = ARSkeleton.JointName(rawValue: jointName)
                    if let transform = bodyAnchor.skeleton.localTransform(for: joint) {
                        childNode.transform = SCNMatrix4.init(transform)
                    }
                }
            }
        }
    }
    
    public func didFinishRecording(at url: URL) {
        playback = AVBodyPlaybackViewController.instantiate { coder in
            return AVBodyPlaybackViewController(coder: coder,
                                                robotNode: self.robotNode,
                                                url: url)
        }
        currentMode = playback
    }
    
    // MARK: - ARSCNViewDelegate
        
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
        sceneView.session.run(configuration)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}
