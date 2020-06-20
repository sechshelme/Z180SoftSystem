unit System_Terminal;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Controls, ExtCtrls, Graphics;

type

    { TSystemTerminal }

    TSystemTerminal = class

    private   // Attribute
    const
        terminalColumns = 80;
        terminalRows = 24;
        charHeight = 22;
        charWidth = 11;
        startLeft = 6;
        startTop = 6;

    var
        newCharAvailable: boolean;
        imagePage1, imagePage2: TImage;
        timerTerminalPageRefresh: TTimer;
        timerCursorFlash: TTimer;
        charData: array[1..terminalRows, 1..terminalColumns] of char;
        charStyle: array[1..terminalRows, 1..terminalColumns] of TFontStyles;
        charColor: array[1..terminalRows, 1..terminalColumns] of TColor;
        terminalCursor: record
            column: integer;
            row: integer;
            cursorChar: char;
            Visible: boolean;
        end;
        keyboardBuffer: string;
        enableCrLf: boolean;
        enableLocalEcho: boolean;
        enableTerminalLogging: boolean;
        loggingFile: file of char;

    protected // Attribute
        procedure timerCursorFlashTimer(Sender: TObject);
        procedure timerTerminalPageRefreshTimer(Sender: TObject);

    public    // Attribute

    public  // Konstruktor/Destruktor
        constructor Create(terminalPanel: TPanel); overload;
        destructor Destroy; override;

    private   // Methoden
        procedure terminalReset;
        procedure writeCharOnScreen(character: char; color: TColor = clBlack; style: TFontStyles = []);
        procedure scrollTerminalContentUp;
        procedure cursorHome;
        procedure cursorLeft;
        procedure cursorRight;
        procedure cursorUp;
        procedure cursorDown;
        procedure backspace;
        procedure setTabulator;
        procedure lineFeed;
        procedure clearScreen;
        procedure carriageReturn;
        procedure deleteEndOfLine;

    protected // Methoden

    public    // Methoden
        procedure setCrLF(enable: boolean);
        procedure setLocalEcho(enable: boolean);
        procedure setTerminalLogging(enable: boolean);
        procedure writeCharacter(character: byte);
        function readCharacter(getStatus: boolean): byte;
        procedure getKeyBoardInput(key: word; shift: TShiftState);

    end;

var
    SystemTerminal: TSystemTerminal;

implementation

{ TSystemTerminal }

// --------------------------------------------------------------------------------
procedure TSystemTerminal.timerCursorFlashTimer(Sender: TObject);
begin
    timerCursorFlash.Enabled := False;
    if (terminalCursor.Visible) then begin
        terminalCursor.Visible := False;
    end
    else begin
        terminalCursor.Visible := True;
    end;
    timerCursorFlash.Enabled := True;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.timerTerminalPageRefreshTimer(Sender: TObject);
var
    row, column, posX, posY: integer;
    viewChar: char;
begin
    timerTerminalPageRefresh.Enabled := False;
    for row := 1 to terminalRows do begin
        for column := 1 to terminalColumns do begin
            if (terminalCursor.Visible and (row = terminalCursor.row) and (column = terminalCursor.column)) then begin
                viewchar := terminalCursor.cursorChar;
            end
            else begin
                viewchar := charData[row, column];
            end;
            posX := startLeft + (charWidth * (column - 1));
            posY := startTop + (charHeight * (row - 1));
            if (imagePage1.Visible) then begin
                imagePage2.Canvas.Font.Color := charColor[row, column];
                imagePage2.Canvas.Font.Style := charStyle[row, column];
                imagePage2.Canvas.TextOut(posX, posY, viewChar);
            end
            else begin
                imagePage1.Canvas.Font.Color := charColor[row, column];
                imagePage1.Canvas.Font.Style := charStyle[row, column];
                imagePage1.Canvas.TextOut(posX, posY, viewChar);
            end;
        end;
    end;
    imagePage1.Visible := imagePage2.Visible;
    imagePage2.Visible := not imagePage1.Visible;
    timerTerminalPageRefresh.Enabled := True;
end;

// --------------------------------------------------------------------------------
constructor TSystemTerminal.Create(terminalPanel: TPanel);
var
    pageTop, pageLeft, pageWidth, pageHeight: integer;
