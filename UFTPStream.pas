unit UFTPStream;

interface
  uses classes, windows, sysutils;

  type

  TFTP_StoreFileStream = class(TStream)
  private
    FPosition : Int64;
    FSize     : Int64;
    hFile     : Cardinal;
    FFileName : String;
    function CheckFileOpen     : Boolean;
  protected
    function GetSize: Int64; overload; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(FileName : String);
    destructor Destroy; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
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
  var
    Value       : Int64;
begin
 Value              := 0;
 Int64Rec(Value).Lo := SetFilePointer(hFile, Int64Rec(Value).Lo, @Int64Rec(Value).Hi, soFromEnd);
 result             := Value;
end;

destructor TFTP_StoreFileStream.Destroy;
begin
 if hFile <> INVALID_HANDLE_VALUE then
 begin
   if CloseHandle(hFile) then
     hFile := INVALID_HANDLE_VALUE;
 end
end;

constructor TFTP_StoreFileStream.Create;
begin
 FFileName := FileName;
 if FileExists(FFileName) then
   hFile := CreateFile(PChar(FFileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
 else
   hFile := CreateFile(PChar(FFileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
 FSize := 0;
end;

function TFTP_StoreFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
  var
    nMoveMethod : Cardinal;
    Value       : Int64;
begin
  Value               := Offset; 
  nMoveMethod         := soFromBeginning;
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    case Origin of
      TSeekOrigin(soFromBeginning): nMoveMethod := soFromBeginning;
      TSeekOrigin(soFromCurrent):   nMoveMethod := soFromCurrent;
      TSeekOrigin(soFromEnd):       nMoveMethod := soFromEnd;
    end;
    Int64Rec(Value).Lo := SetFilePointer(hFile, Int64Rec(Value).Lo, @Int64Rec(Value).Hi, nMoveMethod);
  end;
  FPosition := Value;
  Result    := FPosition;
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
end;

end.
