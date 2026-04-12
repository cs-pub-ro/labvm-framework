#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Install XFCE packages

XFCE4_PACKAGES=(
    xfwm4 xfce4-session xfwm4-theme-breeze
    xfdesktop4 # xfce desktop background, icons and root menu manager
    xfce4-panel # panel for Xfce4 desktop environment
    xfce4-settings # graphical application for managing Xfce settings
    xfconf # utilities for managing settings
    xfce4-notifyd # notification daemon for Xfce 
    thunar # file manager
    mousepad # text editor
    ristretto # picture viewer
    xfce4-screenshooter # screenshots utility for Xfce
    xfce4-terminal # Xfce terminal emulator
    xfce4-appfinder # Application finder for the Xfce4 Desktop Environment
    xfce4-clipman # clipboard history utility
    xfce4-whiskermenu-plugin # alternate menu plugin
    xfce4-indicator-plugin
    xfce4-clipman-plugin # clipboard history plugin
    xfce4-datetime-plugin # date and time plugin
)

pkg_install --no-install-recommends "${XFCE4_PACKAGES[@]}"

# we also need a browser
pkg_install firefox-esr

# install lightdm session manager
pkg_install lightdm

