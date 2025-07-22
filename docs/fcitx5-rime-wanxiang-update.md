# Fcitx5 + Rime + 万象输入法更新记录

本文档记录了对 `setup-rime-wanxiang.sh` 脚本的更新，以解决在清理旧的 Rime 配置文件时遇到的问题。

## 问题

在执行 `setup-rime-wanxiang.sh` 脚本时，`clean_old_config` 函数中的 `find` 命令在尝试删除非空目录时会失败，导致脚本中断。

## 解决方案

为了解决这个问题，`clean_old_config` 函数被重写，用一个 `for` 循环和 `rm -rf` 命令来代替 `find` 命令。这种方法可以确保在清理旧的配置文件时，非空目录也能被正确地删除。
