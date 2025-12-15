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