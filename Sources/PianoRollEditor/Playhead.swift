import SwiftUI

public struct Playhead: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerWidth = rect.width * 0.1
        path.move(to: CGPoint(x: rect.minX + cornerWidth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerWidth, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerWidth), control: .init(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - cornerWidth))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerWidth, y: rect.midY + cornerWidth), control: .init(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + cornerWidth / 2, y: rect.maxY - cornerWidth / 2))
        path.addQuadCurve(to: CGPoint(x: rect.midX - cornerWidth / 2, y: rect.maxY - cornerWidth / 2), control: .init(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerWidth, y: rect.midY + cornerWidth))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY - cornerWidth), control: .init(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerWidth))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerWidth, y: rect.minY), control: .init(x: rect.minX, y: rect.minY))

        return path
    }
}

#if DEBUG
struct Playhead_Previews: PreviewProvider {
    static var previews: some View {
        Playhead()
            .frame(width: 100, height: 100)
    }
}
#endif
