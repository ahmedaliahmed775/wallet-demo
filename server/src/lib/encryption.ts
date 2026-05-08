import CryptoJS from 'crypto-js';

export function encryptAES(text: string, key: string): string {
  const keyBytes = CryptoJS.enc.Utf8.parse(key.substring(0, 32));
  const iv = CryptoJS.lib.WordArray.random(16);

  const encrypted = CryptoJS.AES.encrypt(text, keyBytes, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7,
  });

  // Combine IV and ciphertext for storage
  const combined = iv.toString(CryptoJS.enc.Base64) + ':' + encrypted.toString();
  return combined;
}

export function decryptAES(encrypted: string, key: string): string {
  const parts = encrypted.split(':');
  if (parts.length !== 2) {
    throw new Error('Invalid encrypted format');
  }

  const iv = CryptoJS.enc.Base64.parse(parts[0]);
  const keyBytes = CryptoJS.enc.Utf8.parse(key.substring(0, 32));

  const decrypted = CryptoJS.AES.decrypt(parts[1], keyBytes, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7,
  });

  return decrypted.toString(CryptoJS.enc.Utf8);
}

export function md5Hash(text: string): string {
  return CryptoJS.MD5(text).toString();
}

export function generateMerchantToken(spId: string, username: string, timestamp: string): string {
  const raw = spId + username + timestamp;
  return md5Hash(raw);
}
