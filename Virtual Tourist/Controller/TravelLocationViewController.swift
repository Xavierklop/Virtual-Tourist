//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 03.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var pins: [Pin] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescription = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescription]
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            pins = result
        } catch {
            print(error.localizedDescription)
        }
        
        setupMapView()
    }
    
    @IBAction func longPress(_ send: UILongPressGestureRecognizer) {
        if send.state == .began{
            let location = send.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            mapView.addAnnotation(annotation)
            
            print(coordinate.longitude)
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.creationDate = Date()

            do {
                try dataController.viewContext.save()
            } catch {
                print(error.localizedDescription)
            }
            pins.insert(pin, at: 0)
        }
    }


}

extension TravelLocationViewController {
    
    func setupMapView() {
        var annotations = [MKPointAnnotation]()
        
        for dictionary in pins {
            let lat = CLLocationDegrees(dictionary.latitude)
            let long = CLLocationDegrees(dictionary.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
            
        }
        
        // set current region
        if VirtualTouristModel.didPostUserLocation {
            let latitude:CLLocationDegrees = CLLocationDegrees(pins[0].latitude)
            let longitude:CLLocationDegrees = CLLocationDegrees(pins[0].longitude)
            let latDelta:CLLocationDegrees = 0.05
            let lonDelta:CLLocationDegrees = 0.05
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: false)
        }
        
        mapView.addAnnotations(annotations)
    }
}

extension TravelLocationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "mapPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

