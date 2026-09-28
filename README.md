# DockTuck

<p align="center">
  <img src="DockTuck/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="DockTuck" width="128" />
</p>

点击已经在前台的 App 的 Dock 图标，把它的窗口最小化。再点一次恢复。

DockTuck 是 [Click2Minimize](https://github.com/hatimhtm/Click2Minimize) 的非商业衍生项目，由 Warren2068 维护。菜单栏图标、应用图标和磁盘镜像缩略图都是 DockTuck 自己的图标。

## 许可

本项目继续适用 [PolyForm Noncommercial 1.0.0](LICENSE)（<https://polyformproject.org/licenses/noncommercial/1.0.0>）。修改和再分发也必须沿用同一份条款，并带上许可证正文或该 URL，以及下面这行原文：

Required Notice: Copyright Hatim El Hassak (https://github.com/hatimhtm/Click2Minimize)

Copyright © 2025–2026 Hatim El Hassak.

DockTuck 的改名和后续维护 © 2026 Warren2068.

个人使用、学习、爱好项目，以及非商业再分发，都在这份许可之内。商业使用需要另向版权持有人取得许可。

## 和上游的差别

代码基于上游 2.1，并保留 Dock 扫描修复：枚举过程中某个 Dock 图标消失时，System Events 可能返回 `-1728`。旧逻辑会把整份 `dockItems` 清空，点击最小化随后失效。现在会跳过消失的项；整次扫描失败或结果为空时，最多重试三次，每次间隔一秒。

应用名是 DockTuck，bundle id 是 `com.warren2068.DockTuck`。应用内更新检查指向 `Warren2068/DockTuck` 的 GitHub Releases；发现新版本时打开发布页供用户下载。

## 行为

- 点击**已经在前台**的 App 的 Dock 图标：最小化它的窗口。
- 点击**不在前台**的 App：保持 macOS 原有行为。
- Launchpad、废纸篓、下载：不处理。
- 前台 App 处于全屏：不最小化。
- 再次从“应用程序”打开已运行的 DockTuck：显示设置窗口。

实现上，菜单栏应用注册一个只看鼠标左键按下的 `CGEvent` tap，用缓存的 Dock 图标矩形做命中测试，再通过 Accessibility 把该 App 的可见窗口设为最小化。Dock 矩形由 AppleScript 查询，并在启动、激活、退出和空间切换后做 300ms 尾沿合并。

## 构建

需要 Xcode 26 或更新版本（新版图标使用 Icon Composer）。最低目标系统是 macOS 13.0，因为登录时启动功能使用 macOS 13 引入的 `SMAppService`。Release 同时包含 Apple Silicon (`arm64`) 和 Intel (`x86_64`)。Intel Mac 的官方系统范围是 macOS 13、14、15、26；macOS 27 只支持 Apple Silicon。实际能安装的系统版本仍取决于 Mac 机型。

```bash
xcodebuild -scheme DockTuck -configuration Release -derivedDataPath build

# 查看构建产物是否包含两个架构
lipo -archs build/Build/Products/Release/DockTuck.app/Contents/MacOS/DockTuck

# 生成 dist/DockTuck.dmg，包内附有 LICENSE
./build_dmg.sh
```

DMG 使用 ad-hoc 签名。第一次打开需要在 Finder 里右键，选择“打开”。启动后到系统设置 → 隐私与安全性 → 辅助功能，打开 DockTuck。需要自动化权限时，在菜单里打开 Automation Preferences。
