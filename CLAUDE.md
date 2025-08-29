- response in 中文
- 这是一个 IOS App,同时适配 ipad 和 macos 系统
- 目前只实现 IOS 界面，ipad 和 macos 系统暂时显示 hello world
- 优先使用 SwiftUI 开发，SwitfUI 实现不了的用 Uikit

### 本项目使用 xcodegen 管理，不需要你修改 knots3d.xcodeproj 文件，只要在增删文件之后执行一下 xcodegen 就行

- IOS App 使用下面这个命令进行编译: <br>
  `xcodebuild -scheme knots3d_iOS -destination 'platform=iOS Simulator,name=iPhone 16' build`
- 代码要整洁，重复的代码需要抽出来
- 代码可以适当的加一些注释
- 代码里的各种文本需要 **多语言**支持
- 每次修改完就 git commit，说明修改了什么
- 使用 NavigationLink 的话，不要加右箭头，NavigationLink 本身就包含了右箭头
