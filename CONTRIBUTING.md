# 贡献指南

感谢您对 Hyprland Elite Desktop 项目的关注和支持！我们欢迎各种形式的贡献。

## 🤝 如何贡献

### 报告问题
- 使用 [Issues](https://github.com/laofahai/hyprland-elite-desktop/issues) 报告 bug
- 请提供详细的系统信息、错误信息和重现步骤
- 使用相关的标签标记问题类型

### 提交功能请求
- 在 Issues 中描述您想要的功能
- 解释这个功能为什么有用
- 如果可能，提供实现思路

### 代码贡献

#### 开发环境设置
```bash
# Fork 并克隆项目
git clone https://github.com/yourusername/hyprland-elite-desktop.git
cd hyprland-elite-desktop

# 创建开发分支
git checkout -b feature/your-feature-name
```

#### 代码规范
- **Shell 脚本**：遵循 POSIX 标准，使用 `shellcheck` 进行语法检查
- **配置文件**：保持一致的缩进和格式
- **文档**：使用中文和英文双语，保持简洁清晰

#### 提交规范
使用语义化提交信息：
```
feat: 添加新功能
fix: 修复问题
docs: 更新文档
style: 代码格式调整
refactor: 重构代码
test: 添加测试
chore: 构建和工具相关
```

### Pull Request 流程
1. Fork 项目并创建功能分支
2. 完成开发并测试功能
3. 确保代码通过 `shellcheck` 检查
4. 提交 Pull Request 并详细描述更改
5. 等待代码审查和合并

## 📋 项目结构

```
dotfiles/
├── config/              # 应用配置文件
│   ├── hypr/           # Hyprland 配置
│   ├── waybar/         # 状态栏配置
│   └── ...
├── scripts/            # 工具脚本
├── shell/              # Shell 配置
├── dotfiles.sh         # 主安装脚本
└── README.md           # 项目文档
```

## 🔧 测试

在提交前请确保：
- [ ] 所有脚本可以正常执行
- [ ] 配置文件语法正确
- [ ] 在虚拟机中测试安装过程
- [ ] 文档更新与代码变更一致

## 💡 贡献想法

### 优先级高的改进
- 支持更多 Linux 发行版
- 添加自动化测试
- 优化安装脚本性能
- 增强错误处理和用户反馈

### 长期目标
- 图形化配置界面
- 主题系统
- 插件架构
- 多语言支持

## 📞 联系方式

- GitHub Issues: 技术问题和 bug 报告
- Email: 急需联系时使用
- 讨论: 通过 GitHub Discussions 进行

## 📄 许可证

通过贡献代码，您同意您的贡献将在 MIT 许可证下发布。

---

再次感谢您的贡献！每一个贡献都让这个项目变得更好。