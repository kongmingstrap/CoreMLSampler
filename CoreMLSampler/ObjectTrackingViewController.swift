//
//  ObjectTrackingViewController.swift
//  CoreMLSampler
//
//  Created by tanaka.takaaki on 2017/10/28.
//  Copyright © 2017年 kongming. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

class ObjectTrackingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var handler = VNSequenceRequestHandler()
    private var currentTarget: VNDetectedObjectObservation?
    private var lockOnLayer = CALayer()
    
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
        setupTargetView()
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
    }
    
    private func setupTargetView() {
        self.lockOnLayer.borderWidth = 4.0
        self.lockOnLayer.borderColor = UIColor.green.cgColor
        self.previewLayer.addSublayer(self.lockOnLayer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        self.view.addGestureRecognizer(tapRecognizer)

        let longTapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        longTapRecognizer.minimumPressDuration = 0.5
        self.view.addGestureRecognizer(longTapRecognizer)
    }
    
    private func handleRectangls(request: VNRequest, error: Error?) {
        guard let nextTarget = request.results?.first as? VNDetectedObjectObservation else {
            return
        }
        self.currentTarget = nextTarget
        
        var boundingBox = nextTarget.boundingBox
        boundingBox.origin.y = 1 - boundingBox.origin.y
        let convertedRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: boundingBox)
        
        DispatchQueue.main.async {
            self.lockOnLayer.frame = convertedRect
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        self.lockOnLayer.frame.size = CGSize(width: 100, height: 100)
        self.lockOnLayer.position = sender.location(in: self.view)
        var convertedRect = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.lockOnLayer.frame)
        convertedRect.origin.y = 1 - convertedRect.origin.y
        self.currentTarget = VNDetectedObjectObservation(boundingBox: convertedRect)
    }
    
    @IBAction func longPressed(_ sender: Any) {
        self.currentTarget = nil
        self.lockOnLayer.frame = .zero
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let target = self.currentTarget else {
                return
        }
        
        let objectDetectionRequest = VNTrackObjectRequest(detectedObjectObservation: target,
                                                          completionHandler: self.handleRectangls)
        objectDetectionRequest.trackingLevel = .accurate
        
        try? self.handler.perform([objectDetectionRequest], on: pixelBuffer)
    }

}
