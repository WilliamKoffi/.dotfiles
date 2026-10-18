#!/bin/bash

# Liste des services à désactiver (différence entre les deux listes)
SERVICES_TO_DISABLE=(
    "avahi-daemon.service"
    "bluetooth.service"
    "console-setup.service"
    "cups-browsed.service"
    "cups.service"
    "ModemManager.service"
    "switcheroo-control.service"
    "udisks2.service"
)

# Fonction pour désactiver un service
disable_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo "Arrêt et désactivation de $service"
        sudo systemctl stop "$service"
        sudo systemctl disable "$service"
        sudo systemctl mask "$service"  # Empêche toute réactivation accidentelle
    else
        echo "$service n'est pas actif, désactivation seule"
        sudo systemctl disable "$service"
        sudo systemctl mask "$service"
    fi
}

# Désactiver chaque service
for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        disable_service "$service"
    else
        echo "Service $service non trouvé - ignoré"
    fi
done

echo "Opération terminée. Services désactivés:"
for service in "${SERVICES_TO_DISABLE[@]}"; do
    status=$(systemctl is-enabled "$service" 2>/dev/null || echo "missing")
    echo "- $service: $status"
done