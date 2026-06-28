//
//  ShareView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI

struct ShareView: View {
    let onDismiss: () -> Void
    var popoverSource: UIView?

    @State private var showLinkPlatformPicker = false
    @State private var linkPlatform: AppSharePlatform?
    @State private var qrPlatform: AppSharePlatform?
    @State private var showPDF = false

    private var accentColor: Color { Color("BaptismsBlue") }

    var body: some View {
        NavigationStack {
            List {
                shareRow(
                    title: "Send Link",
                    systemImage: "link",
                    action: { showLinkPlatformPicker = true }
                )
                shareRow(
                    title: AppSharePlatform.ios.qrCodeMenuTitle,
                    systemImage: "qrcode",
                    action: { qrPlatform = .ios }
                )
                shareRow(
                    title: AppSharePlatform.android.qrCodeMenuTitle,
                    systemImage: "qrcode",
                    action: { qrPlatform = .android }
                )
                shareRow(
                    title: "Promotional PDF",
                    systemImage: "doc.richtext",
                    action: { showPDF = true }
                )
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack {
                    Spacer(minLength: 8)
                    Image("morningstarmoroni")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 140, maxHeight: 140)
                        .darkBackgroundLogoGlow()
                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
            .navigationTitle("Share Holy Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .confirmationDialog(
            "Send Link",
            isPresented: $showLinkPlatformPicker,
            titleVisibility: .visible
        ) {
            Button(AppSharePlatform.ios.linkPickerTitle) {
                linkPlatform = .ios
            }
            Button(AppSharePlatform.android.linkPickerTitle) {
                linkPlatform = .android
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose which store link to share.")
        }
        .sheet(item: $linkPlatform) { platform in
            ShareActivityView(
                activityItems: AppShareLinks.activityItems(for: platform),
                popoverSource: popoverSource
            )
        }
        .sheet(item: $qrPlatform) { platform in
            ShareQRCodeView(platform: platform, popoverSource: popoverSource)
        }
        .sheet(isPresented: $showPDF) {
            SharePDFView(popoverSource: popoverSource)
        }
    }

    @ViewBuilder
    private func shareRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(accentColor)
                    .frame(width: 28)

                Text(title)
                    .font(.custom("Baskerville", size: 20))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
    }
}

extension AppSharePlatform: Identifiable {
    var id: Self { self }
}

#Preview {
    ShareView(onDismiss: {})
}
