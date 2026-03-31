import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Prompt', 'Noto Sans Thai', 'sans-serif'],
      },
      colors: {
        primary: { DEFAULT: '#1E3A8A', light: '#3B82F6', dark: '#0F172A' },
        accent: '#F59E0B',
        hiclaw: { DEFAULT: '#8B5CF6', dark: '#6D28D9' },
      },
    },
  },
  plugins: [],
}
export default config
