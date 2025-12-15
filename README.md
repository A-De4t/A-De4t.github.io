# A-De4t 模拟金融交易 Starter（商品类，单一卖家）

这是一个“模拟交易（paper trading）”的 Starter 项目（Next.js + Supabase）。适合作为原型或研发环境，用于商品/大宗商品交易逻辑演示与算法验证。

本项目要点
- 前端：Next.js (pages)
- 身份与 DB：Supabase（Auth + Postgres）
- 模拟撮合（paper engine）：在 server-side 通过写入 orders / trades 表并根据模拟市价生成成交
- 不处理真实资金、不接入真实经纪（可在 README 指南中看到如何切换到实盘适配器）

文件结构（zip 内容）
- package.json
- .env.example
- README.md (本文件)
- pages/
  - index.js
  - login.js
  - signup.js
  - dashboard.js
  - api/market.js
  - api/orders.js
  - api/webhook.js
- lib/
  - supabaseClient.js
  - paperEngine.js
- components/
  - Layout.js
- create_zip.sh
- create_zip.ps1

快速开始（本地）
1. 在 Supabase 创建项目（https://supabase.com），记下：
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - SUPABASE_SERVICE_ROLE_KEY（服务端使用，请妥善保管，不要放到前端）

2. 在 Supabase SQL Editor 中执行下列 SQL（创建必要表）：
```sql
-- users 由 Supabase Auth 管理（此处示例只建交易相关表）
create extension if not exists pgcrypto;

create table products (
  id uuid default gen_random_uuid() primary key,
  symbol text not null,
  name text,
  description text,
  created_at timestamptz default now()
);

create table orders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  symbol text not null,
  side text not null, -- 'buy' or 'sell'
  qty numeric not null,
  price numeric, -- limit price if any
  type text not null, -- 'market' or 'limit'
  status text not null default 'pending', -- pending/filled/cancelled
  created_at timestamptz default now()
);

create table trades (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references orders(id),
  user_id uuid not null,
  symbol text not null,
  qty numeric not null,
  price numeric not null,
  executed_at timestamptz default now()
);

create table positions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  symbol text not null,
  qty numeric not null,
  avg_price numeric,
  updated_at timestamptz default now()
);
```

3. 克隆并运行（或直接在本地解压 zip）
- 安装依赖：
  npm install
- 在项目根创建 `.env.local`（参考 `.env.example`）
- 运行开发：
  npm run dev
- 打开 http://localhost:3000

如何测试下单（演示流程）
- 注册 / 登录（Supabase Auth）
- 前往首页查看模拟市场价格（GET /api/market?symbol=GOLD）
- 提交买入订单（POST /api/orders，type=market），服务端会基于模拟市场价在 trades 表中生成成交并更新 positions（paper trading）

部署提示
- 部署到 Vercel：把仓库连接到 Vercel，设置环境变量（NEXT_PUBLIC_SUPABASE_URL、NEXT_PUBLIC_SUPABASE_ANON_KEY、SUPABASE_SERVICE_ROLE_KEY 等），部署即可
- Webhook：如果后期对接真实经纪或支付，务必实现签名校验并使用服务端安全 key

安全与合规（必须）
- 本 starter 为“模拟”用途。禁止在未取得合规许可/未完成资金托管方案情况下用于实盘
- 服务端请使用 Supabase Service Role Key（在 server-side API 中使用），切勿把该 key 放到前端

下一步（可选）
- 添加限价单簿与撮合算法（matching engine）
- 添加策略订阅/付费墙（Stripe）
- 对接真实经纪 API（如 Alpaca / OANDA / Binance）并完成合规审查