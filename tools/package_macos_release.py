#!/usr/bin/env python3
"""Package an already-exported, signature-verified macOS app with install notes."""
import hashlib
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'config/version="([^"]+)"', (ROOT/'godot/project.godot').read_text()).group(1)
app = ROOT/'builds/Escape Velocity HD.app'
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
app_version = subprocess.check_output(['/usr/libexec/PlistBuddy', '-c', 'Print CFBundleShortVersionString', str(app/'Contents/Info.plist')], text=True).strip()
if app_version != version:
    raise SystemExit(f'App {app_version} does not match project {version}; export first.')
folder = ROOT/'builds'/f'release-{version}'
folder.mkdir(exist_ok=True)
subprocess.run(['ditto', str(app), str(folder/app.name)], check=True)
(folder/'READ-ME.txt').write_text(f'''Escape Velocity HD {version} — macOS acceptance candidate

No Godot installation needed. Universal Apple Silicon / Intel binary.

INSTALL
Unzip the download, drag Escape Velocity HD.app to Applications, then open it.
This development app is ad-hoc signed, not Developer ID signed or notarized.
If macOS blocks launch and you trust this download, use System Settings >
Privacy & Security > Open Anyway after attempting launch, then confirm Open.

UPDATE AND SAVES
Replace the app; pilot saves live separately in your user data directory.
Back up valuable pilot JSON files before testing a development release.
Open Pilot selects an existing save. New Pilot saves the current living pilot
before creating a separate file. A dead normal pilot preserves its living save;
a strict pilot's permanent death is intentional.

CONTROLS
Arrow keys: steer/thrust. W: thrust. S: retrograde. Space: selected weapon.
Q/E: cycle weapon. Tab: target. J: jump/cancel. M: map. A: autopilot/cancel.
L: land (double-tap: auto-land). B: board (double-tap: auto-board).
Shift + thrust: afterburner. K: cloak. F: fleet. I: journal. P: information.
Esc: menu and controls. Classic primary/secondary firing is optional in settings.

ACCEPTANCE STATUS
Automated campaigns and regression coverage do not establish full manual
campaign parity. See PHASE_6_ACCEPTANCE.md for results, limitations and the
remaining manual campaign checklist. Intel execution and clean-machine
Gatekeeper acceptance remain unverified on this Apple Silicon test machine.
Add-ons remain out of scope. Requested F-14 and other custom features remain.

Project and updates: https://github.com/jblyne/EscapeVelocity
''')
shutil.copy2(ROOT/'godot/CREDITS.md', folder/'CREDITS.md')
report = ROOT/'research/reports/PHASE_6_ACCEPTANCE.md'
if not report.exists(): raise SystemExit('Write the acceptance report before packaging.')
shutil.copy2(report, folder/report.name)
archive = ROOT/'builds'/f'Escape-Velocity-HD-{version}-macOS.zip'
if archive.exists(): raise SystemExit(f'{archive} already exists; choose a new version rather than replacing a release artifact.')
subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(folder), str(archive)], check=True)
digest = hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()
archive.with_suffix(archive.suffix+'.sha256').write_text(f'{digest}  {archive.name}\n')
print(archive)
print(f'SHA256 {digest}')
