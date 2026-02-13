#!/bin/bash

# =============================================================================
# Скрипт установки Nginx, генерации фейковой страницы и базовой настройки
# =============================================================================
# Запуск: sudo bash this_script.sh your.domain.com
# Требования: Ubuntu/Debian, root-доступ
# После запуска: открой http://your.domain.com в браузере

# Цвета для вывода
GRN='\033[0;32m'
RED='\033[0;31m'
YEL='\033[1;33m'
NC='\033[0m'

# Проверка root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ошибка: Запустите скрипт от root (sudo)${NC}"
   exit 1
fi

# Домен как аргумент
DOMAIN="$1"
if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}Ошибка: Укажите домен как аргумент (e.g., $0 example.com)${NC}"
    exit 1
fi

# Шаг 1: Обновление системы и установка зависимостей
echo -e "${YEL}→ Обновляем систему и устанавливаем Nginx${NC}"
apt update -y && apt upgrade -y
apt install -y nginx curl wget nano || { echo -e "${RED}Ошибка установки пакетов${NC}"; exit 1; }

# Включение и запуск Nginx
systemctl enable nginx
systemctl start nginx
systemctl status nginx > /dev/null || { echo -e "${RED}Nginx не запустился${NC}"; exit 1; }
echo -e "${GRN}Nginx установлен и запущен${NC}"

# Шаг 2: Проверка DNS (опционально, но полезно)
LOCAL_IP=$(hostname -I | awk '{print $1}')
DNS_IP=$(dig +short "$DOMAIN")
if [[ "$LOCAL_IP" != "$DNS_IP" ]]; then
    echo -e "${YEL}Предупреждение: Локальный IP ($LOCAL_IP) не совпадает с DNS ($DNS_IP). Продолжить? (y/n)${NC}"
    read -r confirm
    if [[ "$confirm" != "y" ]]; then exit 0; fi
fi

# Шаг 3: Создание директории для сайта
WWW_DIR="/var/www/$DOMAIN"
mkdir -p "$WWW_DIR" || { echo -e "${RED}Не удалось создать $WWW_DIR${NC}"; exit 1; }
chown -R www-data:www-data "$WWW_DIR"
chmod -R 755 "$WWW_DIR"
echo -e "${GRN}Директория $WWW_DIR создана${NC}"

# Шаг 4: Генерация фейковой страницы (CloudSphere версия)
INDEX_FILE="$WWW_DIR/index.html"

