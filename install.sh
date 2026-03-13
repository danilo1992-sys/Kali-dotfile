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
		sudo rm -rf /tmp/ImageMagick* &>"${LOGS}"

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

install_sxhkd() {
	SECONDS=0
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

	set_time "${SECONDS}" "Sxhkd instalado de forma correcta"

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

welcome
system_update
brew
bspwm
install_git
