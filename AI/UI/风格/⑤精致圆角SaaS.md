# ⑤ 精致圆角现代 SaaS（海外主流 shadcn 原版风格）

|项目|内容|
|---|---|
|编号|⑤|
|核心气质|柔和精致商业|
|色相基调|青|
|视觉压力|中|
|最适配场景|客户中台、订阅、项目管理、低代码|
|备注|8px 圆角 + 阴影分层，高密度面板偏松散|

## 风格说明

气质：柔和精致，偏商业化 SaaS，Notion / Vercel 后台那一类。

与「标准工业风」差异：工业风线条硬、密度高、靠分割线分层；本风格靠阴影和圆角柔化，卡片不依赖边框，商业感更强，hover 有极柔和上浮。

## 质感要点

- 圆角 8px，留白充足；
- 阴影分层（卡片 `shadow-sm` / hover `shadow-md`），不依赖分割线，`--border` 极淡或透明；
- 主色低饱和但可稍鲜亮（青，chroma 适中）；
- hover 极柔和上浮（`transition` + `translateY` + 阴影加深）；
- 暗色 `--card` 比 `--background` 略浅一档；
- **短板**：高密度监控面板会显得松散，不适合一屏多指标的运维大屏。

## 通用规则

- 遵循 shadcn 标准 CSS 变量命名，亮色 / 暗色成对配套；
- 功能色降饱和：砖红危险、土黄告警、墨绿成功；
- 主色只用于激活态、按钮、焦点环、高亮文字，不做大面积铺色；
- 圆角、阴影由 `--radius` 与组件层阴影变量控制，切换风格时一并替换。

## 配色明细

> 色值统一为 hex，含 `--destructive / --warning / --success` 语义色。卡片阴影分层由组件层 `--shadow-card` / `--shadow-card-hover` 变量实现。

```
/* 亮色 */
:root {
  --background: #f8f9f8;
  --foreground: #1c211f;
  --card: #ffffff;
  --card-foreground: #1c211f;
  --popover: #ffffff;
  --popover-foreground: #1c211f;
  --primary: #0f6e60;
  --primary-foreground: #f0faf8;
  --secondary: #eef1f0;
  --secondary-foreground: #29302d;
  --muted: #eef1f0;
  --muted-foreground: #606b66;
  --accent: #dcefe9;
  --accent-foreground: #0f6e60;
  --border: #e6e9e7;
  --input: #d4dad7;
  --ring: #0f6e6044;
  --destructive: #a84444;
  --warning: #b57f2a;
  --success: #367a56;
}
/* 暗色 */
.dark {
  --background: #0c0e0d;
  --foreground: #f1f3f2;
  --card: #181b19;
  --card-foreground: #f1f3f2;
  --popover: #181b19;
  --popover-foreground: #f1f3f2;
  --primary: #4fc4ad;
  --primary-foreground: #06231e;
  --secondary: #202422;
  --secondary-foreground: #d4dbd7;
  --muted: #202422;
  --muted-foreground: #8b9790;
  --accent: #14352e;
  --accent-foreground: #96e0cf;
  --border: #232825;
  --input: #303833;
  --ring: #4fc4ad55;
  --destructive: #b85252;
  --warning: #c8923d;
  --success: #418a64;
}
```
