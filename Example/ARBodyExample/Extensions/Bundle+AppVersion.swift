//
//  Bundle+AppVersion.swift
//
//  Created by deeje cooley on 12/14/21.
//

import Foundation

extension Bundle {
    
    static var appVersion: String {
        guard let info = Bundle.main.infoDictionary,
            let name = info["CFBundleName"],
            let version = info["CFBundleShortVersionString"],
            let build = info["CFBundleVersion"] else { return "Unable to get version info"}
        
        return "\(name) \(version) (\(build))"
    }
    
}
