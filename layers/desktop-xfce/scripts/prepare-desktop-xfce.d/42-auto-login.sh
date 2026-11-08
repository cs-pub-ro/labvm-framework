#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Configure `lightdm` desktop manager for autologin

LIGHTDM_CONFIG="/etc/lightdm/lightdm.conf"

if [[ -f "$LIGHTDM_CONFIG" && ! -d "${LIGHTDM_CONFIG}.d" ]]; then
    # Ensure the [Seat:*] section exists
    if ! grep -q "^\[Seat:\*\]" "$LIGHTDM_CONFIG"; then
        echo "[Seat:*]" >> "$LIGHTDM_CONFIG"
    fi
    sed -i "/^\[Seat:\*\]/,/^\[/ s/^#*\s*autologin-user=.*/autologin-user=$VM_USER/g" "$LIGHTDM_CONFIG"
    # Ensure autologin-session is set
    if ! grep -q "^autologin-session=" "$LIGHTDM_CONFIG"; then
        sed -i "/^\[Seat:\*\]/a autologin-session=xfce" "$LIGHTDM_CONFIG"
    fi
else
    # create new file in 
    mkdir -p "$(dirname "$LIGHTDM_CONFIG")"
    cat > "${LIGHTDM_CONFIG}.d/20-autologin.conf" << EOF
[Seat:*]
autologin-user=$VM_USER
autologin-session=xfce
EOF
fi

systemctl daemon-reload
systemctl restart display-manager.service

