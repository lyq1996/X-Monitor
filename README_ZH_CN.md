<p align="center">
  <img src="https://raw.githubusercontent.com/lyq1996/X-Monitor/main/docs/X-Monitor.png" height="300"/>
   <h2 align="center">X-Monitor</h2>
</p>
<p align="center">
  <div align="center">X-Monitor是一款开源、可拓展的macOS的事件监控工具，它使用Objective-C原生实现，可为安全人员提供进程行为审计的能力。注意：X-Monitor的代码大部分来源于2023年，因此99%由人工编写，而非AI-Agent😊。</div>
</p>
<p align="center">
    <a href="https://github.com/lyq1996/X-Monitor/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-green" alt="LICENSE"></a>
    <img alt="Language" src="https://img.shields.io/badge/Language-Objective--C-blue.svg" />
    <a href="https://github.com/lyq1996/X-Monitor/README_ZH_CN.md"><img src="https://img.shields.io/badge/lang-简体中文-red.svg" alt="简体中文"></a>
    <a href="https://github.com/lyq1996/X-Monitor/README.md"><img src="https://img.shields.io/badge/lang-English-red.svg" alt="English"></a>
</p>

![GUI](docs/X-Monitor-GUI.png)

# 功能
它当前支持：
1. 来自Endpoint Security框架的`notify_exec`,`notify_open`,`notify_fork`,`notify_close`,`notify_create`,`notify_exchangedata`,`notify_exit`,`notify_get_task`,`notify_kextload`,`notify_kextunload`,`notify_link`,`notify_mmap`,`notify_mprotect`,`notify_mount`,`notify_unmount`,`notify_iokit_open`,`notify_rename`,`notify_setattrlist`,`notify_setextattr`,`notify_setflags`,`notify_setmode`,`notify_setowner`,`notify_signal`,`notify_unlink`,`notify_write`,`notify_file_provider_materialize`,`notify_file_provider_update`,`notify_readlink`,`notify_truncate`,`notify_lookup`,`notify_chdir`,`notify_getattrlist`,`notify_stat`,`notify_access`,`notify_chroot`,`notify_utimes`,`notify_clone`,`notify_fcntl`,`notify_getextattr`,`notify_listextattr`,`notify_readdir`,`notify_deleteextattr`,`notify_fsgetpath`,`notify_dup`,`notify_settime`,`notify_uipc_bind`,`notify_uipc_connect`,`notify_setacl`,`notify_pty_grant`,`notify_pty_close`,`notify_proc_check`,`notify_searchfs`,`notify_proc_suspend_resume`,`notify_cs_invalidated`事件。
2. 可根据事件类型进行分类。

它未来将支持：
1. 提供来自`Endpoint Security`框架的`所有事件`（H1优先级）（X-Monitor被设计为可拓展的，因此添加`事件`非常简单，例如：[Add set extend attribute event](https://github.com/lyq1996/X-Monitor/commit/cd659bbb7fbf4d6a26abf675a7e623fd341f4855)，只需要在handle实现event属性的解析即可）；
2. 实现事件过滤器（H1优先级）；
3. 进程链分析（H2优先级）；
4. 来自`Network Extension`框架的网络连接、DNS事件（H2优先级）；
5. 事件保存至本地（H3优先级）；
6. 进程阻断（H3优先级）。

# 安装
可以从源码编译，也可以从release安装预编译的二进制。

## 从源码编译
需要Xcode 14.3及以上版本。

### Xcode 14.x
配置你自己的签名身份后直接编译即可。

### Xcode 26 (Xcode 16+)
Xcode 26 对带有 Entitlements 的 Ad-Hoc 签名增加了限制，会要求提供 Provisioning Profile。本项目通过以下方式绕过：
1. 在 X-Monitor 和 X-Service 的 Build Settings 中设置 `CODE_SIGNING_ALLOWED = NO`，禁止 Xcode 自动签名。
2. 添加了 Run Script Build Phase "Resign with Entitlements"，在编译完成后使用 `codesign --force --deep --sign - --entitlements` 对 App 和 System Extension 进行 Ad-Hoc 重签名并注入 Entitlements。

因此，使用 Xcode 26 时直接编译即可，无需额外配置。


## 从release安装
## 系统要求
X-Monitor被设计为支持`macOS 10.15`及以上的系统。

在创建工程时曾考虑过使用内核拓展（KEXT）支持`10.12 ~ 10.14`的系统，但：
1. KEXT是过时的；
2. KEXT支持的事件远比不上SEXT（来自`Endpoint Security`）；

因此，经过权衡，KEXT的开发计划无限期搁置。

## 注意事项
1. 由于X-Monitor的开发人员没有相应的`Entitlements`，请关闭SIP使用。
2. 可能会弹出`X-Monitor was not opened because it contains malware. This action did not harm your Mac.`，请在命令行输入：`xattr -cr /path/to/X-Monitor.app`

## 启动

1. 点击界面`start`，即可开始监控事件，订阅事件可通过左上角`X-Monitor`->`Settings`进行设置。
2. 点击具体行，可显示事件详细信息。

## 卸载
无任何本地文件存留，因此只需要将其移除到废纸篓，其中的系统拓展会自动移除。

# 支持
如果您在使用X-Monitor时遇到任何问题，欢迎提出issue。

# 其它待做事项
1. 单元测试；
2. 文档编写；
3. 系统拓展XPC对端签名校验（自实现）；
4. ~~优化用于显示事件的NSTableView的性能。~~(已完成)
