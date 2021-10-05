unit UFTPProcessServer;

interface
  uses IdFTPServer, IdTCPServer, IdFTPList, IdComponent, sysutils, classes, UStrCalculate, UFTPStream;

  type
    TFTPConnection = class
    private
      FIndex     : integer;
      FPeerIP    : string;
      FPeerPort  : integer;
      FLocalIP   : string;
      FLocalPort : integer;
      FRootPath  : string;
      FUserLogin : Boolean;
      FAThread   : TIdPeerThread;
    public
      property Index     : Integer read FIndex;
      property PeerIP    : string read FPeerIP;
      property PeerPort  : integer read FPeerPort;
      property LocalIP   : string read FLocalIP;
      property LocalPort : integer read FLocalPort;
      property UserLogin : boolean read FUserLogin;
      property RootPath  : string read FRootPath write FRootPath;
    end;

    TCustomListConnection = class
    private
      FTPConnect : Array of TFTPConnection;
      FCount     : Integer;
    public
      function  GetItm( Index : integer ) : TFTPConnection; virtual;
      procedure SetItm( Index : integer; Value: TFTPConnection ); virtual;
      procedure Delete( Index : integer ); virtual;
      function  Count    : integer; virtual;
      procedure Add;             virtual; abstract;
      procedure Clear;           virtual; abstract;
      function  Index    : integer; virtual; abstract;
      property Items [Index: Integer] : TFTPConnection read GetItm write SetItm;
    end;

    TFTPListConnection = class(TCustomListConnection)
    public
      procedure Add;                override;
      procedure Clear;              override;
      function  Index    : integer; override;
      procedure UpdateList; virtual;
      function  Select(PeerIP : string; PeerPort  : integer) : TFTPConnection;
    end;

    TFTPConnections = class
    private
      FConnections : TFTPListConnection;
    public
      constructor Create; virtual;
      destructor Destroy; override;
      property Connections : TFTPListConnection read FConnections write FConnections;
    end;

    TFTPProcessor = class
    protected
      constructor Create(RootPath : String); virtual; abstract;
      procedure FTPServerXConnect(AThread: TIdPeerThread); virtual; abstract;
      procedure FTPServerXDisconnect(AThread: TIdPeerThread); virtual; abstract;
      procedure FTPServerXUserLogin(ASender: TIdFTPServerThread; const AUsername, APassword: String; var AAuthenticated: Boolean);  virtual; abstract;
      procedure FTPServerXListDirectory(ASender: TIdFTPServerThread; const APath: String; ADirectoryListing: TIdFTPListItems); virtual; abstract;
      procedure FTPServerXRenameFile(ASender: TIdFTPServerThread; const ARenameFromFile, ARenameToFile: String); virtual; abstract;
      procedure FTPServerXMakeDirectory(ASender: TIdFTPServerThread; var VDirectory: string);  virtual; abstract;
      procedure FTPServerXRemoveDirectory(ASender: TIdFTPServerThread; var VDirectory: string);  virtual; abstract;
      procedure FTPServerXRetrieveFile(ASender: TIdFTPServerThread; const AFileName: String; var VStream: TStream); virtual; abstract;
      procedure FTPServerXStoreFile(ASender: TIdFTPServerThread; const AFileName: String; AAppend: Boolean; var VStream: TStream); virtual; abstract;
      procedure FTPServerXStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: String); virtual; abstract;
      procedure FTPServerXChangeDirectory(ASender: TIdFTPServerThread; var VDirectory: String); virtual; abstract;
    end;

    TOnConnect = procedure (Connect : TFTPConnection) of object;
    TOnChangeDirectory = procedure (var VDirectory: String) of object;

    TFTPProcessorServer = class(TFTPProcessor)
    private
      FOnConnect         : TOnConnect;
      FOnWriteDataEvent  : TOnWriteDataEvent;
      FOnChangeDirectory : TOnChangeDirectory;
      FRootPath          : string;
      FServer            : TFTPConnections;
      function FTP_curr(ASender: TIdFTPServerThread) : TFTPConnection; overload;
      function FTP_curr(AThread: TIdPeerThread)      : TFTPConnection; overload;
    public
      constructor Create(RootPath : String); override;
      destructor Destroy; override;
      procedure FTPServerXConnect(AThread: TIdPeerThread); override;
      procedure FTPServerXDisconnect(AThread: TIdPeerThread); override;
      procedure FTPServerXUserLogin(ASender: TIdFTPServerThread; const AUsername, APassword: String; var AAuthenticated: Boolean); override;
      procedure FTPServerXListDirectory(ASender: TIdFTPServerThread; const APath: String; ADirectoryListing: TIdFTPListItems); override;
      procedure FTPServerXRenameFile(ASender: TIdFTPServerThread; const ARenameFromFile, ARenameToFile: String); override;
      procedure FTPServerXMakeDirectory(ASender: TIdFTPServerThread; var VDirectory: string); override;
      procedure FTPServerXRemoveDirectory(ASender: TIdFTPServerThread; var VDirectory: string); override;
      procedure FTPServerXRetrieveFile(ASender: TIdFTPServerThread; const AFileName: String; var VStream: TStream); override;
      procedure FTPServerXStoreFile(ASender: TIdFTPServerThread; const AFileName: String; AAppend: Boolean; var VStream: TStream); override;
      procedure FTPServerXStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: String); override;
      procedure FTPServerXChangeDirectory(ASender: TIdFTPServerThread; var VDirectory: String); override;
      property RootPath  : string read FRootPath write FRootPath;
      property OnConnect : TOnConnect read FOnConnect write FOnConnect;
      property Server : TFTPConnections read FServer;
      property OnWriteDataEvent: TOnWriteDataEvent read FOnWriteDataEvent write FOnWriteDataEvent;
      property OnChangeDirectory : TOnChangeDirectory read FOnChangeDirectory write FOnChangeDirectory;
    end;


