//
//  AVBodyMetadata.swift
//  AVBody
//
//  Created by deeje cooley on 1/3/22.
//

import CoreMedia
import AVFoundation

public class AVBodyMetadata {
    
    static let specIdentifier = kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String
    static let specType = kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String
    static let identifier = AVMetadataIdentifier("mdta/com.deeje.ARBody.metadata")
    static let type = kCMMetadataBaseDataType_JSON as String
    
}
