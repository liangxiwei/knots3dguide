import SwiftUI
import UIKit

struct SpriteAnimationData: Codable {
    struct Frame: Codable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }
    
    struct Animation: Codable {
        let frames: [Int]
    }
    
    let images: [String]
    let framerate: Int
    let frames: [[Int]]
    let animations: [String: Animation]
}

class SpriteAnimationController: ObservableObject {
    @Published var currentFrame: Int = 0
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    private var spriteData: SpriteAnimationData?
    private var spriteImage: UIImage?
    private var animationName: String = "adjustablehitch"
    private var frameRate: Double = 10.0
    
    init() {
        loadSpriteData()
    }
    
    private func loadSpriteData() {
        // 打印bundle内容以调试
        if let bundlePath = Bundle.main.resourcePath {
            print("Bundle路径: \(bundlePath)")
        }
        
        // 尝试多种路径查找JSON文件
        var jsonPath: String?
        var imagePath: String?
        
        // 尝试直接从根目录查找
        jsonPath = Bundle.main.path(forResource: "adjustablehitch", ofType: "json")
        print("根目录查找结果: \(jsonPath ?? "nil")")
        
        if jsonPath == nil {
            // 尝试从Resources/sprite目录查找
            jsonPath = Bundle.main.path(forResource: "adjustablehitch", ofType: "json", inDirectory: "Resources/sprite")
            print("Resources/sprite目录查找结果: \(jsonPath ?? "nil")")
        }
        if jsonPath == nil {
            // 尝试从sprite目录查找
            jsonPath = Bundle.main.path(forResource: "adjustablehitch", ofType: "json", inDirectory: "sprite")
            print("sprite目录查找结果: \(jsonPath ?? "nil")")
        }
        
        imagePath = Bundle.main.path(forResource: "adjustablehitch", ofType: "png")
        if imagePath == nil {
            imagePath = Bundle.main.path(forResource: "adjustablehitch", ofType: "png", inDirectory: "Resources/sprite")
        }
        if imagePath == nil {
            imagePath = Bundle.main.path(forResource: "adjustablehitch", ofType: "png", inDirectory: "sprite")
        }
        
        guard let finalJsonPath = jsonPath,
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: finalJsonPath)) else {
            print("无法找到 adjustablehitch.json 文件")
            print("尝试的路径包括: Resources/sprite/, sprite/, 根目录")
            return
        }
        
        guard let finalImagePath = imagePath,
              let image = UIImage(contentsOfFile: finalImagePath) else {
            print("无法找到 adjustablehitch.png 文件")
            print("尝试的路径包括: Resources/sprite/, sprite/, 根目录")
            return
        }
        
        print("成功加载文件:")
        print("JSON: \(finalJsonPath)")
        print("PNG: \(finalImagePath)")
        
        spriteImage = image
        parseSpriteData(from: jsonData)
    }
    
    private func parseSpriteData(from jsonData: Data) {
        guard let data = try? JSONDecoder().decode(SpriteAnimationData.self, from: jsonData) else {
            print("无法解码sprite数据")
            return
        }

        spriteData = data
        frameRate = Double(data.framerate)
        
        // 使用动画的最后一帧作为默认显示帧
        if let animation = data.animations[animationName], !animation.frames.isEmpty {
            currentFrame = animation.frames.count - 1
        }
    }
    
    
    
    
    func play() {
        guard let data = spriteData else { return }
        
        isPlaying = true
        let interval = 1.0 / frameRate
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                if let animation = data.animations[self.animationName] {
                    self.currentFrame = (self.currentFrame + 1) % animation.frames.count
                }
            }
        }
    }
    
    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func stop() {
        pause()
        // 停止时回到最后一帧
        if let data = spriteData,
           let animation = data.animations[animationName], !animation.frames.isEmpty {
            currentFrame = animation.frames.count - 1
        } else {
            currentFrame = 0
        }
    }
    
    func getCurrentFrameImage() -> UIImage? {
        guard let data = spriteData,
              let image = spriteImage,
              let animation = data.animations[animationName] else {
            return nil
        }
        
        guard currentFrame < animation.frames.count else { return nil }
        
        let frameIndex = animation.frames[currentFrame]
        guard frameIndex < data.frames.count else { return nil }
        
        let frameData = data.frames[frameIndex]
        let x = frameData[0]
        let y = frameData[1]
        let width = frameData[2]
        let height = frameData[3]

        
        let rect = CGRect(x: x, y: y, width: width, height: height)
        
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct SpriteAnimationView: View {
    let width: CGFloat
    let height: CGFloat
    let showControls: Bool
    
    @StateObject private var controller = SpriteAnimationController()
    @State private var frameImage: UIImage?
    
    init(width: CGFloat = 200, height: CGFloat = 400, showControls: Bool = true) {
        self.width = width
        self.height = height
        self.showControls = showControls
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = frameImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .overlay(
                        Text("加载中...")
                            .foregroundColor(.secondary)
                    )
            }
            
            if showControls {
                controlsView
            }
        }
        .onReceive(controller.$currentFrame) { _ in
            frameImage = controller.getCurrentFrameImage()
        }
        .onAppear {
            frameImage = controller.getCurrentFrameImage()
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 15) {
            Button(action: {
                if controller.isPlaying {
                    controller.pause()
                } else {
                    controller.play()
                }
            }) {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                controller.stop()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
        }
    }
    
    // 便捷方法，用于访问控制器的公共方法
    func play() {
        controller.play()
    }
    
    func pause() {
        controller.pause()
    }
    
    func stop() {
        controller.stop()
    }
}
