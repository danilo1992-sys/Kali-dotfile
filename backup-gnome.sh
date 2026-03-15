#!/bin/bash

BACKUP_DIR="$HOME/gnome-backup"
DATE=$(date +%Y%m%d)

backup() {
  mkdir -p "$BACKUP_DIR"

  echo "Exportando configuraciones de GNOME..."
  dconf dump / >"$BACKUP_DIR/gnome-settings-$DATE.ini"

  echo "Exportando extensiones..."
  mkdir -p "$BACKUP_DIR/extensions"
  cp -r ~/.local/share/gnome-shell/extensions/* "$BACKUP_DIR/extensions/" 2>/dev/null

  echo "Exportando lista de extensiones instaladas..."
  gnome-extensions list >"$BACKUP_DIR/extensions-list-$DATE.txt"

  echo "Completado! Backup guardado en: $BACKUP_DIR"
  ls -la "$BACKUP_DIR"
}

restart_gnome() {
  echo "Reiniciando GNOME Shell..."
  sleep 1

  if command -v systemctl &>/dev/null; then
    systemctl --user restart gnome-shell 2>/dev/null || true
  fi

  killall -3 gnome-shell 2>/dev/null || true
  sleep 2

  echo "Listo! GNOME se ha reiniciado."
}

restore() {
  echo "Listando backups disponibles:"
  ls -1 "$BACKUP_DIR"/*.ini 2>/dev/null

  echo ""
  read -p "Ingresa el nombre del archivo de configuracion (ej: gnome-settings-20260314.ini): " CONFIG_FILE

  if [ -f "$BACKUP_DIR/$CONFIG_FILE" ]; then
    echo "Restaurando configuraciones..."
    dconf load / <"$BACKUP_DIR/$CONFIG_FILE"
    echo "Restaurando extensiones..."
    cp -r "$BACKUP_DIR/extensions/"* ~/.local/share/gnome-shell/extensions/ 2>/dev/null

    restart_gnome
  else
    echo "Archivo no encontrado!"
  fi
}

case "$1" in
backup)
  backup
  ;;
restore)
  restore
  ;;
install)
  install_gnome_extensions
  ;;
*)
  echo "Uso: $0 {backup|restore|install}"
  exit 1
  ;;
esac

install_gnome_extensions() {
  echo "Instalando gnome-shell-extensions..."

  if command -v apt-get &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y gnome-shell-extensions
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y gnome-shell-extensions
  elif command -v pacman &>/dev/null; then
    sudo pacman -S gnome-shell-extensions
  else
    echo "Gestor de paquetes no soportado"
    return 1
  fi

  echo "Instalacion completada."
}
