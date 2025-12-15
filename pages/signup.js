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