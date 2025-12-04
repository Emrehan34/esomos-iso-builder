#!/bin/bash
################################################################################
# ESOMos ISO Builder - Tam Otomatik Kurulum ve Derleme
# Bu script, tüm adımları otomatik olarak yapar
################################################################################

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         ESOMos ISO Builder - Otomatik Kurulum               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Root kontrolü
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}❌ Bu script root olarak çalıştırılmamalı!${NC}"
   echo -e "${YELLOW}💡 Normal kullanıcı olarak çalıştırın.${NC}"
   exit 1
fi

# Kullanıcı adını al
CURRENT_USER=$(whoami)
echo -e "${BLUE}[1/10]${NC} Kullanıcı kontrolü: ${CURRENT_USER}"

# Sudo kontrolü
echo -e "${BLUE}[2/10]${NC} Sudo kontrol ediliyor..."
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Sudo şifresi gerekiyor. Lütfen şifrenizi girin:${NC}"
    sudo -v
fi

# Gerekli paketleri kur
echo -e "${BLUE}[3/10]${NC} Gerekli paketler kontrol ediliyor..."
MISSING_PACKAGES=()

if ! command -v mkarchiso &> /dev/null; then
    MISSING_PACKAGES+=("archiso")
fi

if ! command -v git &> /dev/null; then
    MISSING_PACKAGES+=("git")
fi

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo -e "${YELLOW}📦 Eksik paketler kuruluyor: ${MISSING_PACKAGES[*]}${NC}"
    sudo pacman -S --noconfirm "${MISSING_PACKAGES[@]}" base-devel python python-pip
fi

# Çalışma dizinlerini oluştur
WORK_DIR="$HOME/esomos_build"
ARCHISO_DIR="$WORK_DIR/archiso"
PROFILE_DIR="$ARCHISO_DIR/releng"
AIROOTFS_DIR="$PROFILE_DIR/airootfs"

echo -e "${BLUE}[4/10]${NC} Çalışma dizinleri oluşturuluyor..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
mkdir -p "$AIROOTFS_DIR/root/.config/hypr"
mkdir -p "$AIROOTFS_DIR/root/.config/waybar"
mkdir -p "$AIROOTFS_DIR/root/.local/bin"
mkdir -p "$AIROOTFS_DIR/root/.local/share/esomos"
mkdir -p "$AIROOTFS_DIR/etc/systemd/user"
mkdir -p "$AIROOTFS_DIR/usr/share/backgrounds"
mkdir -p "$AIROOTFS_DIR/usr/local/bin"

