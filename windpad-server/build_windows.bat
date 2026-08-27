@echo off
echo Installing dependencies from requirements.txt...
pip install -r requirements.txt

echo Building Windpad Helper for Windows...

:: Build the executable
call pyinstaller --onefile --noconsole ^
    --hidden-import pynput.keyboard ^
    --hidden-import pynput.mouse ^
    --hidden-import pynput.keyboard._win32 ^
    --hidden-import pynput.mouse._win32 ^
    --hidden-import zeroconf ^
    --hidden-import zeroconf._utils.ipaddress ^
    --hidden-import zeroconf._dns ^
    --exclude-module matplotlib ^
    --exclude-module numpy ^
    --exclude-module pandas ^
    --exclude-module scipy ^
    --exclude-module unittest ^
    --exclude-module email ^
    --exclude-module html ^
    --exclude-module http ^
    --exclude-module xml ^
    --strip ^
    --icon=windpad.ico ^
    --name="WindpadHelper" main.py

:: Compile the Inno Setup script if ISCC is available
set ISCC_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist %ISCC_PATH% (
    echo Compiling Setup Installer...
    %ISCC_PATH% windpad_setup.iss
    echo Build complete. Installer is located in the Output dir.
) else (
    echo.
    echo Inno Setup Compiler not found at %ISCC_PATH%.
    echo Please install Inno Setup 6 or manually compile windpad_setup.iss to generate the Windows Installer.
    echo The portable executable is located in the dist folder.
)

pause
