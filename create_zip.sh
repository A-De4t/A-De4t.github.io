#!/usr/bin/env bash
set -euo pipefail
OUT="A-De4t_financial_starter.zip"
TMP="$(mktemp -d)"
echo "Creating workspace $TMP"

# Create dirs
mkdir -p "$TMP"/pages/api
mkdir -p "$TMP"/lib
mkdir -p "$TMP"/components

# Write files (minimal README placeholder)
cat > "$TMP/README.md" <<'EOF'
# A-De4t 模拟金融交易 Starter（商品类，单一卖家）

请参考项目 README（完整说明应由上级 README.md 提供）。
EOF

# package.json
cat > "$TMP/package.json" <<'EOF'
{
  "name": "a-de4t-financial-starter",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.31.0",
    "next": "13.5.4",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
EOF

cat > "$TMP/.env.example" <<'EOF'
NEXT_PUBLIC_SUPABASE_URL=https://xyzcompany.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=public-anon-key
SUPABASE_SERVICE_ROLE_KEY=service-role-secret-key
NEXT_PUBLIC_BASE_URL=http://localhost:3000
EOF

# lib
cat > "$TMP/lib/supabaseClient.js" <<'EOF'
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const supabaseAdmin = process.env.SUPABASE_SERVICE_ROLE_KEY
  ? createClient(supabaseUrl, process.env.SUPABASE_SERVICE_ROLE_KEY)
  : null;
EOF

cat > "$TMP/lib/paperEngine.js" <<'EOF'
import { supabaseAdmin } from './supabaseClient';

if (!supabaseAdmin) {
  console.warn('supabaseAdmin 未配置（SUPABASE_SERVICE_ROLE_KEY）。server-side 操作会失败。');
}

export async function getSimulatedPrice(symbol = 'GOLD') {
  const base = {
    GOLD: 1800,
    OIL: 80,
    SILVER: 24
  }[symbol] ?? 100;
  const t = Date.now() / 1000;
  const price = base * (1 + 0.01 * Math.sin(t / 600) + (Math.random() - 0.5) * 0.002);
  return Number(price.toFixed(4));
}

export async function createOrderAndMaybeFill({ user_id, symbol, side, qty, type, price }) {
  if (!supabaseAdmin) throw new Error('supabaseAdmin 未配置');

  const { data: orderRow, error: orderErr } = await supabaseAdmin
    .from('orders')
    .insert([{ user_id, symbol, side, qty, price, type, status: 'pending' }])
    .select('*')
    .single();

  if (orderErr) throw orderErr;

  const marketPrice = await getSimulatedPrice(symbol);

  let execPrice = marketPrice;
  if (type === 'limit' && price) {
    if ((side === 'buy' && price < marketPrice) || (side === 'sell' && price > marketPrice)) {
      return { order: orderRow, filled: false };
    } else {
      execPrice = price;
    }
  }

  const { data: tradeRow, error: tradeErr } = await supabaseAdmin
    .from('trades')
    .insert([{
      order_id: orderRow.id,
      user_id,
      symbol,
      qty,
      price: execPrice
    }])
    .select('*')
    .single();

  if (tradeErr) throw tradeErr;

  await supabaseAdmin
    .from('orders')
    .update({ status: 'filled' })
    .eq('id', orderRow.id);

  const { data: pos } = await supabaseAdmin
    .from('positions')
    .select('*')
    .match({ user_id, symbol })
    .maybeSingle();

  if (!pos) {
    await supabaseAdmin.from('positions').insert([{
      user_id,
      symbol,
      qty: side === 'buy' ? qty : -qty,
      avg_price: execPrice
    }]);
  } else {
    const existingQty = Number(pos.qty);
    const newQty = existingQty + (side === 'buy' ? Number(qty) : -Number(qty));
    const newAvg = ((existingQty * Number(pos.avg_price || 0)) + (side === 'buy' ? qty * execPrice : 0)) / (newQty || 1);
    await supabaseAdmin.from('positions').update({
      qty: newQty,
      avg_price: newAvg,
      updated_at: new Date().toISOString()
    }).eq('id', pos.id);
  }

  return { order: orderRow, filled: true, trade: tradeRow, marketPrice };
}
EOF

# components
cat > "$TMP/components/Layout.js" <<'EOF'
export default function Layout({ children }) {
  return (
    <div style={{ fontFamily: 'Arial, sans-serif', padding: 24 }}>
      <header style={{ marginBottom: 24 }}>
        <h1 style={{ margin: 0 }}>A-De4t 模拟交易平台（Demo）</h1>
      </header>
      <main>{children}</main>
      <footer style={{ marginTop: 48, color: '#666' }}>
        <small>模拟交易演示 — 不处理真实资金。请在部署前阅读 README 中的合规说明。</small>
      </footer>
    </div>
  );
}
EOF

# pages (minimal placeholders copied from template)
cat > "$TMP/pages/index.js" <<'EOF'
import Link from 'next/link';
import { useEffect, useState } from 'react';
import Layout from '../components/Layout';

export default function Home() {
  const [price, setPrice] = useState(null);

  useEffect(() => {
    async function load() {
      const r = await fetch('/api/market?symbol=GOLD');
      const j = await r.json();
      setPrice(j.price);
    }
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
  }, []);

  return (
    <Layout>
      <h1>欢迎 — A-De4t 模拟交易平台（商品类）</h1>
      <p>这是一个 paper-trading 原型，用于演示商品（如 GOLD / OIL）下单与撮合。</p>

      <div style={{ border: '1px solid #ddd', padding: 12, display: 'inline-block' }}>
        <h3>GOLD (模拟)</h3>
        <p style={{ fontSize: 24 }}>{price ? `${price} USD` : '加载中...'}</p>
      </div>

      <div style={{ marginTop: 20 }}>
        <Link href="/signup"><a style={{ marginRight: 12 }}>注册</a></Link>
        <Link href="/login"><a style={{ marginRight: 12 }}>登录</a></Link>
        <Link href="/dashboard"><a>我的面板（需要登录）</a></Link>
      </div>
    </Layout>
  );
}
EOF

cat > "$TMP/pages/signup.js" <<'EOF'
import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import Layout from '../components/Layout';
import { useRouter } from 'next/router';

export default function Signup() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [msg, setMsg] = useState('');
  const router = useRouter();

  async function onSignup(e) {
    e.preventDefault();
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) setMsg(error.message);
    else {
      setMsg('已发送验证邮件（若已启用）。请登录。');
      router.push('/login');
    }
  }

  return (
    <Layout>
      <h2>注册</h2>
      <form onSubmit={onSignup}>
        <input placeholder="邮箱" value={email} onChange={e=>setEmail(e.target.value)} /><br/>
        <input placeholder="密码" value={password} onChange={e=>setPassword(e.target.value)} type="password"/><br/>
        <button type="submit">注册</button>
      </form>
      <p>{msg}</p>
    </Layout>
  );
}
EOF

