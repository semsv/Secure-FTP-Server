unit UFTPStream;

interface
  uses classes, windows, sysutils;

  type

  TSWorkMode = (wsmRead, wsmWrite, wsmReget);

  TOnWriteDataEvent = procedure(Count: Longint);
  TFTP_StoreFileStream = class(TStream)
  private
    FPosition         : Int64;
    FSize             : Int64;
    hFile             : Cardinal;
    FFileName         : String;
    FFMode            : TSWorkMode;
    FOnWriteDataEvent : TOnWriteDataEvent;
    function CheckFileOpen     : Boolean;
  protected
    function GetSize: Int64; overload; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(FileName : String; WorkMode : TSWorkMode);
    destructor Destroy; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    property OnWriteDataEvent: TOnWriteDataEvent read FOnWriteDataEvent write FOnWriteDataEvent;
  end;

implementation

function TFTP_StoreFileStream.CheckFileOpen : boolean;
begin
 if hFile =  INVALID_HANDLE_VALUE then
   hFile  := CreateFile(PChar(FFileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
 result := (hFile <> INVALID_HANDLE_VALUE);
end;

procedure TFTP_StoreFileStream.SetSize(const NewSize: Int64);
  var
    Value       : Int64;
begin
 Value              := NewSize;
 Int64Rec(Value).Lo := SetFilePointer(hFile, Int64Rec(Value).Lo, @Int64Rec(Value).Hi, soFromBeginning);
 FSize              := Value;
end;

function TFTP_StoreFileStream.GetSize: Int64;
begin
  result := Seek(0, soFromEnd);
end;

destructor TFTP_StoreFileStream.Destroy;
begin
 try
   try
     if hFile <> INVALID_HANDLE_VALUE then
     begin
       if CloseHandle(hFile) then
         hFile := INVALID_HANDLE_VALUE;
     end
   finally
     hFile := INVALID_HANDLE_VALUE;
   end;
 except
   on E:Exception do
     E.Free;
 end;
 inherited Destroy;
end;

constructor TFTP_StoreFileStream.Create;
begin
 FFileName := FileName;

 if FileExists(FFileName) and (WorkMode = wsmReget) then
   hFile := CreateFile(PChar(FFileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
 else if FileExists(FFileName) and (WorkMode = wsmWrite) then
   hFile := CreateFile(PChar(FFileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
 else if FileExists(FFileName) and (WorkMode = wsmRead) then
   hFile := CreateFile(PChar(FFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
 else
   hFile := CreateFile(PChar(FFileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
 FSize      := 0;
 FPosition  := 0;
 FFMode     := WorkMode;
end;

function TFTP_StoreFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
  var
    nMoveMethod : Cardinal;
    Value       : Int64;
begin
  nMoveMethod         := soFromBeginning;
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    case Origin of
      TSeekOrigin(soFromBeginning): nMoveMethod := soFromBeginning;
      TSeekOrigin(soFromCurrent):   nMoveMethod := soFromCurrent;
      TSeekOrigin(soFromEnd):       nMoveMethod := soFromEnd;
    end;

    if (nMoveMethod in [soFromCurrent, soFromBeginning]) and (Offset <> 0) then
    begin
      if (FFMode      in [wsmWrite, wsmReget]) then
      begin
        if FPosition <= MaxInt then
          result := FPosition
        else
          result := MaxInt;
        exit;
      end else
      begin
        if nMoveMethod = soFromBeginning then FPosition := Offset;
        if nMoveMethod = soFromCurrent   then FPosition := FPosition + Offset;
      end;
    end
    else if nMoveMethod = soFromEnd then
    begin
      Value              := Offset;
      Int64Rec(Value).Lo := SetFilePointer(hFile, Int64Rec(Value).Lo, @Int64Rec(Value).Hi, soFromEnd);
      FSize              := Value;
      if (FFMode      = wsmRead) then
      begin
        result    := FSize - FPosition;
        if result > MaxInt then
          result := MaxInt;
        exit;
      end else FPosition := Value;
    end
    else if (nMoveMethod = soFromCurrent) and (Offset = 0)
        and (FFMode      = wsmRead)
    then
    begin
      if FPosition + 1 > FSize then
      begin
        if FSize <= MaxInt then
          result := FSize
        else  
          result := MaxInt;
        exit;
      end;
    end;
    Result  := Offset;
  end else Result := MaxInt;
end;

function TFTP_StoreFileStream.Read(var Buffer; Count: Longint): Longint;
  var
    nCount : Cardinal;
    ovp    : _OVERLAPPED;
    vSize  : Cardinal;
begin
 nCount := 0;
 vSize  := SizeOf(_OVERLAPPED);
 ZeroMemory(@ovp, vSize);

 ovp.Offset     := (FPosition AND $FFFFFFFF);
 ovp.OffsetHigh := (FPosition SHR 32);

 if CheckFileOpen then
   readfile(hFile, Buffer, Count, nCount, @ovp);

 FPosition  := FPosition + nCount;
 result     := nCount;
end;

function TFTP_StoreFileStream.Write(const Buffer; Count: Longint): Longint;
  var
    nCount : Cardinal;
    ovp    : _OVERLAPPED;
    vSize  : Cardinal;
begin
 nCount     := 0;
 vSize      := SizeOf(_OVERLAPPED);
 ZeroMemory(@ovp, vSize);
                           
 ovp.Offset     := (FPosition AND $FFFFFFFF);
 ovp.OffsetHigh := (FPosition SHR 32);

 if CheckFileOpen then
   writefile(hFile, Buffer, Count, nCount, @ovp);

 FPosition  := FPosition + nCount;
 result     := nCount;
 
 if Assigned(FOnWriteDataEvent) then
   FOnWriteDataEvent(nCount);
end;

end.
