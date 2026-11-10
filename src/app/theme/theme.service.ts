import { Injectable, signal } from '@angular/core';

export type Theme = 'light' | 'dark' | 'system';

export type NavPosition = 'fixed' | 'floating' | 'scroll' | 'top' | 'bottom';

export interface NavPositionConfig {
  position: NavPosition;
  offsetTop?: number;
  offsetBottom?: number;
  alwaysShown?: boolean;
  translateOnScroll?: boolean;
}

export interface ThemeState {
  theme: Theme;
  isDarkMode: boolean;
  navPosition: NavPosition;
  navConfig: NavPositionConfig;
}

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private readonly THEME_KEY = 'photosweep-theme';
  private readonly SYSTEM_DARK_MODE_KEY = 'photosweep-system-dark';

  private readonly themeMap = new Map<Theme, () => void>([
    ['light', () => document.body.classList.remove('dark-mode')],
    ['dark', () => document.body.classList.add('dark-mode')],
    ['system', () => {
      const isSystemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      if (isSystemDark) {
        document.body.classList.add('dark-mode');
      } else {
        document.body.classList.remove('dark-mode');
      }
    }]
  ]);

  theme = signal<Theme>('system');
  isDarkMode = signal<boolean>(false);
  navPosition = signal<NavPosition>('fixed');
  navConfig = signal<NavPositionConfig>({
    position: 'fixed',
    alwaysShown: true
  });

  constructor() {
    const savedTheme = localStorage.getItem(this.THEME_KEY) as Theme || 'system';
    this.theme.set(savedTheme);

    const savedSystemDark = localStorage.getItem(this.SYSTEM_DARK_MODE_KEY) === 'true';
    this.isDarkMode.set(savedSystemDark);

    const savedNavPos = localStorage.getItem('photosweep-nav-position') as NavPosition || 'fixed';
    this.navPosition.set(savedNavPos);

    const savedNavConfig = localStorage.getItem('photosweep-nav-config');
    if (savedNavConfig) {
      this.navConfig.set(JSON.parse(savedNavConfig));
    }

    this.applyTheme();
  }

  setTheme(theme: Theme): void {
    this.theme.set(theme);
    localStorage.setItem(this.THEME_KEY, theme);

    if (theme === 'system') {
      const isSystemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      localStorage.setItem(this.SYSTEM_DARK_MODE_KEY, String(isSystemDark));
      this.isDarkMode.set(isSystemDark);
    } else {
      this.isDarkMode.set(theme === 'dark');
    }

    this.applyTheme();
  }

  toggleTheme(): void {
    const current = this.theme();
    const next = current === 'light' ? 'dark' : 'light';
    this.setTheme(next);
  }

  setSystemDark(isDark: boolean): void {
    this.isDarkMode.set(isDark);
    localStorage.setItem(this.SYSTEM_DARK_MODE_KEY, String(isDark));
    this.applyTheme();
  }

  setNavPosition(position: NavPosition, config: NavPositionConfig = { position : 'fixed'}): void {
    this.navPosition.set(position);
    this.navConfig.set({ ...this.navConfig(), ...config });
    localStorage.setItem('photosweep-nav-position', position);
    localStorage.setItem('photosweep-nav-config', JSON.stringify(this.navConfig()));
  }

  private applyTheme(): void {
    const theme = this.theme();
    this.themeMap.get(theme)?.();
    this.isDarkMode.set(theme === 'dark' || (theme === 'system' && this.isDarkMode()));
  }

  onSystemThemeChange(callback: () => void): void {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', callback);
  }

  offSystemThemeChange(callback: () => void): void {
    window.matchMedia('(prefers-color-scheme: dark)').removeEventListener('change', callback);
  }
}
