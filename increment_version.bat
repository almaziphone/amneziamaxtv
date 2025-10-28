@echo off
REM Скрипт автоматического увеличения версии для Windows

echo Увеличение версии...

REM Читаем текущую версию из pubspec.yaml
for /f "tokens=2 delims=+" %%a in ('findstr "version:" pubspec.yaml') do set VERSION_LINE=%%a

REM Извлекаем номер сборки (versionCode)
for /f "tokens=2 delims=+" %%b in ('findstr "version:" pubspec.yaml') do set BUILD_NUMBER=%%b

REM Увеличиваем номер сборки на 1
set /a NEW_BUILD_NUMBER=%BUILD_NUMBER%+1

echo Текущий versionCode: %BUILD_NUMBER%
echo Новый versionCode: %NEW_BUILD_NUMBER%

REM Получаем версию (versionName)
for /f "tokens=1 delims=+" %%c in ('findstr "version:" pubspec.yaml ^| findstr /v "sdk"') do set FULL_VERSION=%%c
for /f "tokens=2" %%d in ("%FULL_VERSION%") do set VERSION_NAME=%%d

REM Создаем новую строку версии
set NEW_VERSION=version: %VERSION_NAME%+%NEW_BUILD_NUMBER%

echo Новая версия: %VERSION_NAME%+%NEW_BUILD_NUMBER%

REM Заменяем версию в pubspec.yaml
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', '%NEW_VERSION%' | Set-Content pubspec.yaml"

echo Версия обновлена успешно!
echo.
echo Запуск сборки AAB...
flutter build appbundle --release

pause

