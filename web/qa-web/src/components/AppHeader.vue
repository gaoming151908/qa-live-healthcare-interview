<template>
  <a-layout-header class="header">
    <div class="header-content">
      <div class="logo">
        <img
          src="https://images.pexels.com/photos/40568/medical-appointment-doctor-healthcare-40568.jpeg?auto=compress&cs=tinysrgb&w=100"
          :alt="t('app.name')"
        />
        <span>{{ t('app.name') }}</span>
      </div>
      <a-menu v-model:selectedKeys="selectedKeys" mode="horizontal" class="nav-menu">
        <a-menu-item key="home" @click="navigateTo('/')">
          <HomeOutlined />
          {{ t('nav.home') }}
        </a-menu-item>
        <a-menu-item key="consultation" @click="navigateTo('/consultation')">
          <MessageOutlined />
          {{ t('nav.consultation') }}
        </a-menu-item>
        <a-menu-item key="doctors" @click="navigateTo('/doctors')">
          <TeamOutlined />
          {{ t('nav.doctors') }}
        </a-menu-item>
        <a-menu-item key="about" @click="navigateTo('/about')">
          <InfoCircleOutlined />
          {{ t('nav.about') }}
        </a-menu-item>
      </a-menu>

      <div class="header-actions">
        <!-- Language switcher: top-right of the home page, as required. -->
        <a-select
          v-if="isHome"
          v-model:value="currentLocale"
          class="language-select"
          :options="localeOptions"
          :aria-label="t('language.label')"
          @change="handleLocaleChange"
        />
        <a-button type="primary" class="login-btn" @click="navigateTo('/doctor/login')">
          <UserOutlined />
          {{ t('nav.doctorLogin') }}
        </a-button>
      </div>
    </div>
  </a-layout-header>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import {
  HomeOutlined,
  MessageOutlined,
  TeamOutlined,
  InfoCircleOutlined,
  UserOutlined,
} from '@ant-design/icons-vue';
import {
  LOCALE_OPTIONS,
  LOCALE_STORAGE_KEY,
  type AppLocale,
} from '../locales';

const router = useRouter();
const route = useRoute();
const { t, locale } = useI18n();
const selectedKeys = ref<string[]>(['home']);

const localeOptions = LOCALE_OPTIONS;
const currentLocale = ref<string>(locale.value);
const isHome = computed(() => route.path === '/');

watch(locale, (value) => {
  currentLocale.value = value;
});

const handleLocaleChange = (value: string) => {
  locale.value = value as AppLocale;
  document.documentElement.lang = value;
  try {
    localStorage.setItem(LOCALE_STORAGE_KEY, value);
  } catch {
    // localStorage may be unavailable; switching still works for this session.
  }
};

watch(
  () => route.path,
  (newPath) => {
    if (newPath === '/') {
      selectedKeys.value = ['home'];
    } else if (newPath.startsWith('/consultation')) {
      selectedKeys.value = ['consultation'];
    } else if (newPath.startsWith('/doctors')) {
      selectedKeys.value = ['doctors'];
    } else if (newPath.startsWith('/about')) {
      selectedKeys.value = ['about'];
    }
  },
  { immediate: true },
);

const navigateTo = (path: string) => {
  router.push(path);
};
</script>

<style scoped>
.header {
  background: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  padding: 0;
  height: 64px;
  line-height: 64px;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  padding: 0 24px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
}

.logo img {
  height: 40px;
  width: 40px;
  border-radius: 8px;
  object-fit: cover;
}

.logo span {
  font-size: 20px;
  font-weight: 600;
  color: #1890ff;
  white-space: nowrap;
}

.nav-menu {
  flex: 1;
  border: none;
  margin: 0 40px;
  line-height: 64px;
  min-width: 0;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.language-select {
  width: 110px;
}

.login-btn {
  background: #52c41a;
  border-color: #52c41a;
}

.login-btn:hover {
  background: #73d13d;
  border-color: #73d13d;
}

@media (max-width: 768px) {
  .logo span {
    display: none;
  }

  .nav-menu {
    margin: 0 12px;
  }
}
</style>
