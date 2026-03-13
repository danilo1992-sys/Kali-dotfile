#!/usr/bin/env bash

blue="\u001b[0;34m"

readonly ruta=$(realpath $0 | rev | cut -d'/' -f2- | rev)
readonly user="${USER}"
readonly log="${HOME}/autobspwm.log"
source ./Colors
source ./utils/ask_yes_no.sh
source ./utils/messagebox.sh

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
    echo -e "\n${bright_red}▌ Operation canelled by ${usuario}${end}\n" >&2
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
    "uv" "eza" "superfile" "fnm" "zoxide" "btop"
  )
  if [[ ${#progrmas_a_instalar[@]} -gt 0 ]]; then
    brew install --formula "${progrmas_a_instalar}" &>/dev/null
    set_time 1 "${bright_blue}Se instalaron todos los paquetes con brew ${end}"
  fi
}

welcome
system_update
brew
