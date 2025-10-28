@echo off
chcp 65001 >nul
REM Скрипт для увеличения версии приложения

echo Увеличение версии приложения...

REM Читаем текущую версию из 4-й строки pubspec.yaml
for /f "skip=3 tokens=2" %%a in (pubspec.yaml) do (
    set CURRENT_VERSION=%%a
    goto :found_version
)
:found_version

echo Текущая версия: %CURRENT_VERSION%

REM Извлекаем versionName и versionCode
for /f "tokens=1 delims=+" %%b in ("%CURRENT_VERSION%") do set VERSION_NAME=%%b
for /f "tokens=2 delims=+" %%c in ("%CURRENT_VERSION%") do set BUILD_NUMBER=%%c

REM Увеличиваем versionCode на 1
set /a NEW_BUILD_NUMBER=%BUILD_NUMBER%+1

REM Создаем новую версию
set NEW_VERSION=%VERSION_NAME%+%NEW_BUILD_NUMBER%

echo Новая версия: %NEW_VERSION%

REM Обновляем только 4-ю строку в pubspec.yaml
powershell -Command "$content = Get-Content pubspec.yaml; $content[3] = 'version: %NEW_VERSION%'; $content | Set-Content pubspec.yaml"

echo Версия успешно обновлена!
pause
