import SpriteKit
import SwiftUI


struct SpriteAnimationData: Codable {
    struct Animation: Codable {
        let frames: [Int]
    }

    struct FrameData {
        let x: Int  // X坐标
        let y: Int  // Y坐标
        let width: Int  // 宽度
        let height: Int  // 高度
        let imageIndex: Int  // 图片索引
        let regX: Int  // X轴注册点
        let regY: Int  // Y轴注册点

        init(from array: [Int]) {
            self.x = array.count > 0 ? array[0] : 0
            self.y = array.count > 1 ? array[1] : 0
            self.width = array.count > 2 ? array[2] : 0
            self.height = array.count > 3 ? array[3] : 0
            self.imageIndex = array.count > 4 ? array[4] : 0
            self.regX = array.count > 5 ? array[5] : 0
            self.regY = array.count > 6 ? array[6] : 0
        }
    }

    let images: [String]
    let framerate: Int
    let frames: [[Int]]
    let animations: [String: Animation]
}

struct SpriteKitAnimationView: View {
    let width: CGFloat
    let height: CGFloat
    let showControls: Bool
    let animationData: KnotAnimation?

    @StateObject private var scene: SpriteAnimationScene

    init(width: CGFloat = 200, height: CGFloat = 400, showControls: Bool = true, animationData: KnotAnimation? = nil)
    {
        self.width = width
        self.height = height
        self.showControls = showControls
        self.animationData = animationData
        self._scene = StateObject(
            wrappedValue: SpriteAnimationScene(
                size: CGSize(width: width, height: height),
                animationData: animationData
            )
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            SpriteView(scene: scene)
                .frame(width: width, height: height)
                .onAppear {
                    scene.loadSpriteAnimation()
                }

            if showControls {
                controlsView
            }
        }
    }

    private var controlsView: some View {
        HStack(spacing: 15) {
            // 镜像反转按钮
            Button(action: {
                scene.toggleMirror()
            }) {
                Image(systemName: "arrow.left.and.right")
                    .font(.title2)
                    .foregroundColor(scene.isMirrored ? .blue : .primary)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(8)
            }

            // 90度逆时针旋转按钮
            Button(action: {
                scene.rotateSprite()
            }) {
                Image(systemName: "rectangle.landscape.rotate")
                    .font(.title2)
                    .foregroundColor(scene.isRotated ? .blue : .primary)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(8)
            }

            // 播放/暂停按钮
            Button(action: {
                if scene.isPlaying {
                    scene.pauseAnimation()
                } else {
                    scene.playAnimation()
                }
            }) {
                Image(
                    systemName: scene.isPlaying ? "pause.fill" : "play.fill"
                )
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color(UIColor.systemGray4))
                .cornerRadius(8)
            }

            // 停止按钮
            Button(action: {
                scene.stopAnimation()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(8)
            }

            // 360度模式按钮
            Button(action: {
                scene.toggle360Mode()
            }) {
                Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.title2)
                    .foregroundColor(scene.is360Mode ? .blue : .primary)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }

    func play() {
        scene.playAnimation()
    }

    func pause() {
        scene.pauseAnimation()
    }

    func stop() {
        scene.stopAnimation()
    }
}

class SpriteAnimationScene: SKScene, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isMirrored: Bool = false
    @Published var is360Mode: Bool = false
    @Published var isRotated: Bool = false

    private var spriteNode: SKSpriteNode?
    private var spriteTextures: [SKTexture] = []
    private var sprite360Textures: [SKTexture] = []
    private var frameDataList: [SpriteAnimationData.FrameData] = []
    private var frame360DataList: [SpriteAnimationData.FrameData] = []
    private var animationAction: SKAction?
    private var framerate: Int = 10
    private var baseFramerate: Int = 10
    private var currentRotation: CGFloat = 0
    private var animationData: KnotAnimation?

    // 记录当前动画状态，用于模式切换时的状态同步
    private var currentScale: CGFloat = 1.0
    private var currentMirrorScale: CGFloat = 1.0
    
    init(size: CGSize, animationData: KnotAnimation? = nil) {
        self.animationData = animationData
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .clear
    }

