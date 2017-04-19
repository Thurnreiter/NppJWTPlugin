unit Nathan.Npp.Plugin;

interface

uses
  System.SysUtils,
  System.Classes,
  //  System.AnsiStrings,
  SciSupport,
  npptypes,
  //  Vcl.Dialogs,
  Vcl.Forms,
  Winapi.Windows,
  Winapi.Messages;

type
  /// <summary>
  ///   TNppPlugin basic class for all derived plugin classes.
  /// </summary>
  TNppPlugin = class
  strict private
    FNppBindingToolbarCommndId: Integer;
  private
    FuncArray: array of _TFuncItem;
    FNppData: TNppData;
    FPluginName: nppString;

    property NppData: TNppData read FNppData;

    procedure DoNppnToolbarModification();
    procedure DoNppnShutdown; virtual;
  protected
    function GetAllTextFromCurrentTab(): string;
    function GetSelectedTextFromCurrentTab(): string;
    procedure ReplaceSelectedTextFromCurrentTab(const NewAnsiValue: AnsiString);

    function GetNppDataHandle(): HWND;
    function GetNppDataScintillaMainHandle(): HWND;

    //  Many functions require NPP character set translation to ansi string...
    //    function GetString(const pMsg: UInt; const pSize: integer = 1000): AnsiString;

    //    function GetPluginsConfigDir(): string;
    //    function GetSourceFilename(): string;
    //    function GetSourceFilenameNoPath(): string;

    /// <summary>
    ///   Add a new menu function to the plugin...
    /// </summary>
    procedure AddFunction(
      Name: nppstring;
      const Func: PFUNCPLUGINCMD = nil;
      const ShortcutKey: Char = #0;
      const Shift: TShiftState = []);

    procedure SetToolbarIcon(out ToolbarIcon: TToolbarIcons); virtual;
  public
    constructor Create(); reintroduce; virtual;
    destructor Destroy(); override;
    procedure BeforeDestruction; override;

    {$REGION 'DLL'}
      //  The next methods are needed for DLL export...
    {$ENDREGION}
    function GetName(): nppPChar;
    function GetFuncsArray(var FuncsCount: Integer): Pointer;
    procedure SetInfo(pNppData: TNppData); virtual;
    procedure BeNotified(sn: PSCNotification);
    procedure MessageProc(var Msg: TMessage); virtual;

    function CmdIdFromDlgId(DlgId: Integer): Integer;

    {$REGION 'Messages'}
      //  Wrapper for SendMessage function...
    {$ENDREGION}
    function SendMessageToNpp(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
    function SendMessageWToNpp(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
    function SendMessageToNppScintilla(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
    function IsMessageForPlugin(const PluginWnd: HWND): Boolean;

    //  Need it later...
    //  function DoOpen(filename: String): boolean; overload;
    //  function DoOpen(filename: String; Line: Integer): boolean; overload;
    //  procedure GetFileLine(var filename: String; var Line: Integer);
    //  function GetWord(): string;

    property PluginName: nppString read FPluginName write FPluginName;
    property NppDataHandle: HWND read GetNppDataHandle;
    property NppDataScintillaMainHandle: HWND read GetNppDataScintillaMainHandle;
    property NppBindingToolbarCommndId: Integer read FNppBindingToolbarCommndId write FNppBindingToolbarCommndId;
  end;

  /// <summary>
  ///   "Class of" for my next factory.
  /// </summary>
  TNppPLuginClass = class of TNppPlugin;

  /// <summary>
  ///   Are an interpretation of singelton pattern...
  /// </summary>
  TNathanGlobalNppPlugin = record
  strict private
    class var FInstance: TNPPPlugin;
  public
    class procedure ObtainNppPLugin(const PluginClass: TNppPLuginClass); static;

    class property Instance: TNPPPlugin read FInstance;
  end;


  {$REGION 'Global'}
  //  Global functions need it to set up the plugin for Notepad++...
  {$ENDREGION}
  function GetNppPluginInstance: TNPPPlugin;
  procedure NppRegister(const PluginClass: TNppPLuginClass);
  procedure DLLEntryPoint(dwReason: DWord);

  {$REGION 'DLL Export'}
  //  Now it is follow DLL exported functions. Importent use cdecl and export declaration...
  //  Be careful with renaming etc.
  {$ENDREGION}
  procedure setInfo(NppData: TNppData); cdecl; export;
  procedure beNotified(sn: PSCNotification); cdecl; export;

  function getName(): nppPchar; cdecl; export;
  function getFuncsArray(var nFuncs:integer): Pointer; cdecl; export;
  function messageProc(msg: Integer; _wParam: WPARAM; _lParam: LPARAM): LRESULT; cdecl; export;

  function isUnicode: Boolean; cdecl; export; {$IFDEF NPPUNICODE}{$ENDIF}

implementation

uses
  System.UITypes;

{ **************************************************************************** }

{ TNathanGlobalNppPlugin }

{ Handle to the plugin instance ('singleton') }

class procedure TNathanGlobalNppPlugin.ObtainNppPLugin(const PluginClass: TNppPLuginClass);
begin
  if (not Assigned(PluginClass)) then
    raise Exception.Create('TNppPLuginClass are undefined');

  if (not Assigned(FInstance)) then
    FInstance := PluginClass.Create;
end;



{ **************************************************************************** }

function GetNppPluginInstance(): TNPPPlugin;
begin
  Result := TNathanGlobalNppPlugin.Instance;
end;

procedure NppRegister(const PluginClass: TNppPLuginClass);
begin
  DllProc := @DLLEntryPoint;  //  Dll_Process_Detach_Hook := @DLLEntryPoint;
  TNathanGlobalNppPlugin.ObtainNppPLugin(PluginClass);
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end;

procedure setInfo(NppData: TNppData); cdecl; export;
begin
  TNathanGlobalNppPlugin.Instance.SetInfo(NppData);
end;

function getName(): nppPchar; cdecl; export;
begin
  /// <summary>
  ///   Name des Plugin Notepad++ weitergeben. Wird dann im Menü angezeigt...
  /// </summary>
  Result := TNathanGlobalNppPlugin.Instance.GetName();
end;

function getFuncsArray(var nFuncs: Integer): Pointer; cdecl; export;
begin
  Result := TNathanGlobalNppPlugin.Instance.GetFuncsArray(nFuncs);
end;

procedure beNotified(sn: PSCNotification); cdecl; export;
begin
  TNathanGlobalNppPlugin.Instance.BeNotified(sn);
end;

function messageProc(msg: Integer; _wParam: WPARAM; _lParam: LPARAM): LRESULT; cdecl; export;
var
  xmsg: TMessage;
begin
  /// <summary>
  ///   Windows Message weiterreichen an die Basisklasse...
  /// </summary>
  xmsg.Msg := msg;
  xmsg.WParam := _wParam;
  xmsg.LParam := _lParam;
  xmsg.Result := 0;

  TNathanGlobalNppPlugin.Instance.MessageProc(xmsg);

  Result := xmsg.Result;

  //  Another option?
  //  Result := 0;
end;

function isUnicode: Boolean; cdecl; export; {$IFDEF NPPUNICODE}{$ENDIF}
begin
  /// <summary>
  ///   Notepad++ Plugin Unicode (True) or Ansi (False)...
  /// </summary>
  Result := True;
end;

procedure DLLEntryPoint(dwReason: DWord);
begin
  case dwReason of
    DLL_PROCESS_ATTACH:
      begin
        //  Create the main plugin object etc. class, when you need it here...
        //  Npp := TDbgpNppPlugin.Create;
      end;

    DLL_PROCESS_DETACH:
      begin
        TNathanGlobalNppPlugin.Instance.Destroy;
      end;

    DLL_THREAD_ATTACH: MessageBeep(0);

    DLL_THREAD_DETACH: MessageBeep(0);
  end;
end;

{ **************************************************************************** }

{ TNppPlugin }

constructor TNppPlugin.Create();
begin
  inherited;
  PluginName := '<unknown>';
  FNppBindingToolbarCommndId := 1;
end;

procedure TNppPlugin.BeforeDestruction();
begin
//  Application.Handle := 0;
  Application.Terminate;
  inherited;
end;

destructor TNppPlugin.Destroy();
var
  Idx: Integer;
begin
  for Idx := 0 to Length(FuncArray) - 1 do
  begin
    if Assigned(FuncArray[Idx].ShortcutKey) then
      Dispose(FuncArray[Idx].ShortcutKey);
  end;

  inherited;
end;

procedure TNppPlugin.DoNppnShutdown();
begin
  //  override these, if necessary...
end;

procedure TNppPlugin.DoNppnToolbarModification();
var
  tb: TToolbarIcons;
begin
  tb.ToolbarIcon := 0;
  tb.ToolbarBmp := 0;
  SetToolbarIcon(tb);
  if (tb.ToolbarBmp <> 0) or (tb.ToolbarIcon <> 0) then
//    SendMessageToNpp(NPPM_ADDTOOLBARICON, WPARAM(CmdIdFromDlgId(1)), LPARAM(@tb));
    SendMessageToNpp(NPPM_ADDTOOLBARICON, WPARAM(CmdIdFromDlgId(FNppBindingToolbarCommndId)), LPARAM(@tb));
end;

function TNppPlugin.GetName(): nppPChar;
begin
  Result := nppPChar(PluginName);
end;

function TNppPlugin.GetFuncsArray(var FuncsCount: Integer): Pointer;
begin
  FuncsCount := Length(FuncArray);
  Result := FuncArray;
end;

procedure TNppPlugin.SetInfo(pNppData: TNppData);
begin
  FNppData := pNppData;
end;

procedure TNppPlugin.BeNotified(sn: PSCNotification);
  //var
  //  MsgFrom: THandle;
  //  Clear: Boolean;
begin
  //  Message for my plugin?
  if HWND(sn^.nmhdr.hwndFrom) = NppData.NppHandle then
  begin
    case sn^.nmhdr.code of
      NPPN_TB_MODIFICATION: DoNppnToolbarModification;
      NPPN_SHUTDOWN       : DoNppnShutdown;
    end;
  end;

  //  Another option...
  //  MsgFrom := THandle(Msg.nmhdr.hwndFrom);
  //  Clear := ((MsgFrom = Handles.ScintillaMain) and (Msg.nmhdr.code = SCI_GETCURRENTPOS))
  //        or ((MsgFrom = Handles.Npp) and (Msg.nmhdr.code = NPPN_BUFFERACTIVATED));
  //
  //  if Clear then
  //    NotifyDocChanged
end;

procedure TNppPlugin.MessageProc(var Msg: TMessage);
var
  hm: HMENU;
  Idx: integer;
begin
  if (Msg.Msg = WM_CREATE) then
  begin
    //  Change - to separator items...
    hm := GetMenu(NppData.NppHandle);
    for Idx := 0 to Length(FuncArray) - 1 do
    begin
      if (FuncArray[Idx].ItemName[0] = '-') then
      begin
        ModifyMenu(hm, FuncArray[Idx].CmdID, MF_BYCOMMAND or MF_SEPARATOR, 0, nil);
      end;
    end;
  end;

  Dispatch(Msg);
end;





procedure TNppPlugin.ReplaceSelectedTextFromCurrentTab(const NewAnsiValue: AnsiString);
var
  SelectionTextLength: Integer;
  ResultAnswer: AnsiString;
  Buf: Array of Byte;
begin
  SelectionTextLength := SendMessage(FNppData.ScintillaMainHandle, SCI_GETSELTEXT, 0, 0) + 1;
  if (SelectionTextLength = 2) then
    Exit;

  SetLength(Buf, SelectionTextLength + 1);
  SendMessage(FNppData.ScintillaMainHandle, SCI_GETSELTEXT, Length(Buf), LPARAM(PAnsiChar(Buf)));
  ResultAnswer := Copy(PAnsiChar(Buf), 0, SelectionTextLength);

  SendMessageToNppScintilla(SCI_REPLACESEL, 0, LPARAM(PAnsiChar(NewAnsiValue)));
end;

function TNppPlugin.GetAllTextFromCurrentTab(): string;
var
  TextLength: Integer;
  Buf: Array of Byte;
begin
  TextLength := SendMessage(FNppData.ScintillaMainHandle, SCI_GETTEXTLENGTH, 0, 0);
  if (TextLength > 0) then
  begin
    SetLength(Buf, TextLength + 1);
    SendMessage(FNppData.ScintillaMainHandle, SCI_GETTEXT, Length(Buf), LPARAM(PAnsiChar(Buf)));
    Result := string(Copy(PAnsiChar(Buf), 0, TextLength));
  end
  else
    Result := '';
end;

function TNppPlugin.GetSelectedTextFromCurrentTab(): string;
var
  SelectionTextLength: Integer;
  ResultAnswer: AnsiString;
  Buf: Array of Byte;
begin
  SelectionTextLength := SendMessage(FNppData.ScintillaMainHandle, SCI_GETSELTEXT, 0, 0) + 1;
  if (SelectionTextLength > 0) then
  begin
    SetLength(Buf, SelectionTextLength + 1);
    SendMessage(FNppData.ScintillaMainHandle, SCI_GETSELTEXT, Length(Buf), LPARAM(PAnsiChar(Buf)));
    ResultAnswer := Copy(PAnsiChar(Buf), 0, SelectionTextLength);
    Result := string(ResultAnswer);
  end
  else
    Result := '';
end;

function TNppPlugin.GetNppDataHandle(): HWND;
begin
  Result := FNppData.NppHandle;
end;

function TNppPlugin.GetNppDataScintillaMainHandle(): HWND;
begin
  Result := FNppData.ScintillaMainHandle;
end;

procedure TNppPlugin.AddFunction(
  Name: nppString;
  const Func: PFUNCPLUGINCMD;
  const ShortcutKey: Char;
  const Shift: TShiftState);
var
  NF: _TFuncItem;
begin
  //  Set up the new function...
  FillChar(NF, SizeOf(NF), 0);

  StrLCopy(NF.ItemName, PChar(Name), FuncItemNameLen);

  NF.Func := Func;

  if (ShortcutKey <> #0) then
  begin
    New(NF.ShortcutKey);
    NF.ShortcutKey.IsCtrl := ssCtrl in Shift;
    NF.ShortcutKey.IsAlt := ssAlt in Shift;
    NF.ShortcutKey.IsShift := ssShift in Shift;
    NF.ShortcutKey.Key := vkF12;
    //  NF.ShortcutKey.Key := ShortcutKey; // need widechar ??
    //  VK_F12  Windows...
    //  NF.ShortcutKey.Key := VK_F12; // use Byte('A') for VK_A-Z
  end;

  //  Add the new function to the my function list...
  SetLength(FuncArray, Length(FuncArray) + 1);
  FuncArray[Length(FuncArray) - 1] := NF;   // Zero-based so -1


  //  Preferred
  //  // Set up the new function
  //  FillChar(NF, SizeOf(NF), 0);
  //
  //  {$IFDEF NPPUNICODE}
  //    StringToWideChar(Name, NF.ItemName, FuncItemNameLen); // @todo: change to constant
  //  {$ELSE}
  //    StrCopy(NF.ItemName, PChar(Name));
  //  {$ENDIF}
  //
  //  NF.Func := Func;
  //
  //  if (ShortcutKey <> #0) then
  //  begin
  //    New(NF.ShortcutKey);
  //    NF.ShortcutKey.IsCtrl := ssCtrl in Shift;
  //    NF.ShortcutKey.IsAlt := ssAlt in Shift;
  //    NF.ShortcutKey.IsShift := ssShift in Shift;
  //    NF.ShortcutKey.Key := ShortcutKey; // need widechar ??
  //  end;
  //
  //  // Add the new function to the list
  //  SetLength(FuncArray, Length(FuncArray) + 1);
  //  FuncArray[Length(FuncArray) - 1] := NF;   // Zero-based so -1


  //  Another option...
  //  LaunchKey.IsCtrl := True;
  //  LaunchKey.IsAlt := False;
  //  LaunchKey.IsShift := False;
  //  LaunchKey.Key := VK_F12; // use Byte('A') for VK_A-Z
  //
  //
  //  SetLength(Functions, 1);
  //  Functions[0].ItemName := 'Launch';
  //  Functions[0].Func := CallLaunchRegExHelper;
  //  Functions[0].CmdID := 0;
  //  Functions[0].Checked := False;
  //  Functions[0].ShortcutKey := @LaunchKey;
  //
  //  Result :=  @Functions[0];
  //  ArrayLength := Length(Functions);

end;

procedure TNppPlugin.SetToolbarIcon(out ToolbarIcon: TToolbarIcons);
begin
  // To be overridden for customization
end;





function TNppPlugin.CmdIdFromDlgId(DlgId: Integer): Integer;
begin
  Result := FuncArray[DlgId].CmdId;
end;


function TNppPlugin.SendMessageToNpp(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  Result := SendMessage(NppData.NppHandle, Msg, wParam, lParam);
end;

function TNppPlugin.SendMessageWToNpp(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  Result := SendMessageW(NppData.NppHandle, Msg, wParam, lParam);
end;

function TNppPlugin.SendMessageToNppScintilla(Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  Result := SendMessage(NppData.ScintillaMainHandle, Msg, wParam, lParam);
end;

function TNppPlugin.IsMessageForPlugin(const PluginWnd: HWND): Boolean;
begin
  Result := (PluginWnd = NppData.NppHandle);
end;

{$REGION 'More Samples'}
//function TNppPlugin.GetString(const pMsg: UInt; const pSize: integer): AnsiString;
//var
////  Answer: AnsiString;
//  Answer: string;
//begin
//  // overrides
//  SetLength(Answer, pSize + 1);
//  SendMessageToNpp(pMsg, pSize, LPARAM(PChar(Answer)));
////  {$IFDEF NPPUNICODE}
////    Result := WideCharToString(PWideChar(Answer));
////  {$ELSE}
////    {$WARNING Untested code with ANSI Version of NPP plugin }
//    Result := Answer; // Untested so far; wild guess......
////  {$ENDIF}
//end;
//
//function TNppPlugin.GetPluginsConfigDir(): string;
//begin
//  Result := GetString(NPPM_GETPLUGINSCONFIGDIR);
//end;
//
//function TNppPlugin.GetSourceFilename(): string;
//begin
//  Result := GetString(NPPM_GETFULLCURRENTPATH)
//end;
//
//function TNppPlugin.GetSourceFilenameNoPath(): string;
//begin
//  Result := GetString(NPPM_GETFILENAME);
//end;


//function TNppPlugin.DoOpen(filename: string): boolean;
//var
//  MyText: string;
//begin
//  // ask if we are not already opened
//  SetLength(MyText, 500);
//  SendMessageToNpp(NPPM_GETFULLCURRENTPATH, 0, LPARAM(PChar(MyText)));
//  SetString(MyText, PChar(MyText), strlen(PChar(MyText)));
//  Result := true;
//  if (MyText = filename) then
//    Exit(False);
//
//  Result := SendMessageToNpp(WM_DOOPEN, 0, LPARAM(PChar(filename))) = 0;
//end;
//
//function TNppPlugin.DoOpen(filename: String; Line: Integer): boolean;
//begin
//  Result := DoOpen(filename);
//  if result then
//    SendMessageToNppScintilla(SciSupport.SCI_GOTOLINE, Line, 0);
//end;
//
//procedure TNppPlugin.GetFileLine(var filename: string; var Line: Integer);
//var
//  MyText: string;
//  Res: Integer;
//begin
//  MyText := '';
//  SetLength(MyText, 300);
//  SendMessageToNpp(NPPM_GETFULLCURRENTPATH,0, LPARAM(PChar(MyText)));
//  SetLength(MyText, StrLen(PChar(MyText)));
//  filename := MyText;
//  Res := SendMessageToNppScintilla(SciSupport.SCI_GETCURRENTPOS, 0, 0);
//  Line := SendMessagetoNppScintilla(SciSupport.SCI_LINEFROMPOSITION, Res, 0);
//end;
//
//function TNppPlugin.GetWord(): string;
//begin
//  Result := GetString(NPPM_GETCURRENTWORD, 800);
//end;
{$ENDREGION}

end.

