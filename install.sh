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
    apt update -y &>/dev/null &&
      apt upgrade -y &>/dev/null
  ) &
  PID=$!
  spinner_log "${bright_yellow}Actualizando el sistema esto podria toma un tiempo${end}" "0.2" "${PID}"
  wait "${PID}"

  set_time 1 "${bright_blue}El sistema se actualizo de forma exitosa${end}"
}

brew() {
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.zshrc
    sudo apt-get install build-essential procps curl file git
  fi
  local progrmas_a_instalar=(
    "lazydocker" "lazygit" "neovim" "lsd" "rustcat"
    "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions"
    "uv" "eza" "superfile" "fnm" "zoxide" "btop" "fastfetch" "powerlevel10k"
  )
  if [[ ${#progrmas_a_instalar[@]} -gt 0 ]]; then
    brew install --formula "${progrmas_a_instalar}" &>/dev/null
    set_time 1 "${bright_blue}Se instalaron todos los paquetes con brew ${end}"
  fi
}

bspwm() {
  SECONDS=0
  (
    cd "${ruta}" || exit 1
    declare -a programs=("bspwm" "feh" "libroman-perl" "xxhash")
    rm -rf ~/.config/bspwm/ 2>"${log}"
    cp -r ./config/bspwm/ ~/.config/

    for program in "${programs[@]}"; do
      sudo apt install "${program}" -y &>"${log}"
    done

    cd "${ruta}" || return
    sudo rm -rf /tmp/ImageMagick* &>"${log}"

    [[ ! -d "${HOME}/Imágenes/" ]] && mkdir -p ~/Imágenes
    [[ ! -d "${HOME}/Imágenes/capturas" ]] && mkdir -p ~/Imágenes/capturas

    # Buscador de máquinas
    sudo apt install coreutils util-linux npm nodejs bc moreutils translate-shell -y &>/dev/null
    sudo apt install node-js-beautify -y &>/dev/null

    sudo git clone https://github.com/SelfDreamer/s4vimachines.sh /opt/s4vimachines.sh/ &>/dev/null

    sudo chown -R $user:$user /opt/s4vimachines.sh &>/dev/null
    sudo apt install wmname -y &>/dev/null
    cd "${ruta}" || return 1
    cp ./Icons/Editor.desktop /tmp/
    sed -i "s|user_replace|${user}|" /tmp/Editor.desktop &>/dev/null
    sudo cp ./Icons/neovim.desktop /usr/share/applications/ &>/dev/null
    sudo cp /tmp/Editor.desktop /usr/share/applications/ &>/dev/null
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando ${bright_magenta}bspwm${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_blue}Bspwm instalado de forma exitosa ${end}"

}

sxhkd() {
  (
    cd "${ruta}"
    rm -rf ~/.config/sxhkd/ 2>"${log}"
    cp -r ./config/sxhkd/ ~/.config/
    sudo apt install flameshot xclip moreutils scrub coreutils -y &>/dev/null
    sudo apt install -y mesa-utils &>/dev/null
    sudo apt install libgif-dev -y &>/dev/null
    sudo apt install \
      git build-essential autoconf automake libxcb-xkb-dev libpam0g-dev \
      libcairo2-dev libev-dev libx11-xcb-dev libxkbcommon-dev libxkbcommon-x11-dev \
      libxcb-util0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-composite0-dev \
      libxcb-xinerama0-dev libjpeg-dev libx11-dev libgif-dev -y &>/dev/null

    # Instalamos maim
    sudo apt install libglm-dev -y &>/dev/null
    sudo apt install libglew-dev -y &>/dev/null

    # Intentamos instalar cmake (demás) porque se necesita XD
    sudo apt install -y cmake libxrender-dev libegl1-mesa-dev libpng-dev libjpeg-dev &>/dev/null

    sudo apt install -y \
      libwebp-dev \
      libxcomposite-dev \
      libxfixes-dev \
      libxrandr-dev \
      libicu-dev &>/dev/null

    # Instalamos slop, necesario, deah
    d_temp="$HOME/repos/"
    mkdir -p "${d_temp}" &>/dev/null
    cd "${d_temp}" || exit 1

    git clone https://github.com/naelstrof/slop.git &>/dev/null
    cd slop &>/dev/null
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr" ./ &>/dev/null
    if make &>/dev/null; then
      sudo make install &>/dev/null
    fi
    cd ..
    rm -rf slop &>/dev/null

    # Instalamos maim ya xd
    git clone https://github.com/naelstrof/maim.git &>/dev/null
    cd maim &>/dev/null
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr" ./ &>/dev/null
    if make &>/dev/null; then
      sudo make install &>/dev/null
    fi
    cd ..
    rm -rf maim &>/dev/null
    cd "${ruta}"

    sudo apt install autoconf gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev libxcb-composite0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev libgif-dev -y &>/dev/null

    cd /tmp
    git clone https://github.com/Raymo111/i3lock-color.git &>/dev/null
    cd i3lock-color
    ./install-i3lock-color.sh &>/dev/null
    cd "${ruta}"
    rm -rf /tmp/i3lock-color/ 2>"${log}"
    sudo cp ./scripts/ScreenLocker /usr/bin/

    [[ ! -d "${HOME}/.config/bin/" ]] && mkdir -p ~/.config/bin/
    [[ ! -f "${HOME}/.config/bin/target" ]] && touch ~/.config/bin/target

    cd /tmp/
    readonly xqp_url="https://github.com/baskerville/xqp.git"

    git clone "${xqp_url}" &>/dev/null
    cd xqp &>/dev/null
    make &>/dev/null
    sudo mv xqp /usr/bin/ &>/dev/null
    cd ..
    rm -rf xqp 2>"${log}"
    cd "${ruta}"

    cp -r ./config/jgmenu/ ~/.config/
    sudo apt install jgmenu -y &>/dev/null
    # /home/kali/.local/share/icons/Qogir-Dark
    ICON_DIR="$HOME/.local/share/icons/"
    [[ ! -d "${ICON_DIR}" ]] && mkdir -p "${ICON_DIR}"
    cd /tmp/
    git clone https://github.com/vinceliuice/Qogir-icon-theme.git &>/dev/null
    cd Qogir-icon-theme
    ./install.sh --theme &>/dev/null
    [[ ! -d "${HOME}/.icons" ]] && mkdir -p ~/.icons &>/dev/null
    ./install.sh -c -d ~/.icons &>/dev/null
    cd "${ruta}" || return 1
    cp ./home/.Xresources ~/.Xresources &>/dev/null

    cd "${ruta}"
    rm -rf /tmp/Qogir-icon-theme/ &>/dev/null
    [[ ! -d "${HOME}/.config/gtk-3.0" ]] && mkdir -p ~/.config/gtk-3.0/
    cp ./config/gtk-3.0/settings.ini ~/.config/gtk-3.0/ &>/dev/null
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando${bright_magenta} sxhkd${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 " Sxhkd instalado de forma correcta"

}

install_git() {
  local program="git"
  if command -v "$program" &>/dev/null; then
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
    sudo apt install polybar -y &>/dev/null
    rm -rf ~/.config/polybar/ 2>"${log}"
    cp -r ./config/polybar/ ~/.config/

    sudo apt install libnotify-bin -y &>/dev/null
    sudo apt install dunst -y &>/dev/null

    cp -r ./config/dunst ~/.config/ &>/dev/null
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando${bright_magenta} Polybar${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "La Polybar se instalo de forma correcta"

}

picom() {
  cd "${ruta}" || exit 1

  (
    sudo apt install meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libev-dev libpcre3-dev -y &>/dev/null
    sudo apt install libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev meson ninja-build uthash-dev -y &>/dev/null
    sudo apt install cmake -y &>/dev/null

    [[ -d "picom" ]] && rm -rf picom
    if ! sudo apt install picom -y &>/dev/null; then
      # Instalamos picom desde los repositorios de git
      git clone https://github.com/yshui/picom &>/dev/null
      cd picom || return
      meson setup --buildtype=release build &>/dev/null
      ninja -C build &>/dev/null
      sudo cp build/src/picom /usr/local/bin &>/dev/null
      sudo cp build/src/picom /usr/bin/ &>/dev/null
      cd ..
      rm -rf picom &>/dev/null
    fi
    cd "${ruta}"

    cp -r ./config/picom/ ~/.config/ &>/dev/null

  ) &

  PID=$!

  spinner_log "${bright_white}Instalando${bright_magenta} Picom${bright_white}, esto podria tomar un tiempo${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "Picom se instalo de forma correcta"

}

fonts() {
  cd "${ruta}" || exit 1
  [[ ! -d "${HOME}/.local/share/fonts/" ]] && mkdir -p ~/.local/share/fonts &>/dev/null
  (
    sudo cp -r fonts/* /usr/local/share/fonts &>/dev/null
    sudo cp -r fonts/* ~/.local/share/fonts &>/dev/null
    sudo cp -r fonts/* /usr/share/fonts/truetype/ &>/dev/null
    sudo cp ./config/polybar/fonts/* /usr/share/fonts/truetype &>/dev/null
    sudo apt install -y papirus-icon-theme &>/dev/null
    sudo apt install fonts-noto-color-emoji -y &>/dev/null
    fc-cache -vf &>/dev/null
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
        sudo apt install "libgtk-3-dev" -y 2>&1 | grep -Po '(\S+) \(= [^)]+\)' | sed -E 's/([^ ]+) \(= ([^)]+)\)/\1=\2/' | xargs -r sudo apt install --allow-downgrades -y &>/dev/null
      done
    fi
    # Instalamos eww y sus dependencias
    sudo apt install -y \
      git build-essential pkg-config \
      libgtk-3-dev libpango1.0-dev libglib2.0-dev libcairo2-dev \
      libdbusmenu-glib-dev libdbusmenu-gtk3-dev \
      libgtk-layer-shell-dev \
      libx11-dev libxft-dev libxrandr-dev libxtst-dev &>/dev/null

    # Si hay un directorio eww lo borramos entero
    [[ -d "eww" ]] && rm -rf "eww"

    git clone https://github.com/elkowar/eww.git &>/dev/null
    cd eww

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
    source ${HOME}/.cargo/env &>/dev/null
    cargo clean &>/dev/null
    cargo build --release &>/dev/null

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
    if ! sudo apt install ripgrep -y &>/dev/null; then
      rm -rf "${DIR}" &>/dev/null
      mkdir -p "${DIR}" &>/dev/null
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
      source "$HOME/.cargo/env" &>/dev/null
      cd "${DIR}" &>/dev/null
      git clone https://github.com/BurntSushi/ripgrep.git &>/dev/null
      cd ripgrep &>/dev/null
      cargo build --release &>/dev/null
      sudo cp target/release/rg /usr/local/bin/ &>/dev/null
    fi

    rm -rf "${DIR}" &>/dev/null
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
      ghostscript curl &>/dev/null

    cd /tmp || exit 1
    rm -rf ImageMagick-* &>/dev/null

    sudo apt install -y build-essential checkinstall \
      libx11-dev libxext-dev zlib1g-dev libpng-dev libjpeg-dev \
      libfreetype6-dev libxml2-dev libtiff-dev libwebp-dev \
      libfontconfig1-dev libopenexr-dev libltdl-dev git -y &>/dev/null

    wget https://imagemagick.org/archive/ImageMagick.tar.gz &>/dev/null
    tar xvzf ImageMagick.tar.gz &>/dev/null
    cd ImageMagick-* || return 1

    ./configure --with-modules --enable-shared \
      --with-fontconfig=yes \
      --with-freetype=yes \
      --with-jpeg=yes \
      --with-png=yes \
      --with-tiff=yes \
      --with-webp=yes &>/dev/null

    make -j"$(nproc)" &>/dev/null

    sudo make install &>/dev/null
    sudo ldconfig &>/dev/null

    cd "${ruta}"
    # [[ "${distro}" == "Kali" ]] && ./upgrader --magick &>/dev/null
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando imagemagick${end}" "0.2" "${PID}"

  wait "${PID}"

  set_time 1 "${bright_white}Imagemagick se instalo de forma correcta"

}

rofi() {
  (
    sudo apt install -y rofi &>/dev/null
    sudo apt install -y thunar &>/dev/null
    cp -r ./config/rofi/ ~/.config/
    sudo apt install librsvg2-common -y &>/dev/null
    sudo apt install libgtk-3-bin -y &>/dev/null

    sudo update-icon-caches /usr/share/icons/* &>/dev/null
    sudo gtk-update-icon-cache /usr/share/icons/Papirus-Dark &>/dev/null
  ) &

  PID=$!

  spinner_log "${bright_white}Instalando rofi${end}" "0.2" "${PID}"

  wait "${PID}"
  >?
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
      --nickname "${NICKNAME}" &>/dev/null

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
  BACKUP="$HOME/Kali-dotfile/gnome-backup/"
  EXTENSION="$HOME/Kali-dotfile/gnome-backup/extensions/"
  apt install -y gnome-shell-extensions
  dconf load / <"$BACKUP"*.ini
  cp -r "$EXTENSION"* ~/.local/share/gnome-shell/extensions 2>/dev/null
  if command -v systemctl &>/dev/null; then
    systemctl --user restart gnome-shell 2>/dev/null || true
  fi
  killall -3 gnome-shell 2>/dev/null || true
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
  git clone https://github.com/danilo1992-sys/scripts.git /home/$USER/Escritorio &>/dev/null
  git clone https://github.com/danilo1992-sys/tools.git /home/$USER/Escritorio &>/dev/null
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
