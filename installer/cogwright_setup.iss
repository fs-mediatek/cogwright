; Cogwright Inno Setup Skript
; Aufruf via build_release.ps1 — Version wird via /D AppVersion=X.Y.Z ueberreicht.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{B7C2A4E9-3F16-4A2B-8A4C-2C8F1D5E9B11}}
AppName=Cogwright
AppVersion={#AppVersion}
AppPublisher=UEAG
AppPublisherURL=https://github.com/fs-mediatek/cogwright
DefaultDirName={localappdata}\Cogwright
DefaultGroupName=Cogwright
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputBaseFilename=Cogwright-Setup-{#AppVersion}
OutputDir=..\release
Compression=lzma2/ultra
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=Cogwright
UninstallDisplayIcon={app}\Cogwright.exe
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Desktop-Verknuepfung erstellen"; GroupDescription: "Zusaetzliche Optionen:"; Flags: unchecked

[Files]
Source: "..\game\build\Cogwright.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "Cogwright-Update.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Cogwright-Update.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Cogwright"; Filename: "{app}\Cogwright.exe"
Name: "{group}\Cogwright deinstallieren"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Cogwright"; Filename: "{app}\Cogwright.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Cogwright.exe"; Description: "Cogwright starten"; Flags: nowait postinstall skipifsilent unchecked

[UninstallDelete]
Type: files; Name: "{app}\update.log"
