#!/usr/bin/env bash
#
# Auto-installer para dotfiles de Kali Linux
# Entorno: bspwm + gnome
# Autor: danilo1992-sys
#
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${HOME}/autobspwm.log"
readonly USER="${USER:-$(whoami)}"
readonly DISTRO="Kali"

# Colores
source "${SCRIPT_DIR}/Colors"

# ─────────────────────────────────────────────
# Utilidades
# ─────────────────────────────────────────────

spinner() {
  local msg="${1:-Procesando...}"
  local delay="${2:-0.15}"
  local pid="${3}"
  local chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  tput civis
  while kill -0 "${pid}" 2>/dev/null; do
    for c in "${chars[@]}"; do
      printf "\r\033[K${bright_cyan}[%s]${end} %s" "$c" "$msg"
      sleep "$delay"
      kill -0 "${pid}" 2>/dev/null || break
    done
  done
  tput cnorm
  printf "\r\033[K"
}

log_success() {
  printf "${bright_green}[✔]${bright_white} %s${end}\n" "$1"
}

log_error() {
  printf "${bright_red}[✘]${bright_white} %s${end}\n" "$1" >&2
}

log_info() {
  printf "${bright_cyan}[i]${bright_white} %s${end}\n" "$1"
}

run_as_root() {
  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

apt_install() {
  run_as_root apt install -y "$@" >>"${LOG_FILE}" 2>&1
}

apt_update() {
  run_as_root apt update -y >>"${LOG_FILE}" 2>&1
}

elapsed_time() {
  local secs=$1
  local msg=$2
  if ((secs < 60)); then
    log_success "${msg} (${secs}s)"
  else
    local mins=$(awk -v s="$secs" 'BEGIN { printf "%.1f", s / 60 }')
    log_success "${msg} (~${mins}m)"
  fi
}

check_disk_space() {
  local required_mb="${1:-5120}"
  local available_kb
  available_kb=$(df --output=avail / | tail -1 | tr -d ' ')
  local available_mb=$((available_kb / 1024))
  if ((available_mb < required_mb)); then
    log_error "Espacio insuficiente: ${available_mb}MB disponibles, se necesitan ${required_mb}MB"
    return 1
  fi
  log_info "Espacio en disco: ${available_mb}MB disponibles"
}

check_internet() {
  if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
    log_error "Sin conexión a internet"
    return 1
  fi
  log_info "Conexión a internet verificada"
}

# ─────────────────────────────────────────────
# Pre-chequeos
# ─────────────────────────────────────────────

preflight_checks() {
  log_info "Ejecutando verificaciones previas..."

  check_internet
  check_disk_space 8192

  if [[ -z "${LOG_FILE}" ]]; then :; fi
  : >"${LOG_FILE}"

  log_success "Verificaciones previas completadas"
}

# ─────────────────────────────────────────────
# Bienvenida
# ─────────────────────────────────────────────

welcome() {
  clear
  printf "${bright_blue}"
  cat <<'EOF'
    ..............
        ..,;:ccc,.
      ......''';lxO.
.....''''..........,:ld;
         .';;;:::;,,.x,
    ..'''.            0Xxoc:,.  ...
....                ,ONkc;,;cokOdc',.
.                   OMo           ':ddo.
                    dMc               :OO;
                    0M.                 .:o.
                    ;Wd
                     ;XO,
,d0Odlc;,..
                           ..',;:cdOOd::,.
                                    .:d;.':;.
                                       'd,  .'
                                         ;l   ..
                                          .o
                                            c
                                            .'
                                             .
EOF
  printf "${end}\n"

  printf "${bright_green}•${end} ${bright_white}Instala entorno bspwm + gnome para Kali Linux${end}\n"
  printf "${bright_green}•${end} ${bright_white}Componentes: eww, polybar, sxhkd, rofi${end}\n"
  printf "${bright_green}•${end} ${bright_white}Shell: zsh | Terminal: kitty${end}\n"
  printf "${bright_green}•${end} ${bright_white}Log: ${bright_cyan}${LOG_FILE}${end}\n\n"

  printf "${bright_yellow}¿Deseas continuar con la instalación?${end} ${bright_magenta}[Y/n]${end} "
  read -r confirm
  if [[ "${confirm}" =~ ^[Nn] ]]; then
    printf "\n${bright_red}▌ Operación cancelada por ${USER}${end}\n" >&2
    exit 1
  fi
}

# ─────────────────────────────────────────────
# Selección de componentes
# ─────────────────────────────────────────────

select_components() {
  printf "\n${bright_white}Selecciona modo de instalación:${end}\n"
  printf "  ${bright_green}1.${end} Todo (instalación completa)\n"
  printf "  ${bright_green}2.${end} Solo configuraciones (sin compilación desde fuente)\n"
  printf "  ${bright_green}3.${end} Personalizado\n\n"
  printf "${bright_cyan}▶${end} Selecciona modo [1/2/3] (default: 1): "
  read -r mode

  case "${mode:-1}" in
  1)
    INSTALL_ALL=true
    INSTALL_EWW=true
    INSTALL_PICOM=true
    INSTALL_MAGICK=true
    ;;
  2)
    INSTALL_ALL=false
    INSTALL_EWW=false
    INSTALL_PICOM=false
    INSTALL_MAGICK=false
    ;;
  3)
    INSTALL_ALL=false
    local comps=("bspwm" "sxhkd" "polybar" "picom" "eww" "rofi" "fonts" "magick" "zsh" "gnome" "brew" "htb")
    printf "\n${bright_white}Componentes disponibles:${end}\n"
    for i in "${!comps[@]}"; do
      printf "  ${bright_green}%d.${end} %s\n" $((i + 1)) "${comps[$i]}"
    done
    printf "${bright_cyan}▶${end} Números separados por coma (ej: 1,2,3,5): "
    read -r selections

    INSTALL_BSPWM=false
    INSTALL_SXHKD=false
    INSTALL_POLYBAR=false
    INSTALL_PICOM=false
    INSTALL_EWW=false
    INSTALL_ROFI=false
    INSTALL_FONTS=false
    INSTALL_MAGICK=false
    INSTALL_ZSH=false
    INSTALL_GNOME=false
    INSTALL_BREW=false
    INSTALL_HTB=false

    IFS=',' read -ra selected <<<"$selections"
    for sel in "${selected[@]}"; do
      sel=$(echo "$sel" | tr -d ' ')
      case "$sel" in
      1) INSTALL_BSPWM=true ;;
      2) INSTALL_SXHKD=true ;;
      3) INSTALL_POLYBAR=true ;;
      4) INSTALL_PICOM=true ;;
      5) INSTALL_EWW=true ;;
      6) INSTALL_ROFI=true ;;
      7) INSTALL_FONTS=true ;;
      8) INSTALL_MAGICK=true ;;
      9) INSTALL_ZSH=true ;;
      10) INSTALL_GNOME=true ;;
      11) INSTALL_BREW=true ;;
      12) INSTALL_HTB=true ;;
      esac
    done
    ;;
  *)
    INSTALL_ALL=true
    INSTALL_EWW=true
    INSTALL_PICOM=true
    INSTALL_MAGICK=true
    ;;
  esac

  if [[ "${INSTALL_ALL:-true}" == true ]]; then
    INSTALL_BSPWM=true
    INSTALL_SXHKD=true
    INSTALL_POLYBAR=true
    INSTALL_PICOM=true
    INSTALL_EWW=true
    INSTALL_ROFI=true
    INSTALL_FONTS=true
    INSTALL_MAGICK=true
    INSTALL_ZSH=true
    INSTALL_GNOME=true
    INSTALL_BREW=true
    INSTALL_HTB=true
  fi
}

# ─────────────────────────────────────────────
# Actualización del sistema
# ─────────────────────────────────────────────

system_update() {
  SECONDS=0
  log_info "Actualizando el sistema..."

  DEBIAN_FRONTEND=noninteractive run_as_root apt update -y >>"${LOG_FILE}" 2>&1 &
  spinner "Ejecutando apt update..." 0.2 $!
  wait $!

  DEBIAN_FRONTEND=noninteractive run_as_root apt upgrade -y >>"${LOG_FILE}" 2>&1 &
  spinner "Ejecutando apt upgrade..." 0.2 $!
  wait $!

  elapsed_time "$SECONDS" "Sistema actualizado"
}

# ─────────────────────────────────────────────
# Homebrew
# ─────────────────────────────────────────────

install_brew() {
  [[ "${INSTALL_BREW:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando Homebrew..."

  apt_install build-essential procps curl file git

  if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >>"${LOG_FILE}" 2>&1

    if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -f "${HOME}/.linuxbrew/bin/brew" ]]; then
      eval "$(${HOME}/.linuxbrew/bin/brew shellenv)"
    fi

    local brew_env='eval "$($(brew --prefix)/bin/brew shellenv)"'
    grep -qxF "$brew_env" ~/.zshrc 2>/dev/null || echo "$brew_env" >>~/.zshrc
  fi

  if command -v brew &>/dev/null; then
    local packages=(
      "lazydocker" "lazygit" "neovim" "lsd" "rustcat"
      "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions"
      "uv" "eza" "superfile" "fnm" "zoxide" "btop" "fastfetch" "powerlevel10k"
    )
    (brew install --formula "${packages[@]}" >>"${LOG_FILE}" 2>&1) &
    spinner "Instalando paquetes con Homebrew..." 0.2 $!
    elapsed_time "$SECONDS" "Homebrew y paquetes instalados"
  else
    log_error "Homebrew no se instaló correctamente"
  fi
}

# ─────────────────────────────────────────────
# BSPWM
# ─────────────────────────────────────────────

install_bspwm() {
  [[ "${INSTALL_BSPWM:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando bspwm..."

  (
    cd "${SCRIPT_DIR}" || exit 1

    rm -rf ~/.config/bspwm/ 2>>"${LOG_FILE}"
    cp -r ./config/bspwm/ ~/.config/

    local programs=("bspwm" "feh" "libroman-perl" "xxhash")
    for program in "${programs[@]}"; do
      apt_install "$program"
    done

    run_as_root rm -rf /tmp/ImageMagick* 2>>"${LOG_FILE}"
    mkdir -p ~/Imágenes/capturas 2>/dev/null

    apt_install coreutils util-linux npm nodejs bc moreutils translate-shell
    apt_install node-js-beautify

    if [[ ! -d "/opt/s4vimachines.sh" ]]; then
      run_as_root git clone https://github.com/SelfDreamer/s4vimachines.sh /opt/s4vimachines.sh/ >>"${LOG_FILE}" 2>&1
    fi
    run_as_root chown -R "${USER}:${USER}" /opt/s4vimachines.sh >>"${LOG_FILE}" 2>&1

    apt_install wmname

    cp ./Icons/Editor.desktop /tmp/
    sed -i "s|user_replace|${USER}|" /tmp/Editor.desktop
    run_as_root cp ./Icons/neovim.desktop /usr/share/applications/
    run_as_root cp /tmp/Editor.desktop /usr/share/applications/
  ) &
  spinner "Instalando bspwm..." 0.2 $!
  elapsed_time "$SECONDS" "Bspwm instalado"
}

# ─────────────────────────────────────────────
# SXHKD
# ─────────────────────────────────────────────

install_sxhkd() {
  [[ "${INSTALL_SXHKD:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando sxhkd y dependencias..."

  (
    cd "${SCRIPT_DIR}" || exit 1

    rm -rf ~/.config/sxhkd/ 2>>"${LOG_FILE}"
    cp -r ./config/sxhkd/ ~/.config/

    apt_install flameshot xclip moreutils scrub coreutils mesa-utils libgif-dev

    apt_install \
      git build-essential autoconf automake libxcb-xkb-dev libpam0g-dev \
      libcairo2-dev libev-dev libx11-xcb-dev libxkbcommon-dev libxkbcommon-x11-dev \
      libxcb-util0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-composite0-dev \
      libxcb-xinerama0-dev libjpeg-dev libx11-dev

    apt_install libglm-dev libglew-dev cmake libxrender-dev libegl1-mesa-dev libpng-dev
    apt_install libwebp-dev libxcomposite-dev libxfixes-dev libxrandr-dev libicu-dev

    local repos_dir="${HOME}/repos"
    mkdir -p "${repos_dir}"

    # slop
    if [[ ! -f "/usr/bin/slop" ]]; then
      cd "${repos_dir}"
      git clone https://github.com/naelstrof/slop.git >>"${LOG_FILE}" 2>&1
      cd slop
      cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr" ./ >>"${LOG_FILE}" 2>&1
      make >>"${LOG_FILE}" 2>&1 && run_as_root make install >>"${LOG_FILE}" 2>&1
      cd .. && rm -rf slop
    fi

    # maim
    if [[ ! -f "/usr/bin/maim" ]]; then
      cd "${repos_dir}"
      git clone https://github.com/naelstrof/maim.git >>"${LOG_FILE}" 2>&1
      cd maim
      cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr" ./ >>"${LOG_FILE}" 2>&1
      make >>"${LOG_FILE}" 2>&1 && run_as_root make install >>"${LOG_FILE}" 2>&1
      cd .. && rm -rf maim
    fi

    cd "${SCRIPT_DIR}"

    # i3lock-color
    if [[ ! -f "/usr/bin/i3lock-color" ]]; then
      apt_install autoconf gcc make pkg-config libpam0g-dev libcairo2-dev \
        libfontconfig1-dev libxcb-composite0-dev libev-dev libx11-xcb-dev \
        libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-image0-dev \
        libxcb-util0-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev

      cd /tmp
      git clone https://github.com/Raymo111/i3lock-color.git >>"${LOG_FILE}" 2>&1
      cd i3lock-color
      ./install-i3lock-color.sh >>"${LOG_FILE}" 2>&1
      cd "${SCRIPT_DIR}"
      rm -rf /tmp/i3lock-color/
    fi

    run_as_root cp ./scripts/ScreenLocker /usr/bin/

    mkdir -p ~/.config/bin/
    touch ~/.config/bin/target 2>/dev/null

    # xqp
    if [[ ! -f "/usr/bin/xqp" ]]; then
      cd /tmp/
      git clone https://github.com/baskerville/xqp.git >>"${LOG_FILE}" 2>&1
      cd xqp
      make >>"${LOG_FILE}" 2>&1
      run_as_root mv xqp /usr/bin/
      cd .. && rm -rf xqp
    fi

    cd "${SCRIPT_DIR}"
    cp -r ./config/jgmenu/ ~/.config/
    apt_install jgmenu

    # Qogir icons
    local icon_dir="${HOME}/.local/share/icons/Qogir-Dark"
    if [[ ! -d "${icon_dir}" ]]; then
      mkdir -p "${HOME}/.local/share/icons/"
      cd /tmp/
      git clone https://github.com/vinceliuice/Qogir-icon-theme.git >>"${LOG_FILE}" 2>&1
      cd Qogir-icon-theme
      ./install.sh --theme >>"${LOG_FILE}" 2>&1
      mkdir -p ~/.icons 2>/dev/null
      ./install.sh -c -d ~/.icons >>"${LOG_FILE}" 2>&1
      cd "${SCRIPT_DIR}"
      rm -rf /tmp/Qogir-icon-theme/
    fi

    cp ./home/.Xresources ~/.Xresources

    mkdir -p ~/.config/gtk-3.0/
    cp ./config/gtk-3.0/settings.ini ~/.config/gtk-3.0/
  ) &
  spinner "Instalando sxhkd y dependencias..." 0.2 $!
  elapsed_time "$SECONDS" "Sxhkd instalado"
}

# ─────────────────────────────────────────────
# Polybar
# ─────────────────────────────────────────────

install_polybar() {
  [[ "${INSTALL_POLYBAR:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando Polybar..."

  (
    cd "${SCRIPT_DIR}" || exit 1
    apt_install polybar
    rm -rf ~/.config/polybar/ 2>>"${LOG_FILE}"
    cp -r ./config/polybar/ ~/.config/

    apt_install libnotify-bin dunst
    cp -r ./config/dunst ~/.config/
  ) &
  spinner "Instalando Polybar..." 0.2 $!
  elapsed_time "$SECONDS" "Polybar instalado"
}

# ─────────────────────────────────────────────
# Picom
# ─────────────────────────────────────────────

install_picom() {
  [[ "${INSTALL_PICOM:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando Picom..."

  (
    cd "${SCRIPT_DIR}" || exit 1

    apt_install meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev \
      libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev \
      libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev \
      libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev \
      libev-dev libx11-xcb-dev libxcb-glx0-dev libpcre3-dev

    apt_install libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev \
      libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev \
      libxcb-damage0-dev libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev \
      libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev \
      libxcb-util-dev libxcb-xfixes0-dev meson ninja-build uthash-dev cmake

    [[ -d "picom" ]] && rm -rf picom
    if ! apt_install picom; then
      git clone https://github.com/yshui/picom >>"${LOG_FILE}" 2>&1
      cd picom || return
      meson setup --buildtype=release build >>"${LOG_FILE}" 2>&1
      ninja -C build >>"${LOG_FILE}" 2>&1
      run_as_root cp build/src/picom /usr/local/bin/
      run_as_root cp build/src/picom /usr/bin/
      cd .. && rm -rf picom
    fi

    cd "${SCRIPT_DIR}"
    cp -r ./config/picom/ ~/.config/
  ) &
  spinner "Instalando Picom..." 0.2 $!
  elapsed_time "$SECONDS" "Picom instalado"
}

# ─────────────────────────────────────────────
# Eww
# ─────────────────────────────────────────────

install_eww() {
  [[ "${INSTALL_EWW:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando Eww..."

  (
    cd "${SCRIPT_DIR}" || return 1

    apt_install git build-essential pkg-config \
      libgtk-3-dev libpango1.0-dev libglib2.0-dev libcairo2-dev \
      libdbusmenu-glib-dev libdbusmenu-gtk3-dev libgtk-layer-shell-dev \
      libx11-dev libxft-dev libxrandr-dev libxtst-dev

    if [[ -d "eww" ]]; then rm -rf "eww"; fi

    git clone https://github.com/elkowar/eww.git >>"${LOG_FILE}" 2>&1
    cd eww

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >>"${LOG_FILE}" 2>&1
    source "${HOME}/.cargo/env" 2>/dev/null || true
    cargo clean >>"${LOG_FILE}" 2>&1
    cargo build --release >>"${LOG_FILE}" 2>&1

    if [[ $? -eq 0 ]]; then
      run_as_root cp target/release/eww /usr/bin/
      mkdir -p ~/.config/eww
      cd ..
      rm -rf eww
      cp -r ./config/eww/ ~/.config/
    fi

    # ripgrep
    if ! command -v rg &>/dev/null; then
      if ! apt_install ripgrep; then
        local dir="/tmp/RIPGREP"
        rm -rf "${dir}" && mkdir -p "${dir}"
        cd "${dir}"
        git clone https://github.com/BurntSushi/ripgrep.git >>"${LOG_FILE}" 2>&1
        cd ripgrep
        cargo build --release >>"${LOG_FILE}" 2>&1
        run_as_root cp target/release/rg /usr/local/bin/
      fi
    fi
    rm -rf /tmp/RIPGREP 2>>"${LOG_FILE}"
  ) &
  spinner "Instalando Eww (compilación desde fuente, puede tardar)..." 0.2 $!
  elapsed_time "$SECONDS" "Eww instalado"
}

# ─────────────────────────────────────────────
# ImageMagick
# ─────────────────────────────────────────────

install_magick() {
  [[ "${INSTALL_MAGICK:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando ImageMagick..."

  (
    cd "${SCRIPT_DIR}" || return

    apt_install build-essential checkinstall \
      libx11-dev libxext-dev zlib1g-dev libpng-dev \
      libjpeg-dev libfreetype6-dev libxml2-dev \
      libtiff-dev libwebp-dev libopenexr-dev \
      libheif-dev libraw-dev liblcms2-dev \
      ghostscript curl libfontconfig1-dev libltdl-dev git

    cd /tmp || exit 1
    rm -rf ImageMagick-* 2>>"${LOG_FILE}"

    run_as_root wget https://imagemagick.org/archive/ImageMagick.tar.gz >>"${LOG_FILE}" 2>&1
    tar xvzf ImageMagick.tar.gz >>"${LOG_FILE}" 2>&1
    cd ImageMagick-* || return 1

    ./configure --with-modules --enable-shared \
      --with-fontconfig=yes --with-freetype=yes \
      --with-jpeg=yes --with-png=yes \
      --with-tiff=yes --with-webp=yes >>"${LOG_FILE}" 2>&1

    make -j"$(nproc)" >>"${LOG_FILE}" 2>&1
    run_as_root make install >>"${LOG_FILE}" 2>&1
    run_as_root ldconfig >>"${LOG_FILE}" 2>&1
  ) &
  spinner "Instalando ImageMagick..." 0.2 $!
  elapsed_time "$SECONDS" "ImageMagick instalado"
}

# ─────────────────────────────────────────────
# Rofi
# ─────────────────────────────────────────────

install_rofi() {
  [[ "${INSTALL_ROFI:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando Rofi..."

  (
    cd "${SCRIPT_DIR}" || return

    apt_install rofi thunar librsvg2-common libgtk-3-bin

    cp -r ./config/rofi/ ~/.config/

    run_as_root update-icon-caches /usr/share/icons/* >>"${LOG_FILE}" 2>&1
    run_as_root gtk-update-icon-cache /usr/share/icons/Papirus-Dark >>"${LOG_FILE}" 2>&1
  ) &
  spinner "Instalando Rofi..." 0.2 $!
  elapsed_time "$SECONDS" "Rofi instalado"
}

# ─────────────────────────────────────────────
# Fuentes
# ─────────────────────────────────────────────

install_fonts() {
  [[ "${INSTALL_FONTS:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando fuentes..."

  (
    cd "${SCRIPT_DIR}" || return 1
    mkdir -p ~/.local/share/fonts/ 2>/dev/null

    run_as_root cp -r fonts/* /usr/local/share/fonts/ 2>>"${LOG_FILE}"
    run_as_root cp -r fonts/* ~/.local/share/fonts/ 2>>"${LOG_FILE}"
    run_as_root cp -r fonts/* /usr/share/fonts/truetype/ 2>>"${LOG_FILE}"
    run_as_root cp -r ./config/polybar/fonts/* /usr/share/fonts/truetype/ 2>>"${LOG_FILE}"

    apt_install papirus-icon-theme fonts-noto-color-emoji

    fc-cache -vf >>"${LOG_FILE}" 2>&1
  ) &
  spinner "Instalando fuentes..." 0.2 $!
  elapsed_time "$SECONDS" "Fuentes instaladas"
}

# ─────────────────────────────────────────────
# ZSH
# ─────────────────────────────────────────────

install_zsh() {
  [[ "${INSTALL_ZSH:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Configurando ZSH..."

  (
    cd "${SCRIPT_DIR}" || return

    apt_install zsh

    # Copiar configuraciones
    if [[ -d "./config/zsh" ]]; then
      mkdir -p ~/.config/zsh
      cp -r ./config/zsh/* ~/.config/zsh/ 2>/dev/null || true
    fi

    # Oh My Zsh
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
      RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >>"${LOG_FILE}" 2>&1 || true
    fi

    # Powerlevel10k
    local p10k_dir="${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "${p10k_dir}" ]]; then
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${p10k_dir}" >>"${LOG_FILE}" 2>&1 || true
    fi

    # Plugins
    local plugins_dir="${HOME}/.oh-my-zsh/custom/plugins"
    mkdir -p "${plugins_dir}"

    if [[ ! -d "${plugins_dir}/zsh-autosuggestions" ]]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions "${plugins_dir}/zsh-autosuggestions" >>"${LOG_FILE}" 2>&1 || true
    fi
    if [[ ! -d "${plugins_dir}/zsh-syntax-highlighting" ]]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "${plugins_dir}/zsh-syntax-highlighting" >>"${LOG_FILE}" 2>&1 || true
    fi

    # ZSH como shell por defecto
    run_as_root chsh -s "$(which zsh)" "${USER}" >>"${LOG_FILE}" 2>&1 || true
  ) &
  spinner "Configurando ZSH..." 0.2 $!
  elapsed_time "$SECONDS" "ZSH configurado"
}

# ─────────────────────────────────────────────
# GNOME
# ─────────────────────────────────────────────

install_gnome() {
  [[ "${INSTALL_GNOME:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Configurando GNOME..."

  (
    local backup="${SCRIPT_DIR}/gnome-backup/"
    local extension="${SCRIPT_DIR}/gnome-backup/extensions/"

    apt_install gnome-shell-extensions

    local ini_file
    ini_file=$(find "${backup}" -maxdepth 1 -name "*.ini" -print -quit 2>/dev/null)
    if [[ -n "${ini_file}" ]]; then
      dconf load / <"${ini_file}" >>"${LOG_FILE}" 2>&1
    fi

    if [[ -d "${extension}" ]]; then
      mkdir -p ~/.local/share/gnome-shell/extensions
      cp -r "${extension}"* ~/.local/share/gnome-shell/extensions/ >>"${LOG_FILE}" 2>&1
    fi

    systemctl --user restart gnome-shell >>"${LOG_FILE}" 2>&1 || true
    killall -3 gnome-shell >>"${LOG_FILE}" 2>&1 || true
    sleep 2
  ) &
  spinner "Configurando GNOME..." 0.2 $!
  elapsed_time "$SECONDS" "GNOME configurado"
}

# ─────────────────────────────────────────────
# Configuraciones finales
# ─────────────────────────────────────────────

apply_configs() {
  SECONDS=0
  log_info "Aplicando configuraciones finales..."

  cd "${SCRIPT_DIR}"

  # Configs para root
  local configs=("bat" "bspwm" "ctk" "dunst" "eww" "fastfetch"
    "gtk-3.0" "jgmenu" "kitty" "lazydocker" "lazygit" "nvim" "polybar"
    "PowerLevel10k" "rofi" "sxhkd" "zsh" "zsh-sudo" "zsh-autosuggestions" "superfile" "scripts")

  for conf in "${configs[@]}"; do
    if [[ -d "${HOME}/.config/${conf}" ]]; then
      run_as_root ln -sf "${HOME}/.config/${conf}" "/root/.config/${conf}" 2>/dev/null || true
    fi
  done

  # wallpapers
  mkdir -p ~/Imágenes/wallpapers/
  cp -r ./wallpapers/* ~/Imágenes/wallpapers/

  elapsed_time "$SECONDS" "Configuraciones aplicadas"
}

# ─────────────────────────────────────────────
# HTB Operator
# ─────────────────────────────────────────────

install_htb() {
  [[ "${INSTALL_HTB:-true}" != true ]] && return 0
  SECONDS=0
  log_info "Instalando HTB Operator..."

  if command -v pipx &>/dev/null; then
    pipx install htb-operator >>"${LOG_FILE}" 2>&1 || log_error "Falló htb-operator"
  else
    apt_install pipx >>"${LOG_FILE}" 2>&1
    pipx install htb-operator >>"${LOG_FILE}" 2>&1 || log_error "Falló htb-operator"
  fi
  elapsed_time "$SECONDS" "HTB Operator instalado"
}

# ─────────────────────────────────────────────
# Scripts y herramientas
# ─────────────────────────────────────────────

clone_tools() {
  SECONDS=0
  log_info "Clonando scripts y herramientas..."

  local desktop="${HOME}/Escritorio"
  mkdir -p "${desktop}"

  git clone https://github.com/danilo1992-sys/scripts.git "${desktop}/scripts" >>"${LOG_FILE}" 2>&1 || true
  git clone https://github.com/danilo1992-sys/tools.git "${desktop}/tools" >>"${LOG_FILE}" 2>&1 || true

  elapsed_time "$SECONDS" "Scripts y herramientas clonados"
}

# ─────────────────────────────────────────────
# Generar wallpapers
# ─────────────────────────────────────────────

generate_wallpapers() {
  SECONDS=0
  log_info "Generando wallpapers personalizados..."

  cd "${SCRIPT_DIR}"

  local themes=(Default Latte Macchiato Frappe Mocha)

  local nickname="${NICKNAME:-}"
  if [[ -z "${nickname}" ]]; then
    printf "${bright_cyan}[+]${bright_white} Nick para el wallpaper [${USER}]: ${end}"
    read -r nickname
    nickname="${nickname:-${USER}}"
  fi

  for theme in "${themes[@]}"; do
    ./font.sh \
      --input-image "./wallpapers/Themes/${theme}/HTB.jpg" \
      --output-image "./wallpapers/Themes/${theme}/Wallpaper.jpg" \
      --font-path "/usr/share/fonts/truetype/HackNerdFont-Regular.ttf" \
      --fill white \
      --nickname "${nickname}" >>"${LOG_FILE}" 2>&1 || true
  done

  log_success "Wallpapers generados para: ${nickname}"
  elapsed_time "$SECONDS" "Wallpapers generados"
}

# ─────────────────────────────────────────────
# Resumen final
# ─────────────────────────────────────────────

show_summary() {
  printf "\n${bright_green}"
  cat <<'EOF'
  ╔══════════════════════════════════════════╗
  ║     ¡INSTALACIÓN COMPLETADA!             ║
  ╚══════════════════════════════════════════╝
EOF
  printf "${end}\n"

  log_info "Log guardado en: ${LOG_FILE}"
  log_info "Componentes instalados: bspwm, sxhkd, polybar, picom, eww, rofi, fonts, zsh, gnome"

  printf "\n${bright_yellow}[+]${bright_white} ¿Deseas reiniciar ahora?${end} ${bright_magenta}(Y/n)${end} "
  read -r confirm

  if [[ "${confirm}" =~ ^[YySs] ]]; then
    run_as_root systemctl reboot
  fi
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
  welcome
  preflight_checks
  select_components

  printf "\n${bright_magenta}═══════════════════════════════════════════${end}\n"
  log_info "Iniciando instalación..."
  printf "${bright_magenta}═══════════════════════════════════════════${end}\n\n"

  system_update
  install_brew
  install_bspwm
  install_sxhkd
  install_polybar
  install_picom
  install_eww
  install_magick
  install_rofi
  install_fonts
  install_zsh
  install_gnome
  apply_configs
  install_htb
  clone_tools
  generate_wallpapers

  show_summary
}

main "$@"
