//
//  ModelDetailViewController.swift
//  CoreMLSampler
//
//  Created by tanaka.takaaki on 2017/08/21.
//  Copyright © 2017年 kongming. All rights reserved.
//

import AVFoundation
import UIKit
import CoreML
import Vision

class ModelDetailViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var elapsedLabel: UILabel!
    
    var modelType: ModelType?
    
    var session: AVCaptureSession!
    var image: UIImage?
    var captureTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = AVCaptureSession()
        let device = AVCaptureDevice.default(for: .video)
        let input = try! AVCaptureDeviceInput(device: device!)
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        session.addOutput(output)
        device?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        output.alwaysDiscardsLateVideoFrames = true
        session.startRunning()
        session.sessionPreset = .inputPriority
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = captureView.bounds
        captureView.layer.addSublayer(previewLayer)
        captureTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.takePhoto), userInfo: nil, repeats: true)
        captureTimer.fire()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureTimer.invalidate()
        session.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mlmodel() -> MLModel? {
        guard let type = modelType else { return nil }
        switch type {
        case .mobileNet:
            return MobileNet().model
        //case .squeezeNet:
            //return SqueezeNet().model
        //case .googLeNetPlaces:
            //return GoogLeNetPlaces().model
        case .resNet50:
            return Resnet50().model
        case .inceptionV3:
            return Inceptionv3().model
        case .vgg16:
            return Inceptionv3().model
        case .mymodel:
            return Food().model
        }
    }
    
    func coreMLRequest(image: UIImage) {
        guard let mlmodel = mlmodel() else { return }
        
        guard let coreMLModel = try? VNCoreMLModel(for: mlmodel) else {
            fatalError("faild create VMCoreMLModel")
        }
        
        print(coreMLModel)
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("faild convert CIImage")
        }

        let request = VNCoreMLRequest(model: coreMLModel) { request, error in
            print(request)
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Error faild results")
            }
            
            results.forEach { classification in
                print("identifier = \(classification.identifier)")
                print("confidence = \(classification.confidence)")
            }
            
            if let classification = results.first {
                self.identifierLabel.text = classification.identifier
                self.confidenceLabel.text = "\(classification.confidence)"
            } else {
                print("error")
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        guard (try? handler.perform([request])) != nil else {
            fatalError("faild handler.perform")
        }
    }
    
    func captureImage(sampleBuffer: CMSampleBuffer) -> UIImage {
        // Sampling Bufferから画像を取得
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let newContext: CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)!
        
        let imageRef: CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultImage
    }
    
    @objc func takePhoto() {
        if let image = self.image {
            coreMLRequest(image: image)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension ModelDetailViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let image: UIImage = self.captureImage(sampleBuffer: sampleBuffer)
        self.image = image
    }
}
