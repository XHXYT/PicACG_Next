import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { buffer, util } from '@kit.ArkTS'
import { LogUtil } from '@pura/harmony-utils'
import { KVDbUtil } from './preference/KVdbUtil'
import { StorageKey } from '../common/Consts'

/**
 * AES-GCM 加解密工具
 * 密钥：首次使用时随机生成 16 字节 AES128 密钥，Base64 后持久化到 KVDB
 * 存储格式：`${iv}.${authTag}.${cipherText}` 三段 Base64，用 '.' 分隔
 */
const AAD_TEXT: string = 'picacg_account_password'
let cachedKey: cryptoFramework.SymKey | undefined = undefined

const aadBytes = (): Uint8Array => new Uint8Array(buffer.from(AAD_TEXT, 'utf-8').buffer)

/**
 * 获取（或首次生成并持久化）AES128 对称密钥
 */
async function getKey(): Promise<cryptoFramework.SymKey> {
  if (cachedKey !== undefined) {
    return cachedKey
  }
  const base64 = new util.Base64Helper()
  const generator = cryptoFramework.createSymKeyGenerator('AES128')
  const saved = await KVDbUtil.getData<string>(StorageKey.CRYPTO_KEY, '')
  if (saved !== '') {
    const keyBlob: cryptoFramework.DataBlob = { data: base64.decodeSync(saved) }
    cachedKey = generator.convertKeySync(keyBlob)
  } else {
    const rand = cryptoFramework.createRandom()
    const keyBlob = rand.generateRandomSync(16)
    cachedKey = generator.convertKeySync(keyBlob)
    await KVDbUtil.putData(StorageKey.CRYPTO_KEY, base64.encodeToStringSync(keyBlob.data))
    LogUtil.info('CryptoUtil 已生成并持久化账号加密密钥')
  }
  return cachedKey
}

/**
 * 加密明文字符串
 * @returns 形如 `${iv}.${authTag}.${cipherText}` 的 Base64 组合串
 */
export async function encryptText(plain: string): Promise<string> {
  const key = await getKey()
  const base64 = new util.Base64Helper()
  const rand = cryptoFramework.createRandom()
  const ivBlob = rand.generateRandomSync(12)
  const params: cryptoFramework.GcmParamsSpec = {
    iv: ivBlob,
    aad: { data: aadBytes() },
    authTag: { data: new Uint8Array(16) },
    algName: 'GcmParamsSpec'
  }
  const cipher = cryptoFramework.createCipher('AES128|GCM|PKCS7')
  cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params)
  const plainBlob: cryptoFramework.DataBlob = { data: new Uint8Array(buffer.from(plain, 'utf-8').buffer) }
  const cipherOut = cipher.updateSync(plainBlob)
  const tagOut = cipher.doFinalSync(null)
  return `${base64.encodeToStringSync(ivBlob.data)}.${base64.encodeToStringSync(tagOut.data)}.` +
    `${base64.encodeToStringSync(cipherOut.data)}`
}

/**
 * 解密 encryptText 输出的组合串
 * @returns 明文字符串；格式非法或校验失败时抛出异常
 */
export async function decryptText(encoded: string): Promise<string> {
  const key = await getKey()
  const base64 = new util.Base64Helper()
  const parts = encoded.split('.')
  if (parts.length !== 3) {
    throw new Error('invalid encrypted text format')
  }
  const params: cryptoFramework.GcmParamsSpec = {
    iv: { data: base64.decodeSync(parts[0]) },
    aad: { data: aadBytes() },
    authTag: { data: base64.decodeSync(parts[1]) },
    algName: 'GcmParamsSpec'
  }
  const decoder = cryptoFramework.createCipher('AES128|GCM|PKCS7')
  decoder.initSync(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params)
  const plainOut = decoder.updateSync({ data: base64.decodeSync(parts[2]) })
  // 校验 authTag，失败会抛出异常
  decoder.doFinalSync(null)
  return buffer.from(plainOut.data).toString('utf-8')
}
