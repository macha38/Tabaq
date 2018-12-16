//
//  locationmapVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/24/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import MapKit
import Parse

class locationmapVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!

    // Given data from postVC or feedVC
    var selectedLocation : LocationData!

    override func viewDidLoad() {
        super.viewDidLoad()

        // mapview delegate
        mapView.delegate = self
        
        // pin to the given point
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.title = selectedLocation.name
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: selectedLocation.location!.latitude, longitude: selectedLocation.location!.longitude)
        let pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
        mapView.centerCoordinate = pointAnnotation.coordinate
        mapView.addAnnotation(pinAnnotationView.annotation!)
        
        // Init the zoom level
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(pointAnnotation.coordinate, span)
        mapView.setRegion(region, animated: true)
        
        // alignment
        mapView.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
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
        let markerannotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        
        // setting annotationView
        markerannotationView.canShowCallout = true
        markerannotationView.markerTintColor = UIColor.flatOrange()
        markerannotationView.animatesWhenAdded = true

        // implant UILabel
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
        label.text = "> Open with Google map"
        label.textColor = UIColor.flatSkyBlue()
        markerannotationView.detailCalloutAccessoryView = label

        return markerannotationView
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

    // select function
    @objc func gonextTap(gestureRecognizer: UITapGestureRecognizer) {
        
        let view = gestureRecognizer.view
        
        // extract annotation
        if let annotation = (view as! MKAnnotationView).annotation as? MKPointAnnotation {
            
            // send location to google maps
            if let url = URL(string: "comgooglemaps://?q=\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)") {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }

}
