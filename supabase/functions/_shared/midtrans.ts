export function midtransSnapBaseUrl(): string {
  return Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true'
    ? 'https://app.midtrans.com'
    : 'https://app.sandbox.midtrans.com';
}

export function midtransAuthorization(serverKey: string): string {
  return `Basic ${btoa(`${serverKey}:`)}`;
}

export async function midtransSignature(
  orderId: string,
  statusCode: string,
  grossAmount: string,
  serverKey: string,
): Promise<string> {
  const payload = new TextEncoder().encode(
    `${orderId}${statusCode}${grossAmount}${serverKey}`,
  );
  const digest = await crypto.subtle.digest('SHA-512', payload);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export async function verifyMidtransSignature(
  orderId: string,
  statusCode: string,
  grossAmount: string,
  signatureKey: string,
  serverKey: string,
): Promise<boolean> {
  const expected = await midtransSignature(
    orderId,
    statusCode,
    grossAmount,
    serverKey,
  );
  if (expected.length !== signatureKey.length) return false;
  let mismatch = 0;
  for (let index = 0; index < expected.length; index += 1) {
    mismatch |= expected.charCodeAt(index) ^ signatureKey.charCodeAt(index);
  }
  return mismatch === 0;
}
