//
//  ImageResizer.swift
//  Lidar
//
//  Created by Cem Sertkaya on 5.05.2024.
//


import Foundation
import UIKit

public struct ImageResizer {
    var targetWidth: CGFloat
    
    public func resize(at url: URL) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        return self.resize(image: image)
    }
    
    public func resize(image: UIImage) -> UIImage {
        let originalSize = image.size
        let targetSize = CGSize(width: targetWidth, height: targetWidth*originalSize.height/originalSize.width)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    public func resize(data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else {return nil}
        return resize(image: image )
    }
}

struct MemorySizer {
    static func size(of data: Data) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
        bcf.countStyle = .file
        let string = bcf.string(fromByteCount: Int64(data.count))
        return string
    }
}
