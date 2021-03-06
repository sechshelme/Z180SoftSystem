unit Main_Window;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
    StdCtrls, ComCtrls, ActnList;

type

    { TformMainWindow }

    { TMainWindow }

    TMainWindow = class(TForm)
        actionTerminalSettings: TAction;
        actionHardwareInfo: TAction;
        actionAbout: TAction;
        actionRun: TAction;
        actionSlowRun: TAction;
        actionSingleStep: TAction;
        actionReset: TAction;
        actionStop: TAction;
        actionHddDrive: TAction;
        actionFloppyDrive: TAction;
        actionMemorySettings: TAction;
        actionCpuIoRegister: TAction;
        actionCpuCoreRegister: TAction;
        actionMemoryEditor: TAction;
        actionClose: TAction;
        actionLoadFileToRam: TAction;
        actionlistMainWindow: TActionList;
        imagelistMainWindow: TImageList;
        menuCpuCoreRegister: TMenuItem;
        menuCpuIoRegister: TMenuItem;
        menuFloppyImages: TMenuItem;
        menuHddImage: TMenuItem;
        menuHardwareInfo: TMenuItem;
        menuCopyCpmFiles: TMenuItem;
        menuCreateCpmDiscImages: TMenuItem;
        panelFdd0: TPanel;
        panelFdd1: TPanel;
        popup1Ops: TMenuItem;
        popup2Ops: TMenuItem;
        popup5Ops: TMenuItem;
        popup10Ops: TMenuItem;
        menuTerminalSettings: TMenuItem;
        menuTools: TMenuItem;
        menuReset: TMenuItem;
        menuRun: TMenuItem;
        menuSlowRun: TMenuItem;
        menuSingleStep: TMenuItem;
        N1: TMenuItem;
        menuStop: TMenuItem;
        menuMemorySettings: TMenuItem;
        menuSystem: TMenuItem;
        menuControl: TMenuItem;
        menuMemoryEditor: TMenuItem;
        menuView: TMenuItem;
        menuMainWindow: TMainMenu;
        menuFile: TMenuItem;
        menuLoadFileToRam: TMenuItem;
        menuSeparator1: TMenuItem;
        menuClose: TMenuItem;
        menuHelp: TMenuItem;
        menuAbout: TMenuItem;
        FileOpenDialog: TOpenDialog;
        cpuRun: TTimer;
        panelSystemTerminal: TPanel;
        popupmenuSlowRunSpeed: TPopupMenu;
        statusbarMainWindow: TPanel;
        toolbarMainWindow: TToolBar;
        toolbuttonTerminal: TToolButton;
        toolbuttonSeparator5: TToolButton;
        toolbuttonSeparator1: TToolButton;
        toolbuttonMemoryEditor: TToolButton;
        toolbuttonReset: TToolButton;
        toolbuttonSingleStep: TToolButton;
        toolbuttonSlowRun: TToolButton;
        toolbuttonRun: TToolButton;
        toolbuttonCpuCoreRegister: TToolButton;
        toolbuttonCpuIoRegister: TToolButton;
        toolbuttonSeparator2: TToolButton;
        toolbuttonMemorySettings: TToolButton;
        toolbuttonFloppyImages: TToolButton;
        toolbuttonHddImage: TToolButton;
        toolbuttonSeparator3: TToolButton;
        toolbuttonStop: TToolButton;
        procedure actionAboutExecute(Sender: TObject);
        procedure actionCloseExecute(Sender: TObject);
        procedure actionCpuCoreRegisterExecute(Sender: TObject);
        procedure actionCpuIoRegisterExecute(Sender: TObject);
        procedure actionFloppyDriveExecute(Sender: TObject);
        procedure actionLoadFileToRamExecute(Sender: TObject);
        procedure actionMemoryEditorExecute(Sender: TObject);
        procedure actionMemorySettingsExecute(Sender: TObject);
        procedure actionResetExecute(Sender: TObject);
        procedure actionRunExecute(Sender: TObject);
        procedure actionSingleStepExecute(Sender: TObject);
        procedure actionSlowRunExecute(Sender: TObject);
        procedure actionStopExecute(Sender: TObject);
        procedure actionTerminalSettingsExecute(Sender: TObject);
        procedure cpuRunTimer(Sender: TObject);
        procedure cpuSlowRunTimer(Sender: TObject);
        procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
        procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
        procedure FormShow(Sender: TObject);
        procedure panelFdd0Paint(Sender: TObject);
        procedure panelFdd1Paint(Sender: TObject);
        procedure popupSlowRunSpeedClick(Sender: TObject);

    private
        bootRomEnabled: boolean;
        procedure setSlowRunSpeed;
    public

    end;

