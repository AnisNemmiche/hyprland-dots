#!/usr/bin/env bash
set -euo pipefail

log(){ printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

need_pkg(){
  local pkg="$1"
  if ! pacman -Qi "$pkg" &>/dev/null; then
    log "Installe $pkg"
    sudo pacman -S --needed --noconfirm "$pkg"
  fi
}

grub_cfg_path(){
  if [[ -d /sys/firmware/efi && -d /boot/efi/EFI/arch ]]; then
    echo "/boot/efi/EFI/arch/grub.cfg"
  else
    echo "/boot/grub/grub.cfg"
  fi
}

ensure_kv(){
  # ensure_kv FILE KEY VALUE -> set KEY=VALUE (add or replace)
  local file="$1" key="$2" val="$3"
  if grep -qE "^${key}=" "$file"; then
    sudo sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  else
    echo "${key}=${val}" | sudo tee -a "$file" >/dev/null
  fi
}

main(){
  log "Vérif paquets"
  need_pkg grub
  need_pkg grub-btrfs

  log "Backup /etc/default/grub"
  sudo cp -n /etc/default/grub /etc/default/grub.bak

  log "Timeout GRUB à 0"
  ensure_kv /etc/default/grub GRUB_TIMEOUT 0
  # Optionnel: masquer le menu tout en restant accessible via Shift/Esc
  ensure_kv /etc/default/grub GRUB_TIMEOUT_STYLE hidden

  log "Sous-menus activés"
  # garde la ligne commentée si absente, sinon force y
  if grep -q '^#\?GRUB_DISABLE_SUBMENU=' /etc/default/grub; then
    sudo sed -i 's/^#\?GRUB_DISABLE_SUBMENU=.*/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub
  else
    echo "GRUB_DISABLE_SUBMENU=y" | sudo tee -a /etc/default/grub >/dev/null
  fi

  log "Service grub-btrfsd actif"
  sudo systemctl enable --now grub-btrfsd.service

  log "Regénération grub.cfg"
  out="$(grub_cfg_path)"
  sudo grub-mkconfig -o "$out"

  log "Terminé. Fichier généré: $out"
  log "Astuce: maintiens Shift/Esc au boot pour afficher le menu."
}

main "$@"
