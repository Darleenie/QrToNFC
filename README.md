# QRToNFC

An iOS app that scans QR codes and writes their content to NFC tags.

## Requirements

- Mac with Xcode 15 or later
- iPhone 7 or newer (NFC support required)
- Apple Developer account (free account works for personal device testing)

> **Note:** Camera and NFC do not work in the iOS Simulator. A physical iPhone is required.

## Setup

### 1. Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS App** → Next
3. Configure:
   - **Product Name:** `QRToNFC`
   - **Bundle Identifier:** `com.yourname.QRToNFC`
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Save the project, then delete the auto-generated `ContentView.swift` and app entry point file
5. Drag the following source files into the project:
   - `QRToNFCApp.swift`
   - `ContentView.swift`
   - `QRScannerView.swift`
   - `NFCWriter.swift`

### 2. Configure Info.plist

In Xcode's target settings, add the following keys (or replace the default `Info.plist` with the one from this repo):

| Key | Value |
|-----|-------|
| `NSCameraUsageDescription` | `Camera is used to scan QR codes so you can write their content to an NFC tag.` |
| `NFCReaderUsageDescription` | `NFC is used to write the scanned QR code content to an NFC tag.` |
| `com.apple.developer.nfc.readersession.formats` | Array: `NDEF` |

### 3. Set Entitlements

In **Build Settings → Code Signing Entitlements**, set the value to `QRToNFC.entitlements`.

### 4. Enable Capabilities

In the target's **Signing & Capabilities** tab, add:

- **Near Field Communication Tag Reading**

Camera access is handled via `Info.plist` and does not require a separate capability.

## Running the App

1. Connect your iPhone via USB
2. In Xcode, select your device from the toolbar
3. Under **Signing & Capabilities**, sign in with your Apple ID and select a team
4. Press **Run (▶)**

The app will be built and installed on your device.

## Usage

1. Open the app and tap **Scan QR Code**
2. Point the camera at a QR code
3. Once scanned, tap **Write to NFC Tag**
4. Hold an NFC tag near the top of your iPhone to write the data
