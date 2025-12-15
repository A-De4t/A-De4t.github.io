// GET /api/market?symbol=GOLD
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
