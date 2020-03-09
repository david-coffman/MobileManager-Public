//
//  MigrationTableViewController.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/28/19.
//  Copyright Â© 2019 David Coffman. All rights reserved.
//

import UIKit
import CoreData

class MigrationTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let inboxPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Inbox")
    var inboxPathContents: [String] {
        let contents = try? FileManager().contentsOfDirectory(atPath: inboxPath.relativePath)
        return (contents ?? [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxPathContents.count > 0 ? inboxPathContents.count : 1
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "For more information on how to migrate client data, see the instructions section in the settings tab."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "migrationCell", for: indexPath)
        if inboxPathContents.count > 0 {
            cell.textLabel!.text = inboxPathContents[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        }
        else {
            cell.textLabel!.text = "No data to migrate."
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if inboxPathContents.count > 0 {
            migrateModule(at: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && inboxPathContents.count > 0 {
            let row = indexPath.row
            try! FileManager().removeItem(at: inboxPath.appendingPathComponent(inboxPathContents[row]))
            tableView.reloadData()
        }
    }
    
    func migrateModule(at row: Int) {
        guard let binaryData = try? Data(contentsOf: inboxPath.appendingPathComponent(inboxPathContents[row])) else {badDataError(errno: 1); return}
        guard let pVoterExport = try? JSONDecoder().decode(VoterExport.self, from: binaryData) else {badDataError(errno: 2); return}
        let exportIdentifier = Int16(pVoterExport.exportIdentifier)
        
        let fetchedResultsController: NSFetchedResultsController<Voter> = {
            let fetchRequest: NSFetchRequest<Voter> = Voter.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "lastDispatchID == %d", exportIdentifier)
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            try! fetchedResultsController.performFetch()
            return fetchedResultsController
        }()
        
        let validVoterIDs = fetchedResultsController.fetchedObjects!.map({$0.voterID}).sorted()
        let exportVoterIDs = pVoterExport.exportedVoters.map({$0.voterID}).sorted()
        
        if validVoterIDs == exportVoterIDs {
            print("Verified.")
            for k in fetchedResultsController.fetchedObjects! {
                k.hasEngaged = pVoterExport.exportedVoters.filter({$0.voterID == k.voterID}).first!.hasEngaged
            }
            try! FileManager().removeItem(at: inboxPath.appendingPathComponent(inboxPathContents[row]))
            try! viewContext.save()
            tableView.reloadData()
        }
        else {
            badDataError(errno: 3)
        }
    }
    
    func badDataError(errno: Int) {
        let alertController = UIAlertController(title: "WARNING!", message: "It appears that the imported file is corrupted. It is strongly recommended that you delete the file. Your data has not been changed. (Error # \(errno))", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alertController, animated: true)
    }
}
