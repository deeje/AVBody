//
//  AVBodyRecorder.swift
//  AVBody
//
//  Created by deeje cooley on 1/4/22.
//

import ARKit
import AVFoundation

public protocol AVBodyRecorderDelegate: NSObject {
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, isRecording: Bool)
    
    func avBodyRecorder(_ recorder: AVBodyRecorder, didFinishRecording: URL)
    func avBodyRecorder(_ recorder: AVBodyRecorder, didFailRecording: Error)
    
}

public class AVBodyRecorder: NSObject {
    
    public weak var delegate: AVBodyRecorderDelegate?
    
    public var isRecording = false {
        didSet {
            guard oldValue != isRecording else { return }
            
            DispatchQueue.main.async { [unowned self] in
                delegate?.avBodyRecorder(self, isRecording: isRecording)
            }
        }
    }
    
    private let clock = CMClockGetHostTimeClock()
    
    private var assetWriter: AVAssetWriter!
    
    private var videoInput: AVAssetWriterInput!
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
        
    private var bodyMetadataInput: AVAssetWriterInput!
    private var bodyMetadataInputAdaptor: AVAssetWriterInputMetadataAdaptor!
        
    private var noBody = true
    
    public func startRecording() {
        func getVideoTransform() -> CGAffineTransform {
            switch UIDevice.current.orientation {
            case .portrait:
                return .identity
            case .portraitUpsideDown:
                return CGAffineTransform(rotationAngle: .pi)
            case .landscapeLeft:
                return CGAffineTransform(rotationAngle: .pi/2)
            case .landscapeRight:
                return CGAffineTransform(rotationAngle: -.pi/2)
            default:
                return .identity
            }
        }
        
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString)
                                .appendingPathComponent((outputFileName as NSString)
                                .appendingPathExtension("mov")!)
        let outputURL = URL(fileURLWithPath: outputFilePath)
        
        assetWriter = try! AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let canvasSize = CGSize(width: 640, height: 480)
        let videoSettings: [String : AnyObject] = [
            AVVideoCodecKey  : AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey  : canvasSize.width as AnyObject,
            AVVideoHeightKey : canvasSize.height as AnyObject,
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        videoInput?.transform = getVideoTransform()
        assetWriter.add(videoInput)
        
        let sourceBufferAttributes = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
            (kCVPixelBufferWidthKey as String): Float(canvasSize.width),
            (kCVPixelBufferHeightKey as String): Float(canvasSize.height)] as [String : Any]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput,
                                                                  sourcePixelBufferAttributes: sourceBufferAttributes)
        
        let specs: [String : Any] = [AVBodyMetadata.specIdentifier: AVBodyMetadata.identifier,
                                     AVBodyMetadata.specType: AVBodyMetadata.type]
        var bodyMetadataDesc: CMFormatDescription?
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [specs] as CFArray, formatDescriptionOut: &bodyMetadataDesc)
        
        bodyMetadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: bodyMetadataDesc)
        bodyMetadataInput.expectsMediaDataInRealTime = true;
        bodyMetadataInput.addTrackAssociation(withTrackOf: videoInput, type: AVAssetTrack.AssociationType.metadataReferent.rawValue)
        assetWriter.add(bodyMetadataInput)
        
        bodyMetadataInputAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: bodyMetadataInput)
        
        if assetWriter.startWriting() {
            assetWriter.startSession(atSourceTime: CMClockGetTime(clock))
            
            isRecording = true
        }
    }
    
    public func stopRecording() {
        isRecording = false
        
        videoInput.markAsFinished()
        assetWriter.finishWriting {
            DispatchQueue.main.async { [unowned self] in
                delegate?.avBodyRecorder(self, didFinishRecording: assetWriter.outputURL)
            }
        }
    }
    
    public func capture(from frame: ARFrame) {
        guard isRecording else { return }
                
        let time = CMClockGetTime(clock)
        
        capture(pixelBuffer: frame.capturedImage, at: time)
        capture(anchors: frame.anchors, at: time)
    }
    
    private func capture(pixelBuffer: CVPixelBuffer, at time: CMTime) {
        guard videoInput.isReadyForMoreMediaData else { return }
        
        let _ = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: time)
    }
    
    private func capture(anchors: [ARAnchor], at time: CMTime) {
        guard bodyMetadataInput.isReadyForMoreMediaData else { return }
        
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
            joints["anchor"] = floats
            
            let skeleton = bodyAnchor.skeleton
            let definition = skeleton.definition
            for jointName in definition.jointNames {
                let joint = ARSkeleton.JointName(rawValue: jointName)
                let jointIndex = definition.index(for: joint)
                let isTracked = skeleton.isJointTracked(jointIndex)
                if isTracked, let transform = bodyAnchor.skeleton.localTransform(for: joint) {
                    let floats = transform.rowMajorArray
                    joints[jointName] = floats
                }
            }
            
            let jointsValue = joints as (NSObject & NSCopying)
            newBodyMetadataItem.value = jointsValue
            
            items = [newBodyMetadataItem]
        } else if !noBody {
            noBody = true
            
            items = []
        }
        
        if let items = items {
            let timeRange = CMTimeRangeMake(start: time, duration: CMTime.invalid)
            let metadataItemGroup = AVTimedMetadataGroup(items: items, timeRange: timeRange)
            bodyMetadataInputAdaptor.append(metadataItemGroup)
        }
    }
    
}
