@echo off
echo Starting tunnel...

del "%TEMP%\cloudflared_log.txt" 2>nul

"E:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:80 > "%TEMP%\cloudflared_log.txt" 2>&1 &

timeout /t 12 /nobreak

for /f "tokens=2 delims=|" %%a in ('type "%TEMP%\cloudflared_log.txt" ^| findstr "https://.*trycloudflare"') do set URL=%%a
set URL=%URL: =%

echo URL: %URL%

"C:\Program Files\1cv8\bin\1cv8.exe" ENTERPRISE /F"C:\Users\dobri\Desktop\Диплом\ИС\DevFiles" /N"webhook" /Execute"УстановитьWebhook" /C"%URL%"

echo Done!
pause