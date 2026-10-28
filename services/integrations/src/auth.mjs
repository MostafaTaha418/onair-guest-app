export async function authenticate(request) {
  const match = /^Bearer (.+)$/i.exec(request.headers.authorization ?? '');
  if (!match) throw Object.assign(new Error('UNAUTHENTICATED'), { status: 401 });
  const response = await fetch(`${process.env.SUPABASE_URL}/auth/v1/user`, {
    headers: {
      authorization: `Bearer ${match[1]}`,
      apikey: process.env.SUPABASE_PUBLISHABLE_KEY,
    },
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw Object.assign(new Error('UNAUTHENTICATED'), { status: 401 });
  const user = await response.json();
  if (!user?.id) throw Object.assign(new Error('UNAUTHENTICATED'), { status: 401 });
  const payload = JSON.parse(Buffer.from(match[1].split('.')[1] ?? '', 'base64url').toString('utf8'));
  return { id: user.id, email: user.email, sessionId: payload.session_id };
}
