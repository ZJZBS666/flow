# Flow

**用 365 颗圆点，看这一年过去了多少。**

一个极简的年度进度 App + 桌面小组件。没有账号、没有网络请求、没有广告、没有分析 SDK —— 打开就是一个数字和一片圆点。

<p align="center">
  <img src="docs/icon.png" width="120" alt="Flow 图标">
</p>

| 平台 | 位置 | 最低系统 | 产物 |
| --- | --- | --- | --- |
| iOS | `Flow/`、`Flow/Widget/` | iOS 17.0 | `Flow-unsigned.ipa` |
| Android | `android/` | Android 8.0（API 26） | `Flow-1.0.3.apk` |

两端共用同一套设计：圆环百分比、年 / 月 / 周 / 日四条进度、365 颗圆点（顺序排列 / 日历排列）、主题色与外观设置。

安卓版没有锁屏小组件（安卓本身也没有对应形态），保留主 App 与桌面小组件。

## 怎么编译

两个平台都在 GitHub Actions 上编译，本地什么都不用装：

- iOS：`.github/workflows/build.yml` → 产物 `Flow-unsigned-ipa`
- Android：`.github/workflows/build-android.yml` → 产物 `Flow-android-apk`

到仓库的 **Actions** 页面点最新的绿色记录，底部 **Artifacts** 里下载即可。

安卓的 APK 自带调试签名，可以直接侧载安装，不需要证书、不会过期；
iOS 的 IPA 是未签名的，需要用签名工具（爱思助手 / Sideloadly 等）配自己的证书装。
