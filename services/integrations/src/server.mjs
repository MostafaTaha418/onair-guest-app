import { createServer } from 'node:http';
import { randomInt, randomUUID } from 'node:crypto';
import { pool, withUser } from './db.mjs';
import { authenticate } from './auth.mjs';
import { sendEmail } from './resend.mjs';
import { createPaymentSession, normalizePaymentWebhook, verifyPaymentWebhook,
  refundPayment } from './kashier.mjs';

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 65_536) throw Object.assign(new Error('VALIDATION_FAILED'), { status: 413 });
    chunks.push(chunk);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { throw Object.assign(new Error('VALIDATION_FAILED'), { status: 400 }); }
}

function reply(response, status, body, requestId) {
  response.writeHead(status, { 'content-type': 'application/json; charset=utf-8',
    'x-request-id': requestId, 'cache-control': 'no-store' });
  response.end(JSON.stringify(body));
}

function fail(response, error, requestId) {
  const known = new Set(['UNAUTHENTICATED', 'PERMISSION_DENIED', 'VALIDATION_FAILED',
    'RATE_LIMITED', 'NOT_FOUND', 'QUOTE_EXPIRED', 'TERMS_CHANGED', 'PHONE_NOT_VERIFIED',
    'EMAIL_NOT_VERIFIED', 'DATES_UNAVAILABLE', 'ACTION_NOT_ALLOWED',
    'SEPARATION_OF_DUTIES', 'KASHIER_NOT_CONFIGURED',
    'KASHIER_SESSION_FAILED', 'KASHIER_REFUND_FAILED',
    'KASHIER_REFUND_UNKNOWN', 'EMAIL_SEND_FAILED']);
  const code = known.has(error.message) ? error.message : 'INTERNAL';
  const status = error.status ?? ({ UNAUTHENTICATED: 401, PERMISSION_DENIED: 403,
    NOT_FOUND: 404, RATE_LIMITED: 429, KASHIER_NOT_CONFIGURED: 503,
    EMAIL_SEND_FAILED: 502, KASHIER_SESSION_FAILED: 502,
    KASHIER_REFUND_FAILED: 502, KASHIER_REFUND_UNKNOWN: 502 }[code] ?? (code === 'INTERNAL' ? 500 : 400));
  if (status >= 500) console.error(requestId, error);
  reply(response, status, { error: { code, message_key: `error_${code.toLowerCase()}`, request_id: requestId } }, requestId);
}

async function sendOtp(request, response, requestId) {
  const user = await authenticate(request);
  const { challenge_id: challengeId } = await readJson(request);
  if (!uuid.test(challengeId ?? '')) throw new Error('VALIDATION_FAILED');
  const check = await pool.query(`
    select c.id,c.purpose,c.expires_at,c.last_sent_at,p.email
    from private.otp_challenges c join public.profiles p on p.id=c.recipient_user_id
    where c.id=$1 and c.consumed_at is null and c.expires_at>now()
    and (c.requested_by_user_id=$2 or c.recipient_user_id=$2)`, [challengeId, user.id]);
  if (!check.rowCount) throw new Error('NOT_FOUND');
  const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
  await pool.query(`select private.set_otp_code($1,extensions.crypt($2,extensions.gen_salt('bf',10)))`,
    [challengeId, code]);
  await sendEmail(check.rows[0].email, 'رمز التحقق من OnAir',
    `<div dir="rtl"><p>رمز التحقق الخاص بك:</p><p style="font-size:28px;letter-spacing:4px">${code}</p><p>ينتهي خلال 10 دقائق.</p></div>`);
  reply(response, 200, { challenge_id: challengeId, expires_at: check.rows[0].expires_at }, requestId);
}

async function startPayment(request, response, requestId) {
  const user = await authenticate(request);
  const { quote_id: quoteId, terms_hash: termsHash, idempotency_key: idempotencyKey } = await readJson(request);
  if (!uuid.test(quoteId ?? '') || typeof termsHash !== 'string' ||
    typeof idempotencyKey !== 'string') throw new Error('VALIDATION_FAILED');
  const booking = await withUser(user, async (client) => {
    const result = await client.query('select public.guest_start_booking($1,$2,$3) as data',
      [quoteId, termsHash, idempotencyKey]);
    return result.rows[0].data;
  });
  await openPaymentSession(response,requestId,user,booking);
}

async function startRemainingPayment(request, response, requestId, bookingId) {
  const user = await authenticate(request);
  const { idempotency_key: idempotencyKey } = await readJson(request);
  if (typeof idempotencyKey !== 'string') throw new Error('VALIDATION_FAILED');
  const payment = await withUser(user, async (client) => {
    const result = await client.query('select public.guest_start_remaining_payment($1,$2) as data',
      [bookingId,idempotencyKey]);
    return result.rows[0].data;
  });
  await openPaymentSession(response,requestId,user,payment);
}

