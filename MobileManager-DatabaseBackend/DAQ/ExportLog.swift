//
//  ExportLog.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/19/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import Foundation

struct ExportLog: Codable {
    struct ExportEntry: Codable {
        let stateCode: Int16
        let voterID: Int32
    }
    
    let exportIdentifier: Int
    let exportedTo: String
    let exportedOn: Date
    var exportEntries: [ExportEntry]
}

