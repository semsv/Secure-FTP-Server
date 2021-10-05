unit UFTPServ;
{
 Original Author: Sevastyanov Semen
 Date: 14/05/2019
}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPServer, IdFTPServer, IdFTPList,
  Idglobal, UFTPProcessServer, StdCtrls, Mask, Spin, ExtCtrls;

type
  TSecureFtpServer = class(TForm)
    Panel1: TPanel;
    ListBox1: TListBox;
    OpenDialog1: TOpenDialog;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter2: TSplitter;
    Panel4: TPanel;
    Panel5: TPanel;
    Splitter3: TSplitter;
    Panel6: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    BtnStop: TButton;
    Label1: TLabel;
    SpinEdit1: TSpinEdit;
    Button3: TButton;
    Button4: TButton;
    Label2: TLabel;
    Label3: TLabel;
    EditKey: TMaskEdit;
    KeyShape: TShape;
    PathShape: TShape;
    SrvShape: TShape;
    Label4: TLabel;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure OnConnect(Connect : TFTPConnection);
    procedure OnChangeDirectory(var VDirectory: String);
    procedure OnWriteDataEvent( nCount : Longint);
    procedure FormCreate(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SpinEdit1Change(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure EditKeyChange(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    ProcessorServer : TFTPProcessorServer;
    function check_init_server_path (FileName : String) : boolean;
    function check_init_server_work : boolean;
    function check_init_server_key : boolean;
    procedure IdFTPServerXCommandXCRC( ASender: TIdCommand ) ;
  public
    { Public declarations }
    IdFTPServerX    : TIdFTPServer;
    Procedure CloseAllConnection;
    procedure generate_key;
  end;

  var
    SecureFtpServer : TSecureFtpServer;
    VTransferCount  : Int64;
    
implementation

uses UFTPStream, UStrCalculate;

{$R *.dfm}
procedure TSecureFtpServer.OnConnect(Connect : TFTPConnection);
begin
  Listbox1.Items.Add( 'OnConnect: ' + Connect.PeerIP );
  if KeyShape.Brush.Color = cllime then
    Connect.RootPath := ExtractFilePath(ParamStr(0)) + '[VIRTUAL]\'
end;

procedure TSecureFtpServer.OnChangeDirectory(var VDirectory: String);
begin
  Listbox1.Items.Add('ChangeDirectory: ' + '"' + VDirectory + '"');
end;

procedure TSecureFtpServer.OnWriteDataEvent( nCount : Longint);
 var
   Value : Longint;
begin
  VTransferCount := VTransferCount + nCount;
  if (VTransferCount > 10 * 1024) and (VTransferCount <= 10*1024*1024) then
  begin
    Value := Round( VTransferCount / 1024 );
    SecureFtpServer.Panel5.Caption := IntToStr(Value) + ' K';
  end
    else
  if (VTransferCount > 10*1024*1024) and (VTransferCount <= 1*1024*1024*1024) then
  begin
    Value := Round( VTransferCount / 1024 / 1024 );
    SecureFtpServer.Panel5.Caption := IntToStr(Value) + ' MB';
  end else
  if (VTransferCount > 1*1024*1024*1024) then
  begin
    Value := Round( VTransferCount / 1024 / 1024 / 1024 );
    SecureFtpServer.Panel5.Caption := IntToStr(Value) + ' GB';
  end else
  if (VTransferCount > 0) and (VTransferCount <= 10 * 1024) then
  begin
    SecureFtpServer.Panel5.Caption := IntToStr(VTransferCount) + ' B';
  end else
  begin
    VTransferCount := 0;
  end;
end;

  Var
    RootPath      : string;
    vDataPort     : integer;
    vPort         : integer;
    vKeyStr       : string;

procedure TSecureFtpServer.IdFTPServerXCommandXCRC( ASender: TIdCommand ) ;
// note, this is made up, and not defined in any rfc.
var
  s: string;
begin
  with TIdFTPServerThread( ASender.Thread ) do
  begin
    if Authenticated then
    begin
      try
        s := ProcessPath( CurrentDir, ASender.UnparsedParams ) ;
        s := TransLatePath( s, TIdFTPServerThread( ASender.Thread ) .HomeDir ) ;
        ASender.Reply.SetReply( 213, CalculateCRC( s ) ) ;
      except
        ASender.Reply.SetReply( 500, 'file error' ) ;
      end;
    end;
  end;
end;

function TSecureFtpServer.check_init_server_path (FileName : String) : boolean;
  Var
    S : String;
begin
  if Length(S) > 0 then
    if S[Length(S)] <> '\' then
      S := S + '\';
  S := ExtractFilePath( FileName );
  if DirectoryExists( S ) and Assigned(IdFTPServerX)
   then
   begin
     if IdFTPServerX.Active
      then
        PathShape.Brush.Color := cllime else
        PathShape.Brush.Color := clSilver;
   end
   else
   begin
     if not DirectoryExists( S )
      then
        PathShape.Brush.Color := clRed else
        PathShape.Brush.Color := clSilver;
   end;

  result := (PathShape.Brush.Color = cllime);
end;

function TSecureFtpServer.check_init_server_work : boolean;
begin
  if Assigned(IdFTPServerX) then
    if IdFTPServerX.Active
     then
       SrvShape.Brush.Color := cllime
     else
       SrvShape.Brush.Color := clred
    else
      SrvShape.Brush.Color := clSilver;
  result := (SrvShape.Brush.Color = cllime);
end;

procedure TSecureFtpServer.generate_key;
begin
  EditKey.Text := GenerateKey;
end;

function TSecureFtpServer.check_init_server_key : boolean;
begin
  vKeyStr                        := EditKey.text;
  vKeyStr :=                      replace_chr(' ', chr(0), vKeyStr);
  vKeyStr :=                      replace_chr('-', chr(0), vKeyStr);
  if (Length(replace_chr('0', chr(0), vKeyStr)) > 0)  and
     check_controlsum_key(vKeyStr)
   then
     KeyShape.Brush.Color := cllime else
  if Length(vKeyStr) = 0
   then
     KeyShape.Brush.Color := clSilver
   else
     KeyShape.Brush.Color := clRed;
  result := (KeyShape.Brush.Color = cllime);
end;

procedure TSecureFtpServer.Button1Click(Sender: TObject);
begin
  CloseAllConnection;
  if not Assigned(ProcessorServer) then
    ProcessorServer := TFTPProcessorServer.Create(RootPath);
  IdFTPServerX                     := TIdFTPServer.Create(self);
  IdFTPServerX.DefaultDataPort     := vDataPort;
  IdFTPServerX.DefaultPort         := vPort;
{-- begin initializing event handlers --}  
  IdFTPServerX.OnConnect           := ProcessorServer.FTPServerXConnect;
  IdFTPServerX.OnUserLogin         := ProcessorServer.FTPServerXUserLogin;
  IdFTPServerX.OnChangeDirectory   := ProcessorServer.FTPServerXChangeDirectory;
  IdFTPServerX.OnListDirectory     := ProcessorServer.FTPServerXListDirectory;
  IdFTPServerX.OnRetrieveFile      := ProcessorServer.FTPServerXRetrieveFile;
  IdFTPServerX.OnStoreFile         := ProcessorServer.FTPServerXStoreFile;
  IdFTPServerX.OnStatus            := ProcessorServer.FTPServerXStatus;
  IdFTPServerX.OnRenameFile        := ProcessorServer.FTPServerXRenameFile;
  IdFTPServerX.OnMakeDirectory     := ProcessorServer.FTPServerXMakeDirectory;
  IdFTPServerX.OnRemoveDirectory   := ProcessorServer.FTPServerXRemoveDirectory;
  IdFTPServerX.OnDisconnect        := ProcessorServer.FTPServerXDisconnect;
  with IdFTPServerX.CommandHandlers.add do
  begin
    Command := 'XCRC';
    OnCommand := IdFTPServerXCommandXCRC;
  end;
  ProcessorServer.OnConnect         := OnConnect;
  ProcessorServer.OnWriteDataEvent  := OnWriteDataEvent;
  ProcessorServer.OnChangeDirectory := OnChangeDirectory;
{-- end initializing event handlers --}
  check_init_server_path(edit1.Text);
  check_init_server_work;
  check_init_server_key;
  IdFTPServerX.EmulateSystem     := ftpsUNIX;
  IdFTPServerX.Active            := true;
  sleep(1000);
  if IdFTPServerX.Active then
    ListBox1.Items.Add('FTP Server Started On Port: ' + inttostr(vPort) + ' At: ' + TimeToStr(Time) + ' ' + DateToStr( Date ));
  Timer1.Enabled                 := IdFTPServerX.Active;
  Button1.Enabled                := not IdFTPServerX.Active;
  BtnStop.Enabled                := IdFTPServerX.Active;
  check_init_server_work;
  check_init_server_path(edit1.Text);
  check_init_server_key;
end;

procedure TSecureFtpServer.CloseAllConnection;
begin
  Timer1.Enabled := false;
  Application.ProcessMessages;
  sleep(1000);
  Application.ProcessMessages;
  try
    if Assigned(IdFTPServerX) then
    begin
      try
        try
          IdFTPServerX.TerminateWaitTime := 3000;
          if Assigned(ProcessorServer) then
            ProcessorServer.Destroy;
        except
        end;
      finally
        try
          IdFTPServerX.Destroy;
        finally
          IdFTPServerX                   := nil;
          ProcessorServer                := nil;
        end;
      end;
    end;
  except
    on E:Exception do      
      null;
  end;
end;

procedure TSecureFtpServer.BtnStopClick(Sender: TObject);
begin
  try
    CloseAllConnection;
    Application.ProcessMessages;
  finally
    try
      Button1.Enabled     := true;
      Application.ProcessMessages;
    finally
      try
        BtnStop.Enabled     := false;
        Application.ProcessMessages;
      finally
        try
          ListBox1.Items.Add('FTP Server Terminated ' + inttostr(vPort) + ' At: ' + TimeToStr(Time) + ' ' + DateToStr( Date ));
          Application.ProcessMessages;
        finally
          check_init_server_path(edit1.Text);
          check_init_server_work;
          check_init_server_key;
        end;
      end;
    end;  
  end;
end;

procedure TSecureFtpServer.FormCreate(Sender: TObject);
begin
  IdFTPServerX    := nil;
  ProcessorServer := nil;
  RootPath        := edit1.Text;
  if length(RootPath) > 0 then
    if RootPath[length(RootPath)] <> '\' then
      RootPath := RootPath + '\';
  vPort        := SpinEdit1.Value;
  vDataPort    := SpinEdit1.Value-1;
  check_init_server_path(edit1.Text);
end;

procedure TSecureFtpServer.Edit1Change(Sender: TObject);
begin
  RootPath := edit1.Text;
  if length(RootPath) > 0 then
    if RootPath[length(RootPath)] <> '\' then
      RootPath := RootPath + '\';
end;

procedure TSecureFtpServer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 CanClose := true;
 if Assigned(ProcessorServer) then
 begin
   with ProcessorServer.Server.Connections do
     CanClose := (Count = 0);
 end;
end;

procedure TSecureFtpServer.SpinEdit1Change(Sender: TObject);
begin
  if (Length(SpinEdit1.Text) > 0) then
  begin
    vPort     := SpinEdit1.Value;
    vDataPort := SpinEdit1.Value-1;
  end;
end;

procedure TSecureFtpServer.Button3Click(Sender: TObject);
begin
{}
  OpenDialog1.Options := [ofNoValidate];
  OpenDialog1.Filter := '*.*|*.*';
  if not OpenDialog1.Execute then exit;
{}
  edit1.Text := ExtractFilePath( OpenDialog1.FileName );
  check_init_server_path(edit1.Text);
{}
end;

procedure TSecureFtpServer.EditKeyChange(Sender: TObject);
begin
  check_init_server_key;
end;

procedure TSecureFtpServer.Button4Click(Sender: TObject);
begin
  generate_key;
end;

procedure TSecureFtpServer.Timer1Timer(Sender: TObject);
begin
  if Assigned(ProcessorServer) then
  begin
    if Assigned(ProcessorServer.Server) then
    with ProcessorServer.Server do
      Panel4.Caption := 'Кол-во открытых соединений: ' + inttostr(Connections.count);
  end;
end;

end.
