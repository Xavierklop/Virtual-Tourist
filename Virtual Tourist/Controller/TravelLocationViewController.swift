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

let key = "f896f37933075e5a079db20bb21899f8"
let secret = "34072b477a61a490"

class TravelLocationViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var bottomTextLabel: UILabel!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!

    var pinForNextVC: Pin!
    
    enum EditState { case editing, done }
    var editState = EditState.done
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setupFetchedResultsController()
        setupMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchedResultsController()
        setupMapView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    @IBAction func longPress(_ send: UILongPressGestureRecognizer) {
        if  editState == .done && send.state == .began{
            let location = send.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.pages = 0
            
            createPhotos(by: pin)
            persisteContext()
        }
    }

    @IBAction func tapEditButton() {
        switch editState {
        case .done:
            editButton.title = "Done"
            bottomTextLabel.isHidden = false
            editState = .editing
        case .editing:
            editButton.title = "Edit"
            bottomTextLabel.isHidden = true
            editState = .done
        }
    }
    
    private func createPhotos(by pin: Pin){
        FlickrClient.searchPhotosByLocation(pin: pin) { (photosResponse, error) in
            if let response = photosResponse {
                pin.pages = Int32(response.photos.pages)
                pin.photos = self.createPhotosSet(result: response.photos, pin: pin) as NSSet?
                self.persisteContext()
            } else {
                print("Error happens when create assoicate photos for pin")
            }
        }
    }
    
    private func createPhotosSet(result: PublicPhotos, pin: Pin) -> Set<Photo>? {
        var photos = Set<Photo>()
        if result.photo.isEmpty {
            return nil
        }
        
        result.photo.forEach { publicPhoto in
            let photo = Photo(context: dataController.viewContext)
            photo.id = publicPhoto.id
            photo.url = publicPhoto.url
            photo.title = publicPhoto.title
            photo.pin = pin
            photos.insert(photo)
        }
        persisteContext()
        return photos
    }
    
    fileprivate func safePerformFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescription = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescription]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        safePerformFetch()
    }
    
    fileprivate func persisteContext() {
        do {
            try dataController.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func setupMapView() {
        var annotations: [MKPointAnnotation] = []
        safePerformFetch()
        
        guard let pins = fetchedResultsController.fetchedObjects else {
            print("no fetch pins")
            return
        }
        
        pins.forEach { (pin) in
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! PhotoAlbumViewController
        vc.dataController = dataController
        vc.pin = pinForNextVC
    }

}

extension TravelLocationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pins = fetchedResultsController.fetchedObjects else {
            print("no fetch pins")
            return
        }
        if let coordinate = view.annotation?.coordinate, let selectedPin = pins.first(where: {$0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude}) {
            
            switch editState {
            case .done:
                pinForNextVC = selectedPin
                performSegue(withIdentifier: "showPhotoAlbum", sender: self)
                
            case .editing:
                mapView.removeAnnotations(mapView.annotations)
                dataController.viewContext.delete(selectedPin)
                persisteContext()
                setupMapView()
            }
            
        }
    }
    
}

extension TravelLocationViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            print("In NSfetchRC, cannot fetch Pin!")
            return
        }
        
        let lat = CLLocationDegrees(pin.latitude)
        let long = CLLocationDegrees(pin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        switch type {
        case .insert:
            mapView.addAnnotation(annotation)
        default:
            break
        }
    }
}

