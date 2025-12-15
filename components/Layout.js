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