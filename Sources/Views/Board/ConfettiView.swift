import SwiftUI

struct ConfettiView: View {
    let count: Int

    @State private var pieces: [ConfettiPiece] = []

    private let palette: [Color] = [
        BRColors.primary, BRColors.surfaceHigh,
        Color(hex: "#ff6b6b"), Color(hex: "#4ecdc4"),
        Color(hex: "#f9ca24"), Color(hex: "#ffc5aa"),
        Color(hex: "#a29bfe"), Color(hex: "#fd79a8")
    ]

    init(count: Int = 70) {
        self.count = count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, bounds: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            pieces = (0..<count).map { i in
                ConfettiPiece(color: palette[i % palette.count])
            }
        }
    }
}

// MARK: - Data

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startXRatio: CGFloat = CGFloat.random(in: 0.2...0.8)
    let endXRatio: CGFloat = CGFloat.random(in: -0.1...1.1)
    let endYRatio: CGFloat = CGFloat.random(in: 0.4...1.1)
    let width: CGFloat = CGFloat.random(in: 6...14)
    let height: CGFloat = CGFloat.random(in: 4...9)
    let startRotation: Double = Double.random(in: 0...360)
    let endRotation: Double = Double.random(in: 720...1440)
    let delay: Double = Double.random(in: 0...0.4)
    let duration: Double = Double.random(in: 1.0...1.8)
    let isCircle: Bool = Bool.random()
}

// MARK: - Single Piece View

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let bounds: CGSize

    @State private var x: CGFloat = 0
    @State private var y: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Group {
            if piece.isCircle {
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.width, height: piece.width)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.width, height: piece.height)
            }
        }
        .position(x: x, y: y)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .onAppear {
            x = piece.startXRatio * bounds.width
            y = -20
            rotation = piece.startRotation

            withAnimation(.easeOut(duration: piece.duration).delay(piece.delay)) {
                x = piece.endXRatio * bounds.width
                y = piece.endYRatio * bounds.height
                rotation = piece.endRotation
            }
            withAnimation(.easeIn(duration: 0.5).delay(piece.delay + piece.duration - 0.5)) {
                opacity = 0
            }
        }
    }
}
