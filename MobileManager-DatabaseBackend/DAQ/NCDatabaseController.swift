//
//  NCDatabaseController.swift
//  CoreDataDriver
//
//  Created by David Coffman on 7/11/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class NCDatabaseController {
    var appDelegate: AppDelegate!
    // Define state code constant. NC = 0. More identifiers to be assigned as app gains support for other states.
    let stateCode: Int16 = 0
    
    enum RequestType {
        case voter
        case history
        case geo
    }
    
    // MARK: -- func process(...)
    
    func process(voterFilePath: URL, geoFilePath: URL, voterHistoryPath: URL, countyID: Int16, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            print("Unpacking into database.")
            self.appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            
            let stateCode = self.stateCode
            
            let completionGroup = DispatchGroup()
            completionGroup.enter()
            completionGroup.enter()
            completionGroup.enter()
            
            // Process voter file data.
            DispatchQueue.global(qos: .userInitiated).async {
                let managedContext = self.appDelegate.persistentContainer.newBackgroundContext()
                // Configure StreamReader.
                let voterReader = StreamReader(path: voterFilePath.relativePath)!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                // Select Voter as entity of interest.
                let voterEntity = NSEntityDescription.entity(forEntityName: "Voter", in: managedContext)!
                
                // Skip the header line, set zero-indexed first line.
                var line = voterReader.nextLine()!
                line = voterReader.nextLine() ?? ""
                
                // Retry in edge case that first line (or three) is malformed.
                if line == "" {
                    line = voterReader.nextLine() ?? ""
                    if line == "" {
                        line = voterReader.nextLine() ?? ""
                        if line == "" {
                            line = voterReader.nextLine() ?? ""
                        }
                    }
                }
                
                var lineNum = 1
                
                while line != "" {
                    autoreleasepool {
                        while lineNum % 10000 != 0 && line != "" {
                            // Split tab-delimited text.
                            let split = line.split(separator: "\t")
                            
                            // Create a Voter object.
                            let voter = NSManagedObject(entity: voterEntity, insertInto: managedContext)
                            
                            
                            // Configure the Voter.
                            voter.setValue(Int16(stateCode), forKey: "stateCode")
                            voter.setValue(Int16(countyID), forKey: "countyID")
                            voter.setValue(trimQuotations(split[1]), forKey: "county")
                            voter.setValue(Int32(trimQuotations(split[2]))!, forKey: "voterID")
                            if trimQuotations(split[3]) == "A" {
                                voter.setValue(true, forKey: "registrationIsActive")
                            }
                            else {
                                voter.setValue(false, forKey: "registrationIsActive")
                            }
                            voter.setValue(trimQuotations(split[9]), forKey: "lastName")
                            voter.setValue(trimQuotations(split[10]), forKey: "firstName")
                            voter.setValue(split[14...16].map(trimQuotations).reduce(trimQuotations(split[13]), {$0 + " " + $1}), forKey: "residentialAddress")
                            voter.setValue(split[21...23].map(trimQuotations).reduce(trimQuotations(split[17]), {$0 + " " + $1}), forKey: "mailingAddress")
                            voter.setValue(Int64(trimQuotations(split[24])), forKey: "phoneNumber")
                            switch trimQuotations(split[25]) {
                            case "B":
                                voter.setValue(Int16(0), forKey: "raceCode")
                            case "I":
                                voter.setValue(Int16(1), forKey: "raceCode")
                            case "O":
                                voter.setValue(Int16(2), forKey: "raceCode")
                            case "W":
                                voter.setValue(Int16(3), forKey: "raceCode")
                            case "A":
                                voter.setValue(Int16(4), forKey: "raceCode")
                            case "M":
                                voter.setValue(Int16(5), forKey: "raceCode")
                            default:
                                // applies to case "U" -- undesignated.
                                voter.setValue(Int16(6), forKey: "raceCode")
                            }
                            switch trimQuotations(split[27]) {
                            case "REP":
                                voter.setValue(Int16(1), forKey: "partyCode")
                            case "DEM":
                                voter.setValue(Int16(2), forKey: "partyCode")
                            case "LIB":
                                voter.setValue(Int16(3), forKey: "partyCode")
                            case "GRE":
                                voter.setValue(Int16(4), forKey: "partyCode")
                            case "CON":
                                voter.setValue(Int16(5), forKey: "partyCode")
                            default:
                                // Value for unaffiliated voters is 0.
                                voter.setValue(Int16(0), forKey: "partyCode")
                            }
                            switch trimQuotations(split[28]) {
                            case "M":
                                voter.setValue(Int16(1), forKey: "genderCode")
                            case "F":
                                voter.setValue(Int16(2), forKey: "genderCode")
                            default:
                                voter.setValue(Int16(0), forKey: "genderCode")
                            }
                            voter.setValue(Int16(trimQuotations(split[29])), forKey: "age")
                            voter.setValue(trimQuotations(split[30]), forKey: "birthStateCode")
                            voter.setValue(dateFormatter.date(from: trimQuotations(split[32])), forKey: "registrationDate")
                            voter.setValue(trimQuotations(split[34]), forKey: "municipality")
                            voter.setValue(trimQuotations(split[38]), forKey: "ward")
                            voter.setValue(Int16(trimQuotations(split[39])), forKey: "congressionalDistrict")
                            voter.setValue(trimQuotations(split[40]), forKey: "superiorCourtDistrict")
                            voter.setValue(trimQuotations(split[41]), forKey: "judicialDistrict")
                            voter.setValue(Int16(trimQuotations(split[42])), forKey: "stateSenateDistrict")
                            voter.setValue(Int16(trimQuotations(split[43])), forKey: "stateHouseDistrict")
                            voter.setValue(trimQuotations(split[45]), forKey: "countyCommissioner")
                            voter.setValue(trimQuotations(split[47]), forKey: "township")
                            voter.setValue(trimQuotations(split[49]), forKey: "schoolDistrict")
                            voter.setValue(trimQuotations(split[51]), forKey: "fireDistrict")
                            voter.setValue(trimQuotations(split[53]), forKey: "waterDistrict")
                            voter.setValue(trimQuotations(split[55]), forKey: "sewerDistrict")
                            voter.setValue(trimQuotations(split[57]), forKey: "sanitationDistrict")
                            voter.setValue(trimQuotations(split[59]), forKey: "rescueDistrict")
                            voter.setValue(trimQuotations(split[61]), forKey: "municipalDistrict")
                            voter.setValue(false, forKey: "hasDispatched")
                            voter.setValue(false, forKey: "hasEngaged")
                            
                            line = voterReader.nextLine() ?? ""
                            
                            // Retry in case a line (or three) is malformed.
                            if line == "" {
                                line = voterReader.nextLine() ?? ""
                                if line == "" {
                                    line = voterReader.nextLine() ?? ""
                                    if line == "" {
                                        line = voterReader.nextLine() ?? ""
                                    }
                                }
                            }
                            if line == "" {
                                try! managedContext.save()
                                managedContext.reset()
                            }
                            lineNum += 1
                        }
                    }
                    print("Saved context.")
                    try! managedContext.save()
                    managedContext.reset()
                    lineNum += 1
                    
                }
                // Final write.
                try! managedContext.save()
                voterReader.close()
                completionGroup.leave()
                
                print("Done (2/3)!")
            }
            
            // Now process corresponding geo data.
            DispatchQueue.global(qos: .userInitiated).async {
                let managedContext = self.appDelegate.persistentContainer.newBackgroundContext()
                let geoReader = StreamReader(path: geoFilePath.relativePath)!
                
                var line = geoReader.nextLine() ?? ""
                var lineNum = 1
                
                while line != "" {
                    autoreleasepool {
                        while lineNum % 10000 != 0 && line != "" {
                            let split = line.split(separator: ",")
                            let voterGeoObj = VoterLocation(context: managedContext)
                            voterGeoObj.voterID = Int32(split[0])!
                            if split[1].contains("-") {
                                voterGeoObj.lat = Double(split[1].replacingOccurrences(of: "-", with: ""))! * -1.0
                            }
                            else {
                                voterGeoObj.lat = Double(split[1])!
                            }
                            if split[2].contains("-") {
                                voterGeoObj.lon = Double(split[2].replacingOccurrences(of: "-", with: ""))! * -1.0
                            }
                            else {
                                voterGeoObj.lon = Double(split[2])!
                            }
                            line = geoReader.nextLine() ?? ""
                            voterGeoObj.stateCode = stateCode
                            voterGeoObj.districtIdentifier = countyID
                            lineNum += 1
                            if line == "" {
                                try! managedContext.save()
                                managedContext.reset()
                            }
                        }
                    }
                    print("Saved context.")
                    try! managedContext.save()
                    managedContext.reset()
                    lineNum += 1
                }
                try! managedContext.save()
                geoReader.close()
                completionGroup.leave()
                print("Done (1/3)!")
            }
            
            // Now process corresponding voter history data.
            DispatchQueue.global(qos: .userInitiated).async {
                let managedContext = self.appDelegate.persistentContainer.newBackgroundContext()
                let historyReader = StreamReader(path: voterHistoryPath.relativePath)!
                let encoder = JSONEncoder()
                
                var line = historyReader.nextLine() ?? ""
                line = historyReader.nextLine() ?? ""
                
                // Retry in edge case that first line (or three) is malformed.
                if line == "" {
                    line = historyReader.nextLine() ?? ""
                    if line == "" {
                        line = historyReader.nextLine() ?? ""
                        if line == "" {
                            line = historyReader.nextLine() ?? ""
                        }
                    }
                }
                
                var activeVoter: Int32 = 0
                var numberOfVotersProcessed = 0
                var thisVoterHistory = [VoterHistoryEntry]()
                
                while line != "" {
                    autoreleasepool{
                        while (numberOfVotersProcessed % 10000 != 0) && (line != "") {
                            let split = line.split(separator: "\t")
                            let thisVoter = Int32(trimQuotations(split[2]))!
                            if activeVoter == thisVoter {
                                thisVoterHistory.append(VoterHistoryEntry(split: split))
                            }
                            else {
                                let thisVoterHistoryObj = VoterHistory(context: managedContext)
                                thisVoterHistoryObj.voterID = activeVoter
                                thisVoterHistoryObj.jsonData = try! encoder.encode(thisVoterHistory)
                                thisVoterHistoryObj.districtIdentifier = countyID
                                thisVoterHistoryObj.stateCode = stateCode
                                activeVoter = thisVoter
                                thisVoterHistory.removeAll()
                                numberOfVotersProcessed += 1
                            }
                            
                            line = historyReader.nextLine() ?? ""
                            
                            // Retry in case that a line (or three) is malformed.
                            if line == "" {
                                line = historyReader.nextLine() ?? ""
                                if line == "" {
                                    line = historyReader.nextLine() ?? ""
                                    if line == "" {
                                        line = historyReader.nextLine() ?? ""
                                    }
                                }
                            }
                            if line == "" {
                                try! managedContext.save()
                                managedContext.reset()
                            }
                        }
                    }
                    print("Saved context.")
                    try! managedContext.save()
                    managedContext.reset()
                    numberOfVotersProcessed += 1
                }
                let thisVoterHistoryObj = VoterHistory(context: managedContext)
                thisVoterHistoryObj.voterID = activeVoter
                thisVoterHistoryObj.jsonData = try! encoder.encode(thisVoterHistory)
                thisVoterHistoryObj.districtIdentifier = countyID
                thisVoterHistoryObj.stateCode = stateCode
                try! managedContext.save()
                historyReader.close()
                completionGroup.leave()
                print("Done (3/3)!")
            }
            completionGroup.notify(queue: .main) {completion()}
        }
    }
    
    // MARK: -- func delete(...)
    
    func delete(requestType: RequestType, withPredicate: NSPredicate?) {
        DispatchQueue.main.async {
            self.appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            DispatchQueue.global(qos: .userInitiated).async {
                let managedContext = self.appDelegate.persistentContainer.newBackgroundContext()
                let stateCodePredicate = NSPredicate(format: "stateCode == %d", Int16(0))
                switch requestType {
                    
                case .voter:
                    let voterRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Voter")
                    if let withPredicate = withPredicate {
                        voterRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [withPredicate,stateCodePredicate])
                    }
                    else {
                        voterRequest.predicate = stateCodePredicate
                    }
                    let voterDeleteRequest = NSBatchDeleteRequest(fetchRequest: voterRequest)
                    try! managedContext.execute(voterDeleteRequest)
                    
                case .geo:
                    let geoRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VoterLocation")
                    if let withPredicate = withPredicate {
                        geoRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [withPredicate,stateCodePredicate])
                    }
                    else {
                        geoRequest.predicate = stateCodePredicate
                    }
                    let geoDeleteRequest = NSBatchDeleteRequest(fetchRequest: geoRequest)
                    try! managedContext.execute(geoDeleteRequest)
                    
                case .history:
                    let historyRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VoterHistory")
                    if let withPredicate = withPredicate {
                        historyRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [withPredicate,stateCodePredicate])
                    }
                    else {
                        historyRequest.predicate = stateCodePredicate
                    }
                    let historyDeleteRequest = NSBatchDeleteRequest(fetchRequest: historyRequest)
                    try! managedContext.execute(historyDeleteRequest)
                }
                try! managedContext.save()
                print("Finished batch delete.")
            }
        }
    }
}

