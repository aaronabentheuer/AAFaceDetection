//
//  Visage.swift
//  FaceDetection
//
//  Created by Julian Abentheuer on 21.12.14.
//  Copyright (c) 2014 Aaron Abentheuer. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation
import ImageIO

class Visage: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    enum DetectorAccuracy {
        case BatterySaving
        case HigherPerformance
    }
    
    enum CameraDevice {
        case ISightCamera
        case FaceTimeCamera
    }
    
    var onlyFireNotificatonOnStatusChange : Bool = true
    var visageCameraView : UIView = UIView()
    
    //Private properties of the detected face that can be accessed (read-only) by other classes.
    private(set) var faceDetected : Bool?
    private(set) var faceBounds : CGRect?
    private(set) var faceAngle : CGFloat?
    private(set) var faceAngleDifference : CGFloat?
    private(set) var leftEyePosition : CGPoint?
    private(set) var rightEyePosition : CGPoint?
    
    private(set) var mouthPosition : CGPoint?
    private(set) var hasSmile : Bool?
    private(set) var isBlinking : Bool?
    private(set) var isWinking : Bool?
    private(set) var leftEyeClosed : Bool?
    private(set) var rightEyeClosed : Bool?
    
    //Notifications you can subscribe to for reacting to changes in the detected properties.
    private let visageNoFaceDetectedNotification = NSNotification(name: "visageNoFaceDetectedNotification", object: nil)
    private let visageFaceDetectedNotification = NSNotification(name: "visageFaceDetectedNotification", object: nil)
    private let visageSmilingNotification = NSNotification(name: "visageHasSmileNotification", object: nil)
    private let visageNotSmilingNotification = NSNotification(name: "visageHasNoSmileNotification", object: nil)
    private let visageBlinkingNotification = NSNotification(name: "visageBlinkingNotification", object: nil)
    private let visageNotBlinkingNotification = NSNotification(name: "visageNotBlinkingNotification", object: nil)
    private let visageWinkingNotification = NSNotification(name: "visageWinkingNotification", object: nil)
    private let visageNotWinkingNotification = NSNotification(name: "visageNotWinkingNotification", object: nil)
    private let visageLeftEyeClosedNotification = NSNotification(name: "visageLeftEyeClosedNotification", object: nil)
    private let visageLeftEyeOpenNotification = NSNotification(name: "visageLeftEyeOpenNotification", object: nil)
    private let visageRightEyeClosedNotification = NSNotification(name: "visageRightEyeClosedNotification", object: nil)
    private let visageRightEyeOpenNotification = NSNotification(name: "visageRightEyeOpenNotification", object: nil)
    
    //Private variables that cannot be accessed by other classes in any way.
    private var faceDetector : CIDetector?
    private var videoDataOutput : AVCaptureVideoDataOutput?
    private var videoDataOutputQueue : dispatch_queue_t?
    private var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    private var captureSession : AVCaptureSession = AVCaptureSession()
    private let notificationCenter : NSNotificationCenter = NSNotificationCenter.defaultCenter()
    private var currentOrientation : Int?
    
    init(cameraPosition : CameraDevice, optimizeFor : DetectorAccuracy) {
        super.init()
        
        currentOrientation = convertOrientation(UIDevice.currentDevice().orientation)
        
        switch cameraPosition {
        case .FaceTimeCamera : self.captureSetup(AVCaptureDevicePosition.Front)
        case .ISightCamera : self.captureSetup(AVCaptureDevicePosition.Back)
        }
        
        var faceDetectorOptions : [String : AnyObject]?
        
        switch optimizeFor {
        case .BatterySaving : faceDetectorOptions = [CIDetectorAccuracy : CIDetectorAccuracyLow]
        case .HigherPerformance : faceDetectorOptions = [CIDetectorAccuracy : CIDetectorAccuracyHigh]
        }
        
        self.faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: faceDetectorOptions)
    }
    
    //MARK: SETUP OF VIDEOCAPTURE
    func beginFaceDetection() {
        self.captureSession.startRunning()
    }
    
    func endFaceDetection() {
        self.captureSession.stopRunning()
    }
    
    private func captureSetup (position : AVCaptureDevicePosition) {
        var captureError : NSError?
        var captureDevice : AVCaptureDevice!
        
        for testedDevice in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo){
            if (testedDevice.position == position) {
                captureDevice = testedDevice as! AVCaptureDevice
            }
        }
        
        if (captureDevice == nil) {
            captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        }
        
        var deviceInput : AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            captureError = error
            deviceInput = nil
        }
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        if (captureError == nil) {
            if (captureSession.canAddInput(deviceInput)) {
                captureSession.addInput(deviceInput)
            }
            
            self.videoDataOutput = AVCaptureVideoDataOutput()
            self.videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
            self.videoDataOutput!.alwaysDiscardsLateVideoFrames = true
            self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)
            self.videoDataOutput!.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue!)
            
            if (captureSession.canAddOutput(self.videoDataOutput)) {
                captureSession.addOutput(self.videoDataOutput)
            }
        }
        
        visageCameraView.frame = UIScreen.mainScreen().bounds
		
		let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = UIScreen.mainScreen().bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        visageCameraView.layer.addSublayer(previewLayer)
    }
    
    var options : [String : AnyObject]?
    
    //MARK: CAPTURE-OUTPUT/ANALYSIS OF FACIAL-FEATURES
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(CVPixelBuffer: pixelBuffer, options: nil)
        options = [CIDetectorSmile : true, CIDetectorEyeBlink: true, CIDetectorImageOrientation : 6]
        
        let features = self.faceDetector!.featuresInImage(sourceImage, options: options)
        
        if (features.count != 0) {
            
            if (onlyFireNotificatonOnStatusChange == true) {
                if (self.faceDetected == false) {
                    notificationCenter.postNotification(visageFaceDetectedNotification)
                }
            } else {
                notificationCenter.postNotification(visageFaceDetectedNotification)
            }
            
            self.faceDetected = true
            
            for feature in features as! [CIFaceFeature] {
                faceBounds = feature.bounds
                
                if (feature.hasFaceAngle) {
                    
                    if (faceAngle != nil) {
                        faceAngleDifference = CGFloat(feature.faceAngle) - faceAngle!
                    } else {
                        faceAngleDifference = CGFloat(feature.faceAngle)
                    }
                    
                    faceAngle = CGFloat(feature.faceAngle)
                }
                
                if (feature.hasLeftEyePosition) {
                    leftEyePosition = feature.leftEyePosition
                }
                
                if (feature.hasRightEyePosition) {
                    rightEyePosition = feature.rightEyePosition
                }
                
                if (feature.hasMouthPosition) {
                    mouthPosition = feature.mouthPosition
                }
                
                if (feature.hasSmile) {
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.hasSmile == false) {
                            notificationCenter.postNotification(visageSmilingNotification)
                        }
                    } else {
                        notificationCenter.postNotification(visageSmilingNotification)
                    }
                    
                    hasSmile = feature.hasSmile
                    
                } else {
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.hasSmile == true) {
                            notificationCenter.postNotification(visageNotSmilingNotification)
                        }
                    } else {
                        notificationCenter.postNotification(visageNotSmilingNotification)
                    }
                    
                    hasSmile = feature.hasSmile
                }
                
                if (feature.leftEyeClosed || feature.rightEyeClosed) {
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.isWinking == false) {
                            notificationCenter.postNotification(visageWinkingNotification)
                        }
                    } else {
                        notificationCenter.postNotification(visageWinkingNotification)
                    }
                    
                    isWinking = true
                    
                    if (feature.leftEyeClosed) {
                        if (onlyFireNotificatonOnStatusChange == true) {
                            if (self.leftEyeClosed == false) {
                                notificationCenter.postNotification(visageLeftEyeClosedNotification)
                            }
                        } else {
                            notificationCenter.postNotification(visageLeftEyeClosedNotification)
                        }
                        
                        leftEyeClosed = feature.leftEyeClosed
                    }
                    if (feature.rightEyeClosed) {
                        if (onlyFireNotificatonOnStatusChange == true) {
                            if (self.rightEyeClosed == false) {
                                notificationCenter.postNotification(visageRightEyeClosedNotification)
                            }
                        } else {
                            notificationCenter.postNotification(visageRightEyeClosedNotification)
                        }
                        
                        rightEyeClosed = feature.rightEyeClosed
                    }
                    if (feature.leftEyeClosed && feature.rightEyeClosed) {
                        if (onlyFireNotificatonOnStatusChange == true) {
                            if (self.isBlinking == false) {
                                notificationCenter.postNotification(visageBlinkingNotification)
                            }
                        } else {
                            notificationCenter.postNotification(visageBlinkingNotification)
                        }
                        
                        isBlinking = true
                    }
                } else {
                    
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.isBlinking == true) {
                            notificationCenter.postNotification(visageNotBlinkingNotification)
                        }
                        if (self.isWinking == true) {
                            notificationCenter.postNotification(visageNotWinkingNotification)
                        }
                        if (self.leftEyeClosed == true) {
                            notificationCenter.postNotification(visageLeftEyeOpenNotification)
                        }
                        if (self.rightEyeClosed == true) {
                            notificationCenter.postNotification(visageRightEyeOpenNotification)
                        }
                    } else {
                        notificationCenter.postNotification(visageNotBlinkingNotification)
                        notificationCenter.postNotification(visageNotWinkingNotification)
                        notificationCenter.postNotification(visageLeftEyeOpenNotification)
                        notificationCenter.postNotification(visageRightEyeOpenNotification)
                    }
                    
                    isBlinking = false
                    isWinking = false
                    leftEyeClosed = feature.leftEyeClosed
                    rightEyeClosed = feature.rightEyeClosed
                }
            }
        } else {
            if (onlyFireNotificatonOnStatusChange == true) {
                if (self.faceDetected == true) {
                    notificationCenter.postNotification(visageNoFaceDetectedNotification)
                }
            } else {
                notificationCenter.postNotification(visageNoFaceDetectedNotification)
            }
            
            self.faceDetected = false
        }
    }
    
    //TODO: 🚧 HELPER TO CONVERT BETWEEN UIDEVICEORIENTATION AND CIDETECTORORIENTATION 🚧
    private func convertOrientation(deviceOrientation: UIDeviceOrientation) -> Int {
        var orientation: Int = 0
        switch deviceOrientation {
        case .Portrait:
            orientation = 6
        case .PortraitUpsideDown:
            orientation = 2
        case .LandscapeLeft:
            orientation = 3
        case .LandscapeRight:
            orientation = 4
        default : orientation = 1
        }
        return 6
    }
}