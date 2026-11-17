@echo off
if not exist "D:\FlutterTemp" mkdir "D:\FlutterTemp"
set TEMP=D:\FlutterTemp
set TMP=D:\FlutterTemp
echo Running Orthodoxia using D:\FlutterTemp...
flutter run -d chrome
