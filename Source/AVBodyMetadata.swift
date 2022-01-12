//
//  AVBodyMetadata.swift
//  ARMirror
//
//  Created by deeje cooley on 1/3/22.
//

import CoreMedia
import AVFoundation

public class AVBodyMetadata {
    
    static let specIdentifier = kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String
    static let specType = kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String
    static let identifier = AVMetadataIdentifier.quickTimeMetadataLocationISO6709  // AVMetadataIdentifier("com.deeje.ARMirror.bodyMetadata")
    static let type = kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709 as String    // kCMMetadataBaseDataType_JSON as String
    
}