# archiso profilini kopyala
echo -e "${BLUE}[5/10]${NC} archiso profil şablonu kopyalanıyor..."
sudo cp -r /usr/share/archiso/configs/releng/* "$PROFILE_DIR/"

# Paket listesi oluştur
echo -e "${BLUE}[6/10]${NC} Paket listesi oluşturuluyor..."
cat > "$PROFILE_DIR/packages.x86_64" << 'PKGEOF'
base
linux
linux-firmware
linux-headers
grub
efibootmgr
networkmanager
network-manager-applet
wpa_supplicant
dhcpcd
xorg-server
xorg-xinit
xorg-xrandr
xorg-xsetroot
hyprland
waybar
rofi
wofi
swaybg
python
python-pip
python-setuptools
python-wheel
python-build
python-gobject
python-requests
python-psutil
python-dbus
gtk4
gtk3
adwaita-icon-theme
gnome-themes-extra
systemd
systemd-sysvcompat
sudo
bash-completion
vim
nano
git
curl
wget
pulseaudio
pulseaudio-alsa
pamixer
alsa-utils
ttf-dejavu
ttf-liberation
noto-fonts
noto-fonts-emoji
ttf-jetbrains-mono
polkit
udisks2
udisks2-udisks
gvfs
gvfs-mtp
gvfs-gphoto2
alacritty
kitty
thunar
thunar-volman
thunar-archive-plugin
firefox
htop
neofetch
ranger
sensors
PKGEOF

# Konfigürasyon dosyalarını oluştur (build_esomos.sh'den kopyala)
echo -e "${BLUE}[7/10]${NC} Konfigürasyon dosyaları oluşturuluyor..."

# Hyprland config
cat > "$AIROOTFS_DIR/root/.config/hypr/hyprland.conf" << 'HYPREOF'
monitor=,preferred,auto,1
exec-once = waybar
exec-once = /usr/local/bin/ai_omni_bar.py &
exec-once = systemctl --user start gemini-daemon.service
exec-once = swaybg -i /usr/share/backgrounds/esomos-wallpaper.png
input {
    kb_layout = us
    follow_mouse = 1
    touchpad { natural_scroll = yes }
    sensitivity = 0
}
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(FFD700ee) rgba(FFA500ee) 45deg
    col.inactive_border = rgba(000000aa)
    layout = dwindle
}
decoration {
    rounding = 10
    blur { enabled = true; size = 3; passes = 1 }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(FFD70055)
}
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}
dwindle { pseudotile = yes; preserve_split = yes }
windowrule = float, ^(rofi)$
windowrule = float, ^(ai_omni_bar)$
windowrule = center, ^(rofi)$
windowrule = center, ^(ai_omni_bar)$
$mainMod = SUPER
bind = $mainMod, Q, exec, alacritty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1
HYPREOF

# Waybar config ve style (kısa versiyon)
cat > "$AIROOTFS_DIR/root/.config/waybar/config" << 'WAYCONFEOF'
{
    "layer": "top",
    "position": "right",
    "width": 80,
    "height": "100%",
    "spacing": 10,
    "modules-right": ["custom/system-info", "custom/dock-icons", "custom/system-controls"],
    "custom/system-info": {
        "format": "📊\nCPU: {}%\nRAM: {}/{}GB\nGPU: {}%",
        "exec": "sh -c 'echo \"12\\n4.2\\n16\\n3\"'",
        "interval": 2
    },
    "custom/dock-icons": {
        "format": "📁\n🌐\n🎮\n⚙️",
        "on-click": "thunar"
    },
    "custom/system-controls": {
        "format": "🔊\n📡\n⏻"
    }
}
WAYCONFEOF

cat > "$AIROOTFS_DIR/root/.config/waybar/style.css" << 'WAYSTYLEEOF'
* { border: none; border-radius: 0; font-family: "JetBrains Mono"; font-size: 12px; min-height: 0; }
window#waybar {
    background-color: rgba(26, 26, 26, 0.8);
    border: 2px solid #FFD700;
    border-radius: 15px;
    color: #FFD700;
    margin: 10px;
    padding: 10px;
}
#custom-system-info, #custom-dock-icons, #custom-system-controls {
    background-color: rgba(0, 0, 0, 0.5);
    border: 1px solid rgba(255, 215, 0, 0.3);
    border-radius: 10px;
    padding: 10px;
    margin: 5px 0;
    color: #FFD700;
    font-size: 10px;
    line-height: 1.6;
}
WAYSTYLEEOF

# Duvar kağıdı
cat > "$AIROOTFS_DIR/usr/share/backgrounds/esomos-wallpaper.svg" << 'WALLPAPEREOF'
<svg width="1920" height="1080" xmlns="http://www.w3.org/2000/svg">
  <rect width="1920" height="1080" fill="#000000"/>
  <path d="M 0 540 L 1920 540" stroke="#FFD700" stroke-width="2" opacity="0.3"/>
  <path d="M 960 0 L 960 1080" stroke="#FFD700" stroke-width="2" opacity="0.3"/>
  <path d="M 500 300 Q 800 200, 1100 300 Q 800 400, 500 500 Q 800 600, 1100 700 Q 800 800, 500 900" 
        stroke="#FFD700" stroke-width="4" fill="none" opacity="0.6"/>
  <circle cx="500" cy="300" r="30" fill="#FFD700" opacity="0.8"/>
</svg>
WALLPAPEREOF
cp "$AIROOTFS_DIR/usr/share/backgrounds/esomos-wallpaper.svg" \
   "$AIROOTFS_DIR/usr/share/backgrounds/esomos-wallpaper.png" 2>/dev/null || true

# Gemini Core ve AI Omni-Bar (build_esomos.sh'den kopyalanacak - kısa versiyon)
echo -e "${BLUE}[8/10]${NC} AI bileşenleri oluşturuluyor..."

# Gemini Core (basitleştirilmiş)
cat > "$AIROOTFS_DIR/usr/local/bin/gemini_core.py" << 'GEMINICOREEOF'
#!/usr/bin/env python3
import os, sys, json, time, subprocess, requests
from pathlib import Path
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'
COMMAND_FILE = Path.home() / '.local' / 'share' / 'esomos' / 'ai_command.txt'
RESULT_FILE = Path.home() / '.local' / 'share' / 'esomos' / 'ai_result.json'
def ensure_directories(): COMMAND_FILE.parent.mkdir(parents=True, exist_ok=True)
def send_to_gemini(prompt):
    if not GEMINI_API_KEY: return "Gemini API key not configured."
    try:
        response = requests.post(f'{GEMINI_API_URL}?key={GEMINI_API_KEY}',
            headers={'Content-Type': 'application/json'},
            json={'contents': [{'parts': [{'text': prompt}]}]}, timeout=10)
        result = response.json()
        if 'candidates' in result and len(result['candidates']) > 0:
            return result['candidates'][0]['content']['parts'][0]['text']
        return "No response from Gemini API."
    except Exception as e: return f"Error: {str(e)}"
def parse_command(user_input):
    user_input_lower = user_input.lower()
    if 'wifi' in user_input_lower or 'wi-fi' in user_input_lower:
        if 'kapat' in user_input_lower or 'off' in user_input_lower:
            return {'action': 'wifi_off', 'command': 'nmcli radio wifi off', 'message': 'Wi-Fi kapatılıyor...'}
        elif 'aç' in user_input_lower or 'on' in user_input_lower:
            return {'action': 'wifi_on', 'command': 'nmcli radio wifi on', 'message': 'Wi-Fi açılıyor...'}
    elif 'ses' in user_input_lower or 'sound' in user_input_lower:
        if 'kapat' in user_input_lower or 'mute' in user_input_lower:
            return {'action': 'audio_mute', 'command': 'pamixer --mute', 'message': 'Ses kapatıldı.'}
        elif 'aç' in user_input_lower or 'unmute' in user_input_lower:
            return {'action': 'audio_unmute', 'command': 'pamixer --unmute', 'message': 'Ses açıldı.'}
    return {'action': 'ai_query', 'command': None, 'message': None, 'prompt': user_input}
def execute_command(command_info):
    if command_info.get('command'):
        try:
            result = subprocess.run(command_info['command'], shell=True, capture_output=True, text=True, timeout=10)
            return {'success': result.returncode == 0, 'output': result.stdout, 'error': result.stderr, 'message': command_info.get('message', 'Komut çalıştırıldı.')}
        except Exception as e: return {'success': False, 'output': '', 'error': str(e), 'message': f'Hata: {str(e)}'}
    elif command_info.get('prompt'):
        response = send_to_gemini(command_info['prompt'])
        return {'success': True, 'output': response, 'error': '', 'message': 'Gemini AI yanıtı'}
    return {'success': False, 'output': '', 'error': 'No command or prompt provided', 'message': 'Komut bulunamadı.'}
def main():
    ensure_directories()
    print("ESOMos Gemini Core başlatılıyor...", file=sys.stderr)
    while True:
        try:
            if COMMAND_FILE.exists():
                with open(COMMAND_FILE, 'r') as f: command = f.read().strip()
                if command:
                    command_info = parse_command(command)
                    result = execute_command(command_info)
                    with open(RESULT_FILE, 'w') as f: json.dump(result, f, indent=2)
                    COMMAND_FILE.unlink()
                    print(f"Komut işlendi: {command_info.get('action', 'unknown')}", file=sys.stderr)
            time.sleep(0.5)
        except KeyboardInterrupt:
            print("ESOMos Gemini Core durduruluyor...", file=sys.stderr)
            break
        except Exception as e:
            print(f"Hata: {e}", file=sys.stderr)
            time.sleep(1)
if __name__ == '__main__': main()
GEMINICOREEOF
chmod +x "$AIROOTFS_DIR/usr/local/bin/gemini_core.py"

# Systemd service
cat > "$AIROOTFS_DIR/etc/systemd/user/gemini-daemon.service" << 'SERVICEEOF'
[Unit]
Description=ESOMos Gemini AI System Daemon
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/gemini_core.py
Restart=always
RestartSec=5
Environment="GEMINI_API_KEY="
[Install]
WantedBy=default.target
SERVICEEOF

# AI Omni-Bar (basitleştirilmiş)
cat > "$AIROOTFS_DIR/usr/local/bin/ai_omni_bar.py" << 'AIBAREOF'
#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw
import json
from pathlib import Path
COMMAND_FILE = Path.home() / '.local' / 'share' / 'esomos' / 'ai_command.txt'
RESULT_FILE = Path.home() / '.local' / 'share' / 'esomos' / 'ai_result.json'
class AIOmniBar(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="ESOMos AI Omni-Bar")
        self.set_default_size(600, 60)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_keep_above(True)
        self.set_opacity(0.95)
        self.connect('realize', self.on_realize)
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        main_box.set_margin_start(20)
        main_box.set_margin_end(20)
        main_box.set_margin_top(10)
        main_box.set_margin_bottom(10)
        ai_icon = Gtk.Label(label="🤖")
        main_box.append(ai_icon)
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("AI'ya sorun veya komut verin...")
        self.entry.set_hexpand(True)
        self.entry.connect('activate', self.on_entry_activate)
        main_box.append(self.entry)
        mic_icon = Gtk.Label(label="🎤")
        main_box.append(mic_icon)
        self.set_child(main_box)
        css_provider = Gtk.CssProvider()
        css = "window { background-color: rgba(0, 0, 0, 0.9); border: 2px solid #FFD700; border-radius: 30px; }"
        css_provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        GLib.timeout_add(500, self.check_result)
    def on_realize(self, widget):
        display = Gdk.Display.get_default()
        monitor = display.get_monitors()[0]
        geometry = monitor.get_geometry()
        width, height = self.get_size()
        x = (geometry.width - width) // 2
        y = geometry.height - height - 30
        self.move(x, y)
    def on_entry_activate(self, entry):
        text = entry.get_text().strip()
        if text:
            self.send_command(text)
            entry.set_text("")
    def send_command(self, command):
        COMMAND_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(COMMAND_FILE, 'w') as f: f.write(command)
    def check_result(self):
        if RESULT_FILE.exists():
            try:
                with open(RESULT_FILE, 'r') as f: result = json.load(f)
                self.show_result(result)
                RESULT_FILE.unlink()
            except: pass
        return True
    def show_result(self, result):
        result_window = Gtk.Window()
        result_window.set_title("ESOMos AI Yanıtı")
        result_window.set_default_size(700, 300)
        result_window.set_transient_for(self)
        result_window.set_modal(True)
        result_window.set_position(Gtk.WindowPosition.CENTER)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_start(20)
        box.set_margin_end(20)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        label = Gtk.Label()
        label.set_markup(f"<span color='#FFD700'>{result.get('message', 'Yanıt')}</span>\n\n<span color='#FFFFFF'>{result.get('output', '')}</span>")
        label.set_wrap(True)
        box.append(label)
        close_btn = Gtk.Button(label="Tamam")
        close_btn.connect('clicked', lambda w: result_window.close())
        box.append(close_btn)
        result_window.set_child(box)
        result_window.present()
class ESOMosApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.esomos.ai-bar')
        self.connect('activate', self.on_activate)
    def on_activate(self, app):
        self.win = AIOmniBar(self)
        self.win.present()
if __name__ == '__main__':
    app = ESOMosApp()
    app.run(None)
AIBAREOF
chmod +x "$AIROOTFS_DIR/usr/local/bin/ai_omni_bar.py"

# ISO derleme
echo -e "${BLUE}[9/10]${NC} ISO derleniyor (bu işlem 10-30 dakika sürebilir)..."
echo -e "${YELLOW}⏳ Lütfen bekleyin...${NC}"

cd "$PROFILE_DIR"
sudo mkarchiso -v -w "$WORK_DIR/work" -o "$WORK_DIR/out" "$PROFILE_DIR" 2>&1 | tee "$WORK_DIR/build.log"

# ISO dosyasını bul
ISO_FILE=$(find "$WORK_DIR/out" -name "*.iso" -type f | head -1)

if [ -z "$ISO_FILE" ]; then
    echo -e "${RED}❌ ISO oluşturulamadı! Log: $WORK_DIR/build.log${NC}"
    exit 1
fi

# ISO'yu masaüstüne taşı
DESKTOP_ISO="$HOME/Desktop/ESOMos-$(date +%Y%m%d-%H%M%S).iso"
cp "$ISO_FILE" "$DESKTOP_ISO"
ISO_SIZE=$(du -h "$DESKTOP_ISO" | cut -f1)

# Sonuç
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ BAŞARILI!                              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🎉 ESOMos ISO başarıyla oluşturuldu!${NC}"
echo ""
echo -e "${BLUE}📁 ISO Konumu:${NC} $DESKTOP_ISO"
echo -e "${BLUE}📊 Dosya Boyutu:${NC} $ISO_SIZE"
echo ""
echo -e "${YELLOW}📝 Sonraki Adımlar:${NC}"
echo "   1. VirtualBox veya VMware'de yeni bir sanal makine oluşturun"
echo "   2. ISO dosyasını CD/DVD olarak bağlayın"
echo "   3. Sanal makineyi başlatın ve ESOMos'u kurun"
echo ""
echo -e "${GREEN}✨ İyi kullanımlar!${NC}"

