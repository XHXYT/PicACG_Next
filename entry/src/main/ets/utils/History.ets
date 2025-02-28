import { AppUtil, LogUtil } from '@pura/harmony-utils';
import { ComicDetailInfo } from '../api/models';
import { JSON } from '@kit.ArkTS';
import { StorageKey } from '../common/Consts';
import distributedKVStore from '@ohos.data.distributedKVStore';

export class HistoryUtil {
  private static defaultOptions: distributedKVStore.Options = {
    createIfMissing: true, //当数据库文件不存在时是否创建数据库
    encrypt: true, //设置数据库文件是否加密
    backup: false, //设置数据库文件是否备份
    autoSync: false, //设置数据库是否为跨设备自动同步
    kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION, //设置要创建的数据库类型
    securityLevel: distributedKVStore.SecurityLevel.S1  //设置数据库安全级别
  }
  private static comicStore: distributedKVStore.SingleKVStore
  private static readHistoryStore: distributedKVStore.SingleKVStore

  public static async init(options?: distributedKVStore.Options) {
    let kvManager = distributedKVStore.createKVManager({
      context: AppUtil.getContext(),
      bundleName: AppUtil.getBundleName()
    });
    HistoryUtil.comicStore = await kvManager.getKVStore<distributedKVStore.SingleKVStore>("comic_store",
      options ? options : HistoryUtil.defaultOptions);
    HistoryUtil.readHistoryStore = await kvManager.getKVStore<distributedKVStore.SingleKVStore>("read_history_store",
      options ? options : HistoryUtil.defaultOptions);
  }

  public static add(comic: ComicDetailInfo) {
    HistoryUtil.comicStore.put(comic._id, JSON.stringify(comic)).then(() => {
      LogUtil.info('添加浏览历史')
      let hisIds = AppStorage.get<string[]>(StorageKey.HISTORY)
      if (hisIds) {
        if (hisIds.indexOf(comic._id) < 0) {
          hisIds.splice(0, 0, comic._id)
        } else {
          hisIds.splice(hisIds.indexOf(comic._id), 1)
          hisIds.splice(0, 0, comic._id)
        }
      } else {
        hisIds = [comic._id]
      }
      AppStorage.setOrCreate<string[]>(StorageKey.HISTORY, hisIds)
    }).catch((err: Error) => {
      LogUtil.error('添加浏览历史失败：', err.name)
      LogUtil.error('添加浏览历史失败：', err.message)
      LogUtil.error('添加浏览历史失败：', err.stack)
    })
  }

  public static get(): Promise<ComicDetailInfo[]> {
    return new Promise<ComicDetailInfo[]>(async (resolve, _) => {
      let hisIds = AppStorage.get<string[]>(StorageKey.HISTORY)
      if (hisIds && hisIds.length !== 0) {
        LogUtil.info('获取浏览历史 size ', hisIds.length.toString())
        let comics: ComicDetailInfo[] = []
        for (let id of hisIds) {
          let data = await HistoryUtil.comicStore.get(id)
          LogUtil.info('获取浏览历史: ', id)
          LogUtil.info('获取浏览历史: ', data.toString())
          comics.push(JSON.parse(data as string) as ComicDetailInfo)
        }
        LogUtil.info('获取浏览历史结束')
        resolve(comics)
      } else {
        LogUtil.info('当前不存在浏览历史')
        resolve([])
      }
    })
  }

  public static on(func: (data: distributedKVStore.ChangeNotification) => void) {
    HistoryUtil.comicStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_LOCAL, func)
  }

  public static getRead(comicId: string): Promise<number> {
    return new Promise<number>((resolve, reject) => {
      HistoryUtil.readHistoryStore.get(comicId).then(r => {
        let res = r as string
        LogUtil.info(`查询到阅读章节：`, comicId, ' ', res)
        resolve(Number.parseInt(res.split(',')[0]))
      }).catch((err: Error) => {
        reject(err)
      })
    })
  }

  public static getReadIndex(comicId: string, order: number): Promise<number> {
    return new Promise<number>((resolve, reject) => {
      HistoryUtil.readHistoryStore.get(comicId).then(r => {
        let res = r as string
        LogUtil.info(`查询到阅读Index：`, comicId, ' ', res)
        let hisOrder = Number.parseInt(res.split(',')[0])
        if (order === hisOrder) {
          resolve(Number.parseInt(res.split(',')[1]))
        } else {
          resolve(0)
        }
      }).catch((err: Error) => {
        reject(err)
      })
    })
  }

  public static setRead(comicId: string, order: number, index: number = 0) {
    LogUtil.info('记录阅读历史')
    HistoryUtil.readHistoryStore.put(comicId, `${order},${index}`).then(() => {
      LogUtil.info(`记录阅读历史成功：${comicId} - ${order} - ${index}`)
    })
  }

  public static clear() {
    let hisIds = AppStorage.get<string[]>(StorageKey.HISTORY)
    if (hisIds?.length) {
      LogUtil.info('开始清空历史: ', hisIds.join(','))
      AppStorage.set<string[]>(StorageKey.HISTORY, [])
      HistoryUtil.comicStore.deleteBatch([...hisIds]).then(() => {
        LogUtil.info('历史清空完成')
      })
      HistoryUtil.readHistoryStore.deleteBatch([...hisIds]).then(() => {
        LogUtil.info('历史清空完成')
      })
    }
  }
}