- response in 中文
- 这是一个 IOS App,同时适配 ipad 和 macos 系统
- 目前只实现 IOS 界面，ipad 和 macos 系统暂时显示 hello world
- 优先使用 SwiftUI 开发，SwitfUI 实现不了的用 Uikit
- 使用 xcodegen 管理
- IOS App 使用下面这个命令进行编译: <br>
  `xcodebuild -scheme knots3d_iOS -destination 'platform=iOS Simulator,name=iPhone 16' build`
- 代码要整洁，重复的代码需要抽出来
