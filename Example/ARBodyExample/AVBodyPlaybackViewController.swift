//
//  AVBodyPlaybackViewController.swift
//  AVBodyExample
//
//  Created by deeje cooley on 12/14/21.
//

import UIKit
import AVFoundation
import ARKit
import AVBody

class AVBodyPlaybackViewController : UIViewController, Storyboarded {
    
    private let robotNode: SCNNode
    private let player: AVBodyPlayer

    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var pauseButton: UIButton!
        
    public var isPlaying: Bool {
        get {
            return player.isPlaying
        }
    }
    
    // MARK: - View Controller Life Cycle
    
    init?(coder: NSCoder, robotNode: SCNNode, url: URL) {
        self.robotNode = robotNode
        self.player = AVBodyPlayer(url: url)
        
        super.init(coder: coder)
        
        player.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.isEnabled = true
        pauseButton.isEnabled = false
        
        player.prepare()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        player.pause()
        
        playButton.isEnabled = true
        pauseButton.isEnabled = false
    }
    
    @IBAction private func playButtonTapped(_ sender: AnyObject) {
        player.play()
        
        playButton.isEnabled = false
        pauseButton.isEnabled = true
    }
    
    @IBAction private func pauseButtonTapped(_ sender: AnyObject) {
        player.pause()
        
        playButton.isEnabled = true
        pauseButton.isEnabled = false
    }
    
}

// MARK: - AVBodyPlayerDelegate

extension AVBodyPlaybackViewController: AVBodyPlayerDelegate {
    
    func avBodyPlayer(_ avBodyPlayer: AVBodyPlayer, process joints: [String : Any]) {
        if let floats = joints["anchor"] as? [Float] {
            robotNode.transform = SCNMatrix4(rowMajor: floats)
        }
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let floats = joints[jointName] as? [Float],
               let childNode = robotNode.childNode(withName: jointName, recursively: true)
            {
                childNode.transform = SCNMatrix4(rowMajor: floats)
            }
        }
    }
    
    func avBodyPlayerDidReachEnd(_ avBodyPlayer: AVBodyPlayer) {
        playButton.isEnabled = true
        pauseButton.isEnabled = false
    }
    
}
