---
description: 代码修改后自动推送到 GitHub
---

// turbo-all

完成代码修改后，执行以下命令自动推送：

1. 添加所有更改
```bash
git add .
```

2. 提交更改（使用合适的提交信息）
```bash
git commit -m "更新代码"
```

3. 拉取远程更新并变基
```bash
git pull --rebase origin main
```

4. 推送到 GitHub
```bash
git push origin main
```