cat > "$TMP/pages/login.js" <<'EOF'
import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import Layout from '../components/Layout';
import Router from 'next/router';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [msg, setMsg] = useState('');

  async function onLogin(e) {
    e.preventDefault();
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) setMsg(error.message);
    else {
      setMsg('登录成功');
      Router.push('/dashboard');
    }
  }

  return (
    <Layout>
      <h2>登录</h2>
      <form onSubmit={onLogin}>
        <input placeholder="邮箱" value={email} onChange={e=>setEmail(e.target.value)} /><br/>
        <input placeholder="密码" value={password} onChange={e=>setPassword(e.target.value)} type="password"/><br/>
        <button type="submit">登录</button>
      </form>
      <p>{msg}</p>
    </Layout>
  );
}
EOF

cat > "$TMP/pages/dashboard.js" <<'EOF'
import { useEffect, useState } from 'react';
import Layout from '../components/Layout';
import { supabase } from '../lib/supabaseClient';
import Router from 'next/router';

export default function Dashboard() {
  const [user, setUser] = useState(null);
  const [orders, setOrders] = useState([]);
  const [symbol, setSymbol] = useState('GOLD');
  const [qty, setQty] = useState(1);
  const [side, setSide] = useState('buy');
  const [type, setType] = useState('market');
  const [price, setPrice] = useState('');

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) Router.push('/login');
      else setUser(data.user);
    });
    fetchOrders();
  }, []);

  async function fetchOrders() {
    const session = await supabase.auth.getSession();
    const token = session.data?.session?.access_token;
    if (!token) return;
    const r = await fetch('/api/orders', { headers: { Authorization: `Bearer ${token}` }});
    if (r.ok) {
      const j = await r.json();
      setOrders(j.orders || []);
    }
  }

  async function placeOrder(e) {
    e.preventDefault();
    const session = await supabase.auth.getSession();
    const token = session.data?.session?.access_token;
    const { data: { user } } = await supabase.auth.getUser();
    const body = { user_id: user.id, symbol, side, qty: Number(qty), type, price: price ? Number(price) : null };
    const r = await fetch('/api/orders', { method: 'POST', headers: {'Content-Type':'application/json', Authorization: `Bearer ${token}`}, body: JSON.stringify(body)});
    const j = await r.json();
    alert('下单结果：' + JSON.stringify(j));
    fetchOrders();
  }

  return (
    <Layout>
      <h2>我的面板</h2>
      <p>用户: {user?.email}</p>

      <section style={{ border: '1px solid #eee', padding: 12 }}>
        <h3>下单（示例）</h3>
        <form onSubmit={placeOrder}>
          <label>品种: <input value={symbol} onChange={e=>setSymbol(e.target.value)} /></label><br/>
          <label>方向:
            <select value={side} onChange={e=>setSide(e.target.value)}>
              <option value="buy">买入</option>
              <option value="sell">卖出</option>
            </select>
          </label><br/>
          <label>数量: <input type="number" value={qty} onChange={e=>setQty(e.target.value)} /></label><br/>
          <label>类型:
            <select value={type} onChange={e=>setType(e.target.value)}>
              <option value="market">市价</option>
              <option value="limit">限价</option>
            </select>
          </label><br/>
          <label>限价(如 limit): <input value={price} onChange={e=>setPrice(e.target.value)} /></label><br/>
          <button type="submit">下单</button>
        </form>
      </section>

      <section style={{ marginTop: 20 }}>
        <h3>我的订单</h3>
        <ul>
          {orders.map(o => (
            <li key={o.id}>{o.symbol} {o.side} {o.qty} @ {o.price ?? 'MKT'} 状态: {o.status}</li>
          ))}
        </ul>
      </section>
    </Layout>
  );
}
EOF

