//
//  PhotoCaptureProcessor.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//

import Foundation
import Photos
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class PhotoCaptureProcessor: NSObject {
    
    lazy var context = CIContext()

    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    
    /// The actual captured photo's data
    var photoData: Data?
    
    /// The depth data map image
    var depthMapImage: UIImage?

    init(with requestedPhotoSettings: AVCapturePhotoSettings) {
        self.requestedPhotoSettings = requestedPhotoSettings
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            // captured photo data
            photoData = photo.fileDataRepresentation()
            
            // depth data
            if let depthData = photo.depthData {
                depthMapImage = depthData.asDepthMapImage
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        } else {
            // save depth map as image
            if let uiImage = depthMapImage {
                if let tiffImageData = convertImageToTIFF(image: uiImage) {
                    saveTIFFImageToFile(imageData: tiffImageData, filename: "\(UUID())")
                }
            }
        }
    }

    func convertImageToTIFF(image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage.")
            return nil
        }

        let mutableData = CFDataCreateMutable(nil, 0)!

        guard let imageDestination = CGImageDestinationCreateWithData(mutableData, UTType.tiff.identifier as CFString, 1, nil) else {
            print("Failed to create CGImageDestination.")
            return nil
        }

        CGImageDestinationAddImage(imageDestination, cgImage, nil)
        CGImageDestinationFinalize(imageDestination)

        return mutableData as Data
    }

    func saveTIFFImageToFile(imageData: Data, filename: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename + ".tiff")

        do {
            try imageData.write(to: fileURL)
            print("TIFF image saved successfully at: \(fileURL)")
        } catch {
            print("Error saving TIFF image: \(error)")
        }
    }
}
