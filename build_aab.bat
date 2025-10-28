@echo off
chcp 65001 >nul
REM Скрипт для сборки AAB с автоматическим увеличением версии

echo ========================================
echo    Сборка Android App Bundle (AAB)
echo ========================================
echo.

REM Читаем текущую версию из 4-й строки pubspec.yaml
for /f "skip=3 tokens=2" %%a in (pubspec.yaml) do (
    set CURRENT_VERSION=%%a
    goto :found_version
)
:found_version

echo Текущая версия: %CURRENT_VERSION%
echo.

REM Извлекаем versionName и versionCode
for /f "tokens=1 delims=+" %%b in ("%CURRENT_VERSION%") do set VERSION_NAME=%%b
for /f "tokens=2 delims=+" %%c in ("%CURRENT_VERSION%") do set BUILD_NUMBER=%%c

REM Увеличиваем versionCode на 1
set /a NEW_BUILD_NUMBER=%BUILD_NUMBER%+1

REM Создаем новую версию
set NEW_VERSION=%VERSION_NAME%+%NEW_BUILD_NUMBER%

echo Новая версия: %NEW_VERSION%
echo Обновление pubspec.yaml...

REM Создаем временный файл
powershell -Command "$content = Get-Content pubspec.yaml; $content[3] = 'version: %NEW_VERSION%'; $content | Set-Content pubspec.yaml"

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
    echo Версия: %NEW_VERSION%
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Ошибка при сборке!
    echo ========================================
)

echo.
pause
