//
//  AVBodyRecorderViewController.swift
//  AVBodyExample
//
//  Created by deeje cooley on 12/14/21.
//

import UIKit
import ARKit
import AVFoundation
import AVBody

class AVBodyRecorderViewController : UIViewController, Storyboarded {
    
    let arBodyViewController: ARBodyViewController
    
    @IBOutlet private weak var recordButton: UIButton!
    
    private let avBodyRecorder: AVBodyRecorder
    
    // MARK: - View Controller Life Cycle
    
    init?(coder: NSCoder, arBodyViewController: ARBodyViewController) {
        self.arBodyViewController = arBodyViewController
        
        self.avBodyRecorder = AVBodyRecorder()
        
        super.init(coder: coder)
        
        avBodyRecorder.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButton.isEnabled = true
    }
    
    // MARK: - IBActions
        
    @IBAction func recordButtonTapped(_ recordButton: UIButton) {
        recordButton.isEnabled = false
        
        if avBodyRecorder.isRecording {
            avBodyRecorder.stopRecording()
        } else {
            avBodyRecorder.startRecording(withAudio: arBodyViewController.configuration.providesAudioData)
        }
    }
    
}

// MARK: - Recording Body

extension AVBodyRecorderViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        avBodyRecorder.capture(from: frame)
    }
    
    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        avBodyRecorder.capture(from: audioSampleBuffer)
    }
    
}

// MARK: - AVBodyAssetRecorderDelegate

extension AVBodyRecorderViewController: AVBodyRecorderDelegate {
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, isRecording: Bool) {
        recordButton.isEnabled = true
        
        let title = !isRecording ?
            NSLocalizedString("Record", comment: "Recording button record title") :
            NSLocalizedString("Stop", comment: "Stop button record title")
        recordButton.setTitle(title, for: [])
    }
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, didFinishRecording url: URL) {
        arBodyViewController.didFinishRecording(at: url)
        
        recordButton.isEnabled = true
    }
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, didFailRecording: Error) {
        recordButton.isEnabled = true
    }
    
}
