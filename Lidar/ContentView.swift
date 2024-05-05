//
//  ContentView.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var isCameraOn: Bool = false

    var body: some View {
        VStack {
            if isCameraOn {
                ZStack {
                    CameraPreview(isActive: $isCameraOn)
                }
            } else {
                Text("Tap to start camera")
                    .onTapGesture {
                        self.isCameraOn.toggle()
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct CameraPreview: View {
    @Binding var isActive: Bool

    var body: some View {
        CameraPreviewRepresentable(isActive: $isActive)
            .edgesIgnoringSafeArea(.all)
    }
}

// Integrates CameraViewController into SwiftUI view hierarchy
struct CameraPreviewRepresentable: UIViewControllerRepresentable {
    @Binding var isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if isActive {
            uiViewController.startCamera()
        } else {
            uiViewController.stopCamera()
        }
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraPreviewRepresentable

        init(_ parent: CameraPreviewRepresentable) {
            self.parent = parent
        }

        func didCaptureImage(image: UIImage) {
            parent.isActive = false
        }
    }
}

