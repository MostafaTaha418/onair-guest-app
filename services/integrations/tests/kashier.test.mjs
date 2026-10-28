import test from 'node:test';
import assert from 'node:assert/strict';
import { decimalToMinor, minorToDecimal, verifyPaymentWebhook,
  normalizePaymentWebhook } from '../src/kashier.mjs';

test('money conversion uses exact minor units', () => {
  assert.equal(decimalToMinor('100.05'), 10005);
  assert.equal(minorToDecimal(10005), '100.05');
  assert.throws(() => decimalToMinor('1.234'));
});

test('Kashier payment webhook signature matches official example', () => {
  const data = {
    amount: 1,
    channel: 'online | e-commerce',
    currency: 'EGP',
    kashierOrderId: '9ad06b17-755b-4e21-9774-aff3e2726ac9',
    merchantOrderId: '1653481557813',
    method: 'card',
    orderReference: 'TEST-ORD-38855',
    status: 'SUCCESS',
    transactionId: 'TX-249893963',
    transactionResponseCode: '00',
  };
  data.signatureKeys = Object.keys(data).reverse();
  const body = { data };
  const signature = '9610477b2255b2a8ef84fd89adfaa5f1305ff9c20324205851890f1ea03109f4';
  assert.equal(verifyPaymentWebhook(body, signature, '11111'), true);
  assert.equal(verifyPaymentWebhook(body, signature, 'wrong-key'), false);
  assert.deepEqual(normalizePaymentWebhook(body).payload, {
    provider_order_id: '1653481557813',
    kashier_order_id: '9ad06b17-755b-4e21-9774-aff3e2726ac9',
    provider_transaction_id: 'TX-249893963',
    amount_minor: 100,
    currency: 'EGP',
    status: 'SUCCESS',
  });
});
