//
//  ShareQRCodeView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI

struct ShareQRCodeView: View {
    let platform: AppSharePlatform
    var popoverSource: UIView?

    @State private var showShareSheet = false

    private var storeURL: URL {
        platform.storeURL
    }

    private var qrImage: UIImage? {
        QRCodeGenerator.image(from: storeURL.absoluteString)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(platform.qrScanInstruction)
                        .font(.custom("Baskerville", size: 20))
                        .multilineTextAlignment(.center)

                    if let qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 260, maxHeight: 260)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    } else {
                        Text("Unable to generate QR code.")
                            .font(.custom("Baskerville", size: 18))
                            .foregroundColor(.secondary)
                    }

                    Text(storeURL.absoluteString)
                        .font(.custom("Baskerville", size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)

                    if qrImage != nil {
                        Button("Share QR Image") {
                            showShareSheet = true
                        }
                        .font(.custom("Baskerville", size: 20))
                        .foregroundColor(Color("BaptismsBlue"))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("\(platform.qrTitle) QR Code")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showShareSheet) {
            if let qrImage {
                ShareActivityView(
                    activityItems: [qrImage, storeURL],
                    popoverSource: popoverSource
                )
            }
        }
    }
}
