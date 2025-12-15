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