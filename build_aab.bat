@echo off
REM Скрипт для сборки AAB с автоматическим увеличением версии

echo ========================================
echo    Сборка Android App Bundle (AAB)
echo ========================================
echo.

REM Читаем текущую версию
for /f "tokens=2" %%a in ('findstr "version:" pubspec.yaml ^| findstr /v "sdk"') do set CURRENT_VERSION=%%a
echo Текущая версия: %CURRENT_VERSION%
echo.

REM Извлекаем versionCode (номер после +)
for /f "tokens=2 delims=+" %%b in ("%CURRENT_VERSION%") do set BUILD_NUMBER=%%b

REM Увеличиваем versionCode на 1
set /a NEW_BUILD_NUMBER=%BUILD_NUMBER%+1

REM Извлекаем versionName (номер до +)
for /f "tokens=1 delims=+" %%c in ("%CURRENT_VERSION%") do set VERSION_NAME=%%c

REM Обновляем версию в pubspec.yaml
echo Обновление версии на %VERSION_NAME%+%NEW_BUILD_NUMBER%...
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: %CURRENT_VERSION%', 'version: %VERSION_NAME%+%NEW_BUILD_NUMBER%' | Set-Content pubspec.yaml"

echo.
echo ========================================
echo Очистка предыдущей сборки...
call flutter clean

echo.
echo ========================================
echo Сборка AAB...
call flutter build appbundle --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Успешно! AAB создан:
    echo build\app\outputs\bundle\release\app-release.aab
    echo Версия: %VERSION_NAME%+%NEW_BUILD_NUMBER%
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Ошибка при сборке!
    echo ========================================
)

echo.
pause

