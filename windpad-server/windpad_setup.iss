[Setup]
AppName=Windpad Helper
AppVersion=1.0.0
AppPublisher=Aditya
DefaultDirName={autopf}\Windpad
DefaultGroupName=Windpad
OutputBaseFilename=WindpadHelper_Setup
SetupIconFile=windpad.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "dist\WindpadHelper.exe"; DestDir: "{app}"
Source: "windpad.ico"; DestDir: "{app}"

[Icons]
Name: "{group}\Windpad Helper"; Filename: "{app}\WindpadHelper.exe"
Name: "{commondesktop}\Windpad Helper"; Filename: "{app}\WindpadHelper.exe"

[Run]
Filename: "{app}\WindpadHelper.exe"; Description: "Launch Windpad Helper"; Flags: postinstall nowait
