import SwiftUI
import AVFoundation

/// SwiftUI wrapper around the camera-based QR scanner.
struct QRScannerView: View {
    let onScan: (String) -> Void

    var body: some View {
        ZStack {
            QRScannerRepresentable(onScan: onScan)
                .ignoresSafeArea()

            // Viewfinder overlay
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.8), lineWidth: 3)
                    .frame(width: 240, height: 240)
                Text("Point at a QR code")
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .shadow(radius: 4)
                Spacer()
            }
        }
    }
}

// MARK: - UIViewControllerRepresentable

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onScan = onScan
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

// MARK: - UIViewController

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        if captureSession != nil, !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else {
            showPermissionAlert(message: "No camera found on this device.")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            showPermissionAlert(message: "Camera access is required to scan QR codes. Please enable it in Settings.")
            return
        default:
            break
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            showPermissionAlert(message: "Could not access the camera.")
            return
        }

        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }

        hasScanned = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        captureSession.stopRunning()
        onScan?(value)
    }

    private func showPermissionAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Camera Unavailable", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
