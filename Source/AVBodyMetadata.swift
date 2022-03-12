//
//  AVBodyMetadata.swift
//  AVBody
//
//  Created by deeje cooley on 1/3/22.
//

import CoreMedia
import AVFoundation

public class AVBodyMetadata {
    
    static public let specIdentifier = kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String
    static public let specType = kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String
    static public let identifier = AVMetadataIdentifier("mdta/com.deeje.ARBody.metadata")
    static public let type = kCMMetadataBaseDataType_JSON as String
    
}
