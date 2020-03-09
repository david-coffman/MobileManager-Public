//
//  FilterConfigDetailTableViewController.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/13/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit

class FilterConfigDetailTableViewController: UITableViewController {
    
    var activelyEditingParameter: FilterMode!
    var filter: Filter!
    var selectedRows = [Int]() {
        didSet {
            if selectedRows != [] {
                switch activelyEditingParameter! {
                case .congressionalDistrict:
                    filter.congressionalDistricts = selectedRows.map{Int16($0)+1}
                case .gender:
                    filter.genders = selectedRows.map{Int16($0)}
                case .party:
                    filter.parties = selectedRows.map{Int16($0)}
                case .phoneAvailable:
                    if selectedRows == [0] {
                        filter.phoneAvailable = true
                    }
                    if selectedRows == [1] {
                        filter.phoneAvailable = false
                    }
                case .stateHouseDistrict:
                    filter.stateHouseDistricts = selectedRows.map{Int16($0)+1}
                case .stateSenateDistrict:
                    filter.stateSenateDistricts = selectedRows.map{Int16($0)+1}
                case .race:
                    filter.races = selectedRows.map{Int16($0)}
                default:
                    return
                }
            }
            else {
                switch activelyEditingParameter! {
                case .race:
                    filter.races = nil
                case .congressionalDistrict:
                    filter.congressionalDistricts = nil
                case .gender:
                    filter.genders = nil
                case .party:
                    filter.parties = nil
                case .phoneAvailable:
                    filter.phoneAvailable = nil
                case .stateHouseDistrict:
                    filter.stateHouseDistricts = nil
                case .stateSenateDistrict:
                    filter.stateSenateDistricts = nil
                default:
                    return
                }
            }
            filter.save()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        switch activelyEditingParameter! {
        case .congressionalDistrict:
            if let congressionalDistricts = filter.congressionalDistricts {
                selectedRows = congressionalDistricts.map{Int($0)-1}
            }
        case .gender:
            if let genders = filter.genders {
                selectedRows = genders.map{Int($0)}
            }
        case .party:
            if let parties = filter.parties {
                selectedRows = parties.map{Int($0)}
            }
        case .phoneAvailable:
            if let phoneAvailable = filter.phoneAvailable {
                if phoneAvailable {
                    selectedRows = [0]
                }
                else {
                    selectedRows = [1]
                }
            }
        case .stateHouseDistrict:
            if let stateHouseDistricts = filter.stateHouseDistricts {
                selectedRows = stateHouseDistricts.map{Int($0)-1}
            }
        case .stateSenateDistrict:
            if let stateSenateDistricts = filter.stateSenateDistricts {
                selectedRows = stateSenateDistricts.map{Int($0)-1}
            }
        default:
            return
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            switch activelyEditingParameter! {
            case .gender:
                return 3
            case .congressionalDistrict:
                return 13
            case .party:
                return 6
            case .phoneAvailable:
                return 2
            case .stateHouseDistrict:
                return 120
            case .stateSenateDistrict:
                return 50
            case .race:
                return 7
            default:
                return 0
            }
        }
        else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
        if indexPath.section == 1 {
            if selectedRows.contains(indexPath.row) { cell.accessoryType = .checkmark }
            else {cell.accessoryType = .none}
            let textLabel = cell.textLabel!
            switch activelyEditingParameter! {
            case .gender:
                switch indexPath.row {
                case 1:
                    textLabel.text = "Male"
                case 2:
                    textLabel.text = "Female"
                default:
                    textLabel.text = "Unknown"
                }
                return cell
            case .congressionalDistrict:
                textLabel.text = "District \(indexPath.row+1)"
                return cell
            case .party:
                switch indexPath.row {
                case 1:
                    textLabel.text = "Republican"
                case 2:
                    textLabel.text = "Democrat"
                case 3:
                    textLabel.text = "Libertarian"
                case 4:
                    textLabel.text = "Green"
                case 5:
                    textLabel.text = "Constitution"
                default:
                    textLabel.text = "Unaffiliated"
                }
                return cell
            case .phoneAvailable:
                switch indexPath.row {
                case 0:
                    textLabel.text = "Available"
                default:
                    textLabel.text = "Unavailable"
                }
                return cell
            case .stateHouseDistrict:
                textLabel.text = "District \(indexPath.row+1)"
                return cell
            case .stateSenateDistrict:
                textLabel.text = "District \(indexPath.row+1)"
                return cell
            case .race:
                switch indexPath.row {
                case 0:
                    textLabel.text = "Black"
                case 1:
                    textLabel.text = "American Indian"
                case 2:
                    textLabel.text = "Other"
                case 3:
                    textLabel.text = "White"
                case 4:
                    textLabel.text = "Asian"
                case 5:
                    textLabel.text = "Multiple Races"
                default:
                    textLabel.text = "Undesignated"
                }
                return cell
            default:
                return cell
            }
        }
        else {
            cell.textLabel!.text = "Any (Clear Selection)"
            cell.accessoryType = .none
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            selectedRows = []
        }
        else {
            if selectedRows.contains(indexPath.row) {
                selectedRows = selectedRows.filter{$0 != indexPath.row}
            }
            else {
                selectedRows.append(indexPath.row)
            }
            switch activelyEditingParameter! {
            case .gender:
                if selectedRows.count == 3 {selectedRows = []}
            case .congressionalDistrict:
                if selectedRows.count == 13 {selectedRows = []}
            case .party:
                if selectedRows.count == 6 {selectedRows = []}
            case .phoneAvailable:
                if selectedRows.count == 2 {selectedRows = []}
            case .stateHouseDistrict:
                if selectedRows.count == 120 {selectedRows = []}
            case .stateSenateDistrict:
                if selectedRows.count == 50 {selectedRows = []}
            case .race:
                if selectedRows.count == 7 {selectedRows = []}
            default:
                return
            }
        }
        tableView.reloadData()
    }
}
