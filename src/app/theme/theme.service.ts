import { Injectable, signal } from '@angular/core';

export type Theme = 'light' | 'dark' | 'system';

export interface ThemeState {
  theme: Theme;
  isDarkMode: boolean;
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

  constructor() {
    const savedTheme = localStorage.getItem(this.THEME_KEY) as Theme || 'system';
    this.theme.set(savedTheme);

    const savedSystemDark = localStorage.getItem(this.SYSTEM_DARK_MODE_KEY) === 'true';
    this.isDarkMode.set(savedSystemDark);

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
