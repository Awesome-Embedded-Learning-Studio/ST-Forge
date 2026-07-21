import { defineProject } from './site/.vitepress/config/schema'

export default defineProject({
  name: 'st-forge',
  title: { 'zh-CN': 'ST-Forge 教程文档' },
  description: { 'zh-CN': 'ST-Forge，专注于 STM32F103C8T6 (Blue Pill) 裸机 C + CMake 的嵌入式开发教程文档' },
  base: '/ST-Forge/',
  copyright: 'Copyright © 2026 Awesome-Embedded-Learning-Studio - 保留所有权利',

  documentsDir: 'documentations',
  siteDir: 'site',

  locales: [
    { code: 'zh-CN', label: '中文', default: true },
  ],

  nav: {
    'zh-CN': [
      { text: '首页', link: '/' },
      { text: '教程', link: '/tutorial/' },
      { text: '规划', link: '/planning/' },
      { text: 'GitHub', link: 'https://github.com/Awesome-Embedded-Learning-Studio/ST-Forge' },
    ],
  },

  sidebar: {
    volumes: [
      { name: 'tutorial', srcDir: 'tutorial', urlPrefix: '/tutorial' },
      { name: 'planning', srcDir: 'planning', urlPrefix: '/planning' },
    ],
  },

  github: {
    owner: 'Awesome-Embedded-Learning-Studio',
    repo: 'ST-Forge',
    branch: 'main',
    documentsPath: 'documentations',
  },

  build: {
    concurrency: 4,
    rootPages: ['index.md'],
    rootAssets: [],
  },

  plugins: {
    cppTemplateEscape: true,
    kbd: true,
    math: false,
  },
})
