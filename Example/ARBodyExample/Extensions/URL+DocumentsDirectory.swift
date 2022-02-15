//
//  URL+DocumentsDirectory.swift
//
//  Created by deeje cooley on 12/14/21.
//

import Foundation

extension URL {
    
    static func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
}
