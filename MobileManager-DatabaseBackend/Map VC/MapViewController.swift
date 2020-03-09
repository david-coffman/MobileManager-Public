//
//  ViewController.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 6/27/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit
import MapKit
import Compression
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    var viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var selectedVoterID: Int32!
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        var fetchedResultsController: NSFetchedResultsController<VoterLocation> = {
            let fetchRequest: NSFetchRequest<VoterLocation> = VoterLocation.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "voterID", ascending: true)]
            let primaryFilter = NSPredicate(format: "voterID == %d", selectedVoterID)
            fetchRequest.predicate = primaryFilter
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            return fetchedResultsController
        }()
        try! fetchedResultsController.performFetch()
        
        if let first = fetchedResultsController.fetchedObjects!.first {
            mapView.addAnnotation(MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon)))
        }
    }
}

