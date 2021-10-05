unit UStrCalculate;

interface

  function CalculateCRC( const path: string ) : string;
  function GetFileSize_Int64(FileName : string) : Int64;
  function Replace_chr(schr, dchr : CHAR; InStr : String) : String;
  function Check_ControlSum_Key(vkey : string) : boolean;
  function EnCrypt_String(InStr, vKeyStr : String) : String;
  function DeCrypt_String(InStr, vKeyStr : String) : String;
  function EnCrypt_FolderName(Path : String; InStr, vKeyStr : String) : String;
  function Decrypt_Path_Dir(VDirectory, RootPath, vKeyStr : String) : string;
  function TranslatePath( const APathname, homeDir: string ) : string;
  function GenerateKey : String;
  
implementation

  uses Classes, Windows, IdHashCRC, SysUtils, MaskUtils;

  function CalculateCRC( const path: string ) : string;
    var
      f       : tfilestream;
      value   : dword;
      IdHashCRC32 : TIdHashCRC32;
  begin
    IdHashCRC32 := nil;
    f := nil;
    try
      IdHashCRC32 := TIdHashCRC32.create;
      f := TFileStream.create( path, fmOpenRead or fmShareDenyWrite ) ;
      value := IdHashCRC32.HashValue( f ) ;
      result := inttohex( value, 8 ) ;
    finally
      f.free;
      IdHashCRC32.free;
    end;
  end;

  function GetFileSize_Int64(FileName : string) : Int64;
    Var
      hFile : Cardinal;
      LSize : Int64;
      HSize : Int64;
  begin
    result := 0;
    hFile := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if hFile <> INVALID_HANDLE_VALUE then
    begin
      LSize := windows.GetFileSize(hFile, @HSize);
      FileClose(hFile);
      result := LSize + (HSize shl 32);
    end;
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
    if Length(vkey) <> 25
      then exit;
    For I := 1 to 4 do
     begin
       value    := StrToInt(Copy(r, (i-1)*5 + 1, 5));
       cntrlsum := cntrlsum + value xor $AA;
     end;
    result := (Copy(Inttostr(cntrlsum), 1, 5) = cmpsumstr);
  end;

  function encrypt_string(InStr, vKeyStr : String) : String;
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

  function decrypt_string(InStr, vKeyStr : String) : String;
  begin
    result := encrypt_string( InStr, vKeyStr );
  end;

  function encrypt_foldername(Path : String; InStr, vKeyStr : String) : String;
    Var
      S    : String;
  begin
    if InStr = '/' then
    begin
      result := InStr;
      exit;
    end;
    S      := encrypt_string( Path + InStr, vKeyStr );
    while pos('\', S) > 0
    do
     delete(S, 1, pos('\', S));
    while ((pos('/', S) > 0) and (pos('/', S) <> length(S)))
    do
      delete(S, 1, pos('/', S));
    result := S;
  end;

  function decrypt_path_dir(VDirectory, RootPath, vKeyStr : String) : string;
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
      old_split  := encrypt_foldername(RootPath + old_split, save_str, vKeyStr);
      result_path := result_path + old_split;

      delete( curr_path, 1, pos('/', curr_path));
    end;
    result    := split_path;

    if Length(result_path) > 2 then
      if result_path[1] = '/' then
        delete(result_path, 1, 1);

    if Length(result_path) > 1 then
      if result_path[1] = '.' then
        delete(result_path, 1, 1);

    result_path := replace_chr('/', '\', result_path);
        
    result := result_path;
  end;

  function GenerateKey : String;
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
      if I < 4 then
        s := s + '-';
    end;
    cntrlsum     := 0;
    r            := replace_chr('-', chr(0), s);
    For I := 1 to 4 do
    begin
      value    := StrToInt(Copy(r, (i-1)*5 + 1, 5));
      cntrlsum := cntrlsum + value xor $AA;
    end;
    result := s + '-' + Copy(Inttostr(cntrlsum), 1, 5);
  {}  
  end;

  function TranslatePath( const APathname, homeDir: string ) : string;
function SlashToBackSlash( const str: string ) : string;
var
  a: dword;
begin
  result := str;
  for a := 1 to length( result ) do
    if result[a] = '/' then
      result[a] := '\';
end;
var
  tmppath: string;
begin
  result := SlashToBackSlash( homeDir ) ;
  tmppath := SlashToBackSlash( APathname ) ;
  if homedir = '/' then
  begin
    result := tmppath;
    exit;
  end;

  if length( APathname ) = 0 then
    exit;
  if result[length( result ) ] = '\' then
    result := copy( result, 1, length( result ) - 1 ) ;

  if length(tmppath) > 0 then
  begin
    if tmppath[1] <> '\' then
      result := result + '\';
  end else
    result := result + '\';
    
  result := result + tmppath;
end;

end.
