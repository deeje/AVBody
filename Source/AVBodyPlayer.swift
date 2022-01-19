//
//  AVBodyPlayer.swift
//  AVBody
//
//  Created by deeje cooley on 1/11/22.
//

import AVFoundation

extension AVAssetTrack {
    
    func has(metadataIdentifier: String) -> Bool {
        let formatDescription = formatDescriptions[0] as! CMFormatDescription
        if let metadataIdentifiers = CMMetadataFormatDescriptionGetIdentifiers(formatDescription) as NSArray? {
            if metadataIdentifiers.contains(metadataIdentifier) {
                return true
            }
        }
        return false
    }
    
}

public protocol AVBodyPlayerDelegate: NSObject {
    
    func avBodyPlayer(_ avBodyPlayer: AVBodyPlayer, process joints: [String: Any])
    func avBodyPlayerDidReachEnd(_ avBodyPlayer: AVBodyPlayer)
    
}

public class AVBodyPlayer: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    
    public weak var delegate: AVBodyPlayerDelegate?
    
    private let player: AVPlayer
    private let bodyMetadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
    private var seekToZeroBeforePlay = false
    
    public var isPlaying: Bool {
        get {
            return player.timeControlStatus != .paused
        }
    }
    
    public init(url: URL) {
        let asset = AVAsset(url: url)
        let mutableComposition = AVMutableComposition()
        for metadataTrack in asset.tracks(withMediaType: .metadata) {
            if metadataTrack.has(metadataIdentifier: AVBodyMetadata.identifier.rawValue) {
                let bodyMetadataTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.metadata,
                                                                           preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try bodyMetadataTrack!.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration),
                                                           of: metadataTrack,
                                                           at: CMTime.zero)
                }
                catch let error as NSError {
                    print("Could not insert time range into metadata mutable composition: \(error)")
                }
            }
        }
        let playerItem = AVPlayerItem(asset: mutableComposition)
        playerItem.add(bodyMetadataOutput)
        self.player = AVPlayer(playerItem: playerItem)
        
        super.init()
    }
    
    public func prepare() {
        let metadataQueue = DispatchQueue(label: "bodyMetadataPlaybackQeue", attributes: [])
        bodyMetadataOutput.setDelegate(self, queue: metadataQueue)
        
        player.actionAtItemEnd = .none
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    public func play() {
        if seekToZeroBeforePlay {
            seekToZeroBeforePlay = false
            player.seek(to: CMTime.zero)
        }
        
        player.play()
    }
    
    public func pause() {
        player.pause()
    }
    
    /// Called when the player item has played to its end time.
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        // After the movie has played to its end time, seek back to time zero to play it again.
        seekToZeroBeforePlay = true
        
        delegate?.avBodyPlayerDidReachEnd(self)
    }
    
    // MARK: - Playback Body
        
    public func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?)
    {
        for metadataGroup in groups {
            if metadataGroup.items.count == 0 {
                // TODO: handle intervals where no body exists
            }
            else {
                for metdataItem in metadataGroup.items {
                    guard let itemIdentifier = metdataItem.identifier, let itemDataType = metdataItem.dataType else {
                        continue
                    }
                    
                    switch itemIdentifier {
                    case AVBodyMetadata.identifier:
                        if itemDataType == String(AVBodyMetadata.type) {
                            guard let joints = metdataItem.value as? [String: Any]
                             else { return }
                            
                            delegate?.avBodyPlayer(self, process: joints)
                        }
                        
                        default:
                            print("Timed metadata: unrecognized metadata identifier \(itemIdentifier)")
                    }
                }
            }
        }
    }
    
}
