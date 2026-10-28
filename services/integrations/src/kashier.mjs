import { createHmac, timingSafeEqual } from 'node:crypto';

const origin = () => process.env.KASHIER_ENV === 'live'
  ? 'https://api.kashier.io'
  : 'https://test-api.kashier.io';

export function minorToDecimal(minor) {
  if (!Number.isSafeInteger(minor) || minor < 0) throw new Error('INVALID_AMOUNT');
  return `${Math.floor(minor / 100)}.${String(minor % 100).padStart(2, '0')}`;
}

export function decimalToMinor(value) {
  const text = String(value);
  if (!/^(0|[1-9]\d*)(?:\.\d{1,2})?$/.test(text)) throw new Error('INVALID_AMOUNT');
  const [major, fraction = ''] = text.split('.');
  const result = BigInt(major) * 100n + BigInt(fraction.padEnd(2, '0'));
  if (result > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('INVALID_AMOUNT');
  return Number(result);
}

export function verifyPaymentWebhook(body, signature, apiKey) {
  const data = body?.data;
  if (!data || !Array.isArray(data.signatureKeys) || !signature || !apiKey) return false;
  const canonical = [...data.signatureKeys].sort().map((key) => {
    if (!Object.hasOwn(data, key) || data[key] == null) throw new Error('INVALID_WEBHOOK');
    return `${key}=${encodeURIComponent(String(data[key]))}`;
  }).join('&');
  const expected = createHmac('sha256', apiKey).update(canonical).digest('hex');
  if (!/^[a-f0-9]{64}$/i.test(signature)) return false;
  return timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(signature, 'hex'));
}

export function normalizePaymentWebhook(body) {
  const data = body?.data;
  if (!data?.merchantOrderId || !data?.transactionId || !data?.status) {
    throw new Error('INVALID_WEBHOOK');
  }
  return {
    provider: 'kashier',
    providerEventId: `${data.transactionId}:${data.status}`,
    eventType: String(body.event ?? 'payment.status'),
    payload: {
      provider_order_id: String(data.merchantOrderId),
      kashier_order_id: data.kashierOrderId ? String(data.kashierOrderId) : null,
      provider_transaction_id: String(data.transactionId),
      amount_minor: decimalToMinor(data.amount),
      currency: String(data.currency),
      status: String(data.status).toUpperCase(),
    },
  };
}

export async function createPaymentSession({ paymentId, amountMinor, currency, email, locale }) {
  const required = ['KASHIER_MERCHANT_ID', 'KASHIER_API_KEY', 'KASHIER_SECRET_KEY',
    'KASHIER_WEBHOOK_URL', 'KASHIER_REDIRECT_URL'];
  if (required.some((name) => !process.env[name])) throw new Error('KASHIER_NOT_CONFIGURED');
  const expireAt = new Date(Date.now() + 15 * 60_000).toISOString();
  const response = await fetch(`${origin()}/v3/payment/sessions`, {
    method: 'POST',
    headers: {
      authorization: process.env.KASHIER_SECRET_KEY,
      'api-key': process.env.KASHIER_API_KEY,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      expireAt,
      maxFailureAttempts: 3,
      paymentType: 'credit',
      amount: minorToDecimal(amountMinor),
      currency,
      order: paymentId,
      merchantRedirect: process.env.KASHIER_REDIRECT_URL,
      serverWebhook: process.env.KASHIER_WEBHOOK_URL,
      display: locale === 'en' ? 'en' : 'ar',
      type: 'one-time',
      merchantId: process.env.KASHIER_MERCHANT_ID,
      customer: { email },
    }),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  if (!response.ok || !result?.sessionUrl) {
    throw Object.assign(new Error('KASHIER_SESSION_FAILED'), { details: result });
  }
  return { sessionUrl: result.sessionUrl, expiresAt: expireAt,
    sessionId: result._id ?? result.id ?? null };
}

export async function refundPayment({ kashierOrderId, transactionId, amountMinor, reason }) {
  if (!process.env.KASHIER_SECRET_KEY) throw new Error('KASHIER_NOT_CONFIGURED');
  const host = process.env.KASHIER_ENV === 'live'
    ? 'https://fep.kashier.io' : 'https://test-fep.kashier.io';
  const response = await fetch(`${host}/v3/orders/${encodeURIComponent(kashierOrderId)}`, {
    method: 'PUT',
    headers: { authorization: process.env.KASHIER_SECRET_KEY,
      accept: 'application/json', 'content-type': 'application/json' },
    body: JSON.stringify({ apiOperation: 'REFUND', reason,
      transaction: { amount: Number(minorToDecimal(amountMinor)),
        targetTransactionId: transactionId } }),
    signal: AbortSignal.timeout(15000),
  });
  const data = await response.json();
  if (!response.ok) throw Object.assign(new Error('KASHIER_REFUND_FAILED'), { details: data });
  const status = String(data.status ?? data.response?.status ?? '').toUpperCase();
  if (!['SUCCESS','PENDING','FAILURE'].includes(status)) {
    throw Object.assign(new Error('KASHIER_REFUND_UNKNOWN'), { details: data });
  }
  return { status, providerRefundId: data.response?.transactionId ?? null };
}
