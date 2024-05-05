//
//  CameraViewController.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//

import Foundation
import AVFoundation
import SwiftUI

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(image: UIImage)
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: CameraViewControllerDelegate?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    private let depthOutput = AVCaptureDepthDataOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        depthOutput.setDelegate(self, callbackQueue: DispatchQueue.main)
    }

    func setupCamera() {
        captureSession = AVCaptureSession()

        guard let captureSession = captureSession else { return }

        guard let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
            //else case not handled assuming application already hase non-lidar functionallity
            print("This device has not a Lidar camera.")
            return
        }

        do {
            //adding input device for capturing session data
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
            return
        }

        //session output check
        if captureSession.canAddOutput(depthOutput) {
            captureSession.addOutput(depthOutput)
        } else {
            print("Unable to add depth output to capture session.")
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        captureSession.startRunning()
    }

    func startCamera() {
        DispatchQueue.global().async {
            self.captureSession?.startRunning()
        }
    }

    func stopCamera() {
        captureSession?.stopRunning()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            delegate?.didCaptureImage(image: image)
        }
    }

    func captureImage() {
        let settings = AVCapturePhotoSettings()
        AVCapturePhotoOutput().capturePhoto(with: settings, delegate: self)
    }
}

//capturing incoming data
extension CameraViewController: AVCaptureDepthDataOutputDelegate {
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        DispatchQueue.global().async {
            print(depthData.asDisparityFloat32)
        }
    }
}

//converting data do 32bit
extension AVDepthData {
    var asDisparityFloat32: AVDepthData {
        var convertedDepthData: AVDepthData
        if self.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            convertedDepthData = self.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        } else {
            convertedDepthData = self
        }

        return convertedDepthData
    }
}
