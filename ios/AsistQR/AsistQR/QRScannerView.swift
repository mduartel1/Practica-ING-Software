import SwiftUI
import AVFoundation
import Combine

final class QRScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isAuthorized = true
    @Published var statusText = "Esperando lectura..."
    @Published var lastCode: String? = nil
    @Published var lastScannedAt: Date? = nil

    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var isConfigured = false

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.configureSession()
                    } else {
                        self.statusText = "Permiso de camara denegado"
                    }
                }
            }
        default:
            isAuthorized = false
            statusText = "Permiso de camara denegado"
        }
    }

    func start() {
        guard isConfigured, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // No-op: evitar crashear si no se puede cambiar el flash
        }
    }

    private func configureSession() {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            statusText = "No se pudo acceder a la camara"
            isAuthorized = false
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            statusText = "No se pudo iniciar la camara"
            isAuthorized = false
            session.commitConfiguration()
            return
        }

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        session.commitConfiguration()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let code = object.stringValue else {
            return
        }

        if code == lastCode { return }
        lastCode = code
        lastScannedAt = Date()
        statusText = "Leido: \(code)"
        stop()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

struct QRScannerView: View {
    @EnvironmentObject private var store: AsistQRStore
    @StateObject private var scanner = QRScannerModel()
    @State private var isTorchOn = false
    @State private var showResult = false
    @State private var showManualEntry = false
    @State private var manualCode = ""
    @State private var isFocused = false
    @State private var scanResult: AttendanceRegistrationResult = .failure("Sin lectura.")

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.07),
                    Color(red: 0.06, green: 0.08, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Escanear QR")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Apunta la camara al QR de la sesion")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.black.opacity(0.35))
                        .frame(height: 320)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )

                    if scanner.isAuthorized {
                        CameraPreview(session: scanner.session)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.slash")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("Activa el permiso de camara")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(height: 320)
                    }

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 0.90, green: 0.87, blue: 0.35), lineWidth: 3)
                        .frame(width: 230, height: 230)
                }

                HStack(spacing: 14) {
                    Button {
                        isTorchOn.toggle()
                        scanner.setTorch(on: isTorchOn)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isTorchOn ? "bolt.fill" : "bolt")
                            Text("Flash")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white.opacity(0.12))
                        )
                    }

                    Button {
                        showManualEntry = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "keyboard")
                            Text("Manual")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white.opacity(0.12))
                        )
                    }
                }

                Spacer()

                Text(scanner.statusText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scanner.checkPermissions()
            scanner.start()
        }
        .onDisappear {
            scanner.stop()
            scanner.setTorch(on: false)
            isTorchOn = false
        }
        .onChange(of: scanner.lastCode) { _, newValue in
            guard let newValue else { return }
            register(code: newValue)
        }
        .sheet(isPresented: $showResult, onDismiss: {
            scanner.lastCode = nil
            scanner.statusText = "Esperando lectura..."
            scanner.start()
        }) {
            ScanResultView(code: scanner.lastCode ?? "-", scannedAt: scanner.lastScannedAt, result: scanResult)
        }
        .sheet(isPresented: $showManualEntry, onDismiss: {
            manualCode = ""
        }) {
            ManualEntryView(code: $manualCode) { submitted in
                scanner.lastCode = submitted
                scanner.lastScannedAt = Date()
                scanner.statusText = "Leido: \(submitted)"
                showManualEntry = false
                register(code: submitted)
            }
        }
    }

    private func register(code: String) {
        let name = store.currentUser?.name ?? "Desconocido"
        scanResult = store.registerAttendance(sessionCode: code, studentName: name)
        showResult = true
    }
}

struct ScanResultView: View {
    let code: String
    let scannedAt: Date?
    let result: AttendanceRegistrationResult

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: result.isSuccess ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(result.isSuccess ? Color(red: 0.48, green: 0.90, blue: 0.63) : Color(red: 0.95, green: 0.35, blue: 0.35))
                Text(result.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                if let scannedAt {
                    Text(scannedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Codigo QR")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(code)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                    )
            }

            Spacer()

            Text(result.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
}

struct ManualEntryView: View {
    @Binding var code: String
    var onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color(red: 0.90, green: 0.87, blue: 0.35))
                Text("Ingreso manual")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Escribe el codigo de la sesion")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            TextField("Codigo de sesion", text: $code)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.05))
                )
                .focused($isFocused)

            Button {
                let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onSubmit(trimmed)
            } label: {
                Text("Registrar")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                    )
                    .foregroundStyle(Color.black.opacity(0.9))
            }

            Button {
                dismiss()
            } label: {
                Text("Cancelar")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

#Preview {
    QRScannerView()
        .environmentObject(AsistQRStore())
}
