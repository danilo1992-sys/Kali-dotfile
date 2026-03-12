#!/bin/zsh

# Theme  
THEME="default"
# Fix the Java Problem
export _JAVA_AWT_WM_NONREPARENTING=1

# FZF THEME
case "${THEME}" in 
  mocha) 
    export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
    ;;
  latte)
    export FZF_DEFAULT_OPTS=" \
--color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 \
--color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
--color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
--color=selected-bg:#BCC0CC \
--color=border:#9CA0B0,label:#4C4F69"
    ;;
  frappe)
    export FZF_DEFAULT_OPTS=" \
--color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 \
--color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
--color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
--color=selected-bg:#BCC0CC \
--color=border:#9CA0B0,label:#4C4F69"
    ;;
  macchiato)
    export FZF_DEFAULT_OPTS=" \
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#6E738D,label:#CAD3F5"
    ;; 
  default)
    export FZF_DEFAULT_OPTS=""
esac 


# Enable Powerlevel10k instant prompt. Should stay at the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set up the prompt
autoload -Uz promptinit
promptinit
setopt histignorealldups sharehistory
# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Fzf tabs completions 
zstyle ':fzf-tab:*' fzf-flags --style=full --height=90% --pointer '>' \
                --color 'pointer:green:bold,bg+:-1:,fg+:green:bold,info:blue:bold,marker:yellow:bold,hl:gray:bold,hl+:yellow:bold' \
                --input-label ' Search ' --color 'input-border:blue,input-label:blue:bold' \
                --list-label ' Results ' --color 'list-border:green,list-label:green:bold' \
                --preview-label ' Preview ' --color 'preview-border:magenta,preview-label:magenta:bold'

zstyle ':fzf-tab:*' fzf-bindings 'space:accept'
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' fzf-bindings 'enter:accept'


zstyle ':fzf-tab:complete:bat:*' fzf-preview "if [ -d \$realpath ]; then ls --color=always -1 \$realpath; elif [[ \$(file --mime \$realpath) =~ binary ]]; then echo \$realpath is a binary file; else (bat --style=numbers --color=always --theme=\"Catppuccin ${(C)THEME}\" \$realpath 2>/dev/null || highlight -O ansi -l \$realpath || coderay \$realpath || rougify \$realpath || cat \$realpath) 2> /dev/null | head -500; fi"     

# Manual configuration

PATH=/root/.local/bin:/snap/bin:/usr/sandbox/:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/share/games:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/opt/s4vimachines.sh/:/opt/nvim/bin/:/opt/kitty/bin/ 

# Manual aliases
    alias hack='xdotool key ctrl+shift+t && sudo openvpn /home/danilo/Downloads/release_arena_eu-release-1.ovpn'
    alias try='xdotool key ctrl+shift+t && sudo openvpn /home/danilo/Downloads/us-east-1-danc22-regular.ovpn'
    alias fetch='fastfetch --config groups'
    alias scripts='cd /home/danilo/Escritorio/scripts/ && ls'
    alias key="setxkbmap es"
    alias web='whatweb'  
    alias shell='rlwrap nc -lnvp 9092 '
    alias rust='rcat listen -ib 9092'
    alias ports='extractPorts allports'
    alias service='cat servicios.txt'
    alias s='xrandr --size 1920x1080 && xdotool key super+shift+r && setxkbmap us'
    alias zh='source /home/danilo/.zshrc'
    alias sh='n /home/danilo/.zshrc'
    alias dk='cd /home/danilo/Escritorio/ && ls -la'
    alias bin='cd /usr/bin/ && ls'
    alias tools='cd /home/danilo/Escritorio/tools/ && ls '
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias server='python3 -m http.server 80'
    alias apt='nala'
    alias deploy="auto_deploy.sh"
    alias bug="sudo python3 danilo/Escritorio/tools/bugbountylabs_entity.py"

    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip -c a' 
    alias list='htb-operator machine list --group-by-os'
    alias stop="htb-operator machine stop --stop-vpn && rm output.txt"
    alias reset="htb-operator machine reset"
    alias fetch='fastfetch --kitty-direct ~/.config/fastfetch/logo-small.png'
    alias vim="n"

# Mejoras de visualización de contenido
alias cat='batcat --theme=ansi --style=numbers,changes,header --pager=never'

