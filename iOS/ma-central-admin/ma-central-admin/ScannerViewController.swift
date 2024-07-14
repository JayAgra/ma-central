//
//  ScannerViewController.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import UIKit
import SwiftUI
import AVFoundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Binding var scannedValue: String?
    
    init(scannedValue: Binding<String?>) {
        _scannedValue = scannedValue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.pdf417] // Specify barcode type you want to scan
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            scannedValue = stringValue
            captureSession.stopRunning()
        }
    }

    func failed() { }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedValue: String?
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController(scannedValue: $scannedValue)
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedValue: $scannedValue)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedValue: String?

        init(scannedValue: Binding<String?>) {
            _scannedValue = scannedValue
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first,
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let stringValue = readableObject.stringValue {
                scannedValue = stringValue
            }
        }
    }
}