    func loadSpriteAnimation() {
        guard let animationData = animationData,
              let drawingAnimation = animationData.drawingAnimation else {
            print("动画数据不可用")
            return
        }
        
        // 获取文件名（去掉扩展名）
        let jsonName = String(drawingAnimation.spriteData.dropLast(5)) // 去掉.json
        let imageName = String(drawingAnimation.spriteImage.dropLast(4)) // 去掉.png
        
        // 加载普通动画资源
        guard
            let jsonPath = findResourcePath(
                for: jsonName,
                extension: "json"
            ),
            let imagePath = findResourcePath(
                for: imageName,
                extension: "png"
            ),
            let jsonData = try? Data(
                contentsOf: URL(fileURLWithPath: jsonPath)
            ),
            let spriteData = try? JSONDecoder().decode(
                SpriteAnimationData.self,
                from: jsonData
            ),
            let spriteImage = UIImage(contentsOfFile: imagePath)
        else {
            print("加载普通动画精灵数据失败: \(drawingAnimation.spriteData), \(drawingAnimation.spriteImage)")
            return
        }

        // 加载360度动画资源（可选）
        if let rotation360 = animationData.rotation360 {
            let json360Name = String(rotation360.spriteData.dropLast(5)) // 去掉.json
            let image360Name = String(rotation360.spriteImage.dropLast(4)) // 去掉.png
            
            if let json360Path = findResourcePath(
                for: json360Name,
                extension: "json"
            ),
                let image360Path = findResourcePath(
                    for: image360Name,
                    extension: "png"
                ),
                let json360Data = try? Data(
                    contentsOf: URL(fileURLWithPath: json360Path)
                ),
                let sprite360Data = try? JSONDecoder().decode(
                    SpriteAnimationData.self,
                    from: json360Data
                ),
                let sprite360Image = UIImage(contentsOfFile: image360Path)
            {
                generate360Textures(from: sprite360Image, with: sprite360Data)
                print("360度动画资源加载成功")
            } else {
                print("360度动画资源加载失败: \(rotation360.spriteData), \(rotation360.spriteImage)")
            }
        } else {
            print("360度动画资源未提供，仅使用普通动画模式")
        }

        generateTextures(from: spriteImage, with: spriteData)
        setupSpriteNode()
        showLastFrame()
    }

    /// 根据帧数计算动态帧率，完全还原JS逻辑
    /// - Parameter frameCount: 动画帧数
    /// - Returns: 计算后的帧率
    private func calculateFrameRate(frameCount: Int) -> Int {
        var frameRate = 1
        if frameCount < 20 {
            frameRate = 4
        } else if frameCount >= 20 && frameCount < 40 {
            frameRate = 5
        } else if frameCount >= 40 && frameCount < 60 {
            frameRate = 6
        } else if frameCount >= 60 && frameCount < 80 {
            frameRate = 7
        } else if frameCount >= 80 && frameCount < 100 {
            frameRate = 8
        } else if frameCount >= 100 {
            frameRate = 9
        }
        print("帧数: \(frameCount), 计算出的帧率: \(frameRate)")
        return frameRate
    }

    private func findResourcePath(for name: String, extension ext: String)
        -> String?
    {
        if let path = Bundle.main.path(forResource: name, ofType: ext) {
            return path
        }
        if let path = Bundle.main.path(
            forResource: name,
            ofType: ext,
            inDirectory: "Resources/sprite"
        ) {
            return path
        }
        if let path = Bundle.main.path(
            forResource: name,
            ofType: ext,
            inDirectory: "sprite"
        ) {
            return path
        }
        return nil
    }

    private func generateTextures(
        from image: UIImage,
        with data: SpriteAnimationData
    ) {
        guard let cgImage = image.cgImage,
            let animation = data.animations.values.first
        else { return }

        spriteTextures.removeAll()
        frameDataList.removeAll()

        // 存储基础帧率
        baseFramerate = data.framerate
        // 根据帧数计算实际帧率
        framerate = calculateFrameRate(frameCount: animation.frames.count)

        for frameIndex in animation.frames {
            guard frameIndex < data.frames.count else { continue }

            let frameArray = data.frames[frameIndex]
            let frameData = SpriteAnimationData.FrameData(from: frameArray)

            let rect = CGRect(
                x: frameData.x,
                y: frameData.y,
                width: frameData.width,
                height: frameData.height
            )

            if let croppedImage = cgImage.cropping(to: rect) {
                let texture = SKTexture(cgImage: croppedImage)
                texture.filteringMode = .nearest
                spriteTextures.append(texture)
                frameDataList.append(frameData)
            }
        }
    }