var
    MainWindow: TMainWindow;

implementation

{$R *.lfm}

uses UscaleDPI, System_Settings, Cpu_Register, Cpu_Io_Register, Memory_Editor, Memory_Settings,
    System_Memory, System_InOut, Z180_CPU, System_Terminal, System_Fdc, Fdd_Settings, Terminal_Settings,
    About_Window;

{ TformMainWindow }

// --------------------------------------------------------------------------------
procedure TMainWindow.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
    if (cpuRun.Enabled = True) then begin
        cpuRun.Enabled := False;
        cpuRun.OnTimer := nil;
    end;

    if Assigned(CpuRegister) then begin
        CpuRegister.Close;
    end;

    if Assigned(MemoryEditor) then begin
        MemoryEditor.Close;
    end;

    if Assigned(CpuIoRegister) then begin
        CpuIoRegister.Close;
    end;

    if Assigned(Z180Cpu) then begin
        Z180Cpu.Destroy;
    end;

    if Assigned(SystemInOut) then begin
        SystemInOut.Destroy;
    end;

    if Assigned(SystemFdc) then begin
        SystemFdc.Destroy;
    end;

    if Assigned(SystemMemory) then begin
        SystemMemory.Destroy;
    end;

    if Assigned(SystemTerminal) then begin
        SystemTerminal.Destroy;
    end;

    SystemSettings.saveFormState(TForm(self));
    CloseAction := caFree;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
    SystemTerminal.getKeyBoardInput(Key, Shift);
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.FormShow(Sender: TObject);
var
    ImageFile: string;
