// POST: 创建订单（server-side 使用 service role via paperEngine）
// GET: 获取当前登录用户的订单（前端会把 access token 放入 Authorization）
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

    // 验证 token via supabase auth (client-side 会把 access_token 放入 Authorization)
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