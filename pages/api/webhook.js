// 占位：外部 webhook（例如未来接收经纪/支付回调）
// 请在真实场景下进行签名校验
export default async function handler(req, res) {
  console.log('Received webhook', req.method, req.headers);
  res.status(200).json({ ok: true });
}