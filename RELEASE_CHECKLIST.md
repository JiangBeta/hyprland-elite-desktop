# 发布前检查清单

## 必须完成的修改

### 1. 个人信息替换
- [ ] 替换 LICENSE 中的 `[Please replace with your name]` 为实际姓名
- [ ] 替换 README.md 中的 `YOUR_USERNAME` 为实际 GitHub 用户名
- [ ] 检查所有文件中是否还有个人路径或用户名

### 2. 配置文件清理
- [x] 移除 shell/zshrc 中的个人代理设置（已注释）
- [x] 移除 shell/zshrc 中的 bun 配置（已注释）
- [x] 移除 VS Code 个人配置和缓存数据
- [x] 移除 TOTP 个人密钥文件
- [x] 修复硬编码的个人路径为 $HOME

### 3. 安全检查
- [x] 确认没有密码、密钥或敏感信息
- [x] 确认 .gitignore 正确排除了敏感文件
- [x] 确认所有脚本都有适当的权限

### 4. 文档完善
- [x] README.md 包含完整的安装说明
- [x] 添加了 LICENSE 文件
- [x] 添加了 CONTRIBUTING.md
- [x] 添加了多发行版支持说明

### 5. 功能测试
- [ ] 在干净环境中测试 install.sh
- [ ] 测试 sync.sh 功能
- [ ] 验证所有脚本正常工作

## 可选改进

### 1. 功能增强
- [ ] 添加更多主题选择
- [ ] 添加配置向导脚本
- [ ] 添加卸载脚本

### 2. 文档改进
- [ ] 添加截图展示
- [ ] 添加视频演示
- [ ] 翻译 README 为英文版本

### 3. 社区功能
- [ ] 添加 Issue 模板
- [ ] 添加 PR 模板
- [ ] 设置 GitHub Actions

## 发布后
- [ ] 创建首个 release
- [ ] 添加 changelog
- [ ] 监控 issues 和反馈