//
//  DistanceFilterTableViewController.swift
//  MobileManager-DatabaseBackend
//
//  Created by David Coffman on 7/15/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit
import MapKit

class DistanceFilterTableViewController: UITableViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
    
    @IBOutlet var eighthMileCell: UITableViewCell!
    @IBOutlet var quarterMileCell: UITableViewCell!
    @IBOutlet var halfMileCell: UITableViewCell!
    @IBOutlet var mileCell: UITableViewCell!
    @IBOutlet var twoMileCell: UITableViewCell!
    @IBOutlet var unlimitedRangeCell: UITableViewCell!
    
    override func viewDidLoad() {
        mapView.delegate = self
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let lat = filter!.locationCenterLat, let lon = filter!.locationCenterLon {
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            mapView.addAnnotation(MKPlacemark(coordinate: location))
            if let distMax = filter!.distMax {
                let earthRadius = 3959.0
                let conversionFactor = Double.pi/180.0
                let icf = 180.0/Double.pi
                let topLeft = CLLocationCoordinate2D(latitude: lat+icf*distMax/(earthRadius), longitude: lon - icf*distMax / (earthRadius * cos(lat*conversionFactor)))
                let topRight = CLLocationCoordinate2D(latitude: lat+icf*distMax/(earthRadius), longitude: lon + icf*distMax/(earthRadius * cos(lat*conversionFactor)))
                let bottomRight = CLLocationCoordinate2D(latitude: lat-icf*distMax/(earthRadius), longitude: lon + icf*distMax/(earthRadius * cos(lat*conversionFactor)))
                let bottomLeft = CLLocationCoordinate2D(latitude: lat-icf*distMax/(earthRadius), longitude: lon - icf*distMax / (earthRadius * cos(lat*conversionFactor)))
                let coordinates = [topLeft, topRight, bottomRight, bottomLeft, topLeft]
                print(coordinates)
                let polyline = MKPolyline(coordinates: coordinates, count: 5)
                mapView.addOverlay(polyline)
                mapView.region = MKCoordinateRegion(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            }
            else {
                mapView.region = MKCoordinateRegion(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            }
        }
        if let maxDist = filter!.distMax {
            switch maxDist {
            case 0.125:
                eighthMileCell.accessoryType = .checkmark
            case 0.25:
                quarterMileCell.accessoryType = .checkmark
            case 0.5:
                halfMileCell.accessoryType = .checkmark
            case 1.0:
                mileCell.accessoryType = .checkmark
            case 2.0:
                twoMileCell.accessoryType = .checkmark
            default:
                return
            }
        }
        else {
            unlimitedRangeCell.accessoryType = .checkmark
        }
    }
    
    func resetRectangularOverlay() {
        for k in mapView.overlays {
            mapView.removeOverlay(k)
        }
        
        if let distMax = filter!.distMax, let lon = filter!.locationCenterLon, let lat = filter!.locationCenterLat {
            // removed a zero
            let earthRadius = 3959.0
            let conversionFactor = Double.pi/180.0
            let icf = 180.0/Double.pi
            let topLeft = CLLocationCoordinate2D(latitude: lat+icf*distMax/(earthRadius), longitude: lon - icf*distMax / (earthRadius * cos(lat*conversionFactor)))
            let topRight = CLLocationCoordinate2D(latitude: lat+icf*distMax/(earthRadius), longitude: lon + icf*distMax/(earthRadius * cos(lat*conversionFactor)))
            let bottomRight = CLLocationCoordinate2D(latitude: lat-icf*distMax/(earthRadius), longitude: lon + icf*distMax/(earthRadius * cos(lat*conversionFactor)))
            let bottomLeft = CLLocationCoordinate2D(latitude: lat-icf*distMax/(earthRadius), longitude: lon - icf*distMax / (earthRadius * cos(lat*conversionFactor)))
            let coordinates = [topLeft, topRight, bottomRight, bottomLeft, topLeft]
            print(coordinates)
            let polyline = MKPolyline(coordinates: coordinates, count: 5)
            mapView.addOverlay(polyline)
        }
    }

    // MARK: - Table view data source
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MKPlacemark {
            if let view = mapView.dequeueReusableAnnotationView(withIdentifier: "placemark") {
                view.largeContentTitle = "Filter Center"
                return view
            }
            else {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "placemark")
                view.largeContentTitle = "Filter Center"
                return view
            }
        }
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 5
            print("About to return renderer...")
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        for k in [eighthMileCell, quarterMileCell, halfMileCell, mileCell, twoMileCell, unlimitedRangeCell] {
            k!.accessoryType = .none
        }
        guard indexPath.section == 0 else {return}
        if let filter = filter {
            switch indexPath.row {
            case 0:
                filter.distMax = 0.125
                eighthMileCell.accessoryType = .checkmark
            case 1:
                filter.distMax = 0.25
                quarterMileCell.accessoryType = .checkmark
            case 2:
                filter.distMax = 0.5
                halfMileCell.accessoryType = .checkmark
            case 3:
                filter.distMax = 1.0
                mileCell.accessoryType = .checkmark
            case 4:
                filter.distMax = 2.0
                twoMileCell.accessoryType = .checkmark
            default:
                unlimitedRangeCell.accessoryType = .checkmark
                filter.distMax = nil
                filter.locationCenterLon = nil
                filter.locationCenterLat = nil
                for k in mapView.annotations {
                    mapView.removeAnnotation(k)
                }
            }
            resetRectangularOverlay()
        }
        filter!.save()
    }
    
    @IBAction func didLongPressOnMap(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == UIGestureRecognizer.State.ended else {return}
        for k in mapView.annotations {
            mapView.removeAnnotation(k)
        }
        let point = longPressRecognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        mapView.addAnnotation(MKPlacemark(coordinate: coordinate))
        filter!.locationCenterLat = coordinate.latitude
        filter!.locationCenterLon = coordinate.longitude
        filter!.save()
        resetRectangularOverlay()
    }
}
