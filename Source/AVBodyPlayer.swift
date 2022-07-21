//
//  AVBodyPlayer.swift
//  AVBody
//
//  Created by deeje cooley on 3/9/22.
//

import AVFoundation

public protocol AVBodyPlayerDelegate: NSObject {
    
    func avBodyPlayer(_ avBodyPlayer: AVBodyPlayer, process joints: [String: Any])
    
}

public class AVBodyPlayer: AVPlayer, AVPlayerItemMetadataOutputPushDelegate {
    
    public weak var bodyDelegate: AVBodyPlayerDelegate?
    
    private let bodyMetadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
    
    public convenience init(bodyPlayerItem item: AVPlayerItem?) {
        self.init(playerItem: item)
        
        item?.add(bodyMetadataOutput)
        
        let metadataQueue = DispatchQueue(label: "bodyMetadataPlaybackQeue", attributes: [])
        bodyMetadataOutput.setDelegate(self, queue: metadataQueue)
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
                for metadataItem in metadataGroup.items {
                    guard let itemIdentifier = metadataItem.identifier, let itemDataType = metadataItem.dataType else {
                        continue
                    }
                    
                    switch itemIdentifier {
                    case AVBodyMetadata.identifier:
                        if itemDataType == String(AVBodyMetadata.type) {
                            guard let joints = metadataItem.value as? [String: Any]
                             else { return }
                            
                            bodyDelegate?.avBodyPlayer(self, process: joints)
                        }
                        
                        default:
//                            print("Timed metadata: unrecognized metadata identifier \(itemIdentifier)")
                            break
                    }
                }
            }
        }
    }
    
}
