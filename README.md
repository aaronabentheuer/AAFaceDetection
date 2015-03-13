Visage
===============
Convenient implementation of iOS FaceDetection with CIDetector(ofType: CIDetectorTypeFace…).

###Introduction/Motivation
Although face-recognition was first introduced to the platform by Apple in iOS 5, we haven't seen much creative use of this quite interesting feature, especially on live video. This technology is especially interesting for prototyping experimental user-interfaces that make use of the user's emotion (smiling, blinking or winking) or detect the user's attention (whether he is looking at the screen or not). That's why I wanted to make it as easy as possible to prototype those interactions with a simple model based on NSNotifications whenever the status of the user's face changes. All the main features of Apples CIDetector(ofType: CIDetectorTypeFace…) are implemented and can be easily accessed.
