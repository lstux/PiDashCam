#!/bin/sh
DESKTOP_ENTRY="/usr/local/share/applications/toggle-matchbox-keyboard.desktop"
PLACE_BEFORE="lxde-x-www-browser.desktop"

[ "$(id -un)" = "root" ] || { printf "Error : Please run this script through sudo...\n" >&2; exit 1; }

if ! which matchbox-keyboard >/dev/null 2>&1; then
  apt update && apt install matchbox-keyboard || exit 2
fi

cat > /usr/bin/toggle-matchbox-keyboard.sh << EOF
#!/bin/bash
#This script toggle the virtual keyboard
PID=\$(pidof matchbox-keyboard)
if kill -0 \${PID} 2>/dev/null; then
  killall matchbox-keyboard
else
  matchbox-keyboard extended &
fi
EOF
[ $? -eq 0 ] || exit 3
chmod +x /usr/bin/toggle-matchbox-keyboard.sh || exit 3

[ -d "$(dirname "${DESKTOP_ENTRY}")" ] || install -d -m 755 -oroot -groot "$(dirname "${DESKTOP_ENTRY}")" || exit 4
cat > "${DESKTOP_ENTRY}" << EOF
[Desktop Entry]
Name=Toggle Matchbox Keyboard
Comment=Toggle Matchbox Keyboard
Exec=toggle-matchbox-keyboard.sh
Type=Application
Icon=matchbox-keyboard.png
Categories=Panel;Utility;MB
X-MB-INPUT-MECHANISM=True
EOF
[ $? -eq 0 ] || exit 4

#Add desktop entry in ~/.config/lxpanel/LXDE-pi/panels/panel
#
#Plugin {
#  type = launchbar
#  Config {
#+   Button {
#+     id=/usr/local/share/applications/toggle-matchbox-keyboard.desktop
#+   }
#    Button {
#      ...
#    }
#    ...
#  }
grep -q "${DESKTOP_ENTRY}" /home/pi/.config/lxpanel/LXDE-pi/panels/panel || \
  sed -i "s@^\(\s\+id=\)\(${PLACE_BEFORE}\)@\1${DESKTOP_ENTRY}\n    }\n    Button {\n      id=\2@" /home/pi/.config/lxpanel/LXDE-pi/panels/panel

printf "You should now reboot! :)\n"
