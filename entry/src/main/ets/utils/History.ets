import { AppUtil, LogUtil } from '@pura/harmony-utils';
import { ComicDetailInfo, ComicSimpleInfo, Thumb } from '../api/models';
import { JSON } from '@kit.ArkTS';
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';


export class HistoryUtil {
  private static readonly DB_NAME: string = 'comic_history.db';
  private static readonly DB_VERSION: number = 1;
  private static readonly TABLE_COMIC_HISTORY: string = 'COMIC_HISTORY';

  private static rdbStore: relationalStore.RdbStore;
  private static isInitialized: boolean = false;

  // 数据库配置
  private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: HistoryUtil.DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: false
  };

  // 建表SQL - 使用漫画的_id作为主键
  private static readonly SQL_CREATE_TABLE = `
    CREATE TABLE IF NOT EXISTS ${HistoryUtil.TABLE_COMIC_HISTORY} (
      _id TEXT PRIMARY KEY NOT NULL,
      title TEXT NOT NULL,
      thumb TEXT,
      author TEXT,
      categories TEXT,
      finished INTEGER DEFAULT 0,
      epsCount INTEGER DEFAULT 0,
      pagesCount INTEGER DEFAULT 0,
      totalViews INTEGER DEFAULT 0,
      totalLikes INTEGER DEFAULT 0,
      creator_name TEXT,
      creator_id TEXT,
      description TEXT,
      chineseTeam TEXT,
      tags TEXT,
      updated_at TEXT,
      created_at TEXT,
      allowDownload INTEGER DEFAULT 0,
      allowComment INTEGER DEFAULT 0,
      totalComments INTEGER DEFAULT 0,
      viewsCount INTEGER DEFAULT 0,
      likesCount INTEGER DEFAULT 0,
      commentsCount INTEGER DEFAULT 0,
      isFavourite INTEGER DEFAULT 0,
      isLiked INTEGER DEFAULT 0,
      browseTime INTEGER DEFAULT 0,
      lastReadTime INTEGER DEFAULT 0,
      lastReadOrder INTEGER DEFAULT 0,
      lastReadIndex INTEGER DEFAULT 0
    )
  `;

  /**
   * 初始化数据库
   */
  public static async init(): Promise<boolean> {
    if (HistoryUtil.isInitialized) {
      return true;
    }

    return new Promise<boolean>((resolve) => {
      relationalStore.getRdbStore(AppUtil.getContext(), HistoryUtil.STORE_CONFIG, async (err, store) => {
        if (err) {
          LogUtil.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        HistoryUtil.rdbStore = store;
        LogUtil.info('Succeeded in getting RdbStore.');

        try {
          // 创建数据表
          await HistoryUtil.rdbStore.executeSql(HistoryUtil.SQL_CREATE_TABLE);
          LogUtil.info('Comic history table created successfully.');

          HistoryUtil.isInitialized = true;
          resolve(true);
        } catch (e) {
          const error = e as BusinessError;
          LogUtil.error(`Failed to create table. Code:${error.code}, message:${error.message}`);
          resolve(false);
        }
      });
    });
  }

  /**
   * 添加或更新漫画历史记录
   */
  public static async add(comic: ComicDetailInfo): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    const currentTime = new Date().getTime();

    try {
      // 首先检查是否已存在该漫画的记录
      const existingRecord = await HistoryUtil.exists(comic._id);
      LogUtil.info(`ComicHistory ${comic._id} ${existingRecord ? '更新' : '新增'}`);
      if (existingRecord) {
        // 如果记录已存在，使用 UPDATE 更新漫画信息
        const updateSql = `
        UPDATE ${HistoryUtil.TABLE_COMIC_HISTORY}
        SET title = ?, thumb = ?, author = ?, categories = ?, finished = ?, epsCount = ?,
            pagesCount = ?, totalViews = ?, totalLikes = ?, creator_name = ?, creator_id = ?,
            description = ?, chineseTeam = ?, tags = ?, updated_at = ?, created_at = ?,
            allowDownload = ?, allowComment = ?, totalComments = ?, viewsCount = ?,
            likesCount = ?, commentsCount = ?, isFavourite = ?, isLiked = ?, browseTime = ?,
            lastReadTime = ?, lastReadOrder = ?
        WHERE _id = ?
      `;

        await HistoryUtil.rdbStore.executeSql(updateSql, [
          comic.title,
          comic.thumb ? JSON.stringify(comic.thumb) : '',
          comic.author,
          comic.categories ? JSON.stringify(comic.categories) : '',
          comic.finished ? 1 : 0,
          comic.epsCount || 0,
          comic.pagesCount || 0,
          comic.totalViews || 0,
          comic.totalLikes || 0,
          comic._creator?.name || '',
          comic._creator?._id || '',
          comic.description,
          comic.chineseTeam,
          comic.tags ? JSON.stringify(comic.tags) : '',
          comic.updated_at,
          comic.created_at,
          comic.allowDownload ? 1 : 0,
          comic.allowComment ? 1 : 0,
          comic.totalComments || 0,
          comic.viewsCount || 0,
          comic.likesCount || 0,
          comic.commentsCount || 0,
          comic.isFavourite ? 1 : 0,
          comic.isLiked ? 1 : 0,
          currentTime, // browseTime
          currentTime, // lastReadTime
          comic.lastReadOrder,
          comic._id
        ]);

        LogUtil.info(`Updated 漫画信息: ${comic._id}`);
      } else {
        // 如果记录不存在，插入新记录
        const insertSql = `
        INSERT INTO ${HistoryUtil.TABLE_COMIC_HISTORY}
        (_id, title, thumb, author, categories, finished, epsCount, pagesCount, totalViews, totalLikes,
         creator_name, creator_id, description, chineseTeam, tags, updated_at, created_at,
         allowDownload, allowComment, totalComments, viewsCount, likesCount, commentsCount,
         isFavourite, isLiked, browseTime, lastReadTime)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

        await HistoryUtil.rdbStore.executeSql(insertSql, [
          comic._id,
          comic.title,
          comic.thumb ? JSON.stringify(comic.thumb) : '',
          comic.author,
          comic.categories ? JSON.stringify(comic.categories) : '',
          comic.finished ? 1 : 0,
          comic.epsCount || 0,
          comic.pagesCount || 0,
          comic.totalViews || 0,
          comic.totalLikes || 0,
          comic._creator?.name || '',
          comic._creator?._id || '',
          comic.description,
          comic.chineseTeam,
          comic.tags ? JSON.stringify(comic.tags) : '',
          comic.updated_at,
          comic.created_at,
          comic.allowDownload ? 1 : 0,
          comic.allowComment ? 1 : 0,
          comic.totalComments || 0,
          comic.viewsCount || 0,
          comic.likesCount || 0,
          comic.commentsCount || 0,
          comic.isFavourite ? 1 : 0,
          comic.isLiked ? 1 : 0,
          currentTime, // browseTime
          0, // lastReadTime 初始为0
        ]);

        LogUtil.info(`插入新的历史记录ID: ${comic._id}, lastReadOrder: ${comic.lastReadOrder}`);
      }

      return true;
    } catch (error) {
      const err = error as BusinessError;
      LogUtil.error(`Failed to add comic history. Code:${err.code}, message:${err.message}`);
      return false;
    }
  }

  /**
   * 获取浏览历史列表
   */
  public static async get(): Promise<ComicDetailInfo[]> {
    if (!await HistoryUtil.ensureInitialized()) {
      return [];
    }

    return new Promise<ComicDetailInfo[]>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.orderByDesc('browseTime');

      const columns = [
        '_id', 'title', 'thumb', 'author', 'categories', 'finished', 'epsCount', 'pagesCount',
        'totalViews', 'totalLikes', 'creator_name', 'creator_id', 'description', 'chineseTeam',
        'tags', 'updated_at', 'created_at', 'allowDownload', 'allowComment', 'totalComments',
        'viewsCount', 'likesCount', 'commentsCount', 'isFavourite', 'isLiked',
        'lastReadOrder', 'lastReadIndex' // 新增阅读进度字段
      ];

      HistoryUtil.rdbStore.query(predicates, columns, (err: BusinessError, resultSet: relationalStore.ResultSet) => {
        if (err) {
          LogUtil.error(`Failed to query comic history. Code:${err.code}, message:${err.message}`);
          resolve([]);
          return;
        }

        const comics: ComicDetailInfo[] = [];
        try {
          while (resultSet.goToNextRow()) {
            try {
              const comicInfo = HistoryUtil.resultSetToComicDetailInfo(resultSet);
              comics.push(comicInfo);
            } catch (parseError) {
              LogUtil.warn('Failed to parse comic data:', JSON.stringify(parseError));
            }
          }
          LogUtil.info(`查询历史记录成功, count: ${comics.length}`);
        } catch (e) {
          LogUtil.error('Error processing result set:', JSON.stringify(e));
        } finally {
          resultSet.close();
        }

        resolve(comics);
      });
    });
  }

  /**
   * 将ResultSet转换为ComicDetailInfo
   */
  private static resultSetToComicDetailInfo(resultSet: relationalStore.ResultSet): ComicDetailInfo {
    // 解析复杂对象字段
    let categories: string[] = [];
    try {
      const categoriesStr = resultSet.getString(resultSet.getColumnIndex('categories'));
      if (categoriesStr) {
        categories = JSON.parse(categoriesStr) as string[];
      }
    } catch (e) {
      LogUtil.warn('Failed to parse categories:', JSON.stringify(e));
    }

    let tags: string[] = [];
    try {
      const tagsStr = resultSet.getString(resultSet.getColumnIndex('tags'));
      if (tagsStr) {
        tags = JSON.parse(tagsStr) as string[];
      }
    } catch (e) {
      LogUtil.warn('Failed to parse tags:', JSON.stringify(e));
    }

    // 获取阅读进度
    const lastReadOrder = resultSet.getLong(resultSet.getColumnIndex('lastReadOrder')) || 0;
    const lastReadIndex = resultSet.getLong(resultSet.getColumnIndex('lastReadIndex')) || 0;

    return {
      _id: resultSet.getString(resultSet.getColumnIndex('_id')) || '',
      title: resultSet.getString(resultSet.getColumnIndex('title')) || '',
      thumb: JSON.parse(resultSet.getString(resultSet.getColumnIndex('thumb'))) as Thumb,
      author: resultSet.getString(resultSet.getColumnIndex('author')) || '',
      categories: categories,
      finished: Boolean(resultSet.getLong(resultSet.getColumnIndex('finished'))),
      epsCount: resultSet.getLong(resultSet.getColumnIndex('epsCount')) || 0,
      pagesCount: resultSet.getLong(resultSet.getColumnIndex('pagesCount')) || 0,
      totalViews: resultSet.getLong(resultSet.getColumnIndex('totalViews')) || 0,
      totalLikes: resultSet.getLong(resultSet.getColumnIndex('totalLikes')) || 0,
      _creator: {
        name: resultSet.getString(resultSet.getColumnIndex('creator_name')) || '',
        _id: resultSet.getString(resultSet.getColumnIndex('creator_id')) || ''
      },
      description: resultSet.getString(resultSet.getColumnIndex('description')) || '',
      chineseTeam: resultSet.getString(resultSet.getColumnIndex('chineseTeam')) || '',
      tags: tags,
      updated_at: resultSet.getString(resultSet.getColumnIndex('updated_at')) || '',
      created_at: resultSet.getString(resultSet.getColumnIndex('created_at')) || '',
      allowDownload: Boolean(resultSet.getLong(resultSet.getColumnIndex('allowDownload'))),
      allowComment: Boolean(resultSet.getLong(resultSet.getColumnIndex('allowComment'))),
      totalComments: resultSet.getLong(resultSet.getColumnIndex('totalComments')) || 0,
      viewsCount: resultSet.getLong(resultSet.getColumnIndex('viewsCount')) || 0,
      likesCount: resultSet.getLong(resultSet.getColumnIndex('likesCount')) || 0,
      commentsCount: resultSet.getLong(resultSet.getColumnIndex('commentsCount')) || 0,
      isFavourite: Boolean(resultSet.getLong(resultSet.getColumnIndex('isFavourite'))),
      isLiked: Boolean(resultSet.getLong(resultSet.getColumnIndex('isLiked'))),
      // 新增阅读进度字段
      lastReadOrder: Number(lastReadOrder),
      lastReadIndex: Number(lastReadIndex)
    } as ComicDetailInfo;
  }

  /**
   * 根据漫画ID获取阅读章节
   */
  public static async getRead(comicId: string): Promise<number> {
    if (!await HistoryUtil.ensureInitialized()) {
      return 0;
    }

    return new Promise<number>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.equalTo('_id', comicId);

      HistoryUtil.rdbStore.query(predicates, ['lastReadOrder'], (err: BusinessError, resultSet: relationalStore.ResultSet) => {
        if (err) {
          LogUtil.warn(`Failed to 查询阅读章节 for ${comicId}. Code:${err.code}, message:${err.message}`);
          resolve(0);
          return;
        }

        try {
          if (resultSet.goToFirstRow()) {
            const chapterOrder = resultSet.getLong(resultSet.getColumnIndex('lastReadOrder'));
            LogUtil.info(`查询阅读章节 for ${comicId}: ${chapterOrder}`);
            resolve(Number(chapterOrder));
          } else {
            LogUtil.warn(`未查询到 ${comicId} 的阅读章节记录`);
            resolve(0);
          }
        } catch (e) {
          LogUtil.error('Error processing read order:', JSON.stringify(e));
          resolve(0);
        } finally {
          resultSet.close();
        }
      });
    });
  }

  /**
   * 根据漫画ID获取阅读索引
   */
  public static async getReadIndex(comicId: string, order: number): Promise<number> {
    if (!await HistoryUtil.ensureInitialized()) {
      return 0;
    }

    return new Promise<number>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.equalTo('_id', comicId);

      HistoryUtil.rdbStore.query(predicates, ['lastReadOrder', 'lastReadIndex'], (err: BusinessError, resultSet: relationalStore.ResultSet) => {
        if (err) {
          LogUtil.warn(`Failed to 查询页码索引 for ${comicId}. Code:${err.code}, message:${err.message}`);
          resolve(0);
          return;
        }

        try {
          if (resultSet.goToFirstRow()) {
            const chapterOrder = resultSet.getLong(resultSet.getColumnIndex('lastReadOrder'));
            const pageIndex = resultSet.getLong(resultSet.getColumnIndex('lastReadIndex'));
            LogUtil.info(`查询页码索引 for ${comicId}: 章节${chapterOrder}, 索引页码${pageIndex}`);

            if (order === Number(chapterOrder)) {
              resolve(Number(pageIndex));
            } else {
              resolve(0);
            }
          } else {
            // 没有索引结果
            LogUtil.warn(`未查询到 ${comicId} 的页码索引记录`);
            resolve(0);
          }
        } catch (e) {
          LogUtil.error('Error processing read index:', JSON.stringify(e));
          resolve(0);
        } finally {
          resultSet.close();
        }
      });
    });
  }

  /**
   * 设置阅读进度
   */
  public static async setRead(comicId: string, order: number, index: number = 0): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    const currentTime = new Date().getTime();

    try {
      // 使用 UPDATE 语句更新阅读进度
      const updateSql = `
        UPDATE ${HistoryUtil.TABLE_COMIC_HISTORY}
        SET lastReadOrder = ?, lastReadIndex = ?, lastReadTime = ?
        WHERE _id = ?
      `;
      LogUtil.info(`将保存的阅读进度 for ${comicId}: ${order},${index}`);
      await HistoryUtil.rdbStore.executeSql(updateSql, [order, index, currentTime, comicId]);

      LogUtil.info(`保存阅读进度 for ${comicId}: ${order},${index}`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      LogUtil.error(`Failed to 保存阅读进度 for ${comicId}. Code:${err.code}, message:${err.message}`);
      return false;
    }
  }

  /**
   * 清空所有历史记录
   */
  public static async clear(): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    return new Promise<boolean>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);

      HistoryUtil.rdbStore.delete(predicates, (err: BusinessError, rows: number) => {
        if (err) {
          LogUtil.error(`Failed to 清空历史记录. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        LogUtil.info(`Cleared history, deleted rows: ${rows}`);
        resolve(true);
      });
    });
  }

  /**
   * 删除单个漫画的历史记录
   */
  public static async deleteSingle(comicId: string): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    return new Promise<boolean>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.equalTo('_id', comicId);

      HistoryUtil.rdbStore.delete(predicates, (err: BusinessError, rows: number) => {
        if (err) {
          LogUtil.error(`Failed to 删除 ${comicId} 浏览记录. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        LogUtil.info(`Deleted 漫画 ${comicId} 浏览记录, affected rows: ${rows}`);
        resolve(rows > 0);
      });
    });
  }

  /**
   * 备份数据库
   */
  public static async backup(backupName: string = 'comic_history_backup.db'): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    return new Promise<boolean>((resolve) => {
      HistoryUtil.rdbStore.backup(backupName, (err: BusinessError) => {
        if (err) {
          LogUtil.error(`Failed to backup database. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        LogUtil.info(`Database backup successful: ${backupName}`);
        resolve(true);
      });
    });
  }

  /**
   * 恢复数据库
   */
  public static async restore(backupName: string = 'comic_history_backup.db'): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    return new Promise<boolean>((resolve) => {
      HistoryUtil.rdbStore.restore(backupName, (err: BusinessError) => {
        if (err) {
          LogUtil.error(`Failed to restore database. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        LogUtil.info(`Database restore successful: ${backupName}`);
        resolve(true);
      });
    });
  }

  /**
   * 删除数据库
   */
  public static async deleteDatabase(): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      relationalStore.deleteRdbStore(AppUtil.getContext(), HistoryUtil.DB_NAME, (err: BusinessError) => {
        if (err) {
          LogUtil.error(`Failed to delete database. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        HistoryUtil.isInitialized = false;
        LogUtil.info('Database deleted successfully');
        resolve(true);
      });
    });
  }

  /**
   * 确保数据库已初始化
   */
  private static async ensureInitialized(): Promise<boolean> {
    if (!HistoryUtil.isInitialized) {
      return await HistoryUtil.init();
    }
    return true;
  }

  /**
   * 获取最近阅读的漫画
   */
  public static async getRecentRead(limit: number = 10): Promise<ComicDetailInfo[]> {
    if (!await HistoryUtil.ensureInitialized()) {
      return [];
    }

    return new Promise<ComicDetailInfo[]>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.greaterThan('lastReadTime', 0)
        .orderByDesc('lastReadTime');

      const columns = [
        '_id', 'title', 'thumb', 'author', 'categories', 'finished', 'epsCount', 'pagesCount',
        'totalViews', 'totalLikes', 'creator_name', 'creator_id', 'description', 'chineseTeam',
        'tags', 'updated_at', 'created_at', 'allowDownload', 'allowComment', 'totalComments',
        'viewsCount', 'likesCount', 'commentsCount', 'isFavourite', 'isLiked',
        'lastReadOrder', 'lastReadIndex' // 新增阅读进度字段
      ];

      HistoryUtil.rdbStore.query(predicates, columns, (err: BusinessError, resultSet: relationalStore.ResultSet) => {
        if (err) {
          LogUtil.error(`Failed to query recent read. Code:${err.code}, message:${err.message}`);
          resolve([]);
          return;
        }

        const comics: ComicDetailInfo[] = [];
        try {
          let count = 0;
          while (resultSet.goToNextRow() && count < limit) {
            try {
              const comicInfo = HistoryUtil.resultSetToComicDetailInfo(resultSet);
              comics.push(comicInfo);
              count++;
            } catch (parseError) {
              LogUtil.warn('Failed to parse comic data:', JSON.stringify(parseError));
            }
          }
          LogUtil.info(`Query recent read success, count: ${comics.length}`);
        } catch (e) {
          LogUtil.error('Error processing recent read result set:', JSON.stringify(e));
        } finally {
          resultSet.close();
        }

        resolve(comics);
      });
    });
  }

  /**
   * 根据漫画ID获取完整的漫画详情（包括阅读进度）
   */
  public static async getComicDetail(comicId: string): Promise<ComicDetailInfo | null> {
    if (!await HistoryUtil.ensureInitialized()) {
      return null;
    }

    return new Promise<ComicDetailInfo | null>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.equalTo('_id', comicId);

      const columns = [
        '_id', 'title', 'thumb', 'author', 'categories', 'finished', 'epsCount', 'pagesCount',
        'totalViews', 'totalLikes', 'creator_name', 'creator_id', 'description', 'chineseTeam',
        'tags', 'updated_at', 'created_at', 'allowDownload', 'allowComment', 'totalComments',
        'viewsCount', 'likesCount', 'commentsCount', 'isFavourite', 'isLiked',
        'lastReadOrder', 'lastReadIndex'
      ];

      HistoryUtil.rdbStore.query(predicates, columns, (err: BusinessError, resultSet: relationalStore.ResultSet) => {
        if (err) {
          LogUtil.error(`Failed to query comic detail for ${comicId}. Code:${err.code}, message:${err.message}`);
          resolve(null);
          return;
        }

        try {
          if (resultSet.goToFirstRow()) {
            const comicInfo = HistoryUtil.resultSetToComicDetailInfo(resultSet);
            console.log(`查询信息成功：${comicInfo.title}, 阅读进度: ${comicInfo.lastReadOrder}, ${comicInfo.lastReadIndex}`)
            resolve(comicInfo);
          } else {
            resolve(null);
          }
        } catch (e) {
          LogUtil.error('Error processing comic detail result set:', JSON.stringify(e));
          resolve(null);
        } finally {
          resultSet.close();
        }
      });
    });
  }

  /**
   * 检查漫画是否存在历史记录中
   */
  public static async exists(comicId: string): Promise<boolean> {
    if (!await HistoryUtil.ensureInitialized()) {
      return false;
    }

    return new Promise<boolean>((resolve) => {
      const predicates = new relationalStore.RdbPredicates(HistoryUtil.TABLE_COMIC_HISTORY);
      predicates.equalTo('_id', comicId);

      HistoryUtil.rdbStore.query(predicates, ['_id'], (err: BusinessError, resultSet: relationalStore.ResultSet) => {
        if (err) {
          LogUtil.error(`Failed to check comic existence for ${comicId}. Code:${err.code}, message:${err.message}`);
          resolve(false);
          return;
        }

        try {
          const exists = resultSet.goToFirstRow();
          resolve(exists);
        } catch (e) {
          LogUtil.error('Error checking comic existence:', JSON.stringify(e));
          resolve(false);
        } finally {
          resultSet.close();
        }
      });
    });
  }

  /**
   * 更新漫画的阅读进度到对象中（方便外部使用）
   */
  public static async updateComicWithReadingProgress(comic: ComicDetailInfo): Promise<ComicDetailInfo> {
    const readingProgress = await HistoryUtil.getComicDetail(comic._id);
    if (readingProgress) {
      comic.lastReadOrder = readingProgress.lastReadOrder;
      comic.lastReadIndex = readingProgress.lastReadIndex;
    } else {
      comic.lastReadOrder = 0;
      comic.lastReadIndex = 0;
    }
    return comic;
  }

}