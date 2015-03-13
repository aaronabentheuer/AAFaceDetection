AAFaceDetection: Visage
===============
Approachable implementation of iOS FaceDetection with CIDetector for prototyping based on NSNotification.

###Introduction
Although face-recognition was first introduced to the platform by Apple in iOS 5, we haven't seen much creative use of this quite interesting feature, especially on live video. This technology is especially interesting for prototyping experimental user-interfaces that make use of the user's emotion (smiling, blinking or winking) or detect the user's attention (whether he is looking at the screen or not). That's why I wanted to make it as easy as possible to prototype those interactions with a simple model based on NSNotification whenever the status of the user's face changes. All the main features of Apples CIDetector(ofType: CIDetectorTypeFace…) are implemented and can be easily accessed.

*Please keep in mind that this is meant as a tool for designers learning Swift to prototype. This isn't meant for production environments but for quick experimentation with interactions. I've been doing a few private experiments with it as well as one big project for university, but it's still a work in progress.*

###Usage
To start using "AAFaceDetection/Visage" just drag the "Visage.swift" file into your project folder.

Visage is instantiated by passing a camera-position and a optimization setting for performance like this:
```
let visage = Visage(cameraPosition: Visage.CameraDevice.FaceTimeCamera, optimizeFor: Visage.DetectorAccuracy.HigherPerformance)
```

For *cameraPosition* the possible options are:
* `.ISightCamera`, which uses the back-facing camera of the iPhone or iPad.
* `.FaceTimeCamera`, which uses the front-facing camera of the iPhone or iPad.

For *optimizeFor* the possible options are:
* `.HigherPerformance`, which sets CIDetectorAccuracy to CIDetectorAccuracyHigh.
* `.BatteryLife`, which sets CIDetectorAccuracy to CIDetectorAccuracyLow. (also recommended on older devices)

As I said earlier Visage is based on sending NSNotifications as this is one of the easiest to grasp principles (at least it was for me) for beginners and it basically just works. You can subscribe to a number of events:

* `visageNoFaceDetectedNotification` fires whenever there has been no face detected.
* `visageFaceDetectedNotification` fires whenever there has been a face detected. 😐
* `visageHasSmileNotification` fires when the user is smiling. 😃
* `visageHasNoSmileNotification` fires when the user stopped smiling.
* `visageBlinkingNotification` fires when the user is blinking. (2 eyes closed at once)
* `visageNotBlinkingNotification` fires when the user stopped blinking. (at least one eye opened)
* `visageWinkingNotification` fires when the user is winking. (1 eye closed) 😉
* `visageNotWinkingNotification` fires when the user stopped winking. (2 eyes opened or closed)
* `visageLeftEyeClosedNotification` fires when the user closed the left eye.
* `visageLeftEyeOpenNotification` fires when the user opened the left eye.
* `visageRightEyeClosedNotification` fires when the user closed the right eye.
* `visageRightEyeOpenNotification` fires when the user opened the right eye.

You can subscribe to these events by using one of the provided methods `NSNotificationCenter.defaultCenter().addObsever*`. In the example I'm using the completionBlock but you can use any of the three provided functions and simply pass a selector.

By default these notifications are fired only when the status changes. There is however the option to receive a continuous stream of notifications, which may be handy for some purposes, which can be activated by setting `        visage!.onlyFireNotificatonOnStatusChange = false`. 
Keep in mind that this setting will likely decrease performance.

Visage provides a bunch of properties:
* `faceDetected : Bool?` whether there has been a face detected.
* `faceBounds : CGRect?` the position and size of the face in pixels on screen.
* `faceAngle : CGFloat?` the absolute angle of the face in radians.
* `faceAngleDifference : CGFloat?` the relative angle of the the face (to the previous one) in radians.
* `leftEyePosition : CGPoint?` the position of the left eye on screen.
* `rightEyePosition : CGPoint?` the position of the right eye on screen.
* `mouthPosition : CGPoint?` the position of the mouth on screen.
* `hasSmile : Bool?` whether there has been a smile detected.
* `isWinking : Bool?` whether there has been a wink detected.
* `isBlinking : Bool?` whether there has been a blink detected.
* `leftEyeClosed : Bool?` whether the left eye is closed or not.
* `rightEyeClosed : Bool?`whether the right eye is closed or not.

Visage also provides a previewView of the camera-image as this is something you might want.
Just add it to your view hierarchy like this: `self.view.addSubview(visage!.visageCameraView)`.

###Example Project
The included example uses a bunch of the features and uses it to map emojis to the user's current facial expression.

![screencast](https://github.com/aaronabentheuer/AAFaceDetection/blob/master/screencast.gif)

It's a very simple project that hopefully demonstrates the gist of using "AAFaceDetection/Visage" and is well commented. If you have any questions don't hesitate contacting me [@aaronabentheuer](http://www.twitter.com/aaronabentheuer).
