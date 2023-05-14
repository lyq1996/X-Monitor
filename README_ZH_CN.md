<p align="center">
  <img src="https://raw.githubusercontent.com/lyq1996/X-Monitor/main/docs/X-Monitor.png" height="300"/>
   <h2 align="center">X-Monitor</h2>
</p>
<p align="center">
  <div align="center">X-Monitor是一款开源、可拓展的macOS的事件监控工具，它使用Objective-C原生实现，可为安全人员提供进程行为审计的能力。</div>
</p>
<p align="center">
    <a href="https://github.com/lyq1996/X-Monitor/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-green" alt="LICENSE"></a>
    <img alt="Language" src="https://img.shields.io/badge/Language-Objective--C-blue.svg" />
    <a href="https://github.com/lyq1996/X-Monitor/README_ZH_CN.md"><img src="https://img.shields.io/badge/lang-简体中文-red.svg" alt="简体中文"></a>
    <a href="https://github.com/lyq1996/X-Monitor/README.md"><img src="https://img.shields.io/badge/lang-English-red.svg" alt="English"></a>
</p>

# 功能
它当前支持：
1. 来自Endpoint Security框架的`notify_exit`, `notify_exec`, `notify_fork`, `notify_open`, `notify_unlink`, `notify_rename`事件。
2. 可根据事件类型进行分类。

它未来将支持：
1. 来自Endpoint Security框架的所有事件（未完成）；
2. 来自Network Extension框架的网络连接、DNS事件（未完成）；
3. 进程链分析（未完成）；

# 安装
可以从源码编译，也可以安装预编译的二进制。

## 编译
需要Xcode Version 14.3

# 使用
由于X-Monitor的开发人员没有相应的Endpoint Security Entitlements，请关闭SIP使用。


![GUI](docs/X-Monitor-GUI.png)

1. 点击`start`，即可开始监控事件，订阅事件可通过左上角`X-Monitor`->`Settings`进行设置。
2. 点击具体行，可显示事件详细信息。

# 卸载
只需要将其移除到废纸篓。


# 技术支持
如果您在使用X-Monitor时遇到任何问题，欢迎提出。

# 待做事项
1. 完成所有Endpoint Security事件的解析（太多了，我需要帮助！）；
2. X-Service添加网络连接、DNS事件生产者；
3. 进程链分析；
4. 单元测试；
5. 文档编写；
6. 事件阻断机制实现；
7. 系统拓展XPC对端签名校验（自实现）；
8. 优化用于显示事件的NSTableView的性能。
