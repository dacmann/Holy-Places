//
//  PhotoViewerView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

struct PhotoViewerView: View {
    let image: UIImage
    var onDismiss: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var zoomAnchor: UnitPoint = .center

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale, anchor: zoomAnchor)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(magnifyGesture)
                    .simultaneousGesture(panGesture)
                    .simultaneousGesture(doubleTapGesture(in: geo.size))

                VStack {
                    HStack {
                        Spacer()
                        Button(action: close) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.white.opacity(0.28))
                        }
                        .accessibilityLabel("Close")
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(4, max(1, lastScale * value.magnification))
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    scale = 1
                    lastScale = 1
                    offset = .zero
                    lastOffset = .zero
                    zoomAnchor = .center
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func doubleTapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if scale > 1.01 {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                        zoomAnchor = .center
                    } else {
                        let width = max(size.width, 1)
                        let height = max(size.height, 1)
                        zoomAnchor = UnitPoint(
                            x: min(max(value.location.x / width, 0), 1),
                            y: min(max(value.location.y / height, 0), 1)
                        )
                        scale = 4
                        lastScale = 4
                    }
                }
            }
    }

    private func close() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        zoomAnchor = .center
        onDismiss()
    }
}