    private func generate360Textures(
        from image: UIImage,
        with data: SpriteAnimationData
    ) {
        guard let cgImage = image.cgImage,
            let animation = data.animations.values.first
        else { return }

        sprite360Textures.removeAll()
        frame360DataList.removeAll()

        // 360度动画固定使用7fps，参考JS实现
        let fixed360FrameRate = 7

        for frameIndex in animation.frames {
            guard frameIndex < data.frames.count else { continue }

            let frameArray = data.frames[frameIndex]
            let frameData = SpriteAnimationData.FrameData(from: frameArray)

            let rect = CGRect(
                x: frameData.x,
                y: frameData.y,
                width: frameData.width,
                height: frameData.height
            )

            if let croppedImage = cgImage.cropping(to: rect) {
                let texture = SKTexture(cgImage: croppedImage)
                texture.filteringMode = .nearest
                sprite360Textures.append(texture)
                frame360DataList.append(frameData)
            }
        }

        print(
            "360度动画加载完成，帧数: \(sprite360Textures.count), 固定帧率: \(fixed360FrameRate)"
        )
    }

    /// 状态同步函数，完全还原JS的syncAnimationState逻辑
    /// 在动画模式切换时保持变换状态一致
    private func syncAnimationState() {
        guard let node = spriteNode else { return }

        // 保存当前状态
        let currentPosition = node.position
        let currentXScale = node.xScale
        let currentYScale = node.yScale
        let currentZRotation = node.zRotation

        // 记录当前状态用于下次同步
        currentScale = abs(node.xScale)  // 记录绝对缩放值
        currentMirrorScale = node.xScale  // 记录带符号的缩放值（用于镜像状态）
        currentRotation = currentZRotation

        // 重新设置sprite节点（会触发setupSpriteNode）
        setupSpriteNode()

        // 恢复状态到新节点
        if let newNode = spriteNode {
            newNode.position = currentPosition
            newNode.xScale = currentXScale
            newNode.yScale = currentYScale
            newNode.zRotation = currentZRotation

            print(
                "状态同步完成 - 模式: \(is360Mode ? "360°" : "普通"), 位置: \(currentPosition), 缩放: \(currentXScale), 旋转: \(currentZRotation)"
            )
        }
    }

    private func setupSpriteNode() {
        spriteNode?.removeFromParent()

        // 根据当前模式选择纹理和帧数据
        let currentTextures = is360Mode ? sprite360Textures : spriteTextures
        let currentFrameDataList = is360Mode ? frame360DataList : frameDataList

        guard !currentTextures.isEmpty, !currentFrameDataList.isEmpty else {
            return
        }

        // 重要：按照JS逻辑，以最后一帧开始显示（完整绘制状态）
        spriteNode = SKSpriteNode(texture: currentTextures.last)

        if let node = spriteNode {
            // 使用最后一帧的注册点信息
            let lastFrameData = currentFrameDataList.last!

            // 设置锚点位置（注册点）
            // SKSpriteNode的anchorPoint是相对位置（0-1），需要转换
            let anchorX =
                CGFloat(lastFrameData.regX) / CGFloat(lastFrameData.width)
            let anchorY =
                CGFloat(lastFrameData.regY) / CGFloat(lastFrameData.height)
            node.anchorPoint = CGPoint(x: anchorX, y: 1.0 - anchorY)  // Y轴翻转，因为SpriteKit和CreateJS的坐标系不同

            // 设置节点位置
            node.position = CGPoint(x: size.width / 2, y: size.height / 2)

            // 自适应缩放以确保图像完整显示在view内
            let originalSize = node.texture?.size() ?? CGSize.zero
            if originalSize.width > 0 && originalSize.height > 0 {
                let scaleX = size.width / originalSize.width
                let scaleY = size.height / originalSize.height
                let scale = min(scaleX, scaleY)  // 选择较小的缩放比例确保完整显示
                currentScale = scale
                node.setScale(scale)
                print(
                    "模式: \(is360Mode ? "360°" : "普通"), scale: \(scale), anchorPoint: (\(anchorX), \(1.0 - anchorY))"
                )
            }

            // 保持之前的变换状态
            if isMirrored {
                node.xScale *= -1
                currentMirrorScale = node.xScale
            }
            node.zRotation = currentRotation
            
            // 更新旋转状态
            let normalizedRotation = currentRotation.truncatingRemainder(dividingBy: 2 * CGFloat.pi)
            isRotated = abs(normalizedRotation) > 0.01

            addChild(node)
        }
    }

