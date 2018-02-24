//
//  BarcodeDetectionViewController.swift
//  CoreMLSampler
//
//  Created by tanaka.takaaki on 2017/10/29.
//  Copyright © 2017年 kongming. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

class BarcodeDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var handler = VNSequenceRequestHandler()
    private var currentTarget: VNDetectedObjectObservation?
    private var textLayer: CATextLayer! = nil
    private var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.session.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.session.stopRunning()
    }
    
    private func setup() {
        setupVideoProcessing()
        setupCameraPreview()
        setupTextLayer()
    }
    
    private func setupVideoProcessing() {
        self.session.sessionPreset = .photo
        
        let device = AVCaptureDevice.default(for: .video)
        let input = try! AVCaptureDeviceInput(device: device!)
        self.session.addInput(input)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: .global())
        self.session.addOutput(videoDataOutput)
    }
    
    private func setupCameraPreview() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.backgroundColor = UIColor.clear.cgColor
        self.previewLayer.videoGravity = .resizeAspectFill
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        self.previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(self.previewLayer)
        imageView.frame = self.view.bounds
        self.view.addSubview(imageView)
    }
    
    private func setupTextLayer() {
        let textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 20
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 24)
        textLayer.cornerRadius = 4
        textLayer.backgroundColor = UIColor(white: 0.25, alpha: 0.5).cgColor
        textLayer.position = self.view.center
        textLayer.isHidden = true
        self.previewLayer.addSublayer(textLayer)
        self.textLayer = textLayer
    }
    
    private func handleBarcodes(request: VNRequest, error: Error?) {
        guard let barcode = request.results?.first as? VNBarcodeObservation else {
            DispatchQueue.main.async {
                self.textLayer.isHidden = true
            }
            return
        }
        
        if let value = barcode.payloadStringValue {
            DispatchQueue.main.async {
                self.textLayer.string = value
                self.textLayer.isHidden = false
            }
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
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let handler = VNSequenceRequestHandler()
        let barcodesDetectionRequest = VNDetectBarcodesRequest(completionHandler: self.handleBarcodes)
        
        try? handler.perform([barcodesDetectionRequest], on: pixelBuffer)
    }
}
