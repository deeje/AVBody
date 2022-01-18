//
//  AVBodyRecorder.swift
//  ARMirror
//
//  Created by deeje cooley on 1/4/22.
//

import ARKit
import AVFoundation

public protocol AVBodyRecorderDelegate: NSObject {
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, setupResult: AVBodyRecorder.SessionSetupResult)
    func avBodyRecorder(_ recorder: AVBodyRecorder, isRunning: Bool)
    func avBodyRecorder(_ recorder: AVBodyRecorder, isRecording: Bool)
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, didFinishRecording: URL)
    func avBodyRecorder(_ recorder: AVBodyRecorder, didFailRecording: Error)
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, sessionError: Error)
    func avBodyRecorderSessionInterruped(_ recorder: AVBodyRecorder)
    func avBodyRecorderSessionInterruptionEnded(_ recorder: AVBodyRecorder)
    
}

public class AVBodyRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    public weak var delegate: AVBodyRecorderDelegate?
    
    public enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    public var setupResult: SessionSetupResult = .success {
        didSet {
            guard oldValue != setupResult else { return }
            
            DispatchQueue.main.async { [unowned self] in
                delegate?.avBodyRecorder(self, setupResult: setupResult)
            }
        }
    }
    public var isRunning = false {
        didSet {
            guard oldValue != isRunning else { return }
            
            DispatchQueue.main.async { [unowned self] in
                delegate?.avBodyRecorder(self, isRunning: isRunning)
            }
        }
    }
    public var isRecording = false {
        didSet {
            guard oldValue != isRecording else { return }
            
            DispatchQueue.main.async { [unowned self] in
                delegate?.avBodyRecorder(self, isRecording: isRecording)
            }
        }
    }
    
    private let avCaptureSession = AVCaptureSession()
    private let avCaptureSessionQueue = DispatchQueue(label: "avCaptureSessionQueue", attributes: [], target: nil)
    
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil
        
    private let clock = CMClockGetHostTimeClock()
    
    private var bodyMetadataInput: AVCaptureMetadataInput?
    
    private var avCaptureSessionRunningObserveContext = 0
    
    private var noBody = true
    
    // MARK: - Session Management
    
    public func authorizeSession() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
            
        case .notDetermined:
            avCaptureSessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.avCaptureSessionQueue.resume()
            }
            
        default:
            setupResult = .notAuthorized
        }
        
        avCaptureSessionQueue.async {
            self.configureSession()
        }
    }
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        avCaptureSession.beginConfiguration()
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if avCaptureSession.canAddInput(audioDeviceInput) {
                avCaptureSession.addInput(audioDeviceInput)
            }
            else {
                print("Could not add audio device input to the session")
            }
        }
        catch {
            print("Could not create audio device input: \(error)")
        }
        
        if avCaptureSession.canAddOutput(movieFileOutput) {
            avCaptureSession.addOutput(movieFileOutput)
        } else {
            print("Could not add movie file output to the session")
            setupResult = .configurationFailed
            avCaptureSession.commitConfiguration()
            return
        }
        
        connectMetadataPorts()
        
        avCaptureSession.commitConfiguration()
    }
    
    public func startSession() {
        avCaptureSessionQueue.async {
            if (self.setupResult == .success) {
                // Only set up observers and start running the av session if setup succeeded.
                self.addAVObservers()
                self.avCaptureSession.startRunning()
                self.isRunning = self.avCaptureSession.isRunning
            }
        }
    }
    
    public func stopSession() {
        avCaptureSessionQueue.async {
            if self.setupResult == .success {
                self.avCaptureSession.stopRunning()
                self.removeAVObservers()
            }
        }
    }
    
    public func resumeSession(completion: @escaping ((Bool) -> Void)) {
        avCaptureSessionQueue.async {
            /*
                The session might fail to start running, e.g., if a phone or FaceTime call is still
                using audio or video. A failure to start the session running will be communicated via
                a session runtime error notification. To avoid repeatedly failing to start the session
                running, we only try to restart the session running in the session runtime error handler
                if we aren't trying to resume the session running.
            */
            self.avCaptureSession.startRunning()
            self.isRunning = self.avCaptureSession.isRunning
            
            DispatchQueue.main.async { [unowned self] in
                completion(avCaptureSession.isRunning)
            }
        }
    }
    
    // MARK: - Metadata Support
        
    private func connectMetadataPorts() {
        if !isConnectionActiveWithInputPort(AVBodyMetadata.identifier.rawValue) {
            
            let specs: [String : Any] = [AVBodyMetadata.specIdentifier: AVBodyMetadata.identifier,
                                         AVBodyMetadata.specType: AVBodyMetadata.type]
            
            var bodyMetadataDesc: CMFormatDescription?
            CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [specs] as CFArray, formatDescriptionOut: &bodyMetadataDesc)
            
            let newBodyMetadataInput = AVCaptureMetadataInput(formatDescription: bodyMetadataDesc!, clock: CMClockGetHostTimeClock())
            avCaptureSession.addInputWithNoConnections(newBodyMetadataInput)
            
            let inputPort = newBodyMetadataInput.ports[0]
            avCaptureSession.addConnection(AVCaptureConnection(inputPorts: [inputPort], output: movieFileOutput))
            
            bodyMetadataInput = newBodyMetadataInput
        }
    }
    
    private func isConnectionActiveWithInputPort(_ portType: String) -> Bool {
        for connection in movieFileOutput.connections {
            for inputPort in connection.inputPorts {
                if let formatDescription = inputPort.formatDescription, CMFormatDescriptionGetMediaType(formatDescription) == kCMMediaType_Metadata {
                    if let metadataIdentifiers = CMMetadataFormatDescriptionGetIdentifiers(inputPort.formatDescription!) as NSArray? {
                        if metadataIdentifiers.contains(portType) {
                            return connection.isActive
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    // MARK: - Recording Movies
    
    public func toggleRecording() {
        avCaptureSessionQueue.async { [unowned self] in
            if !self.movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    /*
                        Set up background task.
                        This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
                        callback is not received until AVCam returns to the foreground unless you request background execution time.
                        This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                        To conclude this background execution, endBackgroundTask(_:) is called in
                        `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
                    */
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                                
                // Start recording to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString)
                                        .appendingPathComponent((outputFileName as NSString)
                                        .appendingPathExtension("mov")!)
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            }
            else
            {
                self.isRecording = false
                self.movieFileOutput.stopRecording()
            }
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.isRecording = true
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?)
    {
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
            
            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }

        isRecording = false
        
        DispatchQueue.main.async { [unowned self] in
            if success {
                delegate?.avBodyRecorder(self, didFinishRecording: outputFileURL)
            } else {
                delegate?.avBodyRecorder(self, didFailRecording: error!)
            }
        }
    }
    
    // MARK: - KVO and Notifications
        
    private func addAVObservers() {
        avCaptureSession.addObserver(self, forKeyPath: "running", options: .new, context: &avCaptureSessionRunningObserveContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(avSessionRuntimeError),name: NSNotification.Name.AVCaptureSessionRuntimeError, object: avCaptureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(avSessionWasInterrupted(notification:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: avCaptureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(avSessionInterruptionEnded(notification:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: avCaptureSession)
    }
    
    private func removeAVObservers() {
        NotificationCenter.default.removeObserver(self)
        
        avCaptureSession.removeObserver(self, forKeyPath: "running", context: &avCaptureSessionRunningObserveContext)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &avCaptureSessionRunningObserveContext {
            guard let isSessionRunning = change?[.newKey] as? Bool else { return }
            
            isRunning = isSessionRunning
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc func avSessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
            Automatically try to restart the session running if media services were
            reset and the last start running succeeded. Otherwise, enable the user
            to try to resume the session running.
        */
        if error.code == .mediaServicesWereReset {
            avCaptureSessionQueue.async { [unowned self] in
                if self.isRunning {
                    self.avCaptureSession.startRunning()
                    self.isRunning = self.avCaptureSession.isRunning
                }
                else {
                    DispatchQueue.main.async { [unowned self] in
                        delegate?.avBodyRecorder(self, sessionError: error)
                    }
                }
            }
        }
        else {
            DispatchQueue.main.async { [unowned self] in
                delegate?.avBodyRecorder(self, sessionError: error)
            }
        }
    }
    
    @objc
    private func avSessionWasInterrupted(notification: NSNotification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            
            if reason == AVCaptureSession.InterruptionReason.audioDeviceInUseByAnotherClient || reason == AVCaptureSession.InterruptionReason.videoDeviceInUseByAnotherClient {
                DispatchQueue.main.async { [unowned self] in
                    delegate?.avBodyRecorderSessionInterruped(self)
                }
            }
        }
    }
    
    @objc
    private func avSessionInterruptionEnded(notification: NSNotification) {
        DispatchQueue.main.async { [unowned self] in
            delegate?.avBodyRecorderSessionInterruptionEnded(self)
        }
    }
    
    // MARK: - Recording Body
    
    public func capture(from anchors: [ARAnchor]) {
        guard isRecording else { return }
        
        let timeRange = CMTimeRangeMake(start: CMClockGetTime(clock), duration: CMTime.invalid)
        var items: [AVMutableMetadataItem]?
        
        if let bodyAnchor = anchors.filter({ $0 is ARBodyAnchor }).first as? ARBodyAnchor
        {
            noBody = false
            
            let newBodyMetadataItem = AVMutableMetadataItem()
            newBodyMetadataItem.identifier = AVBodyMetadata.identifier
            newBodyMetadataItem.dataType = AVBodyMetadata.type
            
            var joints : [String : Any] = [:]
            
            let root = SCNMatrix4.init(bodyAnchor.transform)
            let floats = root.rowMajorArray
            joints["root"] = floats
            
            for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
                let joint = ARSkeleton.JointName(rawValue: jointName)
                if let transform = bodyAnchor.skeleton.localTransform(for: joint) {
                    let floats = transform.rowMajorArray
                    joints[jointName] = floats
                }
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: joints, options: [.prettyPrinted])
            {
                newBodyMetadataItem.value = jsonData as NSData
            }
            
            items = [newBodyMetadataItem]
        } else if !noBody {
            noBody = true
            
            items = []
        }
        
        if let items = items {
            avCaptureSessionQueue.async {
                if self.movieFileOutput.isRecording {
                    let metadataItemGroup = AVTimedMetadataGroup(items: items, timeRange: timeRange)
                    do {
                        try self.bodyMetadataInput?.append(metadataItemGroup)
                    }
                    catch {
                        print("Could not add timed metadata group: \(error)")
                    }
                }
            }
        }
    }
    
}
