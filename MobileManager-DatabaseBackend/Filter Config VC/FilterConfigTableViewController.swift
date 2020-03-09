//
//  FilterConfigTableViewController.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/13/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit
import CoreLocation

enum FilterMode {
    case party
    case gender
    case age
    case phoneAvailable
    case congressionalDistrict
    case stateHouseDistrict
    case stateSenateDistrict
    case race
}

class Filter: Codable {
    static private let filterPath = documentPath.appendingPathComponent("savedFilter").appendingPathExtension("json")
    
    var parties: [Int16]?
    var genders: [Int16]?
    var races: [Int16]?
    var ageMax: Int16?
    var ageMin: Int16?
    var congressionalDistricts: [Int16]?
    var stateHouseDistricts: [Int16]?
    var stateSenateDistricts: [Int16]?
    var phoneAvailable: Bool?
    var distMax: Double?
    var locationCenterLat: Double?
    var locationCenterLon: Double?
    
    init() {
        races = nil
        parties = nil
        genders = nil
        ageMax = nil
        ageMin = nil
        congressionalDistricts = nil
        stateHouseDistricts = nil
        stateSenateDistricts = nil
        phoneAvailable = nil
        distMax = nil
        locationCenterLat = nil
        locationCenterLon = nil
    }
    
    func save() {
        try! JSONEncoder().encode(self).write(to: Filter.filterPath)
    }
    