implementation

function TCustomListConnection.Count : Integer;        
begin
  result := FCount;
end;

function TCustomListConnection.GetItm( Index : integer ) : TFTPConnection;
begin
  result := FTPConnect[Index];
end;

procedure TCustomListConnection.SetItm( Index : integer; Value: TFTPConnection );
begin
  FTPConnect[Index] := Value;
end;

procedure TCustomListConnection.Delete( Index : integer );
  var
    I       : Integer;
    Thread  : TidPeerThread;
    MsgStr  : String;
begin
  if (Index  < FCount) and (Index >= 0) then
  begin
    Thread := FTPConnect[Index].FAThread;
    If Assigned(Thread) then
    begin
      try
        Thread.Synchronize(Thread.Terminate);
        sleep(0);
      except
        on E:Exception do
          MsgStr := E.Message;
      end;
    end;
    FTPConnect[Index].Destroy;
    FTPConnect[Index] := nil;
    For I := Index to FCount - 2 do
    begin
      FTPConnect[I]     := FTPConnect[I + 1];
      FTPConnect[I + 1] := nil;
    end;
    FCount := FCount - 1;
    SetLength(FTPConnect, FCount);
  end;  
end;

procedure TFTPListConnection.Add;
begin
  FCount := FCount + 1;
  SetLength(FTPConnect, FCount);
  FTPConnect[ FCount - 1 ] := TFTPConnection.Create;
end;

procedure TFTPListConnection.Clear;
begin
 FCount := 0;
 SetLength(FTPConnect, FCount);
end;

function TFTPListConnection.Index : integer;
begin
  result := FCount - 1;
end;

procedure TFTPListConnection.UpdateList;
  var
    I            : Integer;
    IsStopped    : Boolean;
begin
  repeat
    IsStopped := false;
    For I := 0 to (FCount - 1) do
    begin
      try
        IsStopped := Items[I].FAThread.Stopped or not Assigned(Items[I].FAThread.Connection);
      finally
        if IsStopped then
          Delete(I);
      end;
      if IsStopped then break;
    end;
  until not IsStopped;
