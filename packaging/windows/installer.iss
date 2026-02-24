; Author: Mouhsine Kassimi Farhaoui
; Mail: mouhsine98@gmail.com
;
; @file packaging/windows/installer.iss
; @brief Inno Setup script for N6705 Power Console.

#define MyAppName "N6705 Power Console"
#define MyAppExeName "N6705PowerConsole.exe"
#define MyAppPublisher "Mouhsine Kassimi Farhaoui"
#define MyAppURL "https://github.com/"

#ifndef SourceRoot
  #error "Define SourceRoot when invoking ISCC."
#endif

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define BuildAppDir SourceRoot + "\\dist\\windows\\app\\N6705PowerConsole"
#define BuildAppExe BuildAppDir + "\\" + MyAppExeName
#define BuildIcon SourceRoot + "\\build\\windows\\n6705_app_icon.ico"

[Setup]
AppId={{7F587330-7408-4536-BF33-7E3DABFC4938}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0
OutputDir={#SourceRoot}\dist\windows\installer
OutputBaseFilename=n6705-power-console-{#AppVersion}-setup
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupLogging=yes
#ifexist "{#BuildIcon}"
SetupIconFile={#BuildIcon}
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#BuildAppDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourceRoot}\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "N6705_UI_HOME"; ValueData: "{app}"; Flags: preservestringtype uninsdeletevalue

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
