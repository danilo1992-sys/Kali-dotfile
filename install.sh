#!/usr/bin/env bash

blue="\u001b[0;34m"

readonly ruta=$(realpath $0 | rev | cut -d'/' -f2- | rev)
readonly user="${USER}"
readonly log="${HOME}/autobspwm.log"
distro="Kali"
source "${ruta}/Colors"
source "${ruta}/utils/ask_yes_no.sh"
source "${ruta}/utils/messagebox.sh"

spinner_log() {
  tput civis
  local msg="${1:-This is a message!}"
  local delay="${2:-0.2}"
  local pid="${3}"
  local values=('|' '/' '-' '\')
  local points=('.' '..' '...' '')
  local len="${#values[@]}"
  ((${#points[@]} < len)) && len="${#points[@]}"

  local i=0
  while kill -0 "${pid}" 2>/dev/null; do
    local value="${values[i]}"
    local point="${points[i]}"
    echo -ne "\r\033[K${bright_cyan}[${value}]${end} ${msg}${bright_white}${point}${end}"
    sleep "${delay}"
    ((i = (i + 1) % len))
  done

  local exit_code=$?
  tput cnorm
  echo -ne "\r\033[K"
  return $exit_code
}

welcome() {
  clear
  printf """${blue}
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
  ${end}"""
  msg="""
 ${bright_green}•${end} ${bright_white}Este script \e[1mNO\e[0m\e[97m tiene el potencial de modificar tu sistema a \e[3mbajo nivel\e[0m\e[97m ni de \e[1mromperlo\e[0m\e[97m.
 ${bright_green}•${end} ${bright_white}Instalará un entorno \e[1;36mbspwm y gnome para la distribucion de kali linux\e[0m\e[97m minimalista utilizando \033[48;5;236meww\e[0m\e[97m, \033[48;5;236mpolybar\e[0m\e[97m y \033[48;5;236msxhkd\e[0m\e[97m para los atajos.
 ${bright_green}•${end} ${bright_white}Estés en la ruta que estés, el script se encargará de \e[3mmoverte a la ruta del ejecutable\e[0m\e[97m.
 ${bright_green}•${end} ${bright_white}Cambiará tu shell a \e[1;36mzsh\e[0m\e[97m e instalará \e[1;36mkitty\e[0m\e[97m como terminal por defecto."""
  messagebox -title " Leer " -message "${msg}" -no-preffix

  options="Si,No"
  confirm=$(
    ask_yes_no \
      -options "${options}" \
      -message "¿Deseas continuar?" \
      -selected-bg "\e[45m" \
      -unselected-bg "\e[100m" \
      -fg "\e[97m"
  )
  if [[ ! "${confirm}" =~ ^[YySs] ]]; then
    echo -e "\n${bright_red}▌ Operation canelled by ${user}${end}\n" >&2
    exit 1
  fi
}

set_time() {
  local secs=$1
  local msg=$2

  if ((secs < 60)); then
    printf "\r\033[K${bright_green}[✔]${bright_white} ${msg} en ${bright_magenta}${secs}${bright_white} segundos.${end}\n"
  else
    local mins=$(awk -v s="$secs" 'BEGIN { printf "%.2f", s / 60 }')
    printf "\r\033[K${bright_green}[✔]${bright_white} ${msg} en aproximadamente ${bright_magenta}${mins}${bright_white} minutos.${end}\n"
  fi

  printf "\b \n"
}

system_update() {
  (
    apt update -y >>"${log}" 2>&1 &&
      apt upgrade -y >>"${log}" 2>&1
  ) &
  PID=$!
  spinner_log "${bright_yellow}Actualizando el sistema esto podria toma un tiempo${end}" "0.2" "${PID}"
  wait "${PID}"

  set_time 1 "${bright_blue}El sistema se actualizo de forma exitosa${end}"
}

brew() {
  sudo apt-get install build-essential procps curl file git -y >>"${log}" 2>&1
  if ! command -v brew >>"${log}" 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >>"${log}" 2>&1
    if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -f "${HOME}/.linuxbrew/bin/brew" ]]; then
      eval "$(${HOME}/.linuxbrew/bin/brew shellenv)"
    fi
    echo 'eval "$($(brew --prefix)/bin/brew shellenv)"' >>~/.zshrc
  fi
  if command -v brew >>"${log}" 2>&1; then
    local progrmas_a_instalar=(
      "lazydocker" "lazygit" "neovim" "lsd" "rustcat"
      "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions"
      "uv" "eza" "superfile" "fnm" "zoxide" "btop" "fastfetch" "powerlevel10k"
    )
    if [[ ${#progrmas_a_instalar[@]} -gt 0 ]]; then
      brew install --formula "${progrmas_a_instalar[@]}" >>"${log}" 2>&1
      set_time 1 "${bright_blue}Se instalaron todos los paquetes con brew ${end}"
    fi
  else
    echo -e "${bright_red}[✘] Brew no se instaló correctamente${end}" >&2
  fi
}

bspwm() {
  SECONDS=0
  (
    cd "${ruta}" || exit 1
    declare -a programs=("bspwm" "feh" "libroman-perl" "xxhash")
    rm -rf ~/.config/bspwm/ 2>>"${log}"
    cp -r ./config/bspwm/ ~/.config/

    sudo apt update -y >>"${log}" 2>&1
    for program in "${programs[@]}"; do
      sudo apt install "${program}" -y >>"${log}" 2>&1 || echo "[✘] Fallo al instalar: ${program}" >>"${log}"
    done

    cd "${ruta}" || return
    sudo rm -rf /tmp/ImageMagick* 2>>"${log}"

    [[ ! -d "${HOME}/Imágenes/" ]] && mkdir -p ~/Imágenes
    [[ ! -d "${HOME}/Imágenes/capturas" ]] && mkdir -p ~/Imágenes/capturas

    # Buscador de máquinas
    sudo apt install coreutils util-linux npm nodejs bc moreutils translate-shell -y >>"${log}" 2>&1
    sudo apt install node-js-beautify -y >>"${log}" 2>&1

    sudo git clone https://github.com/SelfDreamer/s4vimachines.sh /opt/s4vimachines.sh/ >>"${log}" 2>&1

    sudo chown -R $user:$user /opt/s4vimachines.sh >>"${log}" 2>&1
    sudo apt install wmname -y >>"${log}" 2>&1
    cd "${ruta}" || return 1
    cp ./Icons/Editor.desktop /tmp/
    sed -i "s|user_replace|${user}|" /tmp/Editor.desktop >>"${log}" 2>&1
    sudo cp ./Icons/neovim.desktop /usr/share/applications/ >>"${log}" 2>&1
    sudo cp /tmp/Editor.desktop /usr/share/applications/ >>"${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando ${bright_magenta}bspwm${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_blue}Bspwm instalado de forma exitosa ${end}"

}

sxhkd() {
  (
    cd "${ruta}"
    rm -rf ~/.config/sxhkd/ 2>>"${log}"
    cp -r ./config/sxhkd/ ~/.config/
    sudo apt install flameshot xclip moreutils scrub coreutils -y >>"${log}" 2>&1
    sudo apt install -y mesa-utils >>"${log}" 2>&1
    sudo apt install libgif-dev -y >>"${log}" 2>&1
    sudo apt install \
      git build-essential autoconf automake libxcb-xkb-dev libpam0g-dev \
      libcairo2-dev libev-dev libx11-xcb-dev libxkbcommon-dev libxkbcommon-x11-dev \
      libxcb-util0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-composite0-dev \
      libxcb-xinerama0-dev libjpeg-dev libx11-dev libgif-dev -y >>"${log}" 2>&1

    # Instalamos maim
    sudo apt install libglm-dev -y >>"${log}" 2>&1
    sudo apt install libglew-dev -y >>"${log}" 2>&1

    # Intentamos instalar cmake (demás) porque se necesita XD
    sudo apt install -y cmake libxrender-dev libegl1-mesa-dev libpng-dev libjpeg-dev >>"${log}" 2>&1

    sudo apt install -y \
      libwebp-dev \
      libxcomposite-dev \
      libxfixes-dev \
      libxrandr-dev \
      libicu-dev >>"${log}" 2>&1

    # Instalamos slop, necesario, deah
    d_temp="$HOME/repos/"
    mkdir -p "${d_temp}" >>"${log}" 2>&1
    cd "${d_temp}" || exit 1

    git clone https://github.com/naelstrof/slop.git >>"${log}" 2>&1
    cd slop >>"${log}" 2>&1
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr" ./ >>"${log}" 2>&1
    if make >>"${log}" 2>&1; then
      sudo make install >>"${log}" 2>&1
    fi
    cd ..
    rm -rf slop >>"${log}" 2>&1

    # Instalamos maim ya xd
    git clone https://github.com/naelstrof/maim.git >>"${log}" 2>&1
    cd maim >>"${log}" 2>&1
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr" ./ >>"${log}" 2>&1
    if make >>"${log}" 2>&1; then
      sudo make install >>"${log}" 2>&1
    fi
    cd ..
    rm -rf maim >>"${log}" 2>&1
    cd "${ruta}"

    sudo apt install autoconf gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev libxcb-composite0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev libgif-dev -y >>"${log}" 2>&1

    cd /tmp
    git clone https://github.com/Raymo111/i3lock-color.git >>"${log}" 2>&1
    cd i3lock-color
    ./install-i3lock-color.sh >>"${log}" 2>&1
    cd "${ruta}"
    rm -rf /tmp/i3lock-color/ 2>>"${log}"
    sudo cp ./scripts/ScreenLocker /usr/bin/

    [[ ! -d "${HOME}/.config/bin/" ]] && mkdir -p ~/.config/bin/
    [[ ! -f "${HOME}/.config/bin/target" ]] && touch ~/.config/bin/target

    cd /tmp/
    readonly xqp_url="https://github.com/baskerville/xqp.git"

    git clone "${xqp_url}" >>"${log}" 2>&1
    cd xqp >>"${log}" 2>&1
    make >>"${log}" 2>&1
    sudo mv xqp /usr/bin/ >>"${log}" 2>&1
    cd ..
    rm -rf xqp 2>>"${log}"
    cd "${ruta}"

    cp -r ./config/jgmenu/ ~/.config/
    sudo apt install jgmenu -y >>"${log}" 2>&1
    # /home/kali/.local/share/icons/Qogir-Dark
    ICON_DIR="$HOME/.local/share/icons/"
    [[ ! -d "${ICON_DIR}" ]] && mkdir -p "${ICON_DIR}"
    cd /tmp/
    git clone https://github.com/vinceliuice/Qogir-icon-theme.git >>"${log}" 2>&1
    cd Qogir-icon-theme
    ./install.sh --theme >>"${log}" 2>&1
    [[ ! -d "${HOME}/.icons" ]] && mkdir -p ~/.icons >>"${log}" 2>&1
    ./install.sh -c -d ~/.icons >>"${log}" 2>&1
    cd "${ruta}" || return 1
    cp ./home/.Xresources ~/.Xresources >>"${log}" 2>&1

    cd "${ruta}"
    rm -rf /tmp/Qogir-icon-theme/ >>"${log}" 2>&1
    [[ ! -d "${HOME}/.config/gtk-3.0" ]] && mkdir -p ~/.config/gtk-3.0/
    cp ./config/gtk-3.0/settings.ini ~/.config/gtk-3.0/ >>"${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando${bright_magenta} sxhkd${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 " Sxhkd instalado de forma correcta"

}

install_git() {
  local program="git"
  if command -v "$program" >>"${log}" 2>&1; then
    echo "${bright_green} '$program' ya esta instalado${end}"
  else
    spinner_log "${bright_green}Instalando '$program' ${end}"
    sudo apt install "$program" -y
    set_time 1 "${bright_blue} '$program' se instalo de forma exitosa ${end}"
    /usr/bin/git clone https://github.com/danilo1992-sys/Kali-dotfile.git /home/$USER
  fi
}

polybar() {
  cd "${ruta}" || exit 1

  (
    sudo apt install polybar -y >>"${log}" 2>&1
    rm -rf ~/.config/polybar/ 2>>"${log}"
    cp -r ./config/polybar/ ~/.config/

    sudo apt install libnotify-bin -y >>"${log}" 2>&1
    sudo apt install dunst -y >>"${log}" 2>&1

    cp -r ./config/dunst ~/.config/ >>"${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando${bright_magenta} Polybar${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "La Polybar se instalo de forma correcta"

}

picom() {
  cd "${ruta}" || exit 1

  (
    sudo apt install meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libev-dev libpcre3-dev -y >>"${log}" 2>&1
    sudo apt install libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev meson ninja-build uthash-dev -y >>"${log}" 2>&1
    sudo apt install cmake -y >>"${log}" 2>&1

    [[ -d "picom" ]] && rm -rf picom
    if ! sudo apt install picom -y >>"${log}" 2>&1; then
      # Instalamos picom desde los repositorios de git
      git clone https://github.com/yshui/picom >>"${log}" 2>&1
      cd picom || return
      meson setup --buildtype=release build >>"${log}" 2>&1
      ninja -C build >>"${log}" 2>&1
      sudo cp build/src/picom /usr/local/bin >>"${log}" 2>&1
      sudo cp build/src/picom /usr/bin/ >>"${log}" 2>&1
      cd ..
      rm -rf picom >>"${log}" 2>&1
    fi
    cd "${ruta}"

    cp -r ./config/picom/ ~/.config/ >>"${log}" 2>&1

  ) &

  PID=$!

  spinner_log "${bright_white}Instalando${bright_magenta} Picom${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "Picom se instalo de forma correcta"

}

fonts() {
  cd "${ruta}" || exit 1
  [[ ! -d "${HOME}/.local/share/fonts/" ]] && mkdir -p ~/.local/share/fonts >>"${log}" 2>&1
  (
    sudo cp -r fonts/* /usr/local/share/fonts >>"${log}" 2>&1
    sudo cp -r fonts/* ~/.local/share/fonts >>"${log}" 2>&1
    sudo cp -r fonts/* /usr/share/fonts/truetype/ >>"${log}" 2>&1
    sudo cp ./config/polybar/fonts/* /usr/share/fonts/truetype >>"${log}" 2>&1
    sudo apt install -y papirus-icon-theme >>"${log}" 2>&1
    sudo apt install fonts-noto-color-emoji -y >>"${log}" 2>&1
    fc-cache -vf >>"${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando las fuentes necesarias${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_white}Las fuentes se instalaron de forma correcta"

}
eww() {
  cd "${ruta}" || return 1
  (
    if [[ "${distro}" == "Parrot" ]]; then
      for i in {1..3}; do
        sudo apt install "libgtk-3-dev" -y 2>&1 | grep -Po '(\S+) \(= [^)]+\)' | sed -E 's/([^ ]+) \(= ([^)]+)\)/\1=\2/' | xargs -r sudo apt install --allow-downgrades -y >>"${log}" 2>&1
      done
    fi
    # Instalamos eww y sus dependencias
    sudo apt install -y \
      git build-essential pkg-config \
      libgtk-3-dev libpango1.0-dev libglib2.0-dev libcairo2-dev \
      libdbusmenu-glib-dev libdbusmenu-gtk3-dev \
      libgtk-layer-shell-dev \
      libx11-dev libxft-dev libxrandr-dev libxtst-dev >>"${log}" 2>&1

    # Si hay un directorio eww lo borramos entero
    [[ -d "eww" ]] && rm -rf "eww"

    git clone https://github.com/elkowar/eww.git >>"${log}" 2>&1
    cd eww

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >>"${log}" 2>&1
    source ${HOME}/.cargo/env >>"${log}" 2>&1
    cargo clean >>"${log}" 2>&1
    cargo build --release >>"${log}" 2>&1

    if [[ $? -eq 0 ]]; then
      sudo cp target/release/eww /usr/bin/
      mkdir -p ~/.config/eww
      cd ..
      [[ -d "eww" ]] && rm -rf eww
      # Traemos la configuración de eww
      cp -r ./config/eww/ ~/.config/
    fi

    DIR="/tmp/RIPGREP"
    # Instalamos ripgrep
    if ! sudo apt install ripgrep -y >>"${log}" 2>&1; then
      rm -rf "${DIR}" >>"${log}" 2>&1
      mkdir -p "${DIR}" >>"${log}" 2>&1
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >>"${log}" 2>&1
      source "$HOME/.cargo/env" >>"${log}" 2>&1
      cd "${DIR}" >>"${log}" 2>&1
      git clone https://github.com/BurntSushi/ripgrep.git >>"${log}" 2>&1
      cd ripgrep >>"${log}" 2>&1
      cargo build --release >>"${log}" 2>&1
      sudo cp target/release/rg /usr/local/bin/ >>"${log}" 2>&1
    fi

    rm -rf "${DIR}" >>"${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando eww${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_white}Eww se instalo de forma correcta"

}

magick() {
  cd "${ruta}" || return
  (
    sudo apt install -y build-essential checkinstall \
      libx11-dev libxext-dev zlib1g-dev libpng-dev \
      libjpeg-dev libfreetype6-dev libxml2-dev \
      libtiff-dev libwebp-dev libopenexr-dev \
      libheif-dev libraw-dev liblcms2-dev \
      ghostscript curl >>"${log}" 2>&1

    cd /tmp || exit 1
    rm -rf ImageMagick-* >>"${log}" 2>&1

    sudo apt install -y build-essential checkinstall \
      libx11-dev libxext-dev zlib1g-dev libpng-dev libjpeg-dev \
      libfreetype6-dev libxml2-dev libtiff-dev libwebp-dev \
      libfontconfig1-dev libopenexr-dev libltdl-dev git -y >>"${log}" 2>&1

    sudo wget https://imagemagick.org/archive/ImageMagick.tar.gz >>"${log}" 2>&1
    tar xvzf ImageMagick.tar.gz >>"${log}" 2>&1
    cd ImageMagick-* || return 1

    ./configure --with-modules --enable-shared \
      --with-fontconfig=yes \
      --with-freetype=yes \
      --with-jpeg=yes \
      --with-png=yes \
      --with-tiff=yes \
      --with-webp=yes >>"${log}" 2>&1

    make -j"$(nproc)" >>"${log}" 2>&1

    sudo make install >>"${log}" 2>&1
    sudo ldconfig >>"${log}" 2>&1

    cd "${ruta}"
    # [[ "${distro}" == "Kali" ]] && ./upgrader --magick >> "${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando imagemagick${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_white}Imagemagick se instalo de forma correcta"

}

rofi() {
  (
    sudo apt install -y rofi >>"${log}" 2>&1
    sudo apt install -y thunar >>"${log}" 2>&1
    cp -r ./config/rofi/ ~/.config/
    sudo apt install librsvg2-common -y >>"${log}" 2>&1
    sudo apt install libgtk-3-bin -y >>"${log}" 2>&1

    sudo update-icon-caches /usr/share/icons/* >>"${log}" 2>&1
    sudo gtk-update-icon-cache /usr/share/icons/Papirus-Dark >>"${log}" 2>&1
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando rofi${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_white}Rofi se instalo de forma correcta"

  cd "${ruta}" || return

  THEMES=(Default Latte Macchiato Frappe Mocha)

  if [[ -z "${NICKNAME}" ]]; then
    echo -ne "\r${bright_cyan:-}[+]${bright_white:-} Introduce el nick que se vera reflejado en el fondo de pantalla: "
    read -r NICK_INPUT
    NICKNAME="${NICK_INPUT:-${USER}}"
  fi

  for THEME in "${THEMES[@]}"; do
    ./font.sh \
      --input-image "./wallpapers/Themes/${THEME}/HTB.jpg" \
      --output-image "./wallpapers/Themes/${THEME}/Wallpaper.jpg" \
      --font-path "/usr/share/fonts/truetype/HackNerdFont-Regular.ttf" \
      --fill white \
      --nickname "${NICKNAME}" >>"${log}" 2>&1

  done

  echo -e "\n${bright_green:-}[✓]${bright_white:-} Imagenes generadas, nombre de usuario:${bright_magenta:-} ${NICKNAME}${end:-}\n"

  mkdir -p ~/Imágenes/wallpapers/
  cp -r ./wallpapers/* ~/Imágenes/wallpapers/

  echo -ne "${bright_yellow}[+]${bright_white} La instalación del entorno ha finalizado, deseas reiniciar?${end}${bright_magenta} (Y/n)${end} " && read -r confirm

  if [[ "${confirm}" =~ ^[YySs] ]]; then
    sudo systemctl reboot
  fi

}

gnome_install() {
  BACKUP="${ruta}/gnome-backup/"
  EXTENSION="${ruta}/gnome-backup/extensions/"
  sudo apt install -y gnome-shell-extensions >>"${log}" 2>&1

  local ini_file
  ini_file=$(find "${BACKUP}" -maxdepth 1 -name "*.ini" -print -quit 2>/dev/null)
  if [[ -n "${ini_file}" ]]; then
    dconf load / <"${ini_file}" >>"${log}" 2>&1
  fi

  if [[ -d "${EXTENSION}" ]]; then
    mkdir -p ~/.local/share/gnome-shell/extensions
    cp -r "${EXTENSION}"* ~/.local/share/gnome-shell/extensions/ >>"${log}" 2>&1
  fi

  if command -v systemctl >>"${log}" 2>&1; then
    systemctl --user restart gnome-shell >>"${log}" 2>&1 || true
  fi
  killall -3 gnome-shell >>"${log}" 2>&1 || true
  sleep 2
  spinner_log "${bright_blue}Instalando gnome y configuraciones "
  set_time 1 "${bright_blue}Se configuro Gnome de forma correcta ${end}"
}

config() {
  local config=("bat" "bspwm" "ctk" "dunst" "eww" "fastfetch"
    "gtk-3.0" "jgmenu" "kitty" "lazydocker" "lazygit" "nvim" "polybar"
    "powerlevel10k" "rofi" "sxhkd" "zsh" "zsh-sudo" "zsh-autosuggestions" "superfile" "scripts")
  for conf in "${config[@]}"; do
    if [ -d "${HOME}/.config/$conf" ]; then
      ln -sf "${HOME}/.config/$conf" "/root/.config/$conf"
    fi
  done
  spinner_log "${bright_blue}Instalando configuraciones "
  set_time 1 "${bright_blue}se instalaron todas las configuraciones ${end}"
}

htb() {
  pipx install htb-operator
  spinner_log "${bright_blue}Innstalando htb-operator"
  set_time 1 "${bright_blue}Se instalo con exito ${end}"
}

scrips_tools() {
  git clone https://github.com/danilo1992-sys/scripts.git /home/$USER/Escritorio >>"${log}" 2>&1
  git clone https://github.com/danilo1992-sys/tools.git /home/$USER/Escritorio >>"${log}" 2>&1
  spinner_log "${bright_blue} Clonando todas las herramientas y scripts"
  set_time 1 "${bright_blue} Se clonaron todas las herramientas y scripts con exito ${end}"
}

welcome
system_update
brew
bspwm
sxhkd
polybar
picom
eww
magick
install_git
gnome_install
fonts
config
htb
scrips_tools
rofi
