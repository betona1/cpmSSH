[Setup]
AppName=cpmSSH
AppVersion=1.1.0
AppPublisher=betona1
DefaultDirName={autopf}\cpmSSH
DefaultGroupName=cpmSSH
OutputBaseFilename=cpmSSH-1.1.0-windows-setup
OutputDir=Output
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\cpm_ssh_terminal.exe

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\cpmSSH"; Filename: "{app}\cpm_ssh_terminal.exe"
Name: "{commondesktop}\cpmSSH"; Filename: "{app}\cpm_ssh_terminal.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "바탕화면에 바로가기 만들기"; GroupDescription: "추가 아이콘:"

[Run]
Filename: "{app}\cpm_ssh_terminal.exe"; Description: "cpmSSH 실행"; Flags: nowait postinstall skipifsilent
