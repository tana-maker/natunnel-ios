//
//  QRCodeScannerView.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI
import AVFoundation

public struct QRCodeScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    let onScanned: (String) -> Void

    @State private var isTorchOn = false

    public var body: some View {
        ZStack {
            ThemeColor.background.ignoresSafeArea()

            QRScannerControllerRepresentable(isTorchOn: isTorchOn) { code in
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
                onScanned(code)
                presentationMode.wrappedValue.dismiss()
            }
            .ignoresSafeArea()

            // Viewfinder Overlay
            VStack {
                // Top Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Scan V2Ray / VLESS QR")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        isTorchOn.toggle()
                    }) {
                        Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 22))
                            .foregroundColor(isTorchOn ? ThemeColor.primary : .white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))

                Spacer()

                // Target Box
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(ThemeColor.primary, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .shadow(color: ThemeColor.primary.opacity(0.6), radius: 12)

                    Text("Align QR code within the frame")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                        .offset(y: 150)
                }

                Spacer()
            }
        }
    }
}

struct QRScannerControllerRepresentable: UIViewControllerRepresentable {
    var isTorchOn: Bool
    var onFound: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.setTorch(on: isTorchOn)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        var onFound: (String) -> Void

        init(onFound: @escaping (String) -> Void) {
            self.onFound = onFound
        }

        func didFindCode(_ code: String) {
            onFound(code)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            captureSession?.stopRunning()
            delegate?.didFindCode(stringValue)
        }
    }
}
