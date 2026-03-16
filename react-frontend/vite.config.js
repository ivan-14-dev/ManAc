import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const apiUrl = env.VITE_API_URL || (mode === 'development' ? 'http://localhost:8000' : 'https://man-ac.vercel.app')
  
  return {
    plugins: [react()],
    server: {
      port: 3000,
      proxy: mode === 'development' ? {
        '/api': {
          target: 'http://localhost:8000',
          changeOrigin: true,
        },
      } : undefined,
    },
    define: {
      'import.meta.env.VITE_API_URL': JSON.stringify(apiUrl),
    },
  }
})
