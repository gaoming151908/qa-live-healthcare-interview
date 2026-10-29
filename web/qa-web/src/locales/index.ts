import { createI18n } from 'vue-i18n';
import zhCN from './zh-CN';
import enUS from './en-US';

export type AppLocale = 'zh-CN' | 'en-US';

export const LOCALE_STORAGE_KEY = 'qa-locale';

export const LOCALE_OPTIONS: Array<{ value: AppLocale; label: string }> = [
  { value: 'zh-CN', label: '中文' },
  { value: 'en-US', label: 'English' },
];

function readStoredLocale(): AppLocale | null {
  try {
    const stored = localStorage.getItem(LOCALE_STORAGE_KEY);
    return stored === 'zh-CN' || stored === 'en-US' ? stored : null;
  } catch {
    return null;
  }
}

function detectLocale(): AppLocale {
  const stored = readStoredLocale();
  if (stored) {
    return stored;
  }
  const browserLocale = typeof navigator !== 'undefined' ? navigator.language : 'zh-CN';
  return browserLocale.toLowerCase().startsWith('zh') ? 'zh-CN' : 'en-US';
}

const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: detectLocale(),
  fallbackLocale: 'zh-CN',
  messages: {
    'zh-CN': zhCN,
    'en-US': enUS,
  },
});

export default i18n;
