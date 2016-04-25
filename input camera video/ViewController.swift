//
//  ViewController.swift
//  input camera video
//
//  Created by Rplay on 25/04/16.
//  Copyright © 2016 rplay. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //----------------//
    //-- Global var --//
    //----------------//
    
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureVideoDataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    var sessionQueue: dispatch_queue_t?
    var isStart: Bool?
    
    //-------------//
    //-- Outlets --//
    //-------------//
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var switchCameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSession()
    }
    
    override func viewDidAppear(animated: Bool) {
        prevLayer?.frame.size = cameraView.frame.size
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //--------------------//
    //-- Create session --//
    //--------------------//
    
    //-- Create video session.
    func createSession() {
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)  //-- Dispatch work in a specific queue.
        session = AVCaptureSession()                                                //-- Declare session.
        session?.sessionPreset = AVCaptureSessionPresetMedium                       //-- Choose a presset.
        device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)       //-- Choose video media.
        var error: NSError? = nil
        
        do {
            try input = AVCaptureDeviceInput(device: device)                        //-- Create input.
        } catch let err as NSError {
            error = err
        }
        
        if error == nil {
            session?.addInput(input)                                                //-- Add input to the session.
        } else {
            print("camera input error: \(error)")
        }
        
        prevLayer = AVCaptureVideoPreviewLayer(session: session)                    //-- Prepare to display the preview.
        prevLayer?.frame.size = cameraView.frame.size                               //-- To the good size.
        prevLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill               //-- With the good aspect.
        prevLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait //-- And the good orientation.
        cameraView.layer.addSublayer(prevLayer!)                                    //-- Display the preview.
        session?.startRunning()                                                     //-- Let's go.
    }
    
    //------------------//
    //-- Video output --//
    //------------------//
    
    //-- Add video output.
    func addVideoOutput() {
        
        let videoSettings =
            [
                kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)    //-- Choose video settings.
            ] as [NSObject : AnyObject]

        output = AVCaptureVideoDataOutput()                                         //-- Set capture video data object.
        output?.videoSettings = videoSettings                                       //-- Set settings.
        output?.alwaysDiscardsLateVideoFrames = true                                //-- Avoid latency.
        output!.setSampleBufferDelegate(self, queue: sessionQueue)                  //-- Buffer delegate.
        
        if session!.canAddOutput(output) {
            session!.addOutput(output)                                              //-- Add output to the session. -> (captureOutput)
        }
    }
    
    //-- Stop video output.
    func stopVideoOutput() {
        session?.removeOutput(output)
    }
    
    
    //-- Loop when output is added to session
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        if CMSampleBufferGetImageBuffer(sampleBuffer) != nil {
            let image = imageFromSampleBuffer(sampleBuffer)     //-- Transform buffer to UIImage
            print("Image \(image)")                             //-- You can send or record this image.
        }
    }
    
    
    //-------------//
    //-- Actions --//
    //-------------//
    
    //-- Start action.
    @IBAction func start(sender: UIButton) {
        isStart = isStart == nil ? false : isStart
        
        if !isStart! {
            isStart = true
            addVideoOutput()
            startButton.setTitle("Stop", forState: .Normal)
        } else {
            isStart = false
            stopVideoOutput()
            startButton.setTitle("Start", forState: .Normal)
        }
    }
    
    //-- Switch camera action.
    @IBAction func switchCameraSide(sender: AnyObject) {
        if let sess = session {
            let currentCameraInput: AVCaptureInput = sess.inputs[0] as! AVCaptureInput
            sess.removeInput(currentCameraInput)
            var newCamera: AVCaptureDevice
            
            if (currentCameraInput as! AVCaptureDeviceInput).device.position == .Back {
                newCamera = self.cameraWithPosition(.Front)!
            } else {
                newCamera = self.cameraWithPosition(.Back)!
            }
            
            do {
                let newVideoInput = try AVCaptureDeviceInput(device: newCamera)
                session?.addInput(newVideoInput)
            } catch let err as NSError {
                print(err)
            }
        }
    }
    
    //-------------//
    //-- Methods --//
    //-------------//
    
    //-- Method to convert sampleBuffer to UIImage (found on the web).
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer:CVImageBuffer! = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let baseAddress: UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddress(imageBuffer)
        let baseAddressUint8 : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>(baseAddress)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        //-- Create a bitmap graphics context with the sample buffer data
        let context = CGBitmapContextCreate(baseAddressUint8, width, height, 8, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue);
        let quartzImage = CGBitmapContextCreateImage(context)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        //-- Create an image object from the Quartz image
        let image = UIImage(CGImage: quartzImage!, scale: 1.0, orientation: UIImageOrientation.Right)
        
        return (image);
    }
    
    //-- Method for check camera positon (front or back).
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        for device in devices {
            if device.position == position {
                return device as? AVCaptureDevice
            }
        }
        
        return nil
    }
}