end;

function TFTPListConnection.Select(PeerIP : string; PeerPort  : integer) : TFTPConnection;
  var
    I            : Integer;
begin
  UpdateList;
  result := nil;
  For I := 0 to (FCount - 1) do
  begin
    if (Items[I].PeerIP = PeerIP) and (Items[I].PeerPort = PeerPort) then
    begin
      Items[I].FIndex := I;
      result := Items[I];
      exit;
    end;
  end;
end;

constructor TFTPConnections.Create;
begin
  FConnections := TFTPListConnection.Create;
end;

destructor TFTPConnections.Destroy;
  var
    I : Integer;
begin
  for I := 0 to FConnections.Count - 1 do
    FConnections.Delete(0);
end;

constructor TFTPProcessorServer.Create;
begin
  FRootPath    := RootPath;
  FServer      := TFTPConnections.Create;
  FServer.Connections.Clear;
end;

destructor TFTPProcessorServer.Destroy;
begin
  FServer.Destroy;
  inherited;
end;

procedure TFTPProcessorServer.FTPServerXConnect;
begin
  FServer.Connections.Add;
  with FServer.Connections do
    with Items[Index] do
    begin
      FAThread   := AThread;
      FPeerIP    := FAThread.Connection.Socket.Binding.PeerIP;
      FPeerPort  := FAThread.Connection.Socket.Binding.PeerPort;
      FLocalIP   := FAThread.Connection.Socket.Binding.IP;
      FLocalPort := FAThread.Connection.Socket.Binding.Port;
      FUserLogin := false;
      FRootPath  := Self.FRootPath;
    end;
  with FServer.Connections do
    FOnConnect(Items[Index]);
end;

function TFTPProcessorServer.FTP_curr(AThread: TIdPeerThread)      : TFTPConnection;
  var
    vIp   : string;
    vPort : integer;
    curr  : TFTPConnection;
begin
  result := nil;
  if not Assigned(AThread) then exit;
  if not Assigned(AThread.Connection) then exit;
  vIp    := AThread.Connection.Socket.Binding.PeerIp;
  vPort  := AThread.Connection.Socket.Binding.PeerPort;
  with FServer.Connections do
  begin
    curr := Select(vIp, vPort);
    if Assigned(curr) then
      result := curr;
  end;
end;

procedure TFTPProcessorServer.FTPServerXDisconnect;
begin
  Server.Connections.UpdateList;
end;

function TFTPProcessorServer.FTP_curr(ASender: TIdFTPServerThread) : TFTPConnection;
  var
    vIp   : string;
    vPort : integer;
    curr  : TFTPConnection;
begin
  result := nil;
  vIp    := ASender.Connection.Socket.Binding.PeerIp;
  vPort  := ASender.Connection.Socket.Binding.PeerPort;
  with FServer.Connections do
  begin
    curr := Select(vIp, vPort);
    if Assigned(curr) then
      result := curr;
  end;
end;

procedure TFTPProcessorServer.FTPServerXUserLogin(ASender: TIdFTPServerThread;
  const AUsername, APassword: String; var AAuthenticated: Boolean);
  var
    curr  : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    curr.FUserLogin := true;
{}
  AAuthenticated := true;
{}
end;

procedure TFTPProcessorServer.FTPServerXRenameFile;
  var
    curr  : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    RenameFile(curr.RootPath + ARenameFromFile, curr.RootPath + ARenameToFile);
end;

procedure TFTPProcessorServer.FTPServerXMakeDirectory;
  var
    curr  : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    CreateDir(curr.RootPath + VDirectory);
end;

procedure TFTPProcessorServer.FTPServerXRemoveDirectory;
  var
    curr  : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    RemoveDir(curr.RootPath + VDirectory);
end;

