# mango-config

MangoWC 0.16.x + DankMaterialShell 1.6 config (fury)

## Layout
- mango/ -> ~/.config/mango/
- dms/settings.json + plugins.lock.json + amoledBlack/ -> ~/.config/DankMaterialShell/
- mango-session.target -> ~/.config/systemd/user/

## Restore
```bash
cp -r mango ~/.config/
cp dms/settings.json dms/plugins.lock.json ~/.config/DankMaterialShell/
cp -r dms/amoledBlack ~/.config/DankMaterialShell/themes/
cp mango-session.target ~/.config/systemd/user/
chmod +x ~/.config/mango/*.sh
mango -p -c ~/.config/mango/config.conf
systemctl --user daemon-reload
```
See mango-dms-nixos-guide.md for full NixOS system part.