begin
    SystemSettings.restoreFormState(TForm(self));
    {$ifdef Windows}
    Width := 100;
    Height := 100;
    {$endif}
    Constraints.MinWidth := 891;
    Constraints.MaxWidth := Constraints.MinWidth;
    {$ifdef Linux}
    Constraints.MinHeight := 622;
    {$else}
    Constraints.MinHeight := 616;
    {$endif}
    Constraints.MaxHeight := Constraints.MinHeight;
    ScaleDPI(self, 96);

    SystemMemory := TSystemMemory.Create;
    SystemFdc := TSystemFdc.Create;
    SystemInOut := TSystemInOut.Create;
    Z180Cpu := TZ180Cpu.Create;
    SystemTerminal := TSystemTerminal.Create(panelSystemTerminal);

    SystemMemory.setBootRomSize(SystemSettings.ReadString('Memory', 'RomSize', '8KB'));
    SystemMemory.setSystemRamSize(SystemSettings.ReadString('Memory', 'RamSize', '64KB'));
    SystemMemory.EnableReloadImageOnEnable(SystemSettings.ReadBoolean('Memory', 'ReloadOnEnable', False));
    SystemMemory.EnableFullAdressDecode(SystemSettings.ReadBoolean('Memory', 'FullAdressDecode', True));
    ImageFile := SystemSettings.ReadString('Memory', 'RomImageFile', '');
    if ((ImageFile <> '') and (not FileExists(ImageFile))) then begin
        SystemSettings.WriteString('Memory', 'RomImageFile', '');
        ImageFile := '';
    end;
    SystemMemory.SetRomImageFile(ImageFile);
    bootRomEnabled := SystemMemory.isRomFileValid;

    SystemTerminal.setCrLF(SystemSettings.ReadBoolean('Terminal', 'UseCRLF', False));
    SystemTerminal.setLocalEcho(SystemSettings.ReadBoolean('Terminal', 'LocalEcho', False));
    SystemTerminal.setTerminalLogging(SystemSettings.ReadBoolean('Terminal', 'Loggin', False));

    SystemFdc.setFdd0StatusPanel(panelFdd0);
    SystemFdc.setFdd0Sides(SystemSettings.ReadInteger('Fdd0', 'Sides', 2));
    SystemFdc.setFdd0Tracks(SystemSettings.ReadInteger('Fdd0', 'Tracks', 80));
    SystemFdc.setFdd0Sectors(SystemSettings.ReadInteger('Fdd0', 'Sectors', 9));
    SystemFdc.setFdd0SectorBytes(SystemSettings.ReadInteger('Fdd0', 'SectorBytes', 512));
    ImageFile := SystemSettings.ReadString('Fdd0', 'ImageFile', '');
    if ((ImageFile <> '') and (not FileExists(ImageFile))) then begin
        SystemSettings.WriteString('Fdd0', 'ImageFile', '');
        ImageFile := '';
    end;
    SystemFdc.setFdd0Image(ImageFile);

    SystemFdc.setFdd1StatusPanel(panelFdd1);
    SystemFdc.setFdd1Sides(SystemSettings.ReadInteger('Fdd1', 'Sides', 2));
    SystemFdc.setFdd1Tracks(SystemSettings.ReadInteger('Fdd1', 'Tracks', 80));
    SystemFdc.setFdd1Sectors(SystemSettings.ReadInteger('Fdd1', 'Sectors', 9));
    SystemFdc.setFdd1SectorBytes(SystemSettings.ReadInteger('Fdd1', 'SectorBytes', 512));
    ImageFile := SystemSettings.ReadString('Fdd1', 'ImageFile', '');
    if ((ImageFile <> '') and (not FileExists(ImageFile))) then begin
        SystemSettings.WriteString('Fdd1', 'ImageFile', '');
        ImageFile := '';
    end;
    SystemFdc.setFdd1Image(ImageFile);

    setSlowRunSpeed;

end;

// --------------------------------------------------------------------------------
procedure TMainWindow.panelFdd0Paint(Sender: TObject);
begin
    if (panelFdd0.Enabled) then begin
        imagelistMainWindow.Draw(panelFdd0.Canvas, 0, 1, 20);
    end
    else begin
        imagelistMainWindow.Draw(panelFdd0.Canvas, 0, 1, 22);
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.panelFdd1Paint(Sender: TObject);
begin
    if (panelFdd1.Enabled) then begin
        imagelistMainWindow.Draw(panelFdd1.Canvas, 0, 1, 21);
    end
    else begin
        imagelistMainWindow.Draw(panelFdd1.Canvas, 0, 1, 23);
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.popupSlowRunSpeedClick(Sender: TObject);
begin
    if (Sender = popup1Ops) then begin
        cpuRun.Interval := 1000;
        SystemSettings.WriteInteger('Emulation', 'SlowRunSpeed', 0);
    end
    else if (Sender = popup2Ops) then begin
        cpuRun.Interval := 500;
        SystemSettings.WriteInteger('Emulation', 'SlowRunSpeed', 1);
    end
    else if (Sender = popup5Ops) then begin
        cpuRun.Interval := 200;
        SystemSettings.WriteInteger('Emulation', 'SlowRunSpeed', 2);
    end
    else if (Sender = popup10Ops) then begin
        cpuRun.Interval := 100;
        SystemSettings.WriteInteger('Emulation', 'SlowRunSpeed', 3);
    end
    else begin
        cpuRun.Interval := 1000;
        SystemSettings.WriteInteger('Emulation', 'SlowRunSpeed', 0);
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.setSlowRunSpeed;
begin
    case (SystemSettings.ReadInteger('Emulation', 'SlowRunSpeed', 2)) of
        0: begin
            popup1Ops.Checked := True;
            cpuRun.Interval := 1000;
        end;
        1: begin
            popup2Ops.Checked := True;
            cpuRun.Interval := 500;
        end;
        2: begin
            popup5Ops.Checked := True;
            cpuRun.Interval := 200;
        end;
        3: begin
            popup10Ops.Checked := True;
            cpuRun.Interval := 100;
        end;
        else begin
            popup1Ops.Checked := True;
            cpuRun.Interval := 1000;
        end;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.cpuRunTimer(Sender: TObject);
