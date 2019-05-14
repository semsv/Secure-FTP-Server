unit UFTPServ;
{
 Original Author: Sevastyanov Semen
 Date: 14/05/2019
}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPServer, IdFTPServer, IdFTPList,
  StdCtrls, Spin;

type
  TSecureFtpServer = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ListBox1: TListBox;
    Edit1: TEdit;
    SpinEdit1: TSpinEdit;
    Label1: TLabel;
    IdFTPServer1: TIdFTPServer;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    EditKey: TEdit;
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
  private
    { Private declarations }
  public
    { Public declarations }
    IdFTPServerX : TIdFTPServer;
  end;

  var
    SecureFtpServer: TSecureFtpServer;

implementation
{$R *.dfm}
  Var
    RootPath      : string;
    vConnectCount : integer;
    vDataPort     : integer;
    vPort         : integer;
    vKeyStr       : string;

function replace_chr(schr, dchr : CHAR; InStr : String) : String;
  Var
    S : String;
begin
  S := InStr;
  While POS(schr, S) > 0 do
    S[POS(schr, S)] := dchr;
  result := s;
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
           (ORD(S[I]) XOR KEY = 10)       or (ORD(S[I]) = 10)
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

procedure TSecureFtpServer.IdFTPServerXListDirectory(ASender: TIdFTPServerThread;
  const APath: String; ADirectoryListing: TIdFTPListItems);
  var
    Item           : TIdFTPListItem;
    F              : TSearchRec;
    res            : integer;
    curr_path      : string;
begin
  Listbox1.Items.Add('ListDirectory: ' +  APath);
  ADirectoryListing.Clear;
  if APath = '\' then
  begin
    res := FindFirst(RootPath + '*', faDirectory, F);
     while res = 0 do
     begin
       if (f.attr and faDirectory) = faDirectory then
         begin
           Item              := ADirectoryListing.Add;
           Item.Size         := F.Size;
           Item.ModifiedDate := FileDateToDateTime(F.Time);
           Item.FileName     := encrypt_string(F.Name);
           Item.ItemType     := ditDirectory;
         end;
       res := FindNext(F);
     end;

     res := FindFirst(RootPath + '*', faAnyFile, F);
     while res = 0 do
     begin
       if ((f.attr and faDirectory) <> faDirectory) and
          (F.Name <> '.') and
          (F.Name <> '..') then
         begin
           Item              := ADirectoryListing.Add;
           Item.FileName     := encrypt_string(F.Name);
           Item.Size         := F.Size;
           Item.ModifiedDate := FileDateToDateTime(F.Time);
           Item.ItemType     := ditFile;
         end;
       res := FindNext(F);
     end;
  end else
  begin
    curr_path := decrypt_path_dir(APath);
    SecureFtpServer.Caption := replace_chr('/', '\', RootPath + curr_path + '*');

    res := FindFirst(RootPath + curr_path + '*', faDirectory, F);
    while res = 0 do
      begin
        if ((f.attr and faDirectory) = faDirectory) and
            (F.Name <> '.') and
            (F.Name <> '..') then
        begin
          Item := ADirectoryListing.Add;
          Item.Size     := F.Size;
          Item.FileName := encrypt_foldername(RootPath + curr_path, F.Name);
          Item.ModifiedDate := FileDateToDateTime(F.Time);
          Item.ItemType := ditDirectory;
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
           Item := ADirectoryListing.Add;
           Item.FileName     := encrypt_string(F.Name);
           Item.Size         := F.Size;
           Item.ModifiedDate := FileDateToDateTime(F.Time);
           Item.ItemType     := ditFile;
         end;
       res := FindNext(F);
     end;

  end;
end;

procedure TSecureFtpServer.Button1Click(Sender: TObject);
begin
  if Assigned(IdFTPServerX) then
  begin
    IdFTPServerX.Active := false;
    Application.ProcessMessages;
    IdFTPServerX := nil;
  end;
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
  vKeyStr                        := EditKey.text;
  IdFTPServerX.Active := true;
  Button1.Enabled     := not IdFTPServerX.Active;
  Button2.Enabled     := IdFTPServerX.Active;
end;

procedure TSecureFtpServer.Button2Click(Sender: TObject);
begin
  if Assigned(IdFTPServerX) then
  begin
    IdFTPServerX.Active := false;
    Application.ProcessMessages;
    IdFTPServerX        := nil;
  end;
  Button1.Enabled     := true;
  Button2.Enabled     := false;
  vConnectCount       := 0;
end;

procedure TSecureFtpServer.IdFTPServerXStatus(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: String);
begin
  SecureFtpServer.Caption :=  AStatusText;
  Listbox1.Items.Add( 'OnStatus: '  + '[' + IdStati[AStatus] + ']' + AStatusText );
end;

procedure TSecureFtpServer.IdFTPServerXConnect(AThread: TIdPeerThread);
begin
  SecureFtpServer.Caption := 'OnConnect';
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
  vLocFileN := path_dir + encrypt_string( vLocFileN );

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
  edit1.Text := ExtractFilePath( OpenDialog1.FileName );
{}
end;

end.
