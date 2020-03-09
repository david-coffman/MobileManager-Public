//
//  TabularTableViewController.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 7/5/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit
import CoreData

var filter: Filter?

class TabularTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var orderedModules: [VoterModule]!
    var selectedVoterObjectID: NSManagedObjectID?
    var viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var resultControllersForOrderedModules = [NSFetchedResultsController<Voter>]()
    var manifestModules = moduleManifest.allInstalledModules
    var trackingPredicate: NSPredicate?
    var trackingGeoPredicate: NSPredicate?
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var exportButton: UIBarButtonItem!
    var searchText: String?
    
    override func viewDidLoad() {
        self.title = "Loading..."
        if let loadedFilter = Filter.retrieveSavedFilter() {
            filter = loadedFilter
            self.trackingPredicate = filter!.generatePredicate()
            self.trackingGeoPredicate = filter!.generateGeoPredicates()
        }
        else {
            filter = Filter()
            filter!.save()
            self.trackingPredicate = filter!.generatePredicate()
            self.trackingGeoPredicate = filter!.generateGeoPredicates()
        }
        for k in UIApplication.shared.connectedScenes {
            if let lstext = (k.delegate as! SceneDelegate).launchSearchText {
                searchText = lstext
                searchTextField.text = lstext
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.assignOrderedModules()
            self.populateResultControllers()
        }
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if moduleManifest!.allInstalledModules != manifestModules || filter!.generatePredicate() != trackingPredicate || filter!.generateGeoPredicates() != trackingGeoPredicate {
            orderedModules = []
            resultControllersForOrderedModules = []
            DispatchQueue.main.async {self.title = "Refreshing..."}
            DispatchQueue.global(qos: .userInitiated).async {
                self.assignOrderedModules()
                self.populateResultControllers()
            }
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return resultControllersForOrderedModules.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        print(orderedModules!)
        switch orderedModules[section].stateIdentifier {
        case "NC":
            return "North Carolina: \(orderedModules[section].externalIdentifier)"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchedObjects = resultControllersForOrderedModules[section].fetchedObjects {
            return fetchedObjects.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "voter", for: indexPath) as! VoterTableViewCell
        guard let fetchedObjects = resultControllersForOrderedModules[indexPath.section].fetchedObjects else {return cell}
        let thisVoter = fetchedObjects[indexPath.row]
        guard let firstName = thisVoter.firstName, let lastName = thisVoter.lastName else {return cell}
        
        cell.nameLabel.text = "\(lastName), \(firstName) (\(thisVoter.age))"
        
        switch thisVoter.genderCode {
        case 1:
            cell.genderLabelImage.image = UIImage(systemName: "m.circle.fill")
            cell.genderLabelImage.tintColor = .systemBlue
        case 2:
            cell.genderLabelImage.image = UIImage(systemName: "f.circle.fill")
            cell.genderLabelImage.tintColor = .systemPink
        default:
            cell.genderLabelImage.image = UIImage(systemName: "questionmark.circle.fill")
            cell.genderLabelImage.tintColor = .systemOrange
        }
        
        switch thisVoter.partyCode {
        case 1:
            cell.partyLabelImage.image = UIImage(systemName: "r.circle.fill")
            cell.partyLabelImage.tintColor = .systemRed
        case 2:
            cell.partyLabelImage.image = UIImage(systemName: "d.circle.fill")
            cell.partyLabelImage.tintColor = .systemBlue
        case 3:
            cell.partyLabelImage.image = UIImage(systemName: "l.circle.fill")
            cell.partyLabelImage.tintColor = .systemYellow
        case 4:
            cell.partyLabelImage.image = UIImage(systemName: "g.circle.fill")
            cell.partyLabelImage.tintColor = .systemGreen
        case 5:
            cell.partyLabelImage.image = UIImage(systemName: "c.circle.fill")
            cell.partyLabelImage.tintColor = .systemOrange
        default:
            cell.partyLabelImage.image = UIImage(systemName: "u.circle.fill")
            cell.partyLabelImage.tintColor = .purple
        }
        
        switch thisVoter.raceCode {
        case 0:
            cell.raceLabelImage.image = UIImage(systemName: "b.circle.fill")
        case 1:
            cell.raceLabelImage.image = UIImage(systemName: "i.circle.fill")
        case 2:
            cell.raceLabelImage.image = UIImage(systemName: "o.circle.fill")
        case 3:
            cell.raceLabelImage.image = UIImage(systemName: "w.circle.fill")
        case 4:
            cell.raceLabelImage.image = UIImage(systemName: "a.circle.fill")
        case 5:
            cell.raceLabelImage.image = UIImage(systemName: "m.circle.fill")
        default:
            cell.raceLabelImage.image = UIImage(systemName: "questionmark.circle.fill")
        }
        cell.raceLabelImage.tintColor = .black
        
        switch (thisVoter.hasEngaged, thisVoter.hasDispatched) {
        case (true, true):
            cell.engagementIndicator.image = UIImage(systemName: "checkmark.circle.fill")
            cell.engagementIndicator.tintColor = .systemGreen
        case (false, true):
            cell.engagementIndicator.image = UIImage(systemName: "exclamationmark.circle.fill")
                        cell.engagementIndicator.tintColor = .systemOrange
        default:
            cell.engagementIndicator.image = UIImage(systemName: "x.circle.fill")
            cell.engagementIndicator.tintColor = .systemRed
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedVoterObjectID = resultControllersForOrderedModules[indexPath.section].fetchedObjects![indexPath.row].objectID
        performSegue(withIdentifier: "showVoterDetails", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? VoterDetailTableViewController {
            destination.selectedVoterObjectID = self.selectedVoterObjectID!
        }
        if let destination = segue.destination as? FilterConfigTableViewController {
            destination.filter = filter!
        }
    }
    
    func assignOrderedModules() {
        var ret = [VoterModule]()
        for k in moduleManifest.sortedKeys {
            ret += moduleManifest!.modules[k]!.filter({$0.installed})
        }
        orderedModules = ret
    }
    
    func populateResultControllers() {
        resultControllersForOrderedModules = []
        for k in orderedModules {
            
            let tertiaryFilter = filter!.generateGeoPredicates()
            var voterIDsInRange: [Int32]? = nil
            if let tertiaryFilter = tertiaryFilter {
                var fetchedResultsController: NSFetchedResultsController<VoterLocation> = {
                    let fetchRequest: NSFetchRequest<VoterLocation> = VoterLocation.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "voterID", ascending: true)]
                    fetchRequest.predicate = tertiaryFilter
                    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: nil)
                    return fetchedResultsController
                }()
                try! fetchedResultsController.performFetch()
                if let fetchedObjects = fetchedResultsController.fetchedObjects {
                    voterIDsInRange = fetchedObjects.map{let n = $0.voterID; return n}
                }
            }
            
            switch k.stateIdentifier {
            case "NC":
                var fetchedResultsController: NSFetchedResultsController<Voter> = {
                    let fetchRequest: NSFetchRequest<Voter> = Voter.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
                    let primaryFilter = NSPredicate(format: "stateCode == %d AND countyID == %d AND registrationIsActive == YES", argumentArray: [Int16(0), Int16(k.districtIdentifier)!])
                    if let secondaryFilter = filter!.generatePredicate() {
                        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [primaryFilter, secondaryFilter])
                    }
                    else {
                        fetchRequest.predicate = primaryFilter
                    }
                    if let searchText = searchText {
                        if searchText.replacingOccurrences(of: " ", with: "") != "" {
                            let split = searchText.split(separator: " ")
                            if split.count == 0 {
                            }
                            if split.count == 1 {
                                let thisPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(format: "lastName CONTAINS[cd] %@",String(split[0]).capitalized), NSPredicate(format: "firstName CONTAINS[cd] %@", String(split[0]).capitalized)])
                                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:  [fetchRequest.predicate!, thisPredicate])
                            }
                            if split.count == 2 {
                                let thisPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "lastName CONTAINS[cd] %@",String(split[1]).capitalized), NSPredicate(format: "firstName CONTAINS[cd] %@", String(split[0]).capitalized)])
                                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:  [fetchRequest.predicate!, thisPredicate])
                            }
                            if split.count >= 3 {
                                fetchRequest.predicate = NSPredicate(value: false)
                            }
                        }
                    }
                    if let voterIDList = voterIDsInRange {
                        let thisPredicate = NSPredicate(format: "voterID IN %@", voterIDList)
                        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fetchRequest.predicate!, thisPredicate])
                    }
                    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: nil)
                    fetchedResultsController.delegate = self
                    return fetchedResultsController
                }()
                try! fetchedResultsController.performFetch()
                resultControllersForOrderedModules.append(fetchedResultsController)
            default:
                return
            }
        }
        DispatchQueue.main.async {
            self.title = "Tabular View"
            self.tableView.reloadData()
            print("Reloaded table data.")
        }
    }
    @IBAction func searchTextEntered(_ sender: Any) {
        executeSearch()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        searchTextField.text = ""
        executeSearch()
    }
    
    func executeSearch() {
        if let searchText = searchTextField.text {
            self.searchText = searchText
        }
        else {
            searchText = nil
        }
        self.populateResultControllers()
    }
    
    @IBAction func exportButtonPressed(_ sender: Any) {
        var targetUserID: String? = nil
        
        let alertController = UIAlertController(title: "Export", message: "If you're keeping track of dispatch targets, enter the target user ID here.", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        alertController.addAction(UIAlertAction(
            title: "Confirm",
            style: .default,
            handler: {(UIAlertAction) -> Void in targetUserID = alertController.textFields!.first!.text; self.export(for: targetUserID)}
        ))
        alertController.addAction(UIAlertAction(
            title: "Skip Target Recording",
            style: .default,
            handler: {(UIAlertAction) -> Void in self.export(for: nil)}
        ))
        alertController.addAction(UIAlertAction(
            title: "Cancel Export",
            style: .cancel,
            handler: nil
        ))
        present(alertController, animated: true, completion: nil)
    }
    
    func export(for client: String?) {
        let currentDate = Date()
        let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy_MMMM_dd_'at'_dd_HH_mm"
            return dateFormatter
        }()
        let exportPath = documentPath.appendingPathComponent("export").appendingPathComponent("export\(dateFormatter.string(from: currentDate))_for_\(client ?? "NOIDENT")").appendingPathExtension("voterlist")
        
        var exportLogs = (try? JSONDecoder().decode([ExportLog].self, from: Data(contentsOf: documentPath.appendingPathComponent("exportLog").appendingPathExtension("log")))) ?? [ExportLog]()
        var exportLog = ExportLog(exportIdentifier: exportLogs.count+1, exportedTo: client ?? "UNIDENT", exportedOn: Date(), exportEntries: [])
        
        var votersToExport = [CodableVoter]()
        
        for k in resultControllersForOrderedModules {
            for object in k.fetchedObjects! {
                object.lastDispatchID = Int16(exportLogs.count+1)
                
                let voterID = object.voterID
                let stateCode = object.stateCode
                exportLog.exportEntries.append(ExportLog.ExportEntry(stateCode: stateCode, voterID: voterID))
                
                let voterLocationRequest = NSFetchRequest<VoterLocation>(entityName: "VoterLocation")
                voterLocationRequest.predicate = NSPredicate(format: "voterID == %d AND stateCode == %d", argumentArray: [voterID, stateCode])
                let locationID = (try! viewContext.fetch(voterLocationRequest)).first?.objectID
                
                let voterHistoryRequest = NSFetchRequest<VoterHistory>(entityName: "VoterHistory")
                voterHistoryRequest.predicate = NSPredicate(format: "voterID == %d AND stateCode == %d", argumentArray: [voterID, stateCode])
                let historyID = (try! viewContext.fetch(voterHistoryRequest)).first?.objectID
                
                if let exportableVoter = CodableVoter(objectIdentifier: object.objectID, geoObjectIdentifier: locationID, histObjectIdentifier: historyID, managedContext: viewContext) {
                    votersToExport.append(exportableVoter)
                }
            }
            try! viewContext.save()
        }
        
        let voterExport = VoterExport(exportIdentifier: exportLog.exportIdentifier, exportedVoters: votersToExport)
        
        try? JSONEncoder().encode(voterExport).write(to: exportPath, options: .noFileProtection)
        
        let activityController = UIActivityViewController(activityItems: [exportPath], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = exportButton
        present(activityController, animated: true, completion: {
            //try! FileManager().removeItem(at: exportPath)
            exportLogs.append(exportLog)
            try! JSONEncoder().encode(exportLogs).write(to: documentPath.appendingPathComponent("exportLog").appendingPathExtension("log"))
            for k in self.resultControllersForOrderedModules {
                for object in k.fetchedObjects! {
                    object.hasDispatched = true
                }
            }
            try! self.viewContext.save()
        })
    }
}