    /// 显示最后一帧，还原JS中的完整绘制状态显示
    private func showLastFrame() {
        let currentTextures = is360Mode ? sprite360Textures : spriteTextures
        let currentFrameDataList = is360Mode ? frame360DataList : frameDataList

        guard !currentTextures.isEmpty,
              !currentFrameDataList.isEmpty,
              let node = spriteNode,
              let lastTexture = currentTextures.last // 安全地获取最后一帧纹理
        else { return }

        // 1. 设置为最后一帧纹理
        node.texture = lastTexture

        // 2. 【关键修复】将节点的 size 同步为最后一帧纹理的尺寸
//        node.size = lastTexture.size()

        // 3. 更新锚点为最后一帧的注册点
        let lastFrameData = currentFrameDataList.last!
        let anchorX = CGFloat(lastFrameData.regX) / CGFloat(lastFrameData.width)
        let anchorY =
            CGFloat(lastFrameData.regY) / CGFloat(lastFrameData.height)
        node.anchorPoint = CGPoint(x: anchorX, y: 1.0 - anchorY)
    }

    func playAnimation() {
        guard let node = spriteNode else { return }
        
        // 如果动画已经在播放，则不做任何事
        if isPlaying { return }

        // 检查节点上是否已存在动画
        // 如果存在，说明是暂停状态，我们只需要恢复即可
        if node.action(forKey: "spriteAnimation") != nil {
            node.isPaused = false
            isPlaying = true
            print("动画已从暂停处恢复")
        } 
        // 如果不存在，说明是首次播放或停止后播放，需要创建新动画
        else {
            // 根据当前模式选择纹理和帧数据
            let currentTextures = is360Mode ? sprite360Textures : spriteTextures
            let currentFrameDataList = is360Mode ? frame360DataList : frameDataList

            guard !currentTextures.isEmpty, !currentFrameDataList.isEmpty else { return }

            // 重要：按照JS逻辑，360度动画固定使用7fps，普通动画使用计算出的帧率
            let actualFrameRate = is360Mode ? 7 : framerate
            let frameTime = 1.0 / Double(actualFrameRate)
            var actions: [SKAction] = []

            print(
                "开始创建并播放新动画 - 模式: \(is360Mode ? "360°" : "普通"), 帧率: \(actualFrameRate), 总帧数: \(currentTextures.count)"
            )

            // 为每一帧创建动作，包括纹理和锚点变化
            for i in 0..<currentTextures.count {
                let texture = currentTextures[i]
                let frameData = currentFrameDataList[i]

                let textureAction = SKAction.setTexture(texture,resize: true)

                // 计算锚点，完全还原JS的注册点逻辑
                let anchorX = CGFloat(frameData.regX) / CGFloat(frameData.width)
                let anchorY = CGFloat(frameData.regY) / CGFloat(frameData.height)
                let anchorPoint = CGPoint(x: anchorX, y: 1.0 - anchorY)

                let anchorAction = SKAction.run {
                    node.anchorPoint = anchorPoint
                }

                // 组合纹理和锚点动作
                let combinedAction = SKAction.group([textureAction, anchorAction])
                let timedAction = SKAction.sequence([
                    combinedAction, SKAction.wait(forDuration: frameTime),
                ])

                actions.append(timedAction)
            }

            let animationSequence = SKAction.sequence(actions)
            let repeatAction = SKAction.repeatForever(animationSequence)

            animationAction = repeatAction
            node.run(repeatAction, withKey: "spriteAnimation")
            isPlaying = true
        }
    }

