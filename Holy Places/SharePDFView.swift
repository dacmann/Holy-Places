//
//  SharePDFView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import PDFKit
import SwiftUI
import UIKit

struct SharePDFView: View {
    var popoverSource: UIView?

    @State private var showShareSheet = false

    private var pdfURL: URL? {
        AppShareLinks.promotionalPDFURL
    }

    var body: some View {
        NavigationStack {
            Group {
                if let pdfURL {
                    PDFKitRepresentable(url: pdfURL)
                } else {
                    ContentUnavailableView(
                        "Promotional PDF Not Available",
                        systemImage: "doc.richtext",
                        description: Text("The promotional PDF could not be found in the app bundle.")
                    )
                }
            }
            .navigationTitle("Promotional PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if pdfURL != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Print") {
                            printPDF()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Share") {
                            showShareSheet = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL {
                ShareActivityView(
                    activityItems: [pdfURL],
                    popoverSource: popoverSource
                )
            }
        }
    }

    private func printPDF() {
        guard let pdfURL,
              let pdfData = try? Data(contentsOf: pdfURL) else { return }

        let printController = UIPrintInteractionController.shared
        printController.printingItem = pdfData

        if let popoverSource {
            printController.present(from: popoverSource.bounds, in: popoverSource, animated: true)
        } else {
            printController.present(animated: true, completionHandler: nil)
        }
    }
}

private struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}
}