async function openPaymentSession(response, requestId, user, booking) {
  const existing = await pool.query('select payment_url,payment_url_expires_at from public.payments where id=$1',
    [booking.payment_id]);
  if (existing.rows[0]?.payment_url) {
    reply(response, 200, { booking_id: booking.booking_id, payment_id: booking.payment_id,
      payment_url: existing.rows[0].payment_url,
      payment_url_expires_at: existing.rows[0].payment_url_expires_at }, requestId);
    return;
  }
  const session = await createPaymentSession({ paymentId: booking.payment_id,
    amountMinor: Number(booking.amount_minor), currency: booking.currency, email: user.email });
  await pool.query('select private.attach_payment_session($1,$2,$3,$4)',
    [booking.payment_id, booking.payment_id, session.sessionUrl, session.expiresAt]);
  reply(response, 200, { booking_id: booking.booking_id, payment_id: booking.payment_id,
    payment_url: session.sessionUrl, payment_url_expires_at: session.expiresAt }, requestId);
}

async function kashierWebhook(request, response, requestId) {
  const body = await readJson(request);
  if (!verifyPaymentWebhook(body, request.headers['x-kashier-signature'],
    process.env.KASHIER_API_KEY)) throw Object.assign(new Error('PERMISSION_DENIED'), { status: 403 });
  const event = normalizePaymentWebhook(body);
  const client = await pool.connect();
  try {
    await client.query('begin');
    const inserted = await client.query(`insert into private.provider_webhook_events
      (provider,provider_event_id,event_type,payload,signature_valid)
      values($1,$2,$3,$4,true) on conflict(provider_event_id) do nothing returning id`,
      [event.provider,event.providerEventId,event.eventType,event.payload]);
    if (!inserted.rowCount) {
      await client.query('rollback');
      response.writeHead(409, { 'x-request-id': requestId }); response.end();
      return;
    }
    await client.query('select private.apply_kashier_event($1)', [inserted.rows[0].id]);
    await client.query('commit');
    response.writeHead(200, { 'x-request-id': requestId }); response.end();
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally { client.release(); }
}

async function executeRefund(request, response, requestId, refundId) {
  const user = await authenticate(request);
  const allowed = await withUser(user, async (client) => {
    const result = await client.query("select private.has_platform_permission('refunds.execute') as allowed");
    return result.rows[0].allowed;
  });
  if (!allowed) throw new Error('PERMISSION_DENIED');
  const client = await pool.connect();
  try {
    await client.query('begin');
    const result = await client.query(`select r.id,r.status,r.method,r.amount_minor,r.reason,
      r.requested_by,r.approved_by,p.provider_kashier_order_id,p.provider_transaction_id
      from public.refunds r join public.payments p on p.id=r.payment_id
      where r.id=$1 for update of r`, [refundId]);
    if (!result.rowCount) throw new Error('NOT_FOUND');
    const refund = result.rows[0];
    if (refund.status !== 'approved' || refund.method !== 'kashier' ||
      !refund.provider_kashier_order_id || !refund.provider_transaction_id) {
      throw new Error('ACTION_NOT_ALLOWED');
    }
    if (user.id === refund.requested_by || user.id === refund.approved_by) {
      throw new Error('SEPARATION_OF_DUTIES');
    }
    const outcome = await refundPayment({ kashierOrderId: refund.provider_kashier_order_id,
      transactionId: refund.provider_transaction_id,
      amountMinor: Number(refund.amount_minor), reason: refund.reason });
    await client.query('select private.record_kashier_refund_result($1,$2,$3,$4)',
      [refundId,outcome.status,outcome.providerRefundId,user.id]);
    await client.query('commit');
    reply(response, 200, { refund_id: refundId, status: outcome.status }, requestId);
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally { client.release(); }
}

export const server = createServer(async (request, response) => {
  const requestId = uuid.test(request.headers['x-request-id'] ?? '')
    ? request.headers['x-request-id'] : randomUUID();
  try {
    if (request.method === 'GET' && request.url === '/health') {
      reply(response, 200, { status: 'ok' }, requestId); return;
    }
    if (request.method === 'POST' && request.url === '/v1/otp/send') {
      await sendOtp(request,response,requestId); return;
    }
    if (request.method === 'POST' && request.url === '/v1/guest/bookings/start-payment') {
      await startPayment(request,response,requestId); return;
    }
    const remainingMatch = /^\/v1\/guest\/bookings\/([0-9a-f-]{36})\/remaining-payment$/i.exec(request.url ?? '');
    if (request.method === 'POST' && remainingMatch && uuid.test(remainingMatch[1])) {
      await startRemainingPayment(request,response,requestId,remainingMatch[1]); return;
    }
    if (request.method === 'POST' && request.url === '/v1/webhooks/kashier') {
      await kashierWebhook(request,response,requestId); return;
    }
    const refundMatch = /^\/v1\/admin\/refunds\/([0-9a-f-]{36})\/execute$/i.exec(request.url ?? '');
    if (request.method === 'POST' && refundMatch && uuid.test(refundMatch[1])) {
      await executeRefund(request,response,requestId,refundMatch[1]); return;
    }
    throw Object.assign(new Error('NOT_FOUND'), { status: 404 });
  } catch (error) { fail(response,error,requestId); }
});

if (process.env.NODE_ENV !== 'test') {
  server.listen(Number(process.env.PORT ?? 8080), '0.0.0.0');
}
