//
//  InstallNewModulesTableViewController.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 7/6/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit

// https://medium.com/journey-of-one-thousand-apps/tracking-download-progress-with-swift-c1a13f3f8c66

class InstallNewModulesTableViewController: UITableViewController, URLSessionDelegate {

    @IBOutlet var editButton: UIBarButtonItem!
    
    var installing = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return moduleManifest.modules.keys.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "North Carolina"
        default:
            return "Uh-oh."
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moduleManifest!.modules[moduleManifest!.sortedKeys[section]]!.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "availableModuleCell", for: indexPath)
        
        if indexPath.row == moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]!.count {
            cell.textLabel!.text = "Install All Available"
            if installing.contains(indexPath) {
                cell.detailTextLabel!.text = "Installing"
            }
            else {
                cell.detailTextLabel!.text = "Available"
                cell.accessoryType = .disclosureIndicator
            }
            return cell
        }
        
        let module = moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]![indexPath.row]
        
        cell.textLabel!.text = module.externalIdentifier
        
        if module.installed {
            cell.detailTextLabel!.text = "Installed"
            cell.accessoryType = .none
        }
        else if installing.contains(indexPath) {
            cell.detailTextLabel!.text = "Installing"
            cell.accessoryType = .none
        }
        else {
            cell.detailTextLabel!.text = "Available"
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Last cell in each section is an "install all" option.
        if indexPath.row == moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]!.count {
            installAllModules(fromButtonAtIndexPath: indexPath)
        }
        // All other cells are install-one options.
        else {
            installModule(representedByIndexPath: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]!.count {
            return true
        }
        let module = moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]![indexPath.row]
        return module.installed
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.row == moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]!.count {
                for k in moduleManifest.modules[moduleManifest.sortedKeys[indexPath.section]]! {
                    k.uninstall()
                    DispatchQueue.main.async {tableView.reloadData()}
                }
            }
            else {
                let module = moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]![indexPath.row]
                module.uninstall()
                DispatchQueue.main.async {tableView.reloadData()}
            }
        }
    }
    
    func installModule(representedByIndexPath indexPath: IndexPath) {
        let module = moduleManifest!.modules[moduleManifest!.sortedKeys[indexPath.section]]![indexPath.row]
        if module.installed == false {
            let installAlert = UIAlertController(title: "Install Module", message: "Are you sure you'd like to install \(module.externalIdentifier)? Note: you may only install this module if your license permits you to do so.", preferredStyle: .alert)
            installAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            installAlert.addAction(UIAlertAction(title: "Confirm", style: .default){ (UIAlertAction) -> Void in
                // Begin installation process.
                self.installing.append(indexPath)
                DispatchQueue.main.async {self.tableView.reloadData()}
                module.install(errorfunc: self.presentNetworkErrorAlert){
                    self.installing = self.installing.filter({$0 != indexPath})
                    DispatchQueue.main.async {self.tableView.reloadData()}
                }
            })
            self.present(installAlert, animated: true, completion: nil)
        }
    }
    
    func installAllModules(fromButtonAtIndexPath indexPath: IndexPath) {
        let installAlert = UIAlertController(title: "Install Module", message: "Are you sure you'd like to install all available modules for \(moduleManifest.sortedKeys[indexPath.section])? Note: you may only install these modules if your license permits you to do so.", preferredStyle: .alert)
        installAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        installAlert.addAction(UIAlertAction(title: "Confirm", style: .default){ (UIAlertAction) -> Void in
            for k in moduleManifest.modules[moduleManifest.sortedKeys[indexPath.section]]! {
                self.installing.append(indexPath)
                DispatchQueue.main.async {self.tableView.reloadData()}
                k.install(errorfunc: self.presentNetworkErrorAlert){
                    self.installing = self.installing.filter({$0 != indexPath})
                    DispatchQueue.main.async {self.tableView.reloadData()}
                }
            }
        })
        self.present(installAlert, animated: true, completion: nil)
        return
    }
    
    
    

    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func editButtonPressed(_ sender: Any) {
        isEditing.toggle()
        if isEditing {
            editButton.title = "Done"
        }
        else {
            editButton.title = "Edit"
        }
        
    }
    
    func presentNetworkErrorAlert() {
        DispatchQueue.main.async {
            self.present(networkError(), animated: true, completion: nil)
        }
    }
    
}
