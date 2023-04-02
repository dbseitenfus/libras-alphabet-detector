/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The camera view shows the feed from the camera, and renders the points
     returned from VNDetectHumanHandpose observations.
*/

import UIKit
import AVFoundation

class CameraView: UIView {
    private var overlayThumbLayer = CAShapeLayer()
    private var overlayIndexLayer = CAShapeLayer()
    private var overlayMiddleLayer = CAShapeLayer()
    private var overlayRingLayer = CAShapeLayer()
    private var overlayLittleLayer = CAShapeLayer()
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return layer as? AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }

    private func setupOverlay() {
        previewLayer?.addSublayer(overlayThumbLayer)
        previewLayer?.addSublayer(overlayIndexLayer)
        previewLayer?.addSublayer(overlayMiddleLayer)
        previewLayer?.addSublayer(overlayRingLayer)
        previewLayer?.addSublayer(overlayLittleLayer)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == previewLayer {
            overlayThumbLayer.frame = layer.bounds
            overlayIndexLayer.frame = layer.bounds
            overlayMiddleLayer.frame = layer.bounds
            overlayRingLayer.frame = layer.bounds
            overlayLittleLayer.frame = layer.bounds
        }
    }

    func showPoints(_ points: [CGPoint]) {
        guard let wrist: CGPoint = points.last else {
            clearLayers()
            return
        }

        let thumbColor = UIColor(red: 0.6706, green: 0.3137, blue: 0.3686, alpha: 1)
        let indexColor = UIColor(red: 0.851, green: 0.6275, blue: 0.4431, alpha: 1)
        let middleColor = UIColor(red: 0.8118, green: 0.7843, blue: 0.5608, alpha: 1)
        let ringColor = UIColor(red: 0.6471, green: 0.6902, blue: 0.5647, alpha: 1)
        let littleColor = UIColor(red: 0.3765, green: 0.4706, blue: 0.451, alpha: 1)

        drawFinger(overlayThumbLayer, Array(points[0...4]), thumbColor, wrist)
        drawFinger(overlayIndexLayer, Array(points[4...8]), indexColor, wrist)
        drawFinger(overlayMiddleLayer, Array(points[8...12]), middleColor, wrist)
        drawFinger(overlayRingLayer, Array(points[12...16]), ringColor, wrist)
        drawFinger(overlayLittleLayer, Array(points[16...20]), littleColor, wrist)
    }

    func drawFinger(_ layer: CAShapeLayer, _ points: [CGPoint], _ color: UIColor, _ wrist: CGPoint) {
        let fingerPath = UIBezierPath()

        for point in points {
            fingerPath.move(to: point)
            fingerPath.addArc(withCenter: point, radius: 3, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }

        fingerPath.move(to: points[0])
        fingerPath.addLine(to: points[1])
        fingerPath.move(to: points[1])
        fingerPath.addLine(to: points[2])
        fingerPath.move(to: points[2])
        fingerPath.addLine(to: points[3])
        fingerPath.move(to: points[3])
        fingerPath.addLine(to: wrist)

        layer.fillColor = color.cgColor
        layer.strokeColor = color.cgColor
        layer.lineWidth = 3.0
        layer.lineCap = .round
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.path = fingerPath.cgPath
        CATransaction.commit()
    }

    func clearLayers() {
        let emptyPath = UIBezierPath()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayThumbLayer.path = emptyPath.cgPath
        overlayIndexLayer.path = emptyPath.cgPath
        overlayMiddleLayer.path = emptyPath.cgPath
        overlayRingLayer.path = emptyPath.cgPath
        overlayLittleLayer.path = emptyPath.cgPath
        CATransaction.commit()
    }
}
