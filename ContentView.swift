import SwiftUI

struct ContentView: View {
    @State private var scannedContent: String = ""
    @State private var showScanner = false
    @StateObject private var nfcWriter = NFCWriter()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {

                // --- Scanned content display ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scanned QR Content")
                        .font(.headline)
                    ScrollView {
                        Text(scannedContent.isEmpty ? "No QR code scanned yet" : scannedContent)
                            .foregroundColor(scannedContent.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(maxHeight: 120)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // --- Scan button ---
                Button {
                    showScanner = true
                } label: {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // --- Write button ---
                Button {
                    nfcWriter.write(content: scannedContent)
                } label: {
                    Label("Write to NFC Tag", systemImage: "wave.3.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(scannedContent.isEmpty)

                // --- Status banner ---
                if let status = nfcWriter.statusMessage {
                    HStack {
                        Image(systemName: nfcWriter.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(status)
                            .font(.subheadline)
                    }
                    .foregroundColor(nfcWriter.isSuccess ? .green : .red)
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("QR → NFC")
            .animation(.easeInOut, value: nfcWriter.statusMessage)
            .sheet(isPresented: $showScanner) {
                QRScannerView { result in
                    scannedContent = result
                    showScanner = false
                    nfcWriter.statusMessage = nil
                }
            }
        }
    }
}