    func pauseAnimation() {
        guard let node = spriteNode, isPlaying else { return }

        // 不再移除Action，而是将节点暂停
        node.isPaused = true
        isPlaying = false
        print("动画已暂停")
    }

    func stopAnimation() {
        guard let node = spriteNode else { return }
        isPlaying = false
        // 确保节点不是暂停状态，以防万一
        node.isPaused = false
        node.removeAction(forKey: "spriteAnimation")
        setupSpriteNode()
        print("动画已停止并重置")
    }

    // 镜像翻转功能，完全还原JS的handleMirror逻辑
    func toggleMirror() {
        guard let node = spriteNode else { return }

        isMirrored.toggle()

        // JS中镜像动画持续时间为750ms，使用线性缓动
        let mirrorDuration = 0.75  // 750ms转换为秒
        let targetScaleX = isMirrored ? -abs(currentScale) : abs(currentScale)

        let flipAction = SKAction.scaleX(
            to: targetScaleX,
            duration: mirrorDuration
        )
        flipAction.timingMode = .linear  // 对应JS的createjs.Ease.linear()

        node.run(flipAction) {
            self.currentMirrorScale = targetScaleX
        }

        print("镜像状态: \(isMirrored ? "开启" : "关闭"), 目标缩放: \(targetScaleX)")
    }

    // 90度逆时针旋转功能
    func rotateSprite() {
        guard let node = spriteNode else { return }

        // 每次逆时针旋转90度 (π/2弧度)
        currentRotation += CGFloat.pi / 2

        // 更新旋转状态：检查角度是否为0的倍数
        let normalizedRotation = currentRotation.truncatingRemainder(dividingBy: 2 * CGFloat.pi)
        isRotated = abs(normalizedRotation) > 0.01 // 考虑浮点数精度问题

        // 旋转动画持续时间为1000ms，使用线性缓动
        let flipDuration = 1.0  // 1000ms转换为秒
        let rotateAction = SKAction.rotate(
            toAngle: currentRotation,
            duration: flipDuration
        )
        rotateAction.timingMode = .linear

        node.run(rotateAction)

        // 将角度转换为度数显示
        let degrees = Int(currentRotation * 180 / CGFloat.pi) % 360
        print("逆时针旋转90度，当前角度: \(degrees)度，旋转状态: \(isRotated)")
    }

    // 360度模式切换，完全还原JS的handleModeSwitch逻辑
//    func toggle360Mode() {
//        guard !sprite360Textures.isEmpty else {
//            print("360度动画资源不可用")
//            return
//        }
//
//        let wasPlaying = isPlaying
//        if wasPlaying {
//            pauseAnimation()
//        }
//
//        // 切换模式
//        is360Mode.toggle()
//        print("切换到\(is360Mode ? "360°" : "绘制")模式")
//
//        // 重要：使用状态同步功能保持变换状态一致
//        syncAnimationState()
//        showLastFrame()
//
//        // 根据JS逻辑，模式切换时自动开始播放动画
//        isPlaying = true
//        playAnimation()
//    }
    func toggle360Mode() {
        guard !sprite360Textures.isEmpty else {
            print("360度动画资源不可用")
            return
        }

        // 1. 记录切换前是否正在播放
        let wasPlaying = isPlaying

        // 2. 如果正在播放，先调用我们已有的暂停函数来停止它
        //    这个函数会自动将 isPlaying 设置为 false，这是关键
        if wasPlaying {
            pauseAnimation()
        }

        // 3. 切换模式，并同步状态（这会重建 spriteNode）
        is360Mode.toggle()
        print("切换到\(is360Mode ? "360°" : "绘制")模式")
        syncAnimationState()

        // 4. 如果切换前是在播放，那么现在就播放新的动画
        //    因为 isPlaying 在第2步已经变成 false，所以 playAnimation 会正常执行
        if wasPlaying {
            playAnimation()
        }
    }

}