begin
    pageTop := 0;
    pageLeft := 0;
    pageWidth := (charWidth * terminalColumns) + charWidth;
    pageHeight := (charHeight * terminalRows) + charHeight;

    imagePage1 := TImage.Create(terminalPanel);
    imagePage1.Parent := terminalPanel;
    with (imagePage1) do begin
        Top := pageTop;
        Left := PageLeft;
        Width := pageWidth;
        Height := pageHeight;
        Canvas.Brush.Color := clWhite;
        Canvas.Pen.Color := clWhite;
        Canvas.Font.Name := 'Courier New';
        Canvas.Font.Size := 12;
        Canvas.Font.Color := clBlack;
        Canvas.Rectangle(0, 0, imagePage1.Width, imagePage1.Height);
    end;

    imagePage2 := TImage.Create(terminalPanel);
    imagePage2.Parent := terminalPanel;
    with (imagePage2) do begin
        Top := pageTop;
        Left := PageLeft;
        Width := pageWidth;
        Height := pageHeight;
        Canvas.Brush.Color := clWhite;
        Canvas.Pen.Color := clWhite;
        Canvas.Font.Name := 'Courier New';
        Canvas.Font.Size := 12;
        Canvas.Font.Color := clBlack;
        Canvas.Rectangle(0, 0, imagePage2.Width, imagePage2.Height);
    end;

    timerCursorFlash := TTimer.Create(terminalPanel);
    timerCursorFlash.Interval := 600;
    timerCursorFlash.OnTimer := @timerCursorFlashTimer;
    timerCursorFlash.Enabled := False;

    timerTerminalPageRefresh := TTimer.Create(terminalPanel);
    timerTerminalPageRefresh.Interval := 50;
    timerTerminalPageRefresh.OnTimer := @timerTerminalPageRefreshTimer;
    timerTerminalPageRefresh.Enabled := False;

    newCharAvailable := False;
    enableCrLf := False;
    enableLocalEcho := False;
    setTerminalLogging(False);
    terminalReset;

end;
// --------------------------------------------------------------------------------
destructor TSystemTerminal.Destroy;
begin
    timerCursorFlash.Enabled := False;
    timerCursorFlash.OnTimer := nil;
    timerTerminalPageRefresh.Enabled := False;
    timerTerminalPageRefresh.OnTimer := nil;
    if (enableTerminalLogging) then begin
        CloseFile(loggingFile);
    end;
    inherited Destroy;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.terminalReset;
var
    row, column: integer;
begin
    for row := 1 to terminalRows do begin
        for column := 1 to terminalColumns do begin
            charData[row, column] := ' ';
            charColor[row, column] := clBlack;
            charStyle[row, column] := [];
        end;
    end;

    terminalCursor.column := 1;
    terminalCursor.row := 1;
    terminalCursor.cursorChar := '_';
    terminalCursor.Visible := True;

    imagePage1.Visible := True;
    imagePage2.Visible := False;

    timerCursorFlash.Enabled := True;
    timerTerminalPageRefresh.Enabled := True;

    keyboardBuffer := '';
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.writeCharOnScreen(character: char; color: TColor; style: TFontStyles);
begin
    charData[terminalCursor.row, terminalCursor.column] := character;
    charColor[terminalCursor.row, terminalCursor.column] := color;
    charStyle[terminalCursor.row, terminalCursor.column] := style;

    Inc(terminalCursor.column);
    if (terminalCursor.column > terminalColumns) then begin
        terminalCursor.column := 1;
        Inc(terminalCursor.row);
        if (terminalCursor.row > terminalRows) then begin
            scrollTerminalContentUp;
        end;
    end;
end;
// --------------------------------------------------------------------------------
procedure TSystemTerminal.scrollTerminalContentUp;
var
    column, row: integer;
begin
    for row := 1 to terminalRows - 1 do begin
        charData[row] := charData[row + 1];
        charColor[row] := charColor[row + 1];
        charStyle[row] := charStyle[row + 1];
    end;
    for column := 1 to terminalColumns do begin
        charData[terminalRows, column] := ' ';
        charColor[terminalRows, column] := clBlack;
        charStyle[terminalRows, column] := [];
    end;
    terminalCursor.column := 1;
    terminalCursor.row := terminalRows;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.cursorHome;
begin
    terminalCursor.column := 1;
    terminalCursor.row := 1;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.cursorLeft;
begin
    if (terminalCursor.column > 1) then begin
        Dec(terminalCursor.column);
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.cursorRight;
begin
    if (terminalCursor.column < terminalColumns) then begin
        Inc(terminalCursor.column);
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.cursorUp;
begin
    if (terminalCursor.row > 1) then begin
        Dec(terminalCursor.row);
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.cursorDown;
begin
    if (terminalCursor.row < terminalRows) then begin
        Inc(terminalCursor.row);
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.backspace;
begin
    if (terminalCursor.column > 1) then begin
        Dec(terminalCursor.column);
        charData[terminalCursor.row, terminalCursor.column] := ' ';
        charColor[terminalCursor.row, terminalCursor.column] := clBlack;
        charStyle[terminalCursor.row, terminalCursor.column] := [];
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.setTabulator;
begin
    terminalCursor.column := (8 * ((terminalCursor.column div 8) + 1));
    if (terminalCursor.column > terminalColumns) then begin
        terminalCursor.column := 1;
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.lineFeed;
begin
    Inc(terminalCursor.row);
    if (terminalCursor.row > terminalRows) then begin
        scrollTerminalContentUp;
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.clearScreen;
var
    row, column: integer;
begin
    for row := 1 to terminalRows do begin
        for column := 1 to terminalColumns do begin
            charData[row, column] := ' ';
            charColor[row, column] := clBlack;
            charStyle[row, column] := [];
        end;
    end;
    terminalCursor.column := 1;
    terminalCursor.row := 1;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.carriageReturn;
begin
    terminalCursor.column := 1;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.deleteEndOfLine;
var
    column: integer;
