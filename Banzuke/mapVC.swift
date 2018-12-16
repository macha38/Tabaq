//
//  mapVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/16/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import MapKit
import Parse


class mapVC: UIViewController, UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var annotation: MKAnnotation!
    var localSearchRequest: MKLocalSearchRequest!
    var localSearch: MKLocalSearch!
    var localSearchResponse: MKLocalSearchResponse!
    var error: NSError!
    var pointAnnotation: MKPointAnnotation!
    var pinAnnotationView: MKPinAnnotationView!
    
    // Delegate
    var uploadDelegate: uploadVCDelegate?

    // Given data from uploadVC
    var selectedLocation : LocationData!

    // Declare search bar
    var searchBar = UISearchBar()
    
    // GeoPoint setting
    let manager = CLLocationManager()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // mapview delegate
        mapView.delegate = self
        
        // Implement search bar into navigation bar
        searchBar.delegate = self
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): UIColor.black], for: .normal)
        searchBar.sizeToFit()
        searchBar.tintColor = UIColor.flatGray()
        searchBar.frame.size.width = self.view.frame.size.width / 4 * 3
        searchBar.autocapitalizationType = .none
        let searchItem = UIBarButtonItem(customView: searchBar)
        navigationItem.rightBarButtonItem = searchItem
        
        // alignment
        mapView.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        
        // long press
//        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gestureRecognizer:)))
//        mapView.addGestureRecognizer(longpress)
        
        // Initial annotation
        if selectedLocation != nil && selectedLocation.name != nil {
            
            // set place name
            searchBar.text = selectedLocation.name
            // pin to the given point
            pointAnnotation = MKPointAnnotation()
            pointAnnotation.title = selectedLocation.name
            pointAnnotation.subtitle = selectedLocation.title
            pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: selectedLocation.location!.latitude, longitude: selectedLocation.location!.longitude)
            pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
            mapView.centerCoordinate = pointAnnotation.coordinate
            mapView.addAnnotation(pinAnnotationView.annotation!)
            // Init the zoom level
            let span = MKCoordinateSpanMake(0.01, 0.01)
            let region = MKCoordinateRegionMake(pointAnnotation.coordinate, span)
            mapView.setRegion(region, animated: true)
//                self.mapView.showsPointsOfInterest = true /* want to show restaurants point but it does not work */
        } else {
            
            // search location
            searchBar.placeholder = "Search location"
            
            // only has location
            if let selLoc = selectedLocation {
                let coordinate = CLLocationCoordinate2D(latitude: selLoc.location!.latitude, longitude: selLoc.location!.longitude)
                let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.01, 0.01))
                mapView.setRegion(region, animated: true)
            } else {
                // current location
                manager.delegate = self
                if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
                    manager.requestWhenInUseAuthorization()
                } else {
                    
                    // Get current location
                    PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
                        if error == nil {
                            let coordinate = CLLocationCoordinate2D(latitude: geopoint!.latitude, longitude: geopoint!.longitude)
                            let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.01, 0.01))
                            self.mapView.setRegion(region, animated: true)
                        } else {
                            // Handle with the error
                            print("Geo Error")
                        }
                    }
                }
            }
        }
        
    }
    
    // start searching
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Dismiss searcha bar and old annotations
        searchBar.resignFirstResponder()
        
        // remove old annotations
        if self.mapView.annotations.count != 0 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        // search
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearchRequest.region = mapView.region  // search region
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (localSearchResponse, error) -> Void in

            if localSearchResponse == nil{
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            var annotations = [MKPointAnnotation]()
            for placemark in localSearchResponse!.mapItems {

                // pin at result
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(placemark.placemark.coordinate.latitude, placemark.placemark.coordinate.longitude)
                annotation.title = placemark.placemark.name
                annotation.subtitle = placemark.placemark.title
                self.mapView.addAnnotation(annotation)
                annotations.append(annotation)
            }
            self.mapView.showAnnotations(annotations, animated: true)
        }
    }

    // setting annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // set identifier
        let identifier = "restaurants"
        
        // find reusable annnotationView
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            return annotationView
        }
        
        // create new annotationView
//        let pinannotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        let markerannotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

        // setting annotationView
        markerannotationView.canShowCallout = true
        markerannotationView.markerTintColor = UIColor.flatOrange()
        markerannotationView.animatesWhenAdded = true

        // implant UIImage
        let image = UIImage(named: "next.png")
        let uiimage = UIImageView(image: image)
        markerannotationView.rightCalloutAccessoryView = uiimage
        
        return markerannotationView
    }
    
    // select function
    @objc func gonextTap(gestureRecognizer: UITapGestureRecognizer) {
        
        let view = gestureRecognizer.view
        
        // extract annotation
        if let annotation = (view as! MKAnnotationView).annotation as? MKPointAnnotation {
            
            // give location data back to uploadVC
            let location = LocationData()
            let geo = PFGeoPoint(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            location.name = annotation.title
            location.title = annotation.subtitle
            location.location = geo
            
            // get restuuid from resaurant class
            let query = PFQuery(className: "restaurants")
//            query.whereKey("location", nearGeoPoint: location.location!)
            query.whereKey("location", equalTo: location.location!)
            query.whereKey("name", equalTo: location.name!)
            query.findObjectsInBackground {
                
                (objects, error) in
                if error == nil {
                    
                    if objects!.count == 0 {
                        // create new row on restaurants class
                        let newrestObj = PFObject(className: "restaurants")
                        newrestObj["name"] = location.name
                        newrestObj["location"] = location.location
                        newrestObj["title"] = location.title
                        newrestObj.saveInBackground {
                            (success, err) in
                            if success {
                                location.restuuid = newrestObj.objectId
                                self.uploadDelegate?.setLocationFromMap(givenLocation: location)
                                // Push Back (go back to previous view under navigation view)
                                self.navigationController?.popViewController(animated: true)
                            } else {
                                print(err!.localizedDescription)
                            }
                        }

                        
                    } else {
                        // find related objects
                        for object in objects! {
                            // Hold found information
                            location.restuuid = object.objectId
                            break
                        }
                        self.uploadDelegate?.setLocationFromMap(givenLocation: location)
                        // Push Back (go back to previous view under navigation view)
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
        }
        
    }
    
    
    // longpress function
    @objc func longPress(gestureRecognizer: UITapGestureRecognizer) {

        mapView.removeAnnotations(mapView.annotations)
        
        // get location in mapView
        let location = gestureRecognizer.location(in: mapView)
        
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            
            // convert touched point to location
            let mapPoint = mapView.convert(location, toCoordinateFrom: mapView)
            
            // pin to mapView
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = CLLocationCoordinate2DMake(mapPoint.latitude, mapPoint.longitude)
            pointAnnotation.title = "Set location name"
            pointAnnotation.subtitle = "address"
            pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
            mapView.centerCoordinate = pointAnnotation.coordinate
            mapView.addAnnotation(pointAnnotation)
        }

    }
    

    // select annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        // implant tap recognizer
        let nextTap = UITapGestureRecognizer(target: self, action: #selector(gonextTap(gestureRecognizer:)))
        nextTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(nextTap)

    }
    
    // de-select annotation
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {

        // remove gesture recognizer
        view.removeGestureRecognizer(view.gestureRecognizers!.first!)
    }
    

}