cat > "$TMP/pages/api/market.js" <<'EOF'
import { getSimulatedPrice } from '../../lib/paperEngine';

export default async function handler(req, res) {
  const { symbol = 'GOLD' } = req.query;
  try {
    const price = await getSimulatedPrice(symbol);
    res.status(200).json({ symbol, price, ts: Date.now() });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
}
EOF

cat > "$TMP/pages/api/orders.js" <<'EOF'
import { supabase } from '../../lib/supabaseClient';
import { createOrderAndMaybeFill } from '../../lib/paperEngine';

export default async function handler(req, res) {
  if (req.method === 'POST') {
    try {
      const { user_id, symbol, side, qty, type, price } = req.body;
      if (!user_id) return res.status(400).json({ error: 'user_id required (demo)' });
      const result = await createOrderAndMaybeFill({ user_id, symbol, side, qty, type, price });
      res.status(200).json(result);
    } catch (err) {
      res.status(500).json({ error: String(err) });
    }
  } else if (req.method === 'GET') {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ error: 'missing token' });

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) return res.status(401).json({ error: 'invalid token' });

    const { data, error: qErr } = await supabase
      .from('orders')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (qErr) return res.status(500).json({ error: qErr.message });
    res.status(200).json({ orders: data });
  } else {
    res.setHeader('Allow', ['GET', 'POST']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
EOF

cat > "$TMP/pages/api/webhook.js" <<'EOF'
export default async function handler(req, res) {
  console.log('Received webhook', req.method, req.headers);
  res.status(200).json({ ok: true });
}
EOF

# zip
( cd "$TMP" && zip -r "../$OUT" . ) >/dev/null
mv "$TMP/../$OUT" .
rm -rf "$TMP"
echo "Created $OUT in current directory."
EOF