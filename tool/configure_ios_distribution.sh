#!/usr/bin/env bash
set -euo pipefail

for name in IOS_TEAM_ID IOS_DISTRIBUTION_CERTIFICATE_BASE64 \
  IOS_DISTRIBUTION_CERTIFICATE_PASSWORD IOS_PROVISIONING_PROFILE_BASE64; do
  if [[ -z "${!name:-}" ]]; then
    echo "::error::Required iOS signing secret is missing: $name"
    exit 1
  fi
done

umask 077
signing_dir=$(mktemp -d "$RUNNER_TEMP/yalla-ios-signing.XXXXXX")
trap 'rm -f "$signing_dir/distribution.p12" "$signing_dir/profile.mobileprovision" "$signing_dir/profile.plist"; rmdir "$signing_dir"' EXIT
export SIGNING_DIR="$signing_dir"

python3 - <<'PY'
import base64
import os
from pathlib import Path

directory = Path(os.environ['SIGNING_DIR'])
for name, filename in (
    ('IOS_DISTRIBUTION_CERTIFICATE_BASE64', 'distribution.p12'),
    ('IOS_PROVISIONING_PROFILE_BASE64', 'profile.mobileprovision'),
):
    try:
        data = base64.b64decode(''.join(os.environ[name].split()), validate=True)
    except ValueError:
        raise SystemExit(f'{name} must contain valid base64.') from None
    (directory / filename).write_bytes(data)
PY

security cms -D -i "$signing_dir/profile.mobileprovision" > "$signing_dir/profile.plist"
python3 - <<'PY'
import os
import plistlib
import re
from datetime import datetime, timezone
from pathlib import Path
from shutil import copyfile

directory = Path(os.environ['SIGNING_DIR'])
team_id = os.environ['IOS_TEAM_ID']
bundle_id = 'com.yallamarket.app'
with (directory / 'profile.plist').open('rb') as source:
    profile = plistlib.load(source)
entitlements = profile.get('Entitlements', {})
app_id = entitlements.get('application-identifier', '')
prefixes = profile.get('ApplicationIdentifierPrefix', [])
if (not re.fullmatch(r'[A-Z0-9]{10}', team_id)
    or team_id not in profile.get('TeamIdentifier', [])
    or app_id not in {f'{prefix}.{bundle_id}' for prefix in prefixes}
    or profile.get('ProvisionedDevices')
    or profile.get('ProvisionsAllDevices')
    or entitlements.get('get-task-allow')
    or profile['ExpirationDate'].replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc)):
    raise SystemExit('Supply a valid App Store profile matching the team and bundle ID.')

profile_id = profile['UUID']
if not re.fullmatch(r'[a-fA-F0-9]{8}(?:-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}', profile_id):
    raise SystemExit('The App Store profile UUID is invalid.')
profiles = Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles'
profiles.mkdir(parents=True, exist_ok=True)
copyfile(directory / 'profile.mobileprovision', profiles / f'{profile_id}.mobileprovision')

Path('ios/Flutter/DistributionSigning.xcconfig').write_text(
    f'DEVELOPMENT_TEAM = {team_id}\n'
    'CODE_SIGN_STYLE = Manual\n'
    'CODE_SIGN_IDENTITY[sdk=iphoneos*] = Apple Distribution\n'
    f'PROVISIONING_PROFILE_SPECIFIER = {profile_id}\n',
    encoding='ascii',
)
export_options = Path(os.environ['RUNNER_TEMP']) / 'yalla-ios-export.plist'
with export_options.open('wb') as destination:
    plistlib.dump({
        'method': 'app-store-connect',
        'signingStyle': 'manual',
        'signingCertificate': 'Apple Distribution',
        'teamID': team_id,
        'provisioningProfiles': {bundle_id: profile_id},
    }, destination)
PY

keychain="$RUNNER_TEMP/yalla-ios.keychain-db"
keychain_password=$(openssl rand -hex 32)
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$signing_dir/distribution.p12" -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" \
  -t cert -f pkcs12 -k "$keychain" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain"
