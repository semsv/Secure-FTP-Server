unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  type tneural_node = record
         x           : array [1..1000, 1..1000] of byte;
         y           : array [1..1000, 1..1000] of byte;
         index       : integer;
         output      : integer;
         magnitude   : byte;
         name        : string;
         reserv_low  : DWORD;
         reserv_high : DWORD;
                        end;

  var
    Form1: TForm1;

    neural_netw  : array of tneural_node;
    neural_count : integer;
    x            : array [1..1000, 1..1000] of byte;

implementation

{$R *.dfm}

procedure Create_Neural_Network(count     : integer;
                                magnitude : byte;
                                name      : string);
  var
    i     : integer;
    cur_i : integer;
begin
  cur_i        := neural_count;
  neural_count := neural_count + count;
  SetLength(neural_netw, neural_count);
  for i := cur_i to neural_count-1 do
  begin
    neural_netw[i].name      := name;
    neural_netw[i].magnitude := magnitude;
    neural_netw[i].output    := 0;             // ïîêà íåéðîí ÷èñò
    neural_netw[i].index     := i;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Create_Neural_Network( 2, 1, 'Ïðèâåò Ìèð!' );
end;

procedure TForm1.Button1Click(Sender: TObject);
  var a    : tbitmap;
      p    : pointer;
      i, J : integer;
      v    : TColor;
begin
if not fileexists('c:\temp\1.bmp') then exit;
image1.Picture.LoadFromFile('c:\temp\1.bmp');
a := tbitmap.Create;
a.Width  := image1.picture.Width;
a.height := image1.picture.height;
a.Assign(image1.Picture.Bitmap);

for i := 1 to 1000 do
for j := 1 to 1000 do
x[i, j] := 0;
  for I := 1 to a.height do
    begin
      p := a.ScanLine[I-1];
      For J := 1 to a.Width do
        begin
          v := TCOLOR(p^);
         // TCOLOR(p^) := -1;
          p := POINTER(DWORD(p) + SIZEOF(TColor));
          if v <> -1 then
            x[i, j] := 1;
        end;
    end;
// îáðàòíî â Image1:
image1.Picture.Bitmap.assign (a);
end;

end.
