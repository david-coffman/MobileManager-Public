//
//  ManifestManagement.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/11/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let mainManifestPath = documentPath.appendingPathComponent("manifests").appendingPathComponent("main").appendingPathComponent("main").appendingPathExtension("json")

var moduleManifest: ModuleManifest! {
    didSet {
        refreshSavedManifest()
    }
}

class VoterModule: Codable, Equatable {
    static func == (lhs: VoterModule, rhs: VoterModule) -> Bool {
        return lhs.districtIdentifier == rhs.districtIdentifier && lhs.stateIdentifier == rhs.stateIdentifier
    }
    
    var stateIdentifier: String
    var districtIdentifier: String
    var externalIdentifier: String
    var installed: Bool {
        didSet {
            refreshSavedManifest()
        }
    }
    
    func pathForModule() -> URL {
        return documentPath.appendingPathComponent(stateIdentifier).appendingPathComponent(districtIdentifier)
    }
    
    init(stateIdentifier: String, districtIdentifier: String, externalIdentifier: String) {
        self.stateIdentifier = stateIdentifier
        self.districtIdentifier = districtIdentifier
        self.externalIdentifier = externalIdentifier
        self.installed = false
    }
    
    init(stateIdentifier: String, districtIdentifier: String, externalIdentifier: String, installed: Bool) {
        self.stateIdentifier = stateIdentifier
        self.districtIdentifier = districtIdentifier
        self.externalIdentifier = externalIdentifier
        self.installed = installed
    }
    
    func install(errorfunc: @escaping () -> Void, completion: @escaping () -> Void) {
        if self.installed == false {
            switch stateIdentifier {
            case "NC":
                installNCModule(errorfunc: errorfunc) {completion()}
            default:
                moduleNotAvailable()
            }
        }
        else {
            print("Already installed.")
        }
    }
    
    func uninstall() {
        if self.installed == true {
            switch stateIdentifier {
            case "NC":
                uninstallNCModule()
            default:
                moduleNotAvailable()
            }
        }
        else {
            print("Not installed.")
        }
    }
}

struct ModuleManifest: Codable, Equatable {
    var modules = [String: [VoterModule]]()
    var allModules: [VoterModule] {
        modules.values.reduce([VoterModule](), {$0 + $1})
    }
    var allInstalledModules: [VoterModule] {
        allModules.filter({$0.installed})
    }
    var sortedKeys: [String] {
        modules.keys.sorted(by: <)
    }
}

func checkManifestOnAppLoad() {
    if let manifest = try? JSONDecoder().decode(ModuleManifest.self, from: Data(contentsOf: mainManifestPath)) {
        moduleManifest = manifest
    }
    else {
        initializeDirectoriesOnAppInstall()
        print("Completed post-installation directory setup.")
    }
}

func refreshSavedManifest() {
    try! JSONEncoder().encode(moduleManifest).write(to: mainManifestPath)
}

func initializeDirectoriesOnAppInstall() {
    try! FileManager().createDirectory(at: documentPath.appendingPathComponent("manifests").appendingPathComponent("main"), withIntermediateDirectories: true, attributes: nil)
    try! FileManager().createDirectory(at: documentPath.appendingPathComponent("export"), withIntermediateDirectories: true, attributes: nil)
    let manifestBundleURL = Bundle.main.url(forResource: "manifest", withExtension: "json")
    try! FileManager().createFile(atPath: mainManifestPath.relativePath, contents: Data(contentsOf: manifestBundleURL!), attributes: nil)
    checkManifestOnAppLoad()
    for k in moduleManifest.modules.keys {
        try! FileManager().createDirectory(at: documentPath.appendingPathComponent(k), withIntermediateDirectories: true, attributes: nil)
    }
    // MUST prepackage a module JSON.
}

