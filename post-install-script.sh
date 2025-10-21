#!/usr/bin/env bash
set -euo pipefail

# === utilitaires ===
log(){ printf "\n[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }
run(){ log "$*"; eval "$@"; }

# === étapes ===
step_00_network(){
  log "Connexion Wi-Fi"
  read -rp "SSID Wi-Fi : " ssid
  read -rsp "Mot de passe Wi-Fi : " password
  echo
  run "nmcli device wifi connect \"${ssid}\" password \"${password}\""
  if ping -c1 archlinux.org &>/dev/null; then
    log "Connexion OK"
  else
    log "Échec de connexion"
    exit 1
  fi
}

step_01_architect(){
  log "Installation et exécution du script Architect"
  run "sudo pacman -S --needed git base-devel"
  run "git clone https://github.com/Cardiacman13/Architect.git ~/Architect"
  run "cd ~/Architect && chmod +x ./architect.sh && ./architect.sh"
}

step_02_illogical_impulse(){
  log "Installation d'Illogical Impulse"
  if ! command -v curl &>/dev/null; then
    run "sudo pacman -S --needed --noconfirm curl"
  fi
  run "bash <(curl -s https://ii.clsty.link/setup) ~/Documents/illogical-impulse"
}

step_03_remove_vim(){
  log "Suppression de VIM"
  run "sudo pacman -Rns --noconfirm vim || true"
}

step_04_cleanup(){
  log "Nettoyage du dossier ~/Architect"
  run "rm -rf ~/Architect || true"
}

# === exécution principale ===
main(){
  step_00_network
  step_01_architect
  step_02_illogical_impulse
  step_03_remove_vim
  step_04_cleanup
  log "Installation terminée."
}

main "$@"