    func generatePredicate() -> NSPredicate? {
        var predicates = [NSPredicate]()
        if let parties = parties {
            predicates.append(NSPredicate(format: "partyCode IN %@", parties))
        }
        if let genders = genders {
            predicates.append(NSPredicate(format: "genderCode IN %@", genders))
        }
        if let ageMin = ageMin {
            if ageMin != 0 {predicates.append(NSPredicate(format: "age >= %d", ageMin))}
        }
        if let ageMax = ageMax {
            if ageMax != 0 {predicates.append(NSPredicate(format: "age <= %d", ageMax))}
        }
        if let races = races {
            predicates.append(NSPredicate(format: "raceCode IN %@", races))
        }
        if let phoneAvailable = phoneAvailable {
            if phoneAvailable {
                predicates.append(NSPredicate(format: "phoneNumber != %d", Int64(0)))
            }
            else {
                predicates.append(NSPredicate(format: "phoneNumber == %d", Int64(0)))
            }
        }
        if let congressionalDistricts = congressionalDistricts {
            predicates.append(NSPredicate(format: "congressionalDistrict IN %@", congressionalDistricts))
        }
        if let stateHouseDistricts = stateHouseDistricts {
            predicates.append(NSPredicate(format: "stateHouseDistrict IN %@", stateHouseDistricts))
        }
        if let stateSenateDistricts = stateSenateDistricts {
            predicates.append(NSPredicate(format: "stateSenateDistrict IN %@", stateSenateDistricts))
        }
        
        switch predicates.count {
        case 0:
            return nil
        case 1:
            return predicates.first!
        default:
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }
    
    func generateGeoPredicates() -> NSPredicate? {
        var predicates = [NSPredicate]()
        
        if let lat = locationCenterLat, let lon = locationCenterLon, let distMax = distMax {
            let earthRadius = 3959.0
            let conversionFactor = Double.pi/180.0
            let icf = 180.0/Double.pi
            let topLeft = CLLocationCoordinate2D(latitude: lat+icf*distMax/(earthRadius), longitude: lon - icf*distMax / (earthRadius * cos(lat*conversionFactor)))
            let bottomRight = CLLocationCoordinate2D(latitude: lat-icf*distMax/(earthRadius), longitude: lon + icf*distMax/(earthRadius * cos(lat*conversionFactor)))
            predicates.append(NSPredicate(format: "lat <= %d AND lat >= %d", argumentArray: [topLeft.latitude,bottomRight.latitude]))
            predicates.append(NSPredicate(format: "lon <= %d AND lon >= %d", argumentArray: [bottomRight.longitude,topLeft.longitude]))
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        else {return nil}
    }
    
    static func retrieveSavedFilter() -> Filter? {
        if let retrievedFilter = try? JSONDecoder().decode(Filter.self, from: Data(contentsOf: filterPath)) {
            return retrievedFilter
        }
        else {return nil}
    }
}

class FilterConfigTableViewController: UITableViewController {
    
    @IBOutlet var partyAffiliationSelected: UILabel!
    @IBOutlet var genderSelected: UILabel!
    @IBOutlet var ageMinField: UITextField!
    @IBOutlet var ageMaxField: UITextField!
    @IBOutlet var phoneAvailabilitySelected: UILabel!
    @IBOutlet var congressionalDistrictsSelected: UILabel!
    @IBOutlet var stateSenateDistrictsSelected: UILabel!
    @IBOutlet var stateHouseDistrictsSelected: UILabel!
    @IBOutlet var racesSelected: UILabel!
    @IBOutlet var distanceFilterLabel: UILabel!
    var filter: Filter?
    var willEditParameter: FilterMode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for k in [partyAffiliationSelected, genderSelected, phoneAvailabilitySelected, congressionalDistrictsSelected, stateSenateDistrictsSelected, stateHouseDistrictsSelected, distanceFilterLabel] {
            k!.text = "Any"
        }
        ageMinField.text = "-"
        ageMaxField.text = "-"
        if let filter = filter {
            if let parties = filter.parties {
                partyAffiliationSelected.text = parties.map{(code: Int16) -> String in
                    switch code {
                    case 1:
                        return "REP"
                    case 2:
                        return "DEM"
                    case 3:
                        return "LIB"
                    case 4:
                        return "GRE"
                    case 5:
                        return "CON"
                    default:
                        return "UNA"
                    }}.joined(separator: ",")
            }
            if let races = filter.races {
                racesSelected.text = races.map{(code: Int16) -> String in
                    switch code {
                    case 0:
                        return "B"
                    case 1:
                        return "I"
                    case 2:
                        return "O"
                    case 3:
                        return "W"
                    case 4:
                        return "A"
                    case 5:
                        return "M"
                    default:
                        return "U"
                    }}.joined(separator: ",")
            }
            if let genders = filter.genders {
                genderSelected.text = genders.map{(code: Int16) -> String in
                    switch code {
                    case 1:
                        return "MALE"
                    case 2:
                        return "FEMALE"
                    default:
                        return "UNK"
                    }}.joined(separator: ",")
            }
            if let ageMin = filter.ageMin {
                ageMinField.text = "\(ageMin)"
            }
            if let ageMax = filter.ageMax {
                ageMaxField.text = "\(ageMax)"
            }
            if let phoneAvailable = filter.phoneAvailable {
                if phoneAvailable {
                    phoneAvailabilitySelected.text = "AVAILABLE ONLY"
                }
                else {
                    phoneAvailabilitySelected.text = "UNAVAILABLE ONLY"
                }
            }
            if let congressionalDistricts = filter.congressionalDistricts {
                congressionalDistrictsSelected.text = congressionalDistricts.map {(id: Int16) -> String in return "\(id)"}.joined(separator: ",")
            }
            if let stateHouseDistricts = filter.stateHouseDistricts {
                stateHouseDistrictsSelected.text = stateHouseDistricts.map {(id: Int16) -> String in return "\(id)"}.joined(separator: ",")
            }
            if let stateSenateDistricts = filter.stateSenateDistricts {
                stateSenateDistrictsSelected.text = stateSenateDistricts.map {(id: Int16) -> String in return "\(id)"}.joined(separator: ",")
            }
            if let distMax = filter.distMax {
                distanceFilterLabel.text = "\(distMax) miles"
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case [0,0]:
            willEditParameter = .party
        case [0,1]:
            willEditParameter = .gender
        case [0,2]:
            return
        case [0,3]:
            return
        case [0,4]:
            willEditParameter = .race
        case [1,0]:
            willEditParameter = .phoneAvailable
        case [2,0]:
            willEditParameter = .congressionalDistrict
        case [2,1]:
            willEditParameter = .stateSenateDistrict
        case [2,2]:
            willEditParameter = .stateHouseDistrict
        default:
            return
        }
        performSegue(withIdentifier: "showFilterDetails", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FilterConfigDetailTableViewController {
            destination.activelyEditingParameter = willEditParameter
            destination.filter = filter
        }
    }
    
    @IBAction func ageMinChanged(_ sender: Any) {
        if let text = ageMinField.text {
            if let min = Int16(text) {
                filter!.ageMin = min
            }
            else {
                ageMinField.text = ""
            }
        }
        filter!.save()
    }
    @IBAction func ageMaxChanged(_ sender: Any) {
        if let text = ageMaxField.text {
            if let max = Int16(text) {
                filter!.ageMax = max
            }
            else {
                ageMaxField.text = ""
            }
        }
        filter!.save()
    }
}

