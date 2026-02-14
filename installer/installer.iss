#define MyAppName "SpawnPK Market Dashboard"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "SpawnPK"
#define MyAppExeName "spawnpk_market_dashboard.exe"

[Setup]
AppId={{B4A8B1E4-3F66-4D45-9A6E-FAKE-GUID-CHANGE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={pf}\SpawnPK Market Dashboard
DefaultGroupName={#MyAppName}
OutputDir=..\installer_output
OutputBaseFilename=SpawnPKMarketDashboardSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked
Name: "startup"; Description: "Start when Windows starts"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
ValueType: string; ValueName: "SpawnPKMarketDashboard"; \
ValueData: """{app}\{#MyAppExeName}"""; Tasks: startup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; \
Flags: nowait postinstall skipifsilent
