import AppKit
import AVFoundation
import CoreVideo
import Foundation

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("shorts")
let silentURL = outDir.appendingPathComponent("one_decision_short_silent.mp4")
let audioURL = outDir.appendingPathComponent("one_decision_voice.aiff")
let finalURL = outDir.appendingPathComponent("one_decision_youtube_short.mp4")

try? FileManager.default.removeItem(at: silentURL)
try? FileManager.default.removeItem(at: finalURL)

let width = 1080
let height = 1920
let fps: Int32 = 30
let duration = 28.0
let totalFrames = Int(duration * Double(fps))

struct Scene {
    let start: Double
    let end: Double
    let kicker: String
    let title: String
    let caption: String
    let accent: NSColor
}

let scenes = [
    Scene(start: 0.0, end: 3.7, kicker: "STOP SCROLLING", title: "You are one decision away", caption: "from a completely different week.", accent: NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.18, alpha: 1)),
    Scene(start: 3.7, end: 9.4, kicker: "THE RULE", title: "Pick one tiny thing", caption: "Make it so small you cannot negotiate with it.", accent: NSColor(calibratedRed: 0.12, green: 0.82, blue: 0.78, alpha: 1)),
    Scene(start: 9.4, end: 15.2, kicker: "EXAMPLE", title: "Not \"get fit\"", caption: "Just ten squats before the shower.", accent: NSColor(calibratedRed: 1.0, green: 0.38, blue: 0.48, alpha: 1)),
    Scene(start: 15.2, end: 21.6, kicker: "WHY IT WORKS", title: "Momentum beats motivation", caption: "Starting is the signal your brain believes.", accent: NSColor(calibratedRed: 0.55, green: 0.72, blue: 1.0, alpha: 1)),
    Scene(start: 21.6, end: 28.0, kicker: "TRY THIS", title: "Comment your one tiny action", caption: "Then do it before this loops.", accent: NSColor(calibratedRed: 0.72, green: 1.0, blue: 0.42, alpha: 1)),
]

func ease(_ x: Double) -> Double {
    let clamped = max(0, min(1, x))
    return 1 - pow(1 - clamped, 3)
}

func currentScene(at time: Double) -> Scene {
    scenes.last { time >= $0.start } ?? scenes[0]
}

func drawText(_ text: String, in rect: CGRect, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor, align: NSTextAlignment = .center, lineHeight: CGFloat = 1.05) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.minimumLineHeight = fontSize * lineHeight
    paragraph.maximumLineHeight = fontSize * lineHeight
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: 0
    ]
    NSString(string: text).draw(in: rect, withAttributes: attrs)
}

