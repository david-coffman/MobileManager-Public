//
//  CodableVoter.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/19/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import Foundation
import CoreData

struct VoterExport: Codable {
    let exportIdentifier: Int
    let exportedVoters: [CodableVoter]
}

struct VoterInteraction: Codable {
    let interactionType: String
    let interactionDate: Date
}

struct CodableVoter: Codable {
    let age: Int16
    let attributedData: [VoterInteraction]
    let birthStateCode: String?
    let congressionalDistrict: Int16
    let county: String?
    let countyCommissioner: String?
    let countyID: Int16
    let fireDistrict: String?
    let firstName: String?
    let genderCode: Int16
    let hasDispatched: Bool
    let hasEngaged: Bool
    let judicialDistrict: String?
    let lastName: String?
    let mailingAddress: String?
    let municipalDistrict: String?
    let municipality: String?
    let partyCode: Int16
    let phoneNumber: Int64
    let raceCode: Int16
    let registrationDate: Date?
    let rescueDistrict: String?
    let residentialAddress: String?
    let sanitationDistrict: String?
    let schoolDistrict: String?
    let sewerDistrict: String?
    let stateCode: Int16
    let stateHouseDistrict: Int16
    let stateSenateDistrict: Int16
    let superiorCourtDistrict: String?
    let township: String?
    let voterHistory: [VoterHistoryEntry]?
    let voterID: Int32
    let ward: String?
    let waterDistrict: String?
    let latitude: Double?
    let longitude: Double?
    
    init?(objectIdentifier: NSManagedObjectID, geoObjectIdentifier: NSManagedObjectID?, histObjectIdentifier: NSManagedObjectID?, managedContext: NSManagedObjectContext) {
        if let cdVoter = managedContext.object(with: objectIdentifier) as? Voter {
            age = cdVoter.age
            if let cdAttributedData = cdVoter.attributedData {
                attributedData = (try? JSONDecoder().decode([VoterInteraction].self, from: cdAttributedData)) ?? []
            }
            else {
                attributedData = []
            }
            birthStateCode = cdVoter.birthStateCode
            congressionalDistrict = cdVoter.congressionalDistrict
            county = cdVoter.county
            countyCommissioner = cdVoter.countyCommissioner
            countyID = cdVoter.countyID
            fireDistrict = cdVoter.fireDistrict
            firstName = cdVoter.firstName
            genderCode = cdVoter.genderCode
            hasDispatched = true
            hasEngaged = false
            judicialDistrict = cdVoter.judicialDistrict
            lastName = cdVoter.lastName
            mailingAddress = cdVoter.mailingAddress
            municipalDistrict = cdVoter.municipalDistrict
            municipality = cdVoter.municipality
            partyCode = cdVoter.partyCode
            phoneNumber = cdVoter.phoneNumber
            raceCode = cdVoter.raceCode
            registrationDate = cdVoter.registrationDate
            rescueDistrict = cdVoter.rescueDistrict
            residentialAddress = cdVoter.residentialAddress
            sanitationDistrict = cdVoter.sanitationDistrict
            schoolDistrict = cdVoter.schoolDistrict
            sewerDistrict = cdVoter.sewerDistrict
            stateCode = cdVoter.stateCode
            stateHouseDistrict = cdVoter.stateHouseDistrict
            stateSenateDistrict = cdVoter.stateSenateDistrict
            superiorCourtDistrict = cdVoter.superiorCourtDistrict
            township = cdVoter.township
            
            if let voterHistoryID = histObjectIdentifier {
                let histObject = managedContext.object(with: voterHistoryID) as! VoterHistory
                voterHistory = try! JSONDecoder().decode([VoterHistoryEntry].self, from: histObject.jsonData!)
            }
            else {
                voterHistory = nil
            }
            voterID = cdVoter.voterID
            ward = cdVoter.ward
            waterDistrict = cdVoter.waterDistrict
            
            if let geoIdentifier = geoObjectIdentifier {
                let geoObject = managedContext.object(with: geoIdentifier) as! VoterLocation
                latitude = geoObject.lat
                longitude = geoObject.lon
            }
            else {
                latitude = nil
                longitude = nil
            }
        }
        else {
            return nil
        }
    }
}
