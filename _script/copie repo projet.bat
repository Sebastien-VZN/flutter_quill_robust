@echo off
setlocal

:: --- Copie miroir du repo vers sa destination E: ---
set "SRC=C:\Devs\01_client_project\flutter_quill_robust"
set "DST=E:\Projets Dev\plugin_flutter\flutter_quill_robust"

echo.
echo === Copie miroir : flutter_quill_robust ===
echo   Source : %SRC%
echo   Cible  : %DST%
echo.

for %%I in ("%DST%") do if not exist "%%~dpI" mkdir "%%~dpI"

robocopy "%SRC%" "%DST%" /MIR /XF "nul" /R:1 /W:1 /NFL /NDL /NJH /NJS
set "RC=%errorlevel%"

if %RC% LSS 8 (
    echo [flutter_quill_robust] : OK ^(robocopy code %RC%^)
) else (
    echo [flutter_quill_robust] : ECHEC ^(robocopy code %RC%^)
)

echo ---
echo Termine.
endlocal
pause