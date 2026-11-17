New-Item -ItemType Directory -Force -Path "D:\FlutterTemp" | Out-Null
$env:TEMP = "D:\FlutterTemp"
$env:TMP = "D:\FlutterTemp"
Write-Host "Running Orthodoxia using D:\FlutterTemp (202 GB free on D:)..." -ForegroundColor Yellow
flutter run -d chrome
