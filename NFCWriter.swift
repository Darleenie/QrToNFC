import CoreNFC
import Combine

/// Handles writing NDEF messages to NFC tags via CoreNFC.
/// Works as an ObservableObject so SwiftUI views can react to status changes.
@MainActor
class NFCWriter: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {

    @Published var statusMessage: String? = nil
    @Published var isSuccess: Bool = false

    private var session: NFCNDEFReaderSession?
    private var contentToWrite: String = ""

    // MARK: - Public API

    func write(content: String) {
        guard NFCNDEFReaderSession.readingAvailable else {
            setStatus("NFC is not available on this device.", success: false)
            return
        }
        contentToWrite = content
        statusMessage = nil

        session = NFCNDEFReaderSession(delegate: self, queue: .global(qos: .userInitiated), invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NFC tag to write."
        session?.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        // Ignore expected end-of-session codes
        if nfcError?.code == .readerSessionInvalidationErrorFirstNDEFTagRead ||
           nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
            return
        }
        Task { @MainActor in
            self.setStatus("Session error: \(error.localizedDescription)", success: false)
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used — we use didDetect tags for writing
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }

            if let error {
                session.invalidate(errorMessage: "Connection failed.")
                Task { @MainActor in self.setStatus("Connection failed: \(error.localizedDescription)", success: false) }
                return
            }

            tag.queryNDEFStatus { status, _, error in
                if let error {
                    session.invalidate(errorMessage: "Could not read tag status.")
                    Task { @MainActor in self.setStatus("Tag error: \(error.localizedDescription)", success: false) }
                    return
                }

                guard status != .readOnly else {
                    session.invalidate(errorMessage: "This tag is read-only.")
                    Task { @MainActor in self.setStatus("Tag is read-only and cannot be written.", success: false) }
                    return
                }

                let payload = self.buildPayload(for: self.contentToWrite)
                let message = NFCNDEFMessage(records: [payload])

                tag.writeNDEF(message) { error in
                    if let error {
                        session.invalidate(errorMessage: "Write failed.")
                        Task { @MainActor in self.setStatus("Write failed: \(error.localizedDescription)", success: false) }
                    } else {
                        session.alertMessage = "Written successfully!"
                        session.invalidate()
                        Task { @MainActor in self.setStatus("Written to NFC tag successfully.", success: true) }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Builds the correct NDEF payload type:
    /// - URI record for URLs  → iOS opens Safari (same as scanning a URL QR code)
    /// - Text record otherwise → iOS shows the text
    nonisolated private func buildPayload(for content: String) -> NFCNDEFPayload {
        if let url = URL(string: content),
           let scheme = url.scheme,
           !scheme.isEmpty,
           url.host != nil {
            // wellKnownTypeURIPayload returns nil only if the URL is malformed; we already validated above.
            return NFCNDEFPayload.wellKnownTypeURIPayload(url: url) ?? fallbackTextPayload(content)
        }
        return fallbackTextPayload(content)
    }

    nonisolated private func fallbackTextPayload(_ text: String) -> NFCNDEFPayload {
        return NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: .current)
            ?? NFCNDEFPayload(format: .nfcWellKnown, type: Data("T".utf8), identifier: Data(), payload: Data(text.utf8))
    }

    @MainActor
    private func setStatus(_ message: String, success: Bool) {
        isSuccess = success
        statusMessage = message
    }
}