// MARK: - North Carolina -
extension VoterModule {
    private func installNCModule(errorfunc: @escaping () -> Void, completion: @escaping () -> Void) {
        uninstallNCModule()
        let installation = DispatchGroup()
        let districtIdentifier = Int(self.districtIdentifier)!
        var ncGeoPath: URL {
            documentPath.appendingPathComponent("NC").appendingPathComponent("ncgeocoding").appendingPathComponent("ncgeocoding")
        }
        
        let installedNCModules = moduleManifest.modules["NC"]!.filter({$0.installed})
        if installedNCModules.count == 0 {
            installation.enter()
            installNCGeocodingData(inDispatchGroup: installation, errorfunc: errorfunc)
        }
        installation.enter()
        installation.enter()
        installNCVoterData(inDispatchGroup: installation, errorfunc: errorfunc)
        installNCVoterHistory(inDispatchGroup: installation, errorfunc: errorfunc)
        
        installation.notify(queue: .global(qos: .userInitiated)){
            unpackZIP(sourceURL: documentPath.appendingPathComponent("NC").appendingPathComponent("history\(districtIdentifier)").appendingPathExtension("zip"), destinationURL: self.pathForModule().appendingPathComponent("history")){
                NCDatabaseController().process(voterFilePath: self.pathForModule().appendingPathComponent("ncvoter\(districtIdentifier).txt"), geoFilePath: ncGeoPath.appendingPathComponent("ncgeocoding\(districtIdentifier).txt"), voterHistoryPath: self.pathForModule().appendingPathComponent("history").appendingPathComponent("ncvhis\(districtIdentifier).txt"), countyID: Int16(self.districtIdentifier)!) {
                    self.installed = true
                    self.cleanupNCInstall()
                    completion()
                }
            }
        }
    }
    
    private func installNCGeocodingData(inDispatchGroup group: DispatchGroup, errorfunc: @escaping () -> Void) {
        let onlineLocation = URL(string: "https://www.dropbox.com/s/arxso76xt5s374u/ncgeocoding.zip?dl=1")!
        let dataSession = URLSession.shared.dataTask(with: onlineLocation) { (data, response, error) -> Void in
            if let data = data {
                let writePath = documentPath.appendingPathComponent("NC").appendingPathComponent("ncgeocodingarchive").appendingPathExtension("zip")
                let unpackPath = documentPath.appendingPathComponent("NC").appendingPathComponent("ncgeocoding")
                try! data.write(to: writePath, options: .noFileProtection)
                
                unpackZIP(sourceURL: writePath, destinationURL: unpackPath) {
                    // Handle DispatchGroup here.
                    group.leave()
                }
            }
            else {
                errorfunc()
            }
        }
        dataSession.resume()
    }
    
    private func installNCVoterData(inDispatchGroup group: DispatchGroup, errorfunc: @escaping () -> Void) {
        let districtIdentifier = self.districtIdentifier
        let onlineLocation = URL(string: "https://s3.amazonaws.com/dl.ncsbe.gov/data/ncvoter\(districtIdentifier).zip")!
        let dataSession = URLSession.shared.dataTask(with: onlineLocation) { (data, response, error) -> Void in
            if let data = data {
                let writePath = documentPath.appendingPathComponent("NC").appendingPathComponent("\(districtIdentifier)").appendingPathExtension("zip")
                try! data.write(to: writePath, options: .noFileProtection)
                
                unpackZIP(sourceURL: writePath, destinationURL: self.pathForModule()){
                    group.leave()
                }
            }
            else {
                errorfunc()
            }
        }
        dataSession.resume()
    }
    
    private func installNCVoterHistory(inDispatchGroup group: DispatchGroup, errorfunc: @escaping () -> Void) {
        let districtIdentifier = self.districtIdentifier
        let onlineLocation = URL(string: "https://s3.amazonaws.com/dl.ncsbe.gov/data/ncvhis\(districtIdentifier).zip")!
        let dataSession = URLSession.shared.dataTask(with: onlineLocation) { (data, response, error) -> Void in
            if let data = data {
                let writePath = documentPath.appendingPathComponent("NC").appendingPathComponent("history\(districtIdentifier)").appendingPathExtension("zip")
                try! data.write(to: writePath, options: .noFileProtection)
                group.leave()
            }
            else {
                errorfunc()
            }
        }
        dataSession.resume()
    }
    
    private func cleanupNCInstall() {
        let districtIdentifier = self.districtIdentifier
        try! FileManager().removeItem(at: documentPath.appendingPathComponent("NC").appendingPathComponent(districtIdentifier))
    }
    
    private func uninstallNCModule() {
        let voterPredicate = NSPredicate(format: "countyID == %d", Int16(self.districtIdentifier)!)
        let historyGeoPredicate = NSPredicate(format: "districtIdentifier == %d", Int16(self.districtIdentifier)!)
        NCDatabaseController().delete(requestType: .voter, withPredicate: voterPredicate)
        NCDatabaseController().delete(requestType: .history, withPredicate: historyGeoPredicate)
        NCDatabaseController().delete(requestType: .geo, withPredicate: historyGeoPredicate)
        print("Finished batch delete.")
        self.installed = false
    }
}

// MARK: - Next State -
extension VoterModule {
}
