---
title: "第二单元: 系统运维与排障"
subtitle: "Git 分支管理与作业提交规范"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 为什么需要分支

---

## 分支冲突的悲剧

- 每年都会有同学的分支出现冲突
- 直接修改主分支导致无法合并
- 作业提交后才发现 "Merge Block"

> "理解分支 = 理解平行宇宙的概念"

---

## 典型冲突场景

```
main 分支:     A --- B --- C
                  \
lab01 分支:      D --- E

# 如果在 main 上修改了 B 点的 README
# 同时 lab01 也修改了 README
# → 冲突产生!
```

> 红色的分叉线 = 硬分叉 = 无法自动合并

---

# Topic 2: 正确的分支操作流程

---

## 标准工作流

```bash
# 1. 确认当前分支
git branch -v -a

# 2. 回到主分支
git checkout main

# 3. 创建新分支 (以第二次作业为例)
git checkout -b lab02

# 4. 创建同名目录
mkdir lab02
cd lab02

# 5. 编写作业文件
echo "# Lab 02 Report" > README.md
```

---

## 提交与推送

```bash
# 添加文件
git add lab02/

# 编写规范的 commit message
git commit -m "feat: 完成 Lab02 实验报告

- 添加环境配置截图
- 完成所有实验步骤记录
- 补充故障排查过程"

# 推送到远程
git push origin lab02
```

---

# Topic 3: Commit Message 规范

---

## 不好的示例

```
update
upload new file
修改
1
```

> 这种提交信息 = 云盘式使用 Git

---

## 好的示例

```
feat: 添加 Lab02 网络配置实验报告

docs: 补充 DNS 排障过程截图

fix: 修正图片路径错误 (screenshot/)
```

> AI 可以帮你生成规范的 commit message！

---

## 基本规范

| 类型 | 说明 |
| :--- | :--- |
| `feat:` | 新功能 |
| `fix:` | 修复问题 |
| `docs:` | 文档更新 |
| `refactor:` | 代码重构 |

> **记叙文三要素**: 时间、地点、人物 → Git: 做了什么、变更内容

---

# Topic 4: Merge Request 规范

---

## 提交作业的正确姿势

1. **确认分支状态**: GitLab 显示 "Ready to merge"
2. **不要点击 Merge**! 保持 Open 状态
3. **指定 Reviewer**: 勾选助教
4. **确保目录隔离**: 每次作业独立目录

---

## 检查清单

```bash
# 提交前自检:
□ 是否在正确分支上？
□ 是否创建了同名目录？
□ README 是否能在 GitLab 正确渲染？
□ 图片路径是否正确？(相对路径)
□ 分支是否有冲突？(Repository Graph)
```

---

## 图片路径注意事项

```markdown
# 错误 ❌
![](1.png)

# 正确 ✓
![](screenshot/1.png)
```

> **交付意识**: 提交后自己点开看一下，助教看到的就是你看到的

---

# Topic 5: 处理冲突

---

## 预防冲突的最佳实践

```bash
# 每次新建作业前:
git checkout main           # 回到原点
git pull origin main        # 同步最新代码
git checkout -b lab03       # 创建新分支
```

> 这样就能确保所有分支有共同的起点

---

## 冲突解决流程

```bash
# 如果已经出现冲突
# 1. 查看冲突文件
git status

# 2. 手动编辑解决冲突 (<<<<< ===== >>>>> 标记)

# 3. 标记为已解决
git add <resolved-file>

# 4. 继续提交
git commit -m "fix: 解决分支冲突"
```

---

# Topic 6: 学习与成长

---

## Git 与开源文化

- Git 作者 = Linux 作者 = Linus Torvalds
- 没有 Git 就没有今天的开源社区
- 边学边做，在实践中学习

> "犯错是成长的代价，不是扣分的理由"

---

## 常见错误

| 错误 | 后果 | 学习价值 |
| :--- | :--- | :--- |
| 误点 Merge | 印象深刻 | 下次不会 |
| 分支冲突 | 学会解决 | 理解分支 |
| 路径错误 | 图片不显示 | 交付意识 |

> "犯错不可怕，可怕的是重复犯同样的错"