func drawFrame(time: Double, into buffer: CVPixelBuffer) {
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    guard let ctx = CGContext(
        data: base,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    ) else { return }

    let scene = currentScene(at: time)
    let local = (time - scene.start) / max(0.1, scene.end - scene.start)
    let pop = ease(min(local * 1.7, 1))
    let loopPulse = 0.5 + 0.5 * sin(time * 2.4)

    let bg = NSGradient(colors: [
        NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.05, alpha: 1),
        NSColor(calibratedRed: 0.08 + 0.04 * CGFloat(loopPulse), green: 0.12, blue: 0.14, alpha: 1),
        NSColor(calibratedRed: 0.02, green: 0.025, blue: 0.04, alpha: 1)
    ])!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    bg.draw(in: CGRect(x: 0, y: 0, width: width, height: height), angle: -35 + CGFloat(time * 2))

    ctx.setFillColor(scene.accent.withAlphaComponent(0.22).cgColor)
    let orbScale = CGFloat(0.85 + 0.10 * loopPulse)
    ctx.fillEllipse(in: CGRect(x: -160, y: 1180, width: 620 * orbScale, height: 620 * orbScale))
    ctx.setFillColor(scene.accent.withAlphaComponent(0.12).cgColor)
    ctx.fillEllipse(in: CGRect(x: 680, y: 260, width: 520, height: 520))

    let margin: CGFloat = 78
    let safeTop: CGFloat = 210
    let cardY = safeTop + CGFloat(16 * sin(time * 1.8))
    let glowRect = CGRect(x: margin, y: cardY, width: CGFloat(width) - margin * 2, height: 1060)
    let path = NSBezierPath(roundedRect: glowRect, xRadius: 34, yRadius: 34)
    scene.accent.withAlphaComponent(0.13).setFill()
    path.fill()

    drawText(scene.kicker, in: CGRect(x: margin, y: 320, width: CGFloat(width) - margin * 2, height: 60), fontSize: 42, weight: .black, color: scene.accent)

    let scale = CGFloat(0.94 + 0.06 * pop)
    let titleRect = CGRect(x: margin, y: 510 - 22 * scale, width: CGFloat(width) - margin * 2, height: 410)
    drawText(scene.title, in: titleRect, fontSize: 108 * scale, weight: .black, color: .white, lineHeight: 0.96)
    drawText(scene.caption, in: CGRect(x: margin + 20, y: 970, width: CGFloat(width) - (margin + 20) * 2, height: 190), fontSize: 55, weight: .semibold, color: NSColor(white: 0.86, alpha: 1), lineHeight: 1.12)

    let ringCenter = CGPoint(x: CGFloat(width) / 2, y: 1345)
    ctx.setLineWidth(24)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.16).cgColor)
    ctx.strokeEllipse(in: CGRect(x: ringCenter.x - 152, y: ringCenter.y - 152, width: 304, height: 304))
    ctx.setStrokeColor(scene.accent.cgColor)
    let ringPath = CGMutablePath()
    ringPath.addArc(center: ringCenter, radius: 152, startAngle: -.pi / 2, endAngle: -.pi / 2 + CGFloat(local * 2 * Double.pi), clockwise: false)
    ctx.addPath(ringPath)
    ctx.strokePath()
    drawText("\(Int(max(0, ceil(scene.end - time))))", in: CGRect(x: ringCenter.x - 120, y: ringCenter.y - 70, width: 240, height: 120), fontSize: 106, weight: .black, color: .white)

    let progress = CGFloat(time / duration)
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.16).cgColor)
    ctx.fill(CGRect(x: 70, y: 1750, width: CGFloat(width - 140), height: 12))
    ctx.setFillColor(scene.accent.cgColor)
    ctx.fill(CGRect(x: 70, y: 1750, width: CGFloat(width - 140) * progress, height: 12))
    drawText("@YourChannel", in: CGRect(x: 70, y: 1786, width: 360, height: 48), fontSize: 34, weight: .bold, color: NSColor(white: 0.78, alpha: 1), align: .left)
    drawText("SAVE THIS", in: CGRect(x: 650, y: 1786, width: 360, height: 48), fontSize: 34, weight: .bold, color: NSColor(white: 0.78, alpha: 1), align: .right)

    NSGraphicsContext.restoreGraphicsState()
}

let writer = try AVAssetWriter(outputURL: silentURL, fileType: .mp4)
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 8_000_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]
]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height
])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

let frameDuration = CMTime(value: 1, timescale: fps)
for frame in 0..<totalFrames {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
    if let buffer {
        let time = Double(frame) / Double(fps)
        drawFrame(time: time, into: buffer)
        adaptor.append(buffer, withPresentationTime: CMTimeMultiply(frameDuration, multiplier: Int32(frame)))
    }
}
input.markAsFinished()
let group = DispatchGroup()
group.enter()
writer.finishWriting { group.leave() }
group.wait()

let composition = AVMutableComposition()
let videoAsset = AVURLAsset(url: silentURL)
let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: .video)[0], at: .zero)
videoTrack.preferredTransform = videoAsset.tracks(withMediaType: .video)[0].preferredTransform

if FileManager.default.fileExists(atPath: audioURL.path) {
    let audioAsset = AVURLAsset(url: audioURL)
    if let sourceAudio = audioAsset.tracks(withMediaType: .audio).first {
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let audioDuration = min(audioAsset.duration, videoAsset.duration)
        try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration), of: sourceAudio, at: .zero)
    }
}

let semaphore = DispatchSemaphore(value: 0)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
exporter.outputURL = finalURL
exporter.outputFileType = .mp4
exporter.shouldOptimizeForNetworkUse = true
exporter.exportAsynchronously { semaphore.signal() }
semaphore.wait()

if exporter.status != .completed {
    throw NSError(domain: "ShortExport", code: 1, userInfo: [NSLocalizedDescriptionKey: exporter.error?.localizedDescription ?? "Unknown export failure"])
}

print(finalURL.path)