cat > "$INDEX_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>CloudSphere — Ваше облако</title>
  <style>
    :root {
      --primary: #1e40af;
      --primary-dark: #1e3a8a;
      --bg: #f8fafc;
      --card: white;
      --text: #1e293b;
      --text-light: #64748b;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: system-ui, -apple-system, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.5;
    }

    header {
      background: var(--primary);
      color: white;
      padding: 1rem 0;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 2px 10px rgba(0,0,0,0.12);
    }

    .container {
      max-width: 1280px;
      margin: 0 auto;
      padding: 0 1.5rem;
    }

    .header-inner {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .logo {
      font-size: 1.5rem;
      font-weight: 700;
    }

    nav a {
      color: white;
      text-decoration: none;
      margin-left: 1.75rem;
      font-weight: 500;
    }

    nav a:hover {
      text-decoration: underline;
    }

    .hero {
      background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
      color: white;
      text-align: center;
      padding: 7rem 1rem 5rem;
    }

    .hero h1 {
      font-size: 2.8rem;
      margin-bottom: 1rem;
    }

    .hero p {
      font-size: 1.25rem;
      opacity: 0.95;
      max-width: 600px;
      margin: 0 auto 2.5rem;
    }

    .login-box {
      background: white;
      color: var(--text);
      max-width: 420px;
      margin: 0 auto;
      padding: 2.2rem;
      border-radius: 12px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.22);
      display: none;
    }

    .login-box.show {
      display: block;
    }

    input {
      width: 100%;
      padding: 0.9rem;
      margin: 0.8rem 0;
      border: 1px solid #d1d5db;
      border-radius: 6px;
      font-size: 1rem;
    }

    .btn {
      background: var(--primary);
      color: white;
      border: none;
      padding: 0.9rem 1.8rem;
      border-radius: 6px;
      font-size: 1.05rem;
      cursor: pointer;
      transition: 0.2s;
    }

    .btn:hover {
      background: var(--primary-dark);
    }

    .files-section {
      padding: 4rem 1rem;
    }

    .files-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
      gap: 1.5rem;
      margin-top: 2rem;
    }

    .file-card {
      background: var(--card);
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      padding: 1.3rem;
      text-align: center;
      transition: all 0.15s;
    }

    .file-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 20px rgba(0,0,0,0.08);
    }

    .file-icon {
      font-size: 3.8rem;
      margin-bottom: 0.8rem;
    }

    .file-name {
      font-weight: 600;
      margin: 0.5rem 0 0.3rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .file-size {
      color: var(--text-light);
      font-size: 0.9rem;
    }

    .locked {
      opacity: 0.55;
      cursor: not-allowed;
    }

    footer {
      background: #0f172a;
      color: #94a3b8;
      text-align: center;
      padding: 2.5rem 1rem;
      font-size: 0.95rem;
    }

    @media (max-width: 768px) {
      .hero h1 { font-size: 2.2rem; }
      .hero { padding: 5rem 1rem 4rem; }
      nav { display: none; } /* упрощаем на мобилках */
    }
  </style>
</head>
<body>

<header>
  <div class="container">
    <div class="header-inner">
      <div class="logo">CloudSphere</div>
      <nav>
        <a href="#">Файлы</a>
        <a href="#">Общий доступ</a>
        <a href="#">Настройки</a>
        <a href="#" onclick="toggleLogin()">Войти</a>
      </nav>
    </div>
  </div>
</header>

<section class="hero">
  <div class="container">
    <h1>Ваше безопасное облако</h1>
    <p>Храните, синхронизируйте и делитесь файлами с любого устройства</p>

    <div class="login-box" id="loginBox">
      <h2 style="margin-bottom:1.5rem;">Вход в аккаунт</h2>
      <form id="fakeForm">
        <input type="email"    placeholder="Email или телефон" required autocomplete="off"/>
        <input type="password" placeholder="Пароль" required autocomplete="off"/>
        <button type="submit" class="btn" style="width:100%; margin-top:1rem;">Войти</button>
        <p style="margin-top:1.2rem; text-align:center; font-size:0.95rem;">
          <a href="#" style="color:var(--primary);">Забыли пароль?</a>
        </p>
      </form>
    </div>
  </div>
</section>

<section class="files-section">
  <div class="container">
    <h2>Недавние файлы</h2>

    <div class="files-grid">
      <div class="file-card">
        <div class="file-icon">📄</div>
        <div class="file-name">Коммерческое_предложение_2026.pdf</div>
        <div class="file-size">3.2 МБ</div>
      </div>
      <div class="file-card">
        <div class="file-icon">📸</div>
        <div class="file-name">IMG_4782_отпуск.jpg</div>
        <div class="file-size">7.8 МБ</div>
      </div>
      <div class="file-card">
        <div class="file-icon">📊</div>
        <div class="file-name">Финансовый_план_Q1-Q4.xlsx</div>
        <div class="file-size">1.4 МБ</div>
      </div>
      <div class="file-card locked">
        <div class="file-icon">🔒</div>
        <div class="file-name">Договор_конфиденциальности.docx</div>
        <div class="file-size">—</div>
      </div>
      <div class="file-card">
        <div class="file-icon">🎥</div>
        <div class="file-name">Презентация_команда.mp4</div>
        <div class="file-size">68 МБ</div>
      </div>
    </div>
  </div>
</section>

<footer>
  <div class="container">
    © 2024–2026 CloudSphere. Все права защищены.
  </div>
</footer>

<script>
  function toggleLogin() {
    document.getElementById("loginBox").classList.toggle("show");
  }

  document.getElementById("fakeForm")?.addEventListener("submit", function(e) {
    e.preventDefault();
    alert("Неверный логин или пароль. Попробуйте снова.");
  });
</script>

</body>
</html>
EOF

chown www-data:www-data "$INDEX_FILE"
chmod 644 "$INDEX_FILE"
echo -e "${GRN}Фейковая страница сгенерирована: $INDEX_FILE${NC}"

# Шаг 5: Настройка Nginx конфига
CONFIG_FILE="/etc/nginx/sites-available/$DOMAIN"

cat > "$CONFIG_FILE" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $WWW_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ln -sf "$CONFIG_FILE" /etc/nginx/sites-enabled/
nginx -t || { echo -e "${RED}Ошибка в конфиге Nginx${NC}"; exit 1; }
systemctl restart nginx
echo -e "${GRN}Nginx настроен для $DOMAIN${NC}"

# Шаг 6: Финальная проверка и вывод
echo -e "${YEL}→ Тестирование:${NC}"
curl -I "http://$DOMAIN" 2>/dev/null | grep "200 OK" && echo -e "${GRN}Страница доступна: http://$DOMAIN${NC}" || echo -e "${RED}Проблема с доступом. Проверьте DNS/фаервол${NC}"

echo -e "${GRN}Установка завершена! Откройте http://$DOMAIN в браузере.${NC}"