begin
    for column := terminalCursor.column to terminalColumns do begin
        charData[terminalCursor.row, column] := ' ';
        charColor[terminalCursor.row, column] := clBlack;
        charStyle[terminalCursor.row, column] := [];
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.setCrLF(enable: boolean);
begin
    enableCrLf := enable;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.setLocalEcho(enable: boolean);
begin
    enableLocalEcho := enable;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.setTerminalLogging(enable: boolean);
begin
    enableTerminalLogging := enable;
    if (enableTerminalLogging) then begin
        try
            Assign(loggingFile, 'Terminal.log');
            Rewrite(loggingFile);
        except
            enableTerminalLogging := False;
        end;
    end;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.writeCharacter(character: byte);
begin
    case (character) of
        $01: begin
            cursorHome;
        end;
        $04: begin
            cursorRight;
        end;
        $05: begin
            cursorUp;
        end;
        $08: begin
            backspace;
        end;
        $09: begin
            setTabulator;
        end;
        $0A: begin
            lineFeed;
        end;
        $0C: begin
            clearScreen;
        end;
        $0D: begin
            carriageReturn;
            if (enableCrLf) then begin
                lineFeed;
            end;
        end;
        $13: begin
            cursorLeft;
        end;
        $16: begin
            deleteEndOfLine;
        end;
        $18: begin
            cursorDown;
        end;
        $20..$7E: begin
            writeCharOnScreen(chr(character));
        end;
    end;
    if (enableTerminalLogging) then begin
        Write(loggingFile, chr(character));
    end;
end;

// --------------------------------------------------------------------------------
function TSystemTerminal.readCharacter(getStatus: boolean): byte;
var
    Data: byte;
begin
    if (getStatus) then begin
        if (keyboardBuffer.Length = 0) then begin
            Data := $00;
        end
        else begin
            Data := $FF;
        end;
    end
    else begin
        Data := byte(keyboardBuffer[1]);
        Delete(keyboardBuffer, 1, 1);
    end;
    Result := Data;
end;

// --------------------------------------------------------------------------------
procedure TSystemTerminal.getKeyBoardInput(key: word; shift: TShiftState);
var
    character: byte;
begin
    character := $00;
    if Shift = [] then begin
        case Key of
            08: begin // DEL
                character := $7F;
                //RUN_DEL;
            end; { 08 }
            09: character := Key; // TAB
            13: character := Key; // ENTER
            27: character := $1B; // ESC
            32: character := $20; // SPACE
            33: character := $12; // Ctrl R
            34: character := $03; // Ctrl C
            37: character := $13; // links
            38: character := $05; // oben
            39: character := $04; // rechts
            40: character := $18; // unten
            45: character := $16; // Einfg = Ctrl V
            46: character := $07; // Entf = Ctrl G
            48..57: character := Key; // 1..0
            65..90: character := Key + 32; // a..z
            186: character := $75; // ue
            187: character := $2B; // +
            188: character := $2C; // ,
            189: character := $2D; // -
            190: character := $2E; // .
            191: character := $23; // #
            192: character := $6F; // oe
            219: character := $73; // s
            220: character := $5E; // ^
            221: character := $60; // `
            222: character := $61; // a
            226: character := $3C; // <
            else character := $00;
        end; { case Key of }
    end; { if Shift = [] then }


    if Shift = [SSSHIFT] then begin
        if Key <> 16 then begin  // Shift-Taste
            case Key of
                00: character := Key;
                48: character := $3D; // =
                49: character := $21; // !
                50: character := $22; // "
                51: character := $23; // §
                52: character := $24; // $
                53: character := $25; // %
                54: character := $26; // &
                55: character := $2F; // /
                56: character := $28; // (
                57: character := $29; // )
                65..90: character := Key; // A..Z
                187: character := $2A; // *
                188: character := $3B; // ;
                189: character := $5F; // _
                190: character := $3A; // :
                191: character := $27; // '
                219: character := $3F; // ?
                220: character := $7E; // ° -> ~
                221: character := $60; // `
                226: character := $3E; // >
                else character := $00;
            end; { if Key<>16 then }
        end; { if Key<>16 then }
    end; { if Shift=[SSSHIFT] then }


    if Shift = [SSCTRL] then begin
        if Key <> 17 then begin
            if (Key > 64) and (Key < 91) then
                character := Key - 64;
        end; { if Key<>17 then }
    end; { if Shift=[SSCTRL] then }


    if Shift = [ssAlt] then begin
        if Key <> 18 then begin
            case Key of
                48: character := $7D; // }
                55: character := $7B; // {
                56: character := $5B; // [
                57: character := $5D; // ]
                81: character := $40; // @
                187: character := $7E; // ~
                219: character := $5C; // \
                226: character := $7D; // |
                else character := $00;
            end; { case Key of }
        end; { if Key<>18 then }
    end; { if Shift=[ssAlt] then }

    if character > $00 then begin
        keyboardBuffer := keyboardBuffer + char(character);
        if (enableLocalEcho) then begin
            writeCharacter(character);
        end;
    end;

end;

// --------------------------------------------------------------------------------
end.




