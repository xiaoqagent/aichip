export class AppConstants {
  static readonly APP_VERSION: string = '1.0.3'
  static readonly APP_NAME: string = 'AI芯片'
  static readonly DB_VERSION: number = 3
  static readonly DB_NAME: string = 'ai_chip.db'
  static readonly RAW_DB_PATH: string = 'init_db.db'

  // 搜索
  static readonly SEARCH_DEBOUNCE_MS: number = 300
  static readonly SEARCH_PAGE_SIZE: number = 20
  static readonly SEARCH_HISTORY_MAX: number = 10

  // 颜色
  static readonly COLOR_PRIMARY: string = '#1A73E8'
  static readonly COLOR_BG: string = '#F5F6FA'
  static readonly COLOR_TEXT_PRIMARY: string = '#1A1A1A'
  static readonly COLOR_TEXT_SECONDARY: string = '#999999'
  static readonly COLOR_DIVIDER: string = '#E5E5E5'
}
