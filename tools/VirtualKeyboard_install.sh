#!/bin/sh

[ "$(id -un)" = "root" ] || { printf "Error : Please run this script through sudo...\n" >&2; exit 1; }

apt update && apt install matchbox-keyboard || exit 2

cat > /usr/bin/toggle-matchbox-keyboard.sh << EOF
#!/bin/bash
#This script toggle the virtual keyboard
PID=$(pidof matchbox-keyboard)
if [ ! -e ${PID} ]; then
  killall matchbox-keyboard
else
  matchbox-keyboard -s 50 extended &
fi
EOF
[ $? -eq 0 ] || exit 3
chmod +x /usr/bin/toggle-matchbox-keyboard.sh || exit 3

[ -d "/usr/local/share/applications" ] || install -m 755 -oroot -groot /usr/local/share/applications || exit 4
cat > /usr/local/share/applications/toggle-matchbox-keyboard.desktop << EOF
[Desktop Entry]
Name=Toggle Matchbox Keyboard
Comment=Toggle Matchbox Keyboard`
Exec=toggle-matchbox-keyboard.sh
Type=Application
Icon=matchbox-keyboard.png
Categories=Panel;Utility;MB
X-MB-INPUT-MECHANSIM=True
EOF
[ $? -eq 0 ] || exit 4



printf "You should now reboot! :)\n"
