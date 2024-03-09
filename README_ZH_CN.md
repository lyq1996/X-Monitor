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

![GUI](docs/X-Monitor-GUI.png)

# 阻断进程与低版本macOS支持
如果你需要：
1. 阻断功能；
2. 10.12 ~ 10.14系统的事件监控。

可以使用[NuwaStone](https://github.com/ConradSun/NuwaStone)，该项目支持`阻断`未签名的二进制`执行`。

> NuwaStone未来可能与X-Monitor合并，并移动到[Macintosh-Mystery](https://github.com/Macintosh-Mystery)组织。

# 功能
它当前支持：
1. 来自Endpoint Security框架的`notify_exec`,`notify_open`,`notify_fork`,`notify_close`,`notify_create`,`notify_exchangedata`,`notify_exit`,`notify_get_task`,`notify_kextload`,`notify_kextunload`,`notify_link`,`notify_mmap`,`notify_mprotect`,`notify_mount`,`notify_unmount`,`notify_iokit_open`,`notify_rename`,`notify_setattrlist`,`notify_setextattr`,`notify_setflags`,`notify_setmode`,`notify_setowner`,`notify_signal`,`notify_unlink`,`notify_write`,`notify_file_provider_materialize`,`notify_file_provider_update`,`notify_readlink`,`notify_truncate`,`notify_lookup`,`notify_chdir`,`notify_getattrlist`,`notify_stat`,`notify_access`,`notify_chroot`,`notify_utimes`,`notify_clone`,`notify_fcntl`,`notify_getextattr`,`notify_listextattr`,`notify_readdir`,`notify_deleteextattr`,`notify_fsgetpath`,`notify_dup`事件。
2. 可根据事件类型进行分类。

它未来将支持：
1. 提供来自`Endpoint Security`框架的`所有事件`（H1优先级）（X-Monitor被设计为可拓展的，因此添加`事件`非常简单，例如：[Add set extend attribute event](https://github.com/lyq1996/X-Monitor/commit/cd659bbb7fbf4d6a26abf675a7e623fd341f4855)，只需要完善对应的event类，添加特有事件属性，然后在对应event类实现中描述如何序列化和显示详情，最后在handle实现event属性的解析即可）；
2. 实现事件过滤器（H1优先级）；
3. 进程链分析（H2优先级）；
4. 来自`Network Extension`框架的网络连接、DNS事件（H2优先级）；
5. 事件保存至本地（H3优先级）。

# 安装
可以从源码编译，也可以安装预编译的二进制。

## 编译
需要Xcode Version 14.3

# 使用
## 系统要求
X-Monitor被设计为支持`macOS 10.15`及以上的系统。

在创建工程时曾考虑过使用内核拓展（KEXT）支持`10.12 ~ 10.14`的系统，但：
1. KEXT是过时的；
2. KEXT支持的事件远比不上SEXT（来自`Endpoint Security`）；

因此，经过权衡，KEXT的开发计划无限期搁置。

## 注意事项
由于X-Monitor的开发人员没有相应的`Entitlements`，请关闭SIP使用。

## 启动

1. 点击界面`start`，即可开始监控事件，订阅事件可通过左上角`X-Monitor`->`Settings`进行设置。
2. 点击具体行，可显示事件详细信息。

## 卸载
只需要将其移除到废纸篓。

# 支持
如果您在使用X-Monitor时遇到任何问题，欢迎提出issue。

# 其它待做事项
1. 单元测试；
2. 文档编写；
3. 系统拓展XPC对端签名校验（自实现）；
4. ~~优化用于显示事件的NSTableView的性能。~~(已完成)
