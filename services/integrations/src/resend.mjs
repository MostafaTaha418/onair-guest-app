export async function sendEmail(to, subject, html) {
  if (!process.env.RESEND_API_KEY || !process.env.RESEND_FROM) {
    throw new Error('RESEND_NOT_CONFIGURED');
  }
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ from: `OnAir <${process.env.RESEND_FROM}>`, to: [to], subject, html }),
    signal: AbortSignal.timeout(10000),
  });
  const data = await response.json();
  if (!response.ok) throw Object.assign(new Error('EMAIL_SEND_FAILED'), { details: data });
  return data.id;
}
