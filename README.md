# dsh-plugins.top 🐋

**DeepSeek Harness 插件精选站** —— 搜索、浏览、排行 DSH 社区插件。

> 线上地址：https://dsh-plugins.top（GitHub Pages 免费托管 + 自定义域名）

## 功能

- 🔍 **搜索栏**：按插件名 / 描述 / 关键词即时过滤
- 🗺️ **关键词地图**：标签云（记忆 / 上下文 / 浏览器 / 视觉 / 终端…），点击即过滤，支持组合搜索
- 🏆 **排行榜**：全库 Top 50 按 ⭐ 排行，金银铜奖牌
- 🏷️ **分类筛选 + 排序**：10 大分类 chips；Stars ↓ / Stars ↑ / A–Z
- 🔗 **公共镜像**：dsh-external 私有仓库自动链接到社区公开镜像，人人可点开
- 🔄 **每日自动同步**：打开页面自动拉取 [xiaohai-78/Top](https://github.com/xiaohai-78/Top) 最新 star 数据；社区插件由 `discover-dsh-plugins.ps1` 自动发现 `dsh-plugin` topic 并做清单校验
- 🐋 官方 DeepSeek logo 拼豆版（`#4D6BFE` 像素风）

## 部署（GitHub Pages + 自定义域名 + CI 自动重建）

```bash
# 1. 创建同名仓库（统一记忆点）
#    github.com/new → Repository name: dsh-plugins.top → Public → Create repository（不要初始化 README）
cd D:\VIMO\DSH\plugins\dsh-plugins.top
git remote add origin git@github.com:<用户名>/dsh-plugins.top.git
git push -u origin main

# 2. 启用 Pages（源选 GitHub Actions，由 CI 自动部署）
#    GitHub 网页 → Settings → Pages → Source: GitHub Actions
#    Custom domain: dsh-plugins.top → Save → 勾选 Enforce HTTPS

# 3. DNS（在你的域名注册商处，二选一）
#    方案 A（推荐，支持 CNAME 扁平化）：CNAME  dsh-plugins.top → <你的用户名>.github.io
#    方案 B（A 记录）：dsh-plugins.top → 185.199.108.153 / 185.199.109.153 / 185.199.110.153 / 185.199.111.153
#    （可选）www.dsh-plugins.top → CNAME → <你的用户名>.github.io
```

仓库里的 `CNAME` 文件内容为 `dsh-plugins.top`，保证自定义域名在换部署方式后依然生效。

## CI（`.github/workflows/ci.yml`）

- **触发**：每天 03:17 UTC（北京时间 11:17）定时 + `workflow_dispatch` 手动 + push 到 main
- **流程**：刷新 `top-data.json`（最新 star）→ 自动发现并校验 `dsh-plugin` topic（失败不覆盖旧数据）→ 生成 `site-data.json` → 生成 `index.html` → 冒烟测试 → 自动 commit 回仓库 → 部署到 GitHub Pages
- **推送**：CI 内使用 `GITHUB_TOKEN`（仅限本仓库，无需 SSH）；`permissions.contents: write` 已声明

## 数据与重建（可选，开发者）

生成脚本在 `D:\VIMO\DSH\plugins\` 工作区：

```
discover-dsh-plugins.ps1   # 搜索 + 校验 GitHub 公共 dsh-plugin topic → community-plugins.json
build-site-data.ps1        # 精选(top-data.json) + 社区合并 → site-data.json（含关键词）
build-site.ps1             # 注入 → index.html（本站）
smoke.js                   # 冒烟测试 node smoke.js
```

用 GitHub Actions 可每日自动重建：`discover → build-site-data → build-site → commit`，让榜单与 star 数永远新鲜。

## 致谢

数据：[xiaohai-78/Top](https://github.com/xiaohai-78/Top)（dsh-external 生态榜单）· 布局灵感：[skills.sh](https://www.skills.sh/vercel) · 生态参考：[awesome-deepseek-harness](https://github.com/0xsline/awesome-deepseek-harness)
