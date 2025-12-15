import Link from 'next/link';
import { useEffect, useState } from 'react';
import Layout from '../components/Layout';

export default function Home() {
  const [price, setPrice] = useState(null);

  useEffect(() => {
    let mounted = true;
    async function load() {
      const r = await fetch('/api/market?symbol=GOLD');
      const j = await r.json();
      if (mounted) setPrice(j.price);
    }
    load();
    const id = setInterval(load, 5000);
    return () => { mounted = false; clearInterval(id); };
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