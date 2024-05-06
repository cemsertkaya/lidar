//
//  CameraService.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

//  MARK: Class Camera Service, handles setup of AVFoundation needed for a basic camera app.
public struct Photo: Identifiable, Equatable {
    /// The ID of the captured photo
    public var id: String
    /// Data representation of the captured photo
    public var originalData: Data

    public init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

extension Photo {
    public var compressedData: Data? {
        ImageResizer(targetWidth: 800).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailData: Data? {
        ImageResizer(targetWidth: 100).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    public var image: UIImage? {
        guard let data = compressedData else { return nil }
        return UIImage(data: data)
    }
}

public class CameraService {
    typealias PhotoCaptureSessionID = String
    @Published public var photo: Photo?

    // MARK: Session Management Properties
    /// the capture session
    public let session = AVCaptureSession()
    /// whether the sessioin is running or not
    var isSessionRunning = false
    /// whether the sessioin is been cofigured or not
    var isConfigured = false
    /// the result of the setup process
    var setupResult: SessionSetupResult = .success
    /// the GDC queue to be used to execute most of the capture session's processes.
    /// Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    /// the device to capture video
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

    // MARK: Device Configuration Properties
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInLiDARDepthCamera],
        mediaType: .video,
        position: .unspecified
    )

    // MARK: Capturing Photos
    /// configures and captures photos
    private let photoOutput = AVCapturePhotoOutput()
    /// delegates that will handle the photo capture process's stages
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()

    // MARK: KVO and Notifications Properties

    private var keyValueObservations = [NSKeyValueObservation]()

    public func configure() {
        sessionQueue.async {
            self.configureSession()
        }
    }

    private func configureSession() {
        if setupResult != .success {
            return
        }

        session.beginConfiguration()

        session.sessionPreset = .photo

        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?

            guard let lidarDepthCamera = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
                //else case not handled assuming application already has non-lidar functionallity
                return
            }

            print("Lidar enabled ")

            defaultVideoDevice = lidarDepthCamera

            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput

            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)

            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.maxPhotoQualityPrioritization = .quality

        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()

        self.isConfigured = true

        self.start()
    }

    public func start() {
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                case .configurationFailed, .notAuthorized:
                    print("Application not authorized to use camera")
                }
            }
        }
    }

    public func capturePhoto() {
        if self.setupResult != .configurationFailed {
            sessionQueue.async {
                var photoSettings = AVCapturePhotoSettings()

                // Sets the depth data
                if self.photoOutput.isDepthDataDeliverySupported {
                    photoSettings.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliveryEnabled
                }

                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings)

                // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        }
    }
}