begin
    cpuRun.Enabled := False;
    Z180Cpu.exec(35000);
    cpuRun.Enabled := True;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.cpuSlowRunTimer(Sender: TObject);
begin
    Z180Cpu.exec(1);
    if Assigned(MemoryEditor) then begin
        MemoryEditor.showMemoryData;
    end;
    if Assigned(CpuRegister) then begin
        CpuRegister.showRegisterData;
    end;
    if Assigned(CpuIoRegister) then begin
        CpuIoRegister.showRegisterData;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionLoadFileToRamExecute(Sender: TObject);
begin
    FileOpenDialog.Title := 'Lade Binär-Datei ins RAM';
    FileOpenDialog.Filter := 'Binär Dateien (*.bin)|*.bin;*.BIN|Alle Dateien (*.*)|*.*|';
    FileOpenDialog.InitialDir := GetUserDir;
    if (FileOpenDialog.Execute) then begin
        SystemMemory.LoadRamFile(FileOpenDialog.FileName);
        bootRomEnabled := False;
        if Assigned(MemoryEditor) then begin
            MemoryEditor.showMemoryData;
        end;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionMemoryEditorExecute(Sender: TObject);
begin
    if not Assigned(MemoryEditor) then begin
        Application.CreateForm(TMemoryEditor, MemoryEditor);
    end;

    if (Assigned(MemoryEditor) and (MemoryEditor.IsVisible) and (MemoryEditor.WindowState <> wsMinimized)) then begin
        MemoryEditor.Close;
    end
    else begin
        MemoryEditor.Show;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionMemorySettingsExecute(Sender: TObject);
var
    dialog: TMemorySettings;
begin
    Application.CreateForm(TMemorySettings, dialog);
    dialog.ShowModal;
    bootRomEnabled := SystemMemory.isRomFileValid;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionResetExecute(Sender: TObject);
begin
    Z180Cpu.reset;
    SystemMemory.EnableBootRom(bootRomEnabled);
    if Assigned(MemoryEditor) then begin
        MemoryEditor.showMemoryData;
    end;
    if Assigned(CpuRegister) then begin
        CpuRegister.showRegisterData;
    end;
    if Assigned(CpuIoRegister) then begin
        CpuIoRegister.showRegisterData;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionRunExecute(Sender: TObject);
begin
    if (cpuRun.Enabled = True) then begin
        cpuRun.Enabled := False;
        cpuRun.OnTimer := nil;
    end;
    cpuRun.OnTimer := @cpuRunTimer;
    cpuRun.Interval := 2;
    cpuRun.Enabled := True;
    actionMemorySettings.Enabled := False;
    actionFloppyDrive.Enabled := False;
    actionHddDrive.Enabled := False;
    actionLoadFileToRam.Enabled := False;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionSingleStepExecute(Sender: TObject);