# Personalización de comandos del sistema
alias neofetch='neofetch | lolcat'
alias rmh='rmk ~/.zsh_history'

alias s='sudo su'
alias ls='exa -1 --icons --tree --level 1'
alias la='exa -1 --icons --tree --level 1 -a'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Plugins
source ~/powerlevel10k/powerlevel10k.zsh-theme

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 
if [[ "${THEME}" != "default" ]]; then 
  source "$HOME/.config/zsh/themes/catppuccin_${THEME}-zsh-syntax-highlighting.zsh"
fi 
source /usr/share/zsh-sudo/sudo.plugin.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh


# Functions
mkt () {
	source Colors
	dir_name="$1" 
	if [[ ! -n "$dir_name" ]]
	then
		echo -e "\n${bg_bright_red}[ERROR]${end} ${bright_white}Se debe indicar un nombre de directorio: (Ex:${end} ${bright_yellow}$0${end} ${bright_white}<Dir_Name>)${end}\n\n"
		return 1
	fi
	if [[ -d "$dir_name" ]]
	then
		echo -e "\n${bg_bright_red}[ERROR]${end}${bright_white} Error fatal: El directorio $dir_name ya existe!!\n"
		return 1
	fi
	echo
	echo -e "${bright_green}[✔]${bright_white} Directorio ${bright_blue}'$1'${bright_white} creado con subdirectorios:"
	echo -e "    ${sky} nmap${end}"
	echo -e "    ${sky} content${end}"
	echo -e "    ${sky} exploits${end}"
	echo -e "    ${sky} scripts${end}"
	echo
	mkdir -p $dir_name/{nmap,content,scripts,exploits}
}


# Extract nmap information
function extractPorts(){
	ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
	ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
	echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
	echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
	echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
	echo $ports | tr -d '\n' | xclip -sel clip
	echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
	cat extractPorts.tmp; rm extractPorts.tmp
}

# Set 'man' colors
function man() {
    env \
    LESS_TERMCAP_mb=$'\e[01;31m' \
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    man "$@"
}

  # Función para configurar IP y URL
  function st(){
      ip_regex='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
      if [ $# -eq 1 ] && [[ $1 =~ $ip_regex ]]; then
          echo $1 > $HOME/.config/bin/target.txt  
      else
          echo "setTarget [IP]"
      fi
  }

function cleartarget(){
  echo '' > ~/.config/bin/target
}

function system () {
    bright_yellow="\u001b[0;93m"    bright_magenta="\u001b[0;95m"    bright_white="\u001b[0;97m"    end="\u001b[0m"

    ip_adress="$1"
    IFACE="$(ip addr show | awk '/inet .* brd/ {print $NF; exit}')"
    _ADRESS="$(ip addr show "${IFACE}" | awk '/inet / {print $2; exit}' | cut -d/ -f1)"}

    if [[ -z "$ip_adress" ]]; then
        echo -e "\n${bright_magenta}[+]${bright_white} Usage:${bright_yellow} whichSystem${bright_white} ${_ADRESS:-127.0.0.1}${end}\n\n"
        return 0
    fi

    ttl=$(/usr/bin/ping -c 1 "$ip_adress" | grep -oP "ttl=\K\d{1,3}")

    if [[ "$ttl" -ge 1 && "$ttl" -le 64 ]]; then
        system="Linux"
    elif [[ "$ttl" -ge 64 && "$ttl" -le 128 ]]; then
        system="Windows"
    else
        system="Not found"
    fi

    echo -e "\n${bright_yellow}[+]${bright_white} $ip_adress${bright_white} (${bright_magenta}${ttl:-None}${bright_white} ->${bright_yellow} $system${bright_white})${end}\n"
}