procedure TFTPProcessorServer.FTPServerXListDirectory(ASender: TIdFTPServerThread;
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
    curr           : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    curr_path := curr.RootPath + decrypt_path_dir(APath, curr.RootPath, '');

    res := FindFirst(curr_path + '*', faDirectory, F);
    while res = 0 do
      begin
        if ((f.attr and faDirectory) = faDirectory) and
            (F.Name <> '.') and
            (F.Name <> '..') then
        begin
          fname := encrypt_foldername(curr_path, F.Name, '');
          fsize := GetFileSize_Int64(curr_path + fname);
          if fsize = 0 then fsize := F.Size;
          AddlistItem( ADirectoryListing, fname, ditDirectory, fsize, FileDateToDateTime( f.Time ) );
        end;
        res := FindNext(F);
      end;

     res := FindFirst(curr_path + '*', faAnyFile, F);
     while res = 0 do
     begin
       if ((f.attr and faDirectory) <> faDirectory) and
          (F.Name <> '.') and
          (F.Name <> '..') then
         begin
           fname := encrypt_string(F.Name, '');
           fsize := GetFileSize_Int64(curr_path + fname);
           AddlistItem( ADirectoryListing, fname, ditFile, fsize, FileDateToDateTime( f.Time ) );
         end;
       res := FindNext(F);
     end;
end;

procedure TFTPProcessorServer.FTPServerXRetrieveFile(ASender: TIdFTPServerThread;
  const AFileName: String; var VStream: TStream);
  var
    path_dir  : string;
    vLocFileN : string;
    FileName  : String;
    curr      : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    path_dir  := curr.RootPath + decrypt_path_dir( AFileName, curr.RootPath, '')
  else exit;  

  vLocFileN := AFileName;
  while ((pos('/', vLocFileN) > 0) and (pos('/', vLocFileN) <> length(vLocFileN))) do
    delete(vLocFileN, 1, pos('/', vLocFileN));
  vLocFileN := path_dir + decrypt_string( vLocFileN, '' );
  FileName  := vLocFileN;

  VStream := TFTP_StoreFileStream.Create(FileName, TSWorkMode(wsmRead));
end;

procedure TFTPProcessorServer.FTPServerXStoreFile(ASender: TIdFTPServerThread;
  const AFileName: String; AAppend: Boolean; var VStream: TStream);
  var
   path_dir  : string;
   vLocFileN : string;
   FileName  : String;
   curr      : TFTPConnection;
begin
  curr := FTP_curr(ASender);
  if Assigned(curr) then
    path_dir  := curr.RootPath + decrypt_path_dir( AFileName, curr.RootPath, '' )
  else exit;

  vLocFileN := AFileName;
  while ((pos('/', vLocFileN) > 0) and (pos('/', vLocFileN) <> length(vLocFileN))) do
    delete(vLocFileN, 1, pos('/', vLocFileN));
  vLocFileN := path_dir + decrypt_string( vLocFileN, '' );
  FileName  := vLocFileN;

  if FileExists( FileName ) and AAppend then
  begin
    VStream := TFTP_StoreFileStream.Create(FileName, TSWorkMode(wsmReget));
    VStream.Seek( 0, soFromEnd );
  end
    else
  begin
    VStream := TFTP_StoreFileStream.Create(FileName, TSWorkMode(wsmWrite));
    TFTP_StoreFileStream(VStream).OnWriteDataEvent := OnWriteDataEvent;
  end;
end;

procedure TFTPProcessorServer.FTPServerXStatus(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: String);
begin
{}
{} 
end;

procedure TFTPProcessorServer.FTPServerXChangeDirectory(ASender: TIdFTPServerThread; var VDirectory: String);
  var
    curr_path      : string;
begin
  curr_path := VDirectory;
  while pos('\', curr_path) > 0 do
   delete(curr_path, 1, pos('\', curr_path));
  VDirectory := curr_path;
  if Assigned(FOnChangeDirectory) then
    OnChangeDirectory(VDirectory);
end;

end.
 