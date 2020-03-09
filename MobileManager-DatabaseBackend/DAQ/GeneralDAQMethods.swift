//
//  GeneralDAQ.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 7/2/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import Foundation
import UIKit

let documentPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("DigitalCampaignManager")

func networkError() -> UIAlertController {
    let networkErrorAlert = UIAlertController(title: "Network Error", message: "It seems your internet connection is unavailable. You won't be able to install modules until you connect to the internet.", preferredStyle: .alert)
    networkErrorAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
    return networkErrorAlert
}

func moduleNotAvailable() {
    print("Module unavailable -- bad state code or missing district code.")
}

func unpackZIP(sourceURL: URL, destinationURL: URL, completion: @escaping () -> Void) {
    // Clear extraction directory.
    if let contents = try? FileManager().contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil, options: []) {
        for k in contents {
            print(k)
            try! FileManager().removeItem(at: k)
        }
    }
    // Monitor progress and execute completion function when finished.
    var progress = Progress()
    let observer = progress.observe(\Progress.completedUnitCount, options: .new) {
        (progress, change) in
        print(progress.fractionCompleted)
        if progress.fractionCompleted == 1.0 {
            try! FileManager().removeItem(at: sourceURL)
            completion()
        }
    }
    // Perform extraction.
    try! FileManager().unzipItem(at: sourceURL, to: destinationURL, progress: progress)
}

func trimQuotations(_ str: String.SubSequence) -> String {
    guard let fqi = str.firstIndex(of: "\""), let sqi = str.lastIndex(of: "\"") else {return ""}
    let afterfqi = str.index(after: fqi)
    return String(str[afterfqi..<sqi])
}
