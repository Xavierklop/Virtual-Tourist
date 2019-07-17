//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 08.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "PhotoCollectionViewCell"

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    private var insertedIndexPaths: [IndexPath]!
    private var deletedIndexPaths: [IndexPath]!
    private var updatedIndexPaths: [IndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        setupFetchedResultsController()
        setupMapView()
        setFlowLayout()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        setupMapView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    @IBAction func tapBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapNewCollection(_ sender: Any) {
        if collectionView.indexPathsForSelectedItems?.count == 0 {
            downloadNewFlickrPhotos()
        } else {
            deleteSelectedPhoto()
            editButton.setTitle("New Clooection", for: .normal)
        }
    }
    
    fileprivate func downloadNewFlickrPhotos() {
        if let photos = fetchedResultsController.fetchedObjects {
            photos.forEach { dataController.viewContext.delete($0) }
        }
        persisteContext()
        FlickrClient.searchPhotosByLocation(pin: pin) { (photosResponse, error) in
            if let response = photosResponse {
                self.pin.pages = Int32(response.photos.pages)
                self.pin.photos = self.createPhotosSet(result: response.photos, pin: self.pin) as NSSet?
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
    
    fileprivate func deleteSelectedPhoto() {
        if let indexPaths  = collectionView.indexPathsForSelectedItems {
            indexPaths.forEach {
                let photo = fetchedResultsController.object(at: $0)
                dataController.viewContext.delete(photo)
            }
            persisteContext()
        }
    }
    
    fileprivate func persisteContext() {
        do {
            try dataController.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptioin = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptioin]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        safePerformFetch()
    }
    
    fileprivate func safePerformFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupMapView() {
        
        let lat = CLLocationDegrees(pin.latitude)
        let long = CLLocationDegrees(pin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let latDelta:CLLocationDegrees = 1
        let lonDelta:CLLocationDegrees = 1
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2DMake(lat, long)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: false)
        
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func setFlowLayout() {
        let space: CGFloat = 3
        let dimension = (view.frame.width - 2 * space) / 3
        
        flowLayout.minimumLineSpacing = 3 * space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
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
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = []
        deletedIndexPaths = []
        updatedIndexPaths = []
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert: insertedIndexPaths.append(newIndexPath!)
        case .delete: deletedIndexPaths.append(indexPath!)
        case .update: updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in insertedIndexPaths { collectionView.insertItems(at: [indexPath]) }
            
            for indexPath in deletedIndexPaths { collectionView.deleteItems(at: [indexPath]) }
            
            for indexPath in updatedIndexPaths { collectionView.reloadItems(at: [indexPath])}
            
        }, completion: nil)
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            print("No selected cell")
            return
        }
        configureSelectAction(by: cell)
    }
    
    fileprivate func configureSelectAction(by cell: UICollectionViewCell) {
        cell.alpha = cell.isSelected == true ? 0.7 : 1
        let title = collectionView.indexPathsForSelectedItems?.count == 0 ? "New Collection" : "Remove Selected Pictures"
        editButton.setTitle(title, for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            print("No deselected cell")
            return
        }
        configureSelectAction(by: cell)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VirtualTouristCollectionViewCell
        cell.activityIndicator.startAnimating()
        let photo = fetchedResultsController.object(at: indexPath)
        
        guard let imageData = photo.data else {
            FlickrClient.downloadFlickrImage(photo: photo) { (imageData, error) in
                guard let imageData = imageData else {
                    return
                }
                cell.photoImageView.image = UIImage(data: imageData)
            }
            cell.activityIndicator.stopAnimating()
            return cell
        }
        cell.photoImageView.image = UIImage(data: imageData)
        cell.activityIndicator.stopAnimating()
        return cell
    }
    
}
