import pg from 'pg';

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');

export const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 30000,
  ssl: process.env.DATABASE_SSL === 'disable' ? false : { rejectUnauthorized: true },
});

export async function withUser(user, work) {
  const client = await pool.connect();
  try {
    await client.query('begin');
    await client.query('set local role authenticated');
    await client.query('select set_config($1,$2,true)', ['request.jwt.claim.sub', user.id]);
    await client.query('select set_config($1,$2,true)', [
      'request.jwt.claims',
      JSON.stringify({ sub: user.id, role: 'authenticated', session_id: user.sessionId ?? null }),
    ]);
    const result = await work(client);
    await client.query('commit');
    return result;
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally {
    client.release();
  }
}
