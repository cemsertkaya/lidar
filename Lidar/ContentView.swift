//
//  ContentView.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var model = CameraModel()

    // MARK: - body
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                CameraPreview(session: model.session)
                    .onAppear {
                        model.configure()
                    }


                Button(action: {
                    model.capturePhoto()
                }, label: {
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60, alignment: .center)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                .frame(width: 65, height: 65, alignment: .center)
                        )
                })
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
             AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {

    }
}
