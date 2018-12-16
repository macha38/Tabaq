//
//  cameraVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/8/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import AVFoundation
import Parse

class cameraVC: UIViewController, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var cameraView: UIView!
    
    var captureSesssion: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
  
    // Search location
    var currentLocation : PFGeoPoint!
    // GeoPoint setting
    let manager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        captureSesssion = AVCaptureSession()
        stillImageOutput = AVCapturePhotoOutput()

        // Set resolution
//        captureSesssion.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        captureSesssion.sessionPreset = .photo

        let device = AVCaptureDevice.default(for: AVMediaType.video)

        do {
            let input = try AVCaptureDeviceInput(device: device!)

            // Input - camera(?)
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)

                // Output - display(?)
                if (captureSesssion.canAddOutput(stillImageOutput!)) {
                    captureSesssion.addOutput(stillImageOutput!)
                    captureSesssion.startRunning() // Starting camera

                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
                    previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill // Aspect Fill
                    previewLayer?.connection!.videoOrientation = AVCaptureVideoOrientation.portrait

                    cameraView.layer.addSublayer(previewLayer!)

                    // Adjust view size
                    previewLayer?.position = CGPoint(x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
                    previewLayer?.bounds = cameraView.frame
                }
            }
        }
        catch {
            print(error)
        }
        
        // Confirm location authorize setting
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            manager.requestWhenInUseAuthorization()
        }

        // Get current location
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            if error == nil {
                // Display nearby food photo
                self.currentLocation = geopoint!
            } else {
                // Handle with the error
                print("Geo Error")
                self.currentLocation = nil
            }
        }
    }
    
    @IBAction func cancel_clicked(_ sender: Any) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shutterBtn_clicked(_ sender: Any) {
        // Camera settings
        let settingsForMonitoring = AVCapturePhotoSettings()
        settingsForMonitoring.flashMode = .auto
        settingsForMonitoring.isAutoStillImageStabilizationEnabled = true
        settingsForMonitoring.isHighResolutionPhotoEnabled = false
        // Shutter
        stillImageOutput?.capturePhoto(with: settingsForMonitoring, delegate: self)
    }
    
    // Called after taking photo
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            
            let uploadVC = self.storyboard?.instantiateViewController(withIdentifier: "uploadVC") as! uploadVC
            uploadVC.photoData.photoImage = UIImage(data: imageData)!
            uploadVC.photoData.photoLocation = currentLocation
            self.navigationController?.pushViewController(uploadVC, animated: true)

            // Save at photo library
//            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }
    
}