pyenv () {
	readonly virtual=".venv" 
	[[ -d "${virtual}" ]] && source "${virtual}"/bin/activate || python3 -m venv "${virtual}" && source "${virtual}"/bin/activate
	[[ ${#} -gt 0 && -n ${@} ]] && pip3 install ${@}
	return 0
}

# fzf improvement
function fzf-lovely(){

	if [ "$1" = "h" ]; then
		fzf -m --layout=reverse --height=40% --border --reverse --preview-window down:20 --preview "[[ \$(file --mime {}) =~ binary ]] &&
 	               echo {} is a binary file ||
                 (bat --style=numbers --color=always {} --theme=\"Catppuccin ${(C)THEME}\" ||
	                 highlight -O ansi -l {} ||
	                 coderay {} ||
	                 rougify {} ||
	                 cat {}) 2> /dev/null | head -1000"

	else
	       fzf --layout=reverse --height=40% --border -m --preview "[[ \$(file --mime {}) =~ binary ]] &&
	                        echo {} is a binary file ||
                          (bat --style=numbers --color=always {} --theme=\"Catppuccin ${(C)THEME}\" ||
	                         highlight -O ansi -l {} ||
	                         coderay {} ||
	                         rougify {} ||
	                         cat {}) 2> /dev/null | head -1000"
	fi
}

#alias fzf-lovely='FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border" fzf-lovely'
#alias fzf-lovely='FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}" fzf-lovely'

function rmk(){
	scrub -p dod $1
	shred -zun 10 -v $1
}

# Finalize Powerlevel10k instant prompt. Should stay at the bottom of ~/.zshrc.
(( ! ${+functions[p10k-instant-prompt-finalize]} )) || p10k-instant-prompt-finalize

export SUDO_PROMPT="$(tput setaf 3)[${USER}]$(tput setaf 15) Enter your password for root: $(tput sgr0)"
export LS_COLORS="rs=0:di=34:ln=36:mh=00:pi=40;33:so=35:do=35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;4
3:ca=00:tw=30;42:ow=34;42:st=37;44:ex=32:*.tar=31:*.tgz=31:*.arc=31:*.arj=31:*.taz=31:*.lha=31:*.lz4=31:*.lzh=31:*.lzma=
31:*.tlz=31:*.txz=31:*.tzo=31:*.t7z=31:*.zip=31:*.z=31:*.dz=31:*.gz=31:*.lrz=31:*.lz=31:*.lzo=31:*.xz=31:*.zst=31:*.tzst
=31:*.bz2=31:*.bz=31:*.tbz=31:*.tbz2=31:*.tz=31:*.deb=31:*.rpm=31:*.jar=31:*.war=31:*.ear=31:*.sar=31:*.rar=31:*.alz=31:*.ace=31:*.zoo=31:*.cpio=31:*.7z=31:*.rz=31:*.cab=31:*.wim=31:*.swm=31:*.dwm=31:*.esd=31:*.avif=35:*.jpg=35:*.jpeg=35:*.mjpg=35:*.mjpeg=35:*.gif=35:*.bmp=35:*.pbm=35:*.pgm=35:*.ppm=35:*.tga=35:*.xbm=35:*.xpm=35:*.tif=35:*.tiff=35:*.png=35:*.svg=35:*.svgz=35:*.mng=35:*.pcx=35:*.mov=35:*.mpg=35:*.mpeg=35:*.m2v=35:*.mkv=35:*.webm=35:*.webp=35:*.ogm=35:*.mp4=35:*.m4v=35:*.mp4v=35:*.vob=35:*.qt=35:*.nuv=35:*.wmv=35:*.asf=35:*.rm=35:*.rmvb=35:*.flc=35:*.avi=35:*.fli=35:*.flv=35:*.gl=35:*.dl=35:*.xcf=35:*.xwd=35:*.yuv=35:*.cgm=35:*.emf=35:*.ogv=35:*.ogx=35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90::ow=30;44:"
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
bindkey "\e[3~" delete-char
setxkbmap latam
export EDITOR='nvim'
# Esto lo que hace es que nunca creara directorios __pycache__ al hacer scripts de python que sabemos que es molesto.
# Si realmente quieres esos directorios, comenta esa linea y ya 
export PYTHONDONTWRITEBYTECODE=1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# FZF Tab Completion enabled 
autoload -U compinit; compinit

[[ -f ~/.fzf-tab/fzf-tab.plugin.zsh ]] && source ~/.fzf-tab/fzf-tab.plugin.zsh


  # ------------------------------- actualizar sistema completo --------------------------------------- #
  updateAndClean() {
    
      local -r RESET='\033[0m'
      local -r BOLD='\033[1m'
      local -r DIM='\033[2m'
      
      local -r KALI_GREEN='\033[1;32m'          # Verde brillante (prompt principal)
      local -r KALI_RED='\033[1;31m'            # Rojo brillante (errores)
      local -r KALI_BLUE='\033[1;34m'           # Azul brillante (información)
      local -r KALI_CYAN='\033[1;36m'           # Cian brillante (destacados)
      local -r KALI_YELLOW='\033[1;33m'         # Amarillo brillante (advertencias)
      local -r KALI_PURPLE='\033[1;35m'         # Magenta brillante (procesos)
      local -r KALI_WHITE='\033[0;37m'          # Blanco normal (sin bold)
      local -r KALI_GRAY='\033[38;2;94;92;100m'
      local -r KALI_DARK_GREEN='\033[0;32m'     # Verde oscuro (texto normal)
      local -r KALI_DARK_RED='\033[0;31m'       # Rojo oscuro
      local -r KALI_DARK_BLUE='\033[0;34m'      # Azul oscuro
      
      local -r SUDO_COLOR='\033[38;2;94;189;171m'    # #5EBDAB
      local -r COMMAND_COLOR='\033[38;2;73;174;230m'  # #49AEE6
      local -r PARAM_COLOR='\033[38;2;94;189;171m'    # #5EBDAB para parámetros con guiones
      local -r OPERATOR_COLOR='\033[1;38;2;39;127;255m' # #277FFF en negrita para &&
      
      local -r SUCCESS="[+]"
      local -r ERROR="[-]"
      local -r INFO="[*]"
      local -r WORKING=" ▶"
      
      local error_count=0
      local start_time=$(date +%s)
      local temp_log="/tmp/update_clean_$(date +%s).log"
      
      cleanup_temp_files() {
          [[ -f "$temp_log" ]] && rm -f "$temp_log"
      }
      trap cleanup_temp_files EXIT
      
      colorear_comando() {
          local comando="$1"
          local colored_cmd=""
          
          local -a palabras
          palabras=(${=comando})
          
          for i in {1..${#palabras[@]}}; do
              local palabra="${palabras[$i]}"
              
              if [[ "$palabra" == "sudo" ]]; then
                  colored_cmd+="${SUDO_COLOR}${palabra}${RESET}"
              elif [[ "$palabra" == "&&" ]]; then
                  colored_cmd+="${OPERATOR_COLOR}${palabra}${RESET}"
              elif [[ "$palabra" =~ "^(apt|apt-get|aptitude|dpkg|updatedb)$" ]]; then
                  colored_cmd+="${COMMAND_COLOR}${palabra}${RESET}"
              elif [[ "$palabra" =~ "^--?[a-zA-Z-]+$" ]]; then
                  
                  colored_cmd+="${PARAM_COLOR}${palabra}${RESET}"
              else
                colored_cmd+="${KALI_WHITE}${palabra}${RESET}"
              fi
              
              if [[ $i -lt ${#palabras[@]} ]]; then
                  colored_cmd+=" "
              fi
          done
          
          echo -e "$colored_cmd"
      }
      
      sistem() {
          if ! command -v apt-get &> /dev/null; then
              echo -e "\n${KALI_RED}${ERROR}${RESET} ${KALI_RED}${BOLD}Este script requiere apt-get (Debian/Ubuntu)${RESET}"
              return 1
          fi
          
          if ! ping -c 1 8.8.8.8 &> /dev/null; then
              echo -e "\n${KALI_RED}${ERROR}${RESET} ${KALI_RED}${BOLD}Sin conexión a internet${RESET}"
              return 1
          fi
          
          return 0
      }
      
      mostrar_encabezado() {
          local titulo="$1"
          
          echo -e "${KALI_GREEN}${BOLD}▌${KALI_WHITE} ${titulo}${KALI_GREEN}${RESET}\n"
      }
      
      ejecutar_comando() {
          local comando="$1"
          local descripcion="$2"
          local paso="$3"
          local es_critico="${4:-false}"
          
          echo -e "${KALI_CYAN}${paso}${RESET} ${KALI_WHITE}${BOLD}${descripcion}${RESET}"
          echo -e "${KALI_GREEN}${WORKING}${RESET} ${KALI_WHITE}Ejecutando: $(colorear_comando "$comando")\n"
          
          local cmd_pid
          local exit_code
          
          if timeout 300 bash -c "$comando" 2>&1 | tee "$temp_log" | while IFS= read -r linea; do
              [[ -z "$linea" ]] && continue
              
              if [[ "$linea" =~ ^(Reading|Leyendo|Building|Construyendo|Calculating|Preparing) ]]; then
                  echo -e "   ${KALI_BLUE}▶${RESET} ${KALI_WHITE}${linea}${RESET}"
              elif [[ "$linea" =~ ^(Get:|Obj:|Hit:|Des:|Ign:|Fetched) ]]; then
                  echo -e "   ${KALI_DARK_GREEN}↓${RESET} ${KALI_WHITE}${linea}${RESET}"
              elif [[ "$linea" =~ ^(Setting|Configurando|Processing|Procesando|Configuring) ]]; then
                  echo -e "   ${KALI_PURPLE}⚙${RESET} ${KALI_GRAY}${linea}${RESET}"
              elif [[ "$linea" =~ ^(Removing|Eliminando|Purging|Purgando) ]]; then
                  echo -e "   ${KALI_RED}✗${RESET} ${KALI_WHITE}${linea}${RESET}"
              elif [[ "$linea" =~ ^(Installing|Instalando|Upgrading|Actualizando|Unpacking) ]]; then
                  echo -e "   ${KALI_GREEN}+${RESET} ${KALI_GRAY}${linea}${RESET}"
              elif [[ "$linea" =~ (upgraded|actualizados|installed|instalados|removed|eliminados|Summary:|newly installed) ]]; then
                  echo -e "   ${KALI_GREEN}✓${RESET} ${KALI_WHITE}${linea}${RESET}"
              elif [[ "$linea" =~ ^(WARNING:|W:|Warning|ADVERTENCIA|Warnings) ]]; then
                  echo -e "   ${KALI_YELLOW}!${RESET} ${KALI_WHITE}${linea}${RESET}"
              elif [[ "$linea" =~ ^(E:|Error|ERROR|Failed|failed) ]]; then
                  echo -e "   ${KALI_RED}!!${RESET} ${KALI_WHITE}${BOLD}${linea}${RESET}"
              elif [[ "$linea" =~ (up to date|All packages are up to date|Nothing to do) ]]; then
                  echo -e "   ${KALI_GREEN}✓${RESET} ${KALI_WHITE}${linea}${RESET}"
              elif [[ "$linea" =~ ^(Need to get|Se necesita descargar) ]]; then
                  echo -e "   ${KALI_CYAN}📦${RESET} ${KALI_WHITE}${linea}${RESET}"
              else
                  echo -e "   ${KALI_GRAY}${linea}${RESET}"
              fi
          done; then
              exit_code=$?
              
              if [[ $exit_code -eq 0 ]] && ! grep -q "^E:" "$temp_log"; then
                  echo -e "\n${KALI_GREEN}${SUCCESS}${RESET} ${KALI_WHITE}${descripcion} - ${KALI_GREEN}✓ COMPLETADO${RESET}"
              else
                  echo -e "\n${KALI_RED}${ERROR}${RESET} ${KALI_WHITE}${descripcion} - ${KALI_RED}FALLÓ${RESET}"
                  ((error_count++))
                  
                  if [[ "$es_critico" == "true" ]]; then
                      echo -e "${KALI_RED}${ERROR}${RESET} ${KALI_WHITE}Error crítico detectado${RESET}"
                      return 1
                  fi
              fi
          else
              echo -e "\n${KALI_RED}${ERROR}${RESET} ${KALI_WHITE}${descripcion} - ${KALI_RED}TIMEOUT O ERROR${RESET}"
              ((error_count++))
              if [[ "$es_critico" == "true" ]]; then
                  return 1
              fi
          fi
          
          echo -e "${KALI_DARK_BLUE}$(printf '─%.0s' {1..76})${RESET}\n"
      }
      
      clear
      if ! sistem; then
          return 1
      fi
      
      echo -e "${KALI_BLUE}${INFO}${RESET} ${KALI_WHITE}Verificación de privilegios de administrador${RESET}"
      echo -e "${KALI_GRAY}Se requiere acceso sudo para continuar con las operaciones${RESET}"
      
      if ! sudo -v; then
          echo -e "\n${KALI_RED}${ERROR}${RESET} ${KALI_RED}${BOLD}Autenticación fallida. Acceso denegado.${RESET}"
          return 1
      fi
      
      echo -e "${KALI_GREEN}${SUCCESS}${RESET} ${KALI_WHITE}Privilegios verificados correctamente${RESET}"
      sleep 1

      clear

      mostrar_encabezado "SISTEMA DE ACTUALIZACIÓN AUTOMÁTICA"

      echo -e "${KALI_BLUE}${INFO}${RESET} ${KALI_WHITE}Verificando actualizaciones disponibles...${RESET}"
      
      ejecutar_comando \
          "sudo apt-get update" \
          "Sincronizando repositorios de paquetes" \
          "[1/8]" \
          "true"
      
      local updates_available=$(apt list --upgradable 2>/dev/null | wc -l)
      if [[ $updates_available -le 1 ]]; then
          echo -e "${KALI_GREEN}${SUCCESS}${RESET} ${KALI_WHITE}No hay actualizaciones disponibles${RESET}"
      else
          echo -e "${KALI_BLUE}${INFO}${RESET} ${KALI_WHITE}Se encontraron $((updates_available-1)) actualizaciones disponibles${RESET}"
      fi
      
      ejecutar_comando \
          "sudo apt-get upgrade -y" \
          "Instalando actualizaciones disponibles" \
          "[2/8]"
      
      ejecutar_comando \
          "sudo apt-get dist-upgrade -y" \
          "Aplicando actualizaciones críticas del sistema" \
          "[3/8]"
      
      ejecutar_comando \
          "sudo apt-get autoremove --purge -y" \
          "Eliminando dependencias obsoletas" \
          "[4/8]"
      
      ejecutar_comando \
          "sudo apt-get autoclean" \
          "Limpiando archivos temporales parciales" \
          "[5/8]"
      
      ejecutar_comando \
          "sudo apt-get clean" \
          "Limpiando completamente caché de paquetes" \
          "[6/8]"
      
      if command -v updatedb &> /dev/null; then
          ejecutar_comando \
              "sudo updatedb" \
              "Reconstruyendo índice de archivos del sistema" \
              "[7/8]"
      else
          echo -e "${KALI_YELLOW}${INFO}${RESET} ${KALI_WHITE}updatedb no disponible, omitiendo paso [7/8]${RESET}\n"
      fi
      
      ejecutar_comando \
          "sudo apt-get check && sudo apt-get -f install -y" \
          "Verificando y reparando dependencias del sistema" \
          "[8/8]"
      
      return $error_count
  }

  # ------------------------------------- plugins ---------------------------------- #
  source /usr/share/sudo-plugin/sudo.plugin.zsh



  function fa (){
    if [ -n "$1" ]; then 
      ftp -a $1 
    else 
      echo "fa [ip]" 
    fi 
  }

  function ct(){
      echo '' > $HOME/.config/bin/target.txt
  }


  function start(){
  if [ -n "$1" ]; then 
    htb-operator machine start --id $1 --start-vpn >> output.txt &&
    sed -i -E '/Machine ".*": Waiting... IP is being assigned/d' output.txt &&
    sed -n 's/.*IP.*: \([0-9.]*\).*/\1/p' output.txt >> /home/danilo/.config/bin/target.txt
  else 
    echo "start [id]"
  fi 
  }

  function info(){
    if [ -n "$1" ]; then
      htb-operator machine info --id $1 
    else 
      echo "info [id]"
    fi
  }

  function flag () {
    if [[ -z "$1" || -z "$2" ]]; then
      htb-operator machine submit --user-flag $1 &&
      htb-operator machine submit --root-flag $2 
    else 
      echo "flag [user-flag] [root-flag]"
    fi
  }


  function dl(){
    if [ -n "$1" ]; then  
      cd $HOME/Escritorio/docker/"$1" && ls 
    else
      echo "dl [FOLDER]"
    fi 
  }

  function lab(){
    if [ -n "$1" ]; then  
      cd $HOME/Escritorio/lab/"$1" && ls 
    else
      echo "lab [FOLDER]"
    fi 
  }

  function htb(){
    if [ -n "$1" ]; then  
      cd $HOME/Escritorio/htb/"$1" && ls 
    else
      echo "htb [FOLDER]"
    fi 
  }

  function bbl(){
    if [ -n "$1" ]; then  
      cd $HOME/Escritorio/bbl/"$1" && ls 
    else
      echo "bbl [FOLDER]"
    fi 
  }


