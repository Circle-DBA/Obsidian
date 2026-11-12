# ⑧ 干净单线 Minimal（极简线条风）

|项目|内容|
|---|---|
|编号|⑧|
|核心气质|极简单线条|
|色相基调|无彩色|
|视觉压力|很低|
|最适配场景|轻量看板、简单指标面板|
|备注|几乎无填充，表单引导弱，新手成本高|

## 风格说明

气质：几乎无填充，靠轮廓线条表达组件，留白巨大。

与「标准工业风」差异：工业风有明确卡片实底与硬分割线；本风格连卡片填充都抽掉，`--card` 与 `--background` 同色，纯靠 1px 描边组织信息。

## 质感要点

- 组件以描边为主，`--card` 与 `--background` 同色（几乎无填充差异），存在感全在 `--border`；
- 少色块：`--primary` 仅用于关键按钮 / 链接，大面积用 outline 形态；
- `--muted` / `--secondary` 极浅；
- 圆角 6–8px，让线条更柔和；
- 留白巨大；
- **短板**：表单、按钮引导偏弱，新用户上手成本高；只适合交互少、阅读为主的轻量页面。

## 通用规则

- 遵循 shadcn 标准 CSS 变量命名，亮色 / 暗色成对配套；
- 功能色降饱和：砖红危险、土黄告警、墨绿成功；
- 主色只用于关键按钮 / 链接，避免出现大色块；
- 切换主题只替换一套 CSS 变量，基座布局与交互不受影响。

## 配色明细

> 色值统一为 hex，含 `--destructive / --warning / --success` 语义色。`--card` 与 `--background` 同色，分层全靠 `--border` 描边；组件层需把 Card / 次按钮设为透明背景 + 1px 描边。

```
/* 亮色 */
:root {
  --background: #ffffff;
  --foreground: #1c1f1d;
  --card: #ffffff;
  --card-foreground: #1c1f1d;
  --popover: #ffffff;
  --popover-foreground: #1c1f1d;
  --primary: #1c1f1d;
  --primary-foreground: #ffffff;
  --secondary: #f6f7f6;
  --secondary-foreground: #1c1f1d;
  --muted: #f6f7f6;
  --muted-foreground: #98a09c;
  --accent: #eef0ef;
  --accent-foreground: #1c1f1d;
  --border: #cfd4d0;
  --input: #cfd4d0;
  --ring: #1c1f1d33;
  --destructive: #a84444;
  --warning: #b57f2a;
  --success: #367a56;
}
/* 暗色 */
.dark {
  --background: #0c0e0d;
  --foreground: #f1f3f2;
  --card: #0c0e0d;
  --card-foreground: #f1f3f2;
  --popover: #0c0e0d;
  --popover-foreground: #f1f3f2;
  --primary: #f1f3f2;
  --primary-foreground: #0c0e0d;
  --secondary: #181b19;
  --secondary-foreground: #f1f3f2;
  --muted: #181b19;
  --muted-foreground: #6b736e;
  --accent: #202422;
  --accent-foreground: #f1f3f2;
  --border: #3a403c;
  --input: #3a403c;
  --ring: #f1f3f233;
  --destructive: #b85252;
  --warning: #c8923d;
  --success: #418a64;
}
```
