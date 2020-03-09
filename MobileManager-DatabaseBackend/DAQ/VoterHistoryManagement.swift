//
//  VoterHistoryManagement.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/11/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import Foundation

struct VoterHistoryEntry: Codable {
    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
    
    let electionName: String
    let electionDate: Date
    let votedParty: Int16
    
    init(split: [String.SubSequence]) {
        self.electionName = trimQuotations(split[4])
        self.electionDate = VoterHistoryEntry.dateFormatter.date(from: trimQuotations(split[3]))!
        switch trimQuotations(split[6]) {
        case "REP":
            self.votedParty = 1
        case "DEM":
            self.votedParty = 2
        case "LIB":
            self.votedParty = 3
        case "GRE":
            self.votedParty = 4
        case "CON":
            self.votedParty = 5
        default:
            // Value for unaffiliated voters is 0.
            self.votedParty = 0
        }
    }
}
