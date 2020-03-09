//
//  VoterDetailTableViewController.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 7/9/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit
import CoreData

class VoterDetailTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    let viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var selectedVoterObjectID: NSManagedObjectID?
    var thisVoter: Voter?
    var thisVoterHistoryEntries: [VoterHistoryEntry]?
    lazy var fetchedResultsController: NSFetchedResultsController<VoterHistory> = {
        let fetchRequest: NSFetchRequest<VoterHistory> = VoterHistory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "stateCode == %d AND voterID == %d", argumentArray: [Int16(thisVoter!.stateCode), Int32(thisVoter!.voterID)])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "voterID", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        thisVoter = (viewContext.object(with: selectedVoterObjectID!) as! Voter)
        try! fetchedResultsController.performFetch()
        if let vhisObj = fetchedResultsController.fetchedObjects!.first {
            thisVoterHistoryEntries = try! JSONDecoder().decode([VoterHistoryEntry].self, from: vhisObj.jsonData!)
            thisVoterHistoryEntries!.sort(by: {$0.electionDate > $1.electionDate})
        }
        else {
            thisVoterHistoryEntries = []
        }
        self.title = "\(thisVoter!.firstName!) \(thisVoter!.lastName!)"
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 5
        case 1:
            return 3
        case 2:
            return 14
        case 3:
            return max(thisVoterHistoryEntries!.count, 1)
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Biographical"
        case 1:
            return "Contact"
        case 2:
            return "Districts"
        case 3:
            return "Voter History"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath)
        guard let thisVoter = thisVoter else {return tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)}
        
        switch thisVoter.stateCode {
        case 0:
            return cellForNC(at: indexPath)
        default:
            return tableView.dequeueReusableCell(withIdentifier: "INVALID", for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath == [1,2] {
            if thisVoter!.phoneNumber != 0 {
                UIApplication.shared.open(URL(string: "tel://\(thisVoter!.phoneNumber)")!, options: [:])
            }
        }
        if indexPath == [1,0] {
            performSegue(withIdentifier: "viewOnMap", sender: self)
        }
    }
    
    func cellForNC(at indexPath: IndexPath) -> UITableViewCell {
        // withImage, basic, rightDetail, basicMultiline
        guard let thisVoter = thisVoter else {return tableView.dequeueReusableCell(withIdentifier: "INVALID", for: indexPath)}
        
        switch (indexPath.section, indexPath.row) {
            
        case (0,0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "withImage", for: indexPath) as! WithImageTableViewCell
            switch thisVoter.partyCode {
            case 1:
                cell.label.text = "Republican"
                cell.sideImage.image = UIImage(systemName: "r.circle.fill")
                cell.sideImage.tintColor = .systemRed
            case 2:
                cell.label.text = "Democrat"
                cell.sideImage.image = UIImage(systemName: "d.circle.fill")
                cell.sideImage.tintColor = .systemBlue
            case 3:
                cell.label.text = "Libertarian"
                cell.sideImage.image = UIImage(systemName: "l.circle.fill")
                cell.sideImage.tintColor = .systemYellow
            case 4:
                cell.label.text = "Green"
                cell.sideImage.image = UIImage(systemName: "g.circle.fill")
                cell.sideImage.tintColor = .systemGreen
            case 5:
                cell.label.text = "Constitution"
                cell.sideImage.image = UIImage(systemName: "c.circle.fill")
                cell.sideImage.tintColor = .systemOrange
            default:
                cell.label.text = "Unaffiliated"
                cell.sideImage.image = UIImage(systemName: "u.circle.fill")
                cell.sideImage.tintColor = .purple
            }
            cell.accessoryType = .none
            return cell
            
        case (0,1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "withImage", for: indexPath) as! WithImageTableViewCell
            
            switch thisVoter.genderCode {
            case 1:
                cell.label.text = "Male"
                cell.sideImage.image = UIImage(systemName: "m.circle.fill")
                cell.sideImage.tintColor = .systemBlue
            case 2:
                cell.label.text = "Female"
                cell.sideImage.image = UIImage(systemName: "f.circle.fill")
                cell.sideImage.tintColor = .systemPink
            default:
                cell.label.text = "Unknown"
                cell.sideImage.image = UIImage(systemName: "questionmark.circle.fill")
                cell.sideImage.tintColor = .systemOrange
            }
            cell.accessoryType = .none
            return cell
            
        case (0,2):
            let cell = tableView.dequeueReusableCell(withIdentifier: "withImage", for: indexPath) as! WithImageTableViewCell
            if thisVoter.age > 50 {
                cell.sideImage.image = UIImage(systemName: "plus.circle.fill")
            }
            else {
                cell.sideImage.image = UIImage(systemName: "\(thisVoter.age).circle.fill")
            }
            cell.sideImage.tintColor = .black
            cell.label.text = "\(thisVoter.age) years old"
            cell.accessoryType = .none
            return cell
            
        case (0,3):
            let cell = tableView.dequeueReusableCell(withIdentifier: "withImage", for: indexPath) as! WithImageTableViewCell
            switch thisVoter.raceCode {
            case 0:
                cell.label.text = "Black"
                cell.sideImage.image = UIImage(systemName: "b.circle.fill")
                cell.sideImage.tintColor = .black
            case 1:
                cell.label.text = "American Indian"
                cell.sideImage.image = UIImage(systemName: "i.circle.fill")
                cell.sideImage.tintColor = .black
            case 2:
                cell.label.text = "Other"
                cell.sideImage.image = UIImage(systemName: "o.circle.fill")
                cell.sideImage.tintColor = .black
            case 3:
                cell.label.text = "White"
                cell.sideImage.image = UIImage(systemName: "w.circle.fill")
                cell.sideImage.tintColor = .black
            case 4:
                cell.label.text = "Asian"
                cell.sideImage.image = UIImage(systemName: "a.circle.fill")
                cell.sideImage.tintColor = .black
            case 5:
                cell.label.text = "Multiple Races"
                cell.sideImage.image = UIImage(systemName: "m.circle.fill")
                cell.sideImage.tintColor = .black
            default:
                cell.label.text = "Undesignated"
                cell.sideImage.image = UIImage(systemName: "questionmark.circle.fill")
                cell.sideImage.tintColor = .black
            }
            cell.accessoryType = .none
            return cell
            
        case (0,4):
            let cell = tableView.dequeueReusableCell(withIdentifier: "withImage", for: indexPath) as! WithImageTableViewCell
            cell.sideImage.image = UIImage(systemName: "\(Int(Date().timeIntervalSince(thisVoter.registrationDate!)/31536000)).circle.fill")
            cell.sideImage.tintColor = .black
            cell.label.text = "\(Int(Date().timeIntervalSince(thisVoter.registrationDate!)/31536000)) years"
            cell.accessoryType = .none
            return cell
        
        case (1,0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicMultiline", for: indexPath)
            cell.textLabel!.text = "Residential Address:\n\(thisVoter.residentialAddress!)"
            cell.accessoryType = .disclosureIndicator
            return cell
        
        case (1,1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicMultiline", for: indexPath)
            cell.textLabel!.text = "Mailing Address:\n\(thisVoter.mailingAddress!)"
            cell.accessoryType = .none
            return cell
        
        case (1,2):
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicMultiline", for: indexPath)
            if thisVoter.phoneNumber != 0 {
                cell.textLabel!.text = "Phone Number:\n\(thisVoter.phoneNumber)"
                cell.accessoryType = .disclosureIndicator
            }
            else {
                cell.textLabel!.text = "Phone Number Unavailable"
                cell.accessoryType = .none
            }
            return cell
        case (2,_):
            let cell = tableView.dequeueReusableCell(withIdentifier: "rightDetail", for: indexPath)
            switch thisVoter.stateCode {
            // Districts are state-specific.
            // Districts section for North Carolina.
            case 0:
                switch indexPath.row {
                case 0:
                    cell.textLabel!.text = "Congressional District"
                    cell.detailTextLabel!.text = "\(thisVoter.congressionalDistrict)"
                case 1:
                    cell.textLabel!.text = "State Senate District"
                    cell.detailTextLabel!.text = "\(thisVoter.stateSenateDistrict)"
                case 2:
                    cell.textLabel!.text = "State House District"
                    cell.detailTextLabel!.text = "\(thisVoter.stateHouseDistrict)"
                case 3:
                    cell.textLabel!.text = "Municipality"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.municipality) ?? "N/A"); \(nilIfEmpty(thisVoter.municipalDistrict) ?? "N/A")"
                case 4:
                    cell.textLabel!.text = "Superior Court"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.superiorCourtDistrict) ?? "N/A")"
                case 5:
                    cell.textLabel!.text = "Judicial District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.judicialDistrict) ?? "N/A")"
                case 6:
                    cell.textLabel!.text = "County Commissioner"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.countyCommissioner) ?? "N/A")"
                case 7:
                    cell.textLabel!.text = "Township"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.township) ?? "N/A")"
                case 8:
                    cell.textLabel!.text = "School District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.schoolDistrict) ?? "N/A")"
                case 9:
                    cell.textLabel!.text = "Fire District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.fireDistrict) ?? "N/A")"
                case 10:
                    cell.textLabel!.text = "Water District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.waterDistrict) ?? "N/A")"
                case 11:
                    cell.textLabel!.text = "Sewer District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.sewerDistrict) ?? "N/A")"
                case 12:
                    cell.textLabel!.text = "Sanitation District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.sanitationDistrict) ?? "N/A")"
                case 13:
                    cell.textLabel!.text = "Rescue District"
                    cell.detailTextLabel!.text = "\(nilIfEmpty(thisVoter.rescueDistrict) ?? "N/A")"
                default:
                    break
                }
            // Districts sections for additional states should be implemented here.
            default:
                break
            }
            cell.accessoryType = .none
            return cell
            
        case (3,_):
            if let thisVoterHistoryEntries = thisVoterHistoryEntries {
                if thisVoterHistoryEntries.count == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
                    cell.textLabel!.text = "No history available."
                    return cell
                }
                else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "withImage", for: indexPath) as! WithImageTableViewCell
                    cell.label.text = "\(thisVoterHistoryEntries[indexPath.row].electionName)"
                    if thisVoterHistoryEntries[indexPath.row].electionName.contains("PRIMARY") {
                        switch thisVoterHistoryEntries[indexPath.row].votedParty {
                        case 1:
                            cell.sideImage.image = UIImage(systemName: "r.circle.fill")
                            cell.sideImage.tintColor = .systemRed
                        case 2:
                            cell.sideImage.image = UIImage(systemName: "d.circle.fill")
                            cell.sideImage.tintColor = .systemBlue
                        case 3:
                            cell.sideImage.image = UIImage(systemName: "l.circle.fill")
                            cell.sideImage.tintColor = .systemYellow
                        case 4:
                            cell.sideImage.image = UIImage(systemName: "g.circle.fill")
                            cell.sideImage.tintColor = .systemGreen
                        case 5:
                            cell.sideImage.image = UIImage(systemName: "c.circle.fill")
                            cell.sideImage.tintColor = .systemOrange
                        default:
                            cell.sideImage.image = UIImage(systemName: "u.circle.fill")
                            cell.sideImage.tintColor = .purple
                        }
                    }
                    else {
                        cell.sideImage.image = UIImage(systemName: "minus.circle.fill")
                        cell.sideImage.tintColor = .black
                    }
                   
                    return cell
                }
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
                cell.textLabel!.text = "Loading..."
                return cell
            }
            
            
        default:
            print("Unrecognized IndexPath.")
            return tableView.dequeueReusableCell(withIdentifier: "INVALID", for: indexPath)
        }
    }
    
    func nilIfEmpty(_ string: String?) -> String? {
        if let string = string {
            if string == "" {return nil}
            else {return string}
        }
        else {return nil}
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MapViewController {
            destination.selectedVoterID = thisVoter!.voterID
        }
    }
}
