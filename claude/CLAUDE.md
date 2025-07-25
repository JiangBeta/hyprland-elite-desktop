# Sub-Agent 检查和使用要求

## 强制性 Sub-Agent 检查
在每个 session 开始时，必须：

1. **检查项目级 sub-agents**：搜索 `.claude/agents/` 目录下的可用 sub-agents
2. **检查用户级 sub-agents**：搜索 `~/.claude/agents/` 目录下的可用 sub-agents  
3. **强制使用**：如发现合适的 sub-agent，必须优先使用该 sub-agent 进行任务处理

## Sub-Agent 检查流程
```bash
# 检查项目级 sub-agents
ls -la .claude/agents/ 2>/dev/null

# 检查用户级 sub-agents
ls -la ~/.claude/agents/ 2>/dev/null
```

## 使用优先级
1. 项目特定 sub-agents（最高优先级）
2. 用户自定义 sub-agents
3. 默认 Claude 行为（仅当无 sub-agent 可用时）

## Sub-Agent 调用方式
- 使用 `/agents` 命令查看可用 sub-agents
- 根据任务类型自动选择合适的 sub-agent
- 明确提及特定 sub-agent 名称进行调用

---

# Gemini CLI 集成指南
## 概述

本指南说明如何在 Claude Code 中集成 Gemini CLI，实现两个 AI 模型的协同工作。
## 触发条件

当用户输入以下任一指令时，Claude 将启动与 Gemini 的协作模式：
### 支持的触发词

- `Proceed with Gemini` / `与 Gemini 协商`
- `Consult with Gemini` / `咨询 Gemini`
- `Let's discuss this with Gemini` / `让我们和 Gemini 讨论这个`
### 正则表达式匹配

```regex
/(proceed|consult|discuss).*gemini/i
工作流程

1. 提示词生成
Claude 分析用户需求，生成适合 Gemini 的提示词：
export PROMPT="<用户需求的结构化描述>"

2. Gemini CLI 调用
使用 heredoc 方式调用 Gemini：
gemini <<EOF
$PROMPT
EOF

3. 响应处理
• 原始输出：保留 Gemini 的完整响应
• Claude 增强：添加以下内容
▪ 关键要点总结
▪ 补充说明和上下文
▪ 两个模型观点的对比分析

4. 整合输出
最终输出格式：

## Gemini 响应
[Gemini 的原始回答]
## Claude 分析
[Claude 的补充见解和整合]
## 综合结论
[两个 AI 协作后的最终建议]
