unit UFTPServ;
{
 Original Author: Sevastyanov Semen
 Date: 14/05/2019
}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPServer, IdFTPServer, IdFTPList,
  StdCtrls, Spin, ExtCtrls, Mask;

type
  TSecureFtpServer = class(TForm)
    Panel1: TPanel;
    ListBox1: TListBox;
    IdFTPServer1: TIdFTPServer;
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
    Button2: TButton;
    Label1: TLabel;
    SpinEdit1: TSpinEdit;
    Button3: TButton;
    Button4: TButton;
    Label2: TLabel;
    Label3: TLabel;
    EditKey: TMaskEdit;
    Shape1: TShape;
    PathShape: TShape;
    SrvShape: TShape;
    Label4: TLabel;
    procedure IdFTPServerXListDirectory(ASender: TIdFTPServerThread;
      const APath: String; ADirectoryListing: TIdFTPListItems);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure IdFTPServerXStatus(ASender: TObject;
      const AStatus: TIdStatus; const AStatusText: String);
    procedure IdFTPServerXConnect(AThread: TIdPeerThread);
    procedure IdFTPServerXUserLogin(ASender: TIdFTPServerThread;
      const AUsername, APassword: String; var AAuthenticated: Boolean);
    procedure IdFTPServerXChangeDirectory(ASender: TIdFTPServerThread;
      var VDirectory: String);
    procedure IdFTPServerXStoreFile(ASender: TIdFTPServerThread;
      const AFileName: String; AAppend: Boolean; var VStream: TStream);
    procedure IdFTPServerXRetrieveFile(ASender: TIdFTPServerThread;
      const AFileName: String; var VStream: TStream);
    procedure FormCreate(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure IdFTPServerXDisconnect(AThread: TIdPeerThread);
    procedure SpinEdit1Change(Sender: TObject);
    procedure IdFTPServerXRenameFile(ASender: TIdFTPServerThread;
      const ARenameFromFile, ARenameToFile: String);
    procedure Button3Click(Sender: TObject);
    procedure EditKeyChange(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
    function check_init_server_path (FileName : String) : boolean;
    function check_init_server_work : boolean;
    function check_init_server_key : boolean;
  public
    { Public declarations }
    IdFTPServerX : TIdFTPServer;
    Procedure CloseAllConnection;
    procedure generate_key;
  end;

  var
    SecureFtpServer: TSecureFtpServer;

implementation

uses MaskUtils;
{$R *.dfm}
  Var
    RootPath      : string;
    vConnectCount : integer;
    vDataPort     : integer;
    vPort         : integer;
    vKeyStr       : string;

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

function replace_chr(schr, dchr : CHAR; InStr : String) : String;
  Var
    S : String;
begin
  S := InStr;
  While POS(schr, S) > 0 do
    if dchr = '' then
      delete(S, POS(schr, S), 1)
      else
      S[POS(schr, S)] := dchr;
  result := s;
end;

function check_controlsum_key(vkey : string) : boolean;
  var
    r         : string;
    i         : integer;
    cntrlsum  : DWORD;
    value     : DWORD;
    cmpsumstr : string;
begin
  cntrlsum     := 0;
  r            := copy(replace_chr('-', chr(0), vkey),  1, 4*5);
  cmpsumstr    := copy(replace_chr('-', chr(0), vkey), 21, 1*5);
  result       := false;
  if Length(vkey) <> 25 then exit;
  For I := 1 to 4 do
   begin
     value    := StrToInt(Copy(r, (i-1)*5 + 1, 5));
     cntrlsum := cntrlsum + value xor $AA;
   end;
  result := (Copy(Inttostr(cntrlsum), 1, 5) = cmpsumstr);
end;

procedure TSecureFtpServer.generate_key;
  var
    s        : string;
    r        : string;
    a        : byte;
    i        : integer;
    value    : DWORD;
    cntrlsum : DWORD;
begin
{}
  Randomize;
  for i:= 1 to 4 do
  begin
    a := Random(65535);
    r := inttostr(a);
    r := FormatMaskText('00000', r);
    r := replace_chr(' ', '0', r);
    WHILE (POS('0', r) > 0)
      do r[POS('0', r)] := inttostr(Random(65535))[1];
    s := s + r;
    if I < 4
     then
       s := s + '-';
  end;
  cntrlsum     := 0;
  r            := replace_chr('-', chr(0), s);
  For I := 1 to 4 do
   begin
     value    := StrToInt(Copy(r, (i-1)*5 + 1, 5));
     cntrlsum := cntrlsum + value xor $AA;
   end;
  EditKey.Text := s + '-' + Copy(Inttostr(cntrlsum), 1, 5);
{}
end;


function TSecureFtpServer.check_init_server_key : boolean;
begin
  vKeyStr                        := EditKey.text;
  vKeyStr :=                      replace_chr(' ', chr(0), vKeyStr);
  vKeyStr :=                      replace_chr('-', chr(0), vKeyStr);
  if (Length(replace_chr('0', chr(0), vKeyStr)) > 0)  and
     check_controlsum_key(vKeyStr)
   then
     Shape1.Brush.Color := cllime else
  if Length(vKeyStr) = 0
   then
     Shape1.Brush.Color := clSilver
   else
     Shape1.Brush.Color := clRed;
  result := (Shape1.Brush.Color = cllime);
end;

function encrypt_string(InStr : String) : String;
  Var
    S    : String;
    I    : Integer;
    J, K : Integer;
    KEY  : Byte;
begin
  S      := InStr;
  K      := Length(vKeyStr);
  result := S;
  if K = 0 then exit;
  For I := 1 To Length(InStr) do
  begin
    J    := I MOD K;
    KEY  := ORD(vKeyStr[J + 1]);
    if ((S[I] <> '/') and (S[I] <> '\') and (S[I] <> '.')) then
      begin
        if (ORD(S[I]) XOR KEY = 0)        or (ORD(S[I]) = 0) or
           (ORD(S[I]) XOR KEY = ORD('/')) or (ORD(S[I]) = ORD('/')) or
           (ORD(S[I]) XOR KEY = ORD('\')) or (ORD(S[I]) = ORD('\')) or
           (ORD(S[I]) XOR KEY = ORD('.')) or (ORD(S[I]) = ORD('.')) or
           (ORD(S[I]) XOR KEY = ORD(' ')) or (ORD(S[I]) = ORD(' ')) or
           (ORD(S[I]) XOR KEY = ORD('+')) or (ORD(S[I]) = ORD('+')) or
           (ORD(S[I]) XOR KEY = ORD('-')) or (ORD(S[I]) = ORD('-')) or
           (ORD(S[I]) XOR KEY = ORD('*')) or (ORD(S[I]) = ORD('*')) or
           (ORD(S[I]) XOR KEY = ORD('&')) or (ORD(S[I]) = ORD('&')) or
           (ORD(S[I]) XOR KEY = ORD(':')) or (ORD(S[I]) = ORD(':')) or
           (ORD(S[I]) XOR KEY = ORD(';')) or (ORD(S[I]) = ORD(';')) or
           (ORD(S[I]) XOR KEY = 39)       or (ORD(S[I]) = 39) or
           (ORD(S[I]) XOR KEY = 16)       or (ORD(S[I]) = 16) or
           (ORD(S[I]) XOR KEY = 13)       or (ORD(S[I]) = 13) or
           (ORD(S[I]) XOR KEY = 10)       or (ORD(S[I]) = 10) or
           (ORD(S[I]) XOR KEY = 46)       or (ORD(S[I]) = 46) or
           (ORD(S[I]) XOR KEY = 09)       or (ORD(S[I]) = 09) or
           (LENGTH( CHR( ORD(S[I]) XOR KEY ) ) = 0)
        then
        else
          S[I] := CHR(ORD(S[I]) XOR KEY);
      end;
  end;
  result := S;
end;

function decrypt_string(InStr : String) : String;
begin
  result := encrypt_string( InStr );
end;

function encrypt_foldername(Path : String; InStr : String) : String;
  Var
    S    : String;
begin
  if InStr = '/' then
  begin
    result := InStr;
    exit;
  end;
  S      := encrypt_string( Path + InStr );
  while pos('\', S) > 0 do
   delete(S, 1, pos('\', S));
  while ((pos('/', S) > 0) and (pos('/', S) <> length(S))) do
    delete(S, 1, pos('/', S));
  result := S;
end;

function decrypt_path_dir(VDirectory : String) : string;
  var
    split_path  : string;
    old_split   : string;
    save_str    : string;
    result_path : string;
    curr_path   : string;
begin
  curr_path     := VDirectory;
  split_path    := '';
  while pos('/', curr_path) > 0 do
  begin
    old_split  := split_path;
    split_path := split_path + copy( curr_path, 1, pos('/', curr_path));

    save_str   := split_path;
    delete(save_str, 1, Length(old_split));
    if Length(old_split) > 2 then
      if old_split[1] = '/' then
        delete(old_split, 1, 1);
    old_split  := encrypt_foldername(RootPath + old_split, save_str);
    result_path := result_path + old_split;

    delete( curr_path, 1, pos('/', curr_path));
  end;
  result    := split_path;

  if Length(result_path) > 2 then
    if result_path[1] = '/' then
      delete(result_path, 1, 1);

  result := result_path;
end;

function GetFileSize_Int64(FileName : string) : Int64;
 Var
   hFile : Cardinal;
   LSize : Cardinal;
   HSize : Cardinal;
begin
 result := 0;
 hFile := CreateFile(PChar(FileName),
        GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL, 0);
 if hFile <> INVALID_HANDLE_VALUE then
 begin
   LSize := windows.GetFileSize(hFile, @HSize);
   FileClose(hFile);
   result := LSize + (HSize shl 32);
 end;
end;

procedure TSecureFtpServer.IdFTPServerXListDirectory(ASender: TIdFTPServerThread;
  const APath: String; ADirectoryListing: TIdFTPListItems);

  procedure AddlistItem( aDirectoryListing: TIdFTPListItems; Filename: string; ItemType: TIdDirItemType; size: int64; date: tdatetime ) ;
  var
    listitem: TIdFTPListItem;
  begin
    listitem := aDirectoryListing.Add;
    listitem.ItemType         := ItemType;
    listitem.FileName         := Filename;
    listitem.OwnerName        := 'anonymous';
    listitem.GroupName        := 'all';
    listitem.OwnerPermissions := 'rwx';
    listitem.GroupPermissions := 'rwx';
    listitem.UserPermissions  := 'rwx';
    listitem.Size             := size;
    listitem.ModifiedDate     := date;
  end;

  var 
    F              : TSearchRec;
    res            : integer;
    curr_path      : string;
    fsize          : INT64;
    fname          : string;
begin
  Listbox1.Items.Add('ListDirectory: ' +  APath);
  ADirectoryListing.Clear;

    curr_path := decrypt_path_dir(APath);
    SecureFtpServer.ListBox1.Items.Add( 'List Directory: ' + RootPath + curr_path + '*' );

    res := FindFirst(RootPath + curr_path + '*', faDirectory, F);
    while res = 0 do
      begin
        if ((f.attr and faDirectory) = faDirectory) and
            (F.Name <> '.') and
            (F.Name <> '..') then
        begin
          fname := encrypt_foldername(RootPath + curr_path, F.Name);
          fsize := GetFileSize_Int64(TranslatePath(curr_path + F.Name, RootPath));
          AddlistItem( ADirectoryListing, fname, ditDirectory, fsize, FileDateToDateTime( f.Time ) );
        end;
        res := FindNext(F);
      end;

     res := FindFirst(RootPath + curr_path + '*', faAnyFile, F);
     while res = 0 do
     begin
       if ((f.attr and faDirectory) <> faDirectory) and
          (F.Name <> '.') and
          (F.Name <> '..') then
         begin
           fname := encrypt_string(F.Name);
           fsize := GetFileSize_Int64(TranslatePath(curr_path + F.Name, RootPath));
           AddlistItem( ADirectoryListing, fname, ditFile, fsize, FileDateToDateTime( f.Time ) );
         end;
       res := FindNext(F);
     end;

end;

procedure TSecureFtpServer.Button1Click(Sender: TObject);
begin
  CloseAllConnection;
  IdFTPServerX := TIdFTPServer.Create(self);
  IdFTPServerX.DefaultDataPort   := vDataPort;
  IdFTPServerX.DefaultPort       := vPort;
  IdFTPServerX.OnConnect         := IdFTPServerXConnect;
  IdFTPServerX.OnUserLogin       := IdFTPServerXUserLogin;
  IdFTPServerX.OnChangeDirectory := IdFTPServerXChangeDirectory;
  IdFTPServerX.OnListDirectory   := IdFTPServerXListDirectory;
  IdFTPServerX.OnRetrieveFile    := IdFTPServerXRetrieveFile;
  IdFTPServerX.OnStoreFile       := IdFTPServerXStoreFile;
  IdFTPServerX.OnStatus          := IdFTPServerXStatus;
  IdFTPServerX.OnRenameFile      := IdFTPServerXRenameFile;
  check_init_server_path(edit1.Text);
  check_init_server_work;
  check_init_server_key;
  IdFTPServerX.Active            := true;
  sleep(1000);
  if IdFTPServerX.Active then
    ListBox1.Items.Add('FTP Server Started On Port: ' + inttostr(vPort) + ' At: ' + TimeToStr(Time) + ' ' + DateToStr( Date ));
  Button1.Enabled                := not IdFTPServerX.Active;
  Button2.Enabled                := IdFTPServerX.Active;
  check_init_server_work;
  check_init_server_path(edit1.Text);
  check_init_server_key;
end;

procedure TSecureFtpServer.CloseAllConnection;
 var
   a : integer;
begin
  try
    if Assigned(IdFTPServerX) then
    begin
      IdFTPServerX.TerminateWaitTime := 5000;
      IdFTPServerX.Active := false;
      Application.ProcessMessages;
      a := 10;
      sleep(a);
      while (IdFTPServerX.Active and (a <= 5000))
      do
       begin
         Application.ProcessMessages;
         sleep(100);
         Application.ProcessMessages;
         a := a + 100; // Protected to suspension's
       end;
      IdFTPServerX        := nil;
    end;
  except
    
  end;
end;

procedure TSecureFtpServer.Button2Click(Sender: TObject);
begin
  CloseAllConnection;
  Button1.Enabled     := true;
  Button2.Enabled     := false;
  vConnectCount       := 0;
  ListBox1.Items.Add('FTP Server Terminated ' + inttostr(vPort) + ' At: ' + TimeToStr(Time) + ' ' + DateToStr( Date ));
  check_init_server_path(edit1.Text);
  check_init_server_work;
  check_init_server_key;
end;

procedure TSecureFtpServer.IdFTPServerXStatus(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: String);
begin
  Listbox1.Items.Add( 'OnStatus: '  + '[' + IdStati[AStatus] + ']' + AStatusText );
end;

procedure TSecureFtpServer.IdFTPServerXConnect(AThread: TIdPeerThread);
begin
  Listbox1.Items.Add( 'OnConnect: ' +   AThread.Connection.Socket.SocksInfo.LocalName );
end;

procedure TSecureFtpServer.IdFTPServerXUserLogin(ASender: TIdFTPServerThread;
  const AUsername, APassword: String; var AAuthenticated: Boolean);
begin
  Listbox1.Items.Add('UserName: ' + '"' + AUsername + '"' + '; APassword: ' + '"' + APassword + '"');
  AAuthenticated := true;
  vConnectCount := vConnectCount + 1;
end;

procedure TSecureFtpServer.IdFTPServerXChangeDirectory(ASender: TIdFTPServerThread;
  var VDirectory: String);
  var curr_path : string;
begin
  curr_path := VDirectory;
  while pos('\', curr_path) > 0 do
   delete(curr_path, 1, pos('\', curr_path));
  VDirectory := curr_path;
  Listbox1.Items.Add('ChangeDirectory: ' + '"' + decrypt_path_dir( curr_path ) + '"' + '; UserName: ' + '"' + ASender.Username + '"');
end;

procedure TSecureFtpServer.IdFTPServerXStoreFile(ASender: TIdFTPServerThread;
  const AFileName: String; AAppend: Boolean; var VStream: TStream);
begin
  Listbox1.Items.Add('StoreFile: ' + '"' + AFileName + '"');
end;

procedure TSecureFtpServer.IdFTPServerXRetrieveFile(ASender: TIdFTPServerThread;
  const AFileName: String; var VStream: TStream);
  var FileStream : TFileStream;
  var
   path_dir  : string;
   vLocFileN : string;
begin
  path_dir  := decrypt_path_dir( AFileName );
  vLocFileN := AFileName;
  while ((pos('/', vLocFileN) > 0) and (pos('/', vLocFileN) <> length(vLocFileN))) do
    delete(vLocFileN, 1, pos('/', vLocFileN));
  vLocFileN := path_dir + decrypt_string( vLocFileN );

  Listbox1.Items.Add('RetrieveFile: ' + RootPath +  vLocFileN );
  FileStream := TFileStream.Create(RootPath + vLocFileN, fmopenread or fmShareDenyWrite);
  VStream    := FileStream;
end;

procedure TSecureFtpServer.FormCreate(Sender: TObject);
begin
  IdFTPServerX := nil;
  RootPath := edit1.Text;
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
 CanClose := (vConnectCount = 0);
end;

procedure TSecureFtpServer.IdFTPServerXDisconnect(AThread: TIdPeerThread);
begin
  vConnectCount := vConnectCount - 1;
end;

procedure TSecureFtpServer.SpinEdit1Change(Sender: TObject);
begin
  if (Length(SpinEdit1.Text) > 0) then
  begin
    vPort     := SpinEdit1.Value;
    vDataPort := SpinEdit1.Value-1;
  end;
end;

procedure TSecureFtpServer.IdFTPServerXRenameFile(ASender: TIdFTPServerThread;
  const ARenameFromFile, ARenameToFile: String);
begin
 {}
 Listbox1.Items.Add( 'RenameFile: ' + 'From: "' + ARenameFromFile + '" To: "' + ARenameToFile + '"');
 RenameFile(RootPath + ARenameFromFile, RootPath + ARenameToFile);
 {}
end;

procedure TSecureFtpServer.Button3Click(Sender: TObject);
begin
{}
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

end.
