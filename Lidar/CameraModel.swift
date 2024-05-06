//
//  CameraModel.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//

import Combine
import AVFoundation

final class CameraModel: ObservableObject {
    private let service = CameraService()
    @Published var photo: Photo!

    @Published var willCapturePhoto = false

    @Published var isDepthMapAvailable = false

    @Published var isLiDARAvailable = false

    var session: AVCaptureSession

    private var subscriptions = Set<AnyCancellable>()

    init() {
        self.session = service.session

        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
    }

    func configure() {
        service.configure()
    }

    func capturePhoto() {
        service.capturePhoto()
    }
}
