// 简单的 server-side paper trading engine using Supabase
import { supabaseAdmin } from './supabaseClient';

if (!supabaseAdmin) {
  console.warn('supabaseAdmin 未配置（SUPABASE_SERVICE_ROLE_KEY）。server-side 操作会失败。');
}

export async function getSimulatedPrice(symbol = 'GOLD') {
  // 极简模拟：基于时间波动返回价格
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

  // 1) 插入 order
  const { data: orderRow, error: orderErr } = await supabaseAdmin
    .from('orders')
    .insert([{ user_id, symbol, side, qty, price, type, status: 'pending' }])
    .select('*')
    .single();

  if (orderErr) throw orderErr;

  // 2) 获取模拟市价并决定是否成交
  const marketPrice = await getSimulatedPrice(symbol);

  let execPrice = marketPrice;
  if (type === 'limit' && price) {
    // 简化：若 limit 买价 < market 或 sell price > market 则不成交（保持 pending）
    if ((side === 'buy' && Number(price) < marketPrice) || (side === 'sell' && Number(price) > marketPrice)) {
      return { order: orderRow, filled: false };
    } else {
      execPrice = Number(price);
    }
  }

  // 3) 生成 trade
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

  // 4) 更新 order 状态为 filled
  await supabaseAdmin
    .from('orders')
    .update({ status: 'filled' })
    .eq('id', orderRow.id);

  // 5) 更新 positions（非常简化的合并逻辑）
  const { data: posData, error: posErr } = await supabaseAdmin
    .from('positions')
    .select('*')
    .match({ user_id, symbol })
    .maybeSingle();

  const pos = posData || null;

  if (!pos) {
    // 新仓位
    await supabaseAdmin.from('positions').insert([{
      user_id,
      symbol,
      qty: side === 'buy' ? qty : -qty,
      avg_price: execPrice
    }]);
  } else {
    const existingQty = Number(pos.qty);
    const newQty = existingQty + (side === 'buy' ? Number(qty) : -Number(qty));
    const newAvg = ((existingQty * Number(pos.avg_price || 0)) + (side === 'buy' ? Number(qty) * execPrice : 0)) / (newQty || 1);
    await supabaseAdmin.from('positions').update({
      qty: newQty,
      avg_price: newAvg,
      updated_at: new Date().toISOString()
    }).eq('id', pos.id);
  }

  return { order: orderRow, filled: true, trade: tradeRow, marketPrice };
}