begin
    if (cpuRun.Enabled = True) then begin
        cpuRun.Enabled := False;
        cpuRun.OnTimer := nil;
    end;
    Z180Cpu.exec(1);
    if Assigned(MemoryEditor) then begin
        MemoryEditor.showMemoryData;
    end;
    if Assigned(CpuRegister) then begin
        CpuRegister.showRegisterData;
    end;
    if Assigned(CpuIoRegister) then begin
        CpuIoRegister.showRegisterData;
    end;
    actionMemorySettings.Enabled := True;
    actionFloppyDrive.Enabled := True;
    actionHddDrive.Enabled := True;
    actionLoadFileToRam.Enabled := True;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionSlowRunExecute(Sender: TObject);
begin
    if (cpuRun.Enabled = True) then begin
        cpuRun.Enabled := False;
        cpuRun.OnTimer := nil;
    end;
    cpuRun.OnTimer := @cpuSlowRunTimer;
    setSlowRunSpeed;
    cpuRun.Enabled := True;
    actionMemorySettings.Enabled := False;
    actionFloppyDrive.Enabled := False;
    actionHddDrive.Enabled := False;
    actionLoadFileToRam.Enabled := False;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionStopExecute(Sender: TObject);
begin
    if (cpuRun.Enabled = True) then begin
        cpuRun.Enabled := False;
        cpuRun.OnTimer := nil;
    end;
    if Assigned(MemoryEditor) then begin
        MemoryEditor.showMemoryData;
    end;
    if Assigned(CpuRegister) then begin
        CpuRegister.showRegisterData;
    end;
    if Assigned(CpuIoRegister) then begin
        CpuIoRegister.showRegisterData;
    end;
    actionMemorySettings.Enabled := True;
    actionFloppyDrive.Enabled := True;
    actionHddDrive.Enabled := True;
    actionLoadFileToRam.Enabled := True;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionTerminalSettingsExecute(Sender: TObject);
var
    dialogResult: integer;
    dialog: TTerminalSettings;
begin
    Application.CreateForm(TTerminalSettings, dialog);
    dialog.ShowModal;
    dialogResult := dialog.getResult;
    if ((dialogResult and $0001) <> 0) then begin
        SystemTerminal.setCrLF(SystemSettings.ReadBoolean('Terminal', 'UseCRLF', False));
    end;
    if ((dialogResult and $0002) <> 0) then begin
        SystemTerminal.setLocalEcho(SystemSettings.ReadBoolean('Terminal', 'LocalEcho', False));
    end;
    if ((dialogResult and $0004) <> 0) then begin
        SystemTerminal.setTerminalLogging(SystemSettings.ReadBoolean('Terminal', 'Loggin', False));
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionCloseExecute(Sender: TObject);
begin
    Close;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionAboutExecute(Sender: TObject);
var
    dialog: TAboutWindow;
begin
    Application.CreateForm(TAboutWindow, dialog);
    dialog.ShowModal;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionCpuCoreRegisterExecute(Sender: TObject);
begin
    if not Assigned(CpuRegister) then begin
        Application.CreateForm(TCpuRegister, CpuRegister);
    end;

    if (Assigned(CpuRegister) and (CpuRegister.IsVisible) and (CpuRegister.WindowState <> wsMinimized)) then begin
        CpuRegister.Close;
    end
    else begin
        CpuRegister.Show;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionCpuIoRegisterExecute(Sender: TObject);
begin
    if not Assigned(CpuIoRegister) then begin
        Application.CreateForm(TCpuIoRegister, CpuIoRegister);
    end;

    if (Assigned(CpuIoRegister) and (CpuIoRegister.IsVisible) and (CpuIoRegister.WindowState <> wsMinimized)) then begin
        CpuIoRegister.Close;
    end
    else begin
        CpuIoRegister.Show;
    end;
end;

// --------------------------------------------------------------------------------
procedure TMainWindow.actionFloppyDriveExecute(Sender: TObject);
var
    dialog: TFddSettings;
begin
    Application.CreateForm(TFddSettings, dialog);
    dialog.ShowModal;
end;

// --------------------------------------------------------------------------------
end.
