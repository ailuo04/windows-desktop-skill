# Windows 桌面操作技能

把下面这句话发给你的 Codex，就可以安装。电脑重置后也可以用同一句话恢复。

> 请从 https://github.com/ailuo04/windows-desktop-skill 安装 Windows 桌面操作技能。先检查本机环境和已有的 agent-desktop MCP，按 README 运行安装脚本并验证。以后操作 Windows 应用时优先用这个 MCP，确实需要换工具时先说明原因。

## 在 Codex 中安装

需要已登录的 Windows 桌面会话、PowerShell 7 和可运行的 Codex CLI。首次安装 MCP 还需要 Node.js 18+、npm 和可用的网络。可用 Git 克隆，或从 GitHub 下载 ZIP 后解压。在仓库目录运行：

```powershell
pwsh -NoProfile -File .\install.ps1
```

默认安装到当前用户的 `.agents\skills`。若此前只在 Codex 配置目录的 `skills` 下安装过本技能，重复安装会沿用原位置。若客户端从其他位置加载个人技能，可以指定目录，例如 `pwsh -File .\install.ps1 -SkillsRoot "$env:USERPROFILE\.codex\skills"`。启用的同名 MCP 会被复用。全新安装会把上游 `agent-desktop@1.3.1` 放入当前 Codex 配置目录，校验对应架构的二进制文件，并用 `codex mcp add` 注册。支持 x64 和 ARM64，实机测试平台为 Windows x64。

相同版本可以重复安装。更新时，先拉取仓库变更；若已安装的技能内容有变化，核对后可加 `-UpdateSkill` 替换该技能文件。

新开一个 Codex 会话，发送「用 agent-desktop 查询版本，再列出当前可见窗口」。确认 AI 收到了工具返回的版本和窗口列表后，即可发送「打开 WorkBuddy 的加油站，帮我签到领取积分」等具体请求。应用需要已经安装并登录，能否操作取决于它向 Windows 暴露的控件和当前会话的权限。

## 其他 AI 客户端

使用支持本地 stdio MCP 的客户端时，可让 AI 阅读 `skills/agent-desktop-windows/SKILL.md`，并按该客户端的方式加载为桌面操作指引。在 Windows 安装上游 `agent-desktop@1.3.1` 后，注册名称 `agent-desktop`，命令填本机对应架构的可执行文件绝对路径，参数填 `mcp`。请在该客户端验证版本和窗口列表。仓库内的一键安装脚本适用于 Codex，其他客户端的集成尚未实测。

本仓库提供技能和安装脚本。桌面 MCP 来自 [vercel-labs/agent-desktop](https://github.com/vercel-labs/agent-desktop)。
