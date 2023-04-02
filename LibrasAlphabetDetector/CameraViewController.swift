//
//  ViewController.swift
//  LibrasAlphabetDetector
//
//  Created by Daniel on 27/02/23.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {
    private var cameraView: CameraView!
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var session = AVCaptureSession()
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var model: LibrasClassifier?
    private let fingerJointGroupsDict: [VNHumanHandPoseObservation.JointsGroupName: [VNHumanHandPoseObservation.JointName]] = [
        .thumb: [.thumbTip, .thumbIP, .thumbMP, .thumbCMC],
        .indexFinger: [.indexTip, .indexDIP, .indexPIP, .indexMCP],
        .middleFinger: [.middleTip, .middleDIP, .middlePIP, .middleMCP],
        .ringFinger: [.ringTip, .ringDIP, .ringPIP, .ringMCP],
        .littleFinger: [.littleTip, .littleDIP, .littlePIP, .littleMCP]
    ]

    private lazy var letter: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.center = view.center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ""
        label.textAlignment = .center
        label.textColor = .yellow
        label.font = UIFont.systemFont(ofSize: 50)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView = view as? CameraView
        handPoseRequest.maximumHandCount = 1
        setupCaptureSession()
        setupCameraPreviewLayer()
        setupCameraVideoOutput()
        createLibrasClassifier()
        startSession()
        view.addSubview(letter)
    }
    
    func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Could not find a front facing camera.")
            return
        }
        

        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Could not create video device input.")
            return
        }

        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            return
        }
        
        session.sessionPreset = .photo
        session.addInput(deviceInput)
    }

    func setupCameraVideoOutput() {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraFeedDataOutput"))
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        }
    }

    func setupCameraPreviewLayer() {
        cameraView.previewLayer?.session = session
        cameraView.previewLayer?.videoGravity = .resizeAspectFill
    }

    private func startSession() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.session.startRunning()
        }
    }

    func createLibrasClassifier() {
        model = try? LibrasClassifier(configuration: MLModelConfiguration())
    }

    func recognizeHandPose(sampleBuffer: CMSampleBuffer) throws -> VNHumanHandPoseObservation? {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        try handler.perform([handPoseRequest])
        return handPoseRequest.results?.first
    }

    func getHandPosePoints(observation: VNHumanHandPoseObservation) throws -> [VNRecognizedPoint] {
        var handPosePoints: [VNRecognizedPoint] = []

        for (fingerName, jointNames) in fingerJointGroupsDict {
            let fingerPoints = try observation.recognizedPoints(fingerName)
            for jointName in jointNames {
                if let fingerPoint = fingerPoints[jointName] {
                    handPosePoints.append(fingerPoint)
                }
            }
        }

        guard let wristPoints = try? observation.recognizedPoints(.all) else {
            return []
        }

        if let wristPoint = wristPoints[.wrist] {
            handPosePoints.append(wristPoint)
        }

        guard handPosePoints.count == 21 else {
            return []
        }

        return handPosePoints
    }

    func hasLowConfidence(handPosePoints: [VNRecognizedPoint]) -> Bool {
        return handPosePoints.contains(where: {$0.confidence < 0.3})
    }

    func clearScreenElements() {
        DispatchQueue.main.async {
            self.letter.text = ""
            self.cameraView.clearLayers()
        }
    }

    func mapHandPointsToScreenCoordinates(handPosePoints: [VNRecognizedPoint]) -> [CGPoint] {
        guard let previewLayer = cameraView.previewLayer else {
            return []
        }

        let convertedPoints = handPosePoints.compactMap { point -> CGPoint? in
            let location = point.location.inverted()
            let convertedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: location)
            return convertedPoint.flipped(superView: view)
        }

        return convertedPoints
    }

    func makePrediction(keypointsMultiArray: MLMultiArray) throws -> LibrasClassifierOutput? {
        return try model?.prediction(poses: keypointsMultiArray)
    }
}

extension CGPoint {
    func inverted() -> CGPoint {
        return CGPoint(x: self.y, y: self.x)
    }

    func flipped(superView: UIView) -> CGPoint {
        return CGPoint(x: superView.frame.width - self.x, y: superView.frame.height - self.y)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait

        do {
            guard let observation = try recognizeHandPose(sampleBuffer: sampleBuffer),
            let handPosePoints = try? getHandPosePoints(observation: observation),
            !hasLowConfidence(handPosePoints: handPosePoints) else {
                clearScreenElements()
                return
            }

            DispatchQueue.main.async {
                let cgPoints = self.mapHandPointsToScreenCoordinates(handPosePoints: handPosePoints)
                self.cameraView.showPoints(cgPoints)
            }

            let keypointsMultiArray = try observation.keypointsMultiArray()
            if let result = try makePrediction(keypointsMultiArray: keypointsMultiArray) {
                DispatchQueue.main.async {
                    self.letter.text = result.label
                }
            }
        } catch {
            session.stopRunning()
        }
    }
}
