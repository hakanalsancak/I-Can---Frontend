import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let circleSize: CGFloat = 300
    private let minScale: CGFloat = 0.4
    private let maxScale: CGFloat = 5.0

    /// Base image size: shorter side matches circle diameter
    private var baseImageSize: CGSize {
        let aspect = image.size.width / image.size.height
        if aspect > 1 {
            // Landscape: height = circleSize, width scales up
            return CGSize(width: circleSize * aspect, height: circleSize)
        } else {
            // Portrait: width = circleSize, height scales up
            return CGSize(width: circleSize, height: circleSize / aspect)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: baseImageSize.width, height: baseImageSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = max(minScale, min(newScale, maxScale))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    CircleMaskOverlay(circleSize: circleSize)
                        .allowsHitTesting(false)
                }
            }

            VStack {
                Text("Move and Scale")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                Spacer()

                HStack {
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                    }

                    Spacer()

                    Button {
                        let cropped = cropImage()
                        onCrop(cropped)
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func cropImage() -> UIImage {
        let outputSize: CGFloat = 600 // final image pixels
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSize, height: outputSize))
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: outputSize, height: outputSize))
            UIBezierPath(ovalIn: rect).addClip()

            // The image is drawn at baseImageSize * scale, centered, then offset
            let drawW = baseImageSize.width * scale
            let drawH = baseImageSize.height * scale

            // Map from circle's coordinate system to output pixels
            let ratio = outputSize / circleSize

            let drawX = (outputSize / 2) - (drawW / 2 * ratio) + (offset.width * ratio)
            let drawY = (outputSize / 2) - (drawH / 2 * ratio) + (offset.height * ratio)

            image.draw(in: CGRect(x: drawX, y: drawY, width: drawW * ratio, height: drawH * ratio))
        }
    }
}

// MARK: - Circle Mask Overlay

private struct CircleMaskOverlay: View {
    let circleSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black.opacity(0.6))
                )

                let circleRect = CGRect(
                    x: (size.width - circleSize) / 2,
                    y: (size.height - circleSize) / 2,
                    width: circleSize,
                    height: circleSize
                )
                context.blendMode = .destinationOut
                context.fill(Path(ellipseIn: circleRect), with: .color(.white))
            }
            .compositingGroup()

            Circle()
                .strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                .frame(width: circleSize, height: circleSize)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
