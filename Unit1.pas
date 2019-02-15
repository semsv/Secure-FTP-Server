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
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
         initial_x   : byte;
         initial_y   : byte;
         height      : integer;
         width       : integer;
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

  function post_compare_xy_in_node : integer;

implementation
{$R *.dfm}
  var
    node_name    : string;

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
    neural_netw[i].initial_x := 0;
    neural_netw[i].initial_y := 0;
    neural_netw[i].index     := i;
  end;
end;

function Load_Data_In_Node(p_height, p_Width : Integer) : boolean;
  var
    Xi,
      i, J : integer;
begin
  result := false;
  for Xi := 0 to neural_count - 1 do
    begin
      if neural_netw[Xi].initial_x = 0 then
        begin
          for i := 1 to 1000 do
            for j := 1 to 1000 do
              neural_netw[Xi].x[i, j] := x[i, j];
          neural_netw[Xi].initial_x := 1;
          neural_netw[Xi].height    := p_height;
          neural_netw[Xi].width     := p_Width;
          result := true;
          break;
        end else
      if neural_netw[Xi].initial_y = 0 then
        begin
          for i := 1 to 1000 do
            for j := 1 to 1000 do
              neural_netw[Xi].y[i, j] := x[i, j];
          neural_netw[Xi].initial_y := 1;
          if neural_netw[Xi].height < p_height
            then
              neural_netw[Xi].height    := p_height;
          if neural_netw[Xi].width < p_Width
            then
              neural_netw[Xi].width     := p_Width;
          result := true;    
          break;
        end;
    end;
end;

function Load_Node_Array_From_Bmp_File(FileName : string; p_Image: TImage) : integer;
  var a    : tbitmap;
      p    : pointer;
      i, J : integer;
      v    : TColor;
      res  : integer;
begin
  result := 0; 
  if not fileexists(FileName)
    then exit;

  p_image.Picture.LoadFromFile(FileName);
  a := tbitmap.Create;
  a.Width  := p_image.picture.Width;
  a.height := p_image.picture.height;
  a.Assign(p_image.Picture.Bitmap);

  for i := 1 to 1000 do
  for j := 1 to 1000 do
    x[i, j] := 0;

  for I := 1 to a.height do
    begin
      p := a.ScanLine[I-1];
      For J := 1 to a.Width do
        begin
          v := TCOLOR(p^);
         // TCOLOR(p^) := 1;
          p := POINTER(DWORD(p) + SIZEOF(TColor));
          if v <> -1 then
            x[i, j] := 1;
        end;
    end;

// îáðàòíî â p_image:
  p_image.Picture.Bitmap.assign (a);
// Çàãðóçêà äàííûõ â íåéðîñåòü
  res := post_compare_xy_in_node;
  if res = 0 then
  if not Load_Data_In_Node(a.height, a.Width) then
    begin
      // Íàøà íåéðîñåòü óìååò ñàìà ðàçðàñòàòüñÿ
      Create_Neural_Network( 2, 1, node_name );
      Load_Data_In_Node(a.height, a.Width);
    end;
  result := res;  
end;

function compare_xy_in_node : integer;
  var Xi,
      i, J : integer;
      find : boolean;
      sch  : integer;
      ign  : integer;
      h, w : integer;
begin
  result := 0; find := false; h := 0; w := 0; ign := 0;  sch := 0; 
  for Xi := 0 to neural_count - 1 do
    begin
      ign := 0;  sch := 0;
      if (neural_netw[Xi].initial_x = 1) and
         (neural_netw[Xi].initial_y = 1) and
         (neural_netw[Xi].output    = 0)
        then
        begin
          h := neural_netw[Xi].height;
          w := neural_netw[Xi].width;
          for i := 1 to h do
            for j := 1 to w do
              begin
                x[i, j] := abs(neural_netw[Xi].x[i, j] - neural_netw[Xi].y[i, j]);
                if (neural_netw[Xi].x[i, j] = 0) and
                   (neural_netw[Xi].y[i, j] = 0)
                  then
                    ign := ign + 1
                  else
                if x[i, j] = 0
                  then
                    sch := sch + 1;
              end;
          neural_netw[Xi].output := round(sch / ((h*w)-ign) * 100);
          find := true;
          break;
        end;
    end;
  if find then
    begin
      result := round(sch / ((h*w)-ign) * 100);
    end;
end;

function post_compare_xy_in_node : integer;
// Àíàëèç äàííûõ ñ óæå ïîëó÷åííûì ðàíåå îïûòîì
  var Xi,
      i, J        : integer;
      find        : boolean;
      sch         : integer;
      ign         : integer;
      h, w        : integer;
      value       : byte;
      curr_output : integer;
begin
  result := 0; find := false; curr_output := 0;
  for Xi := 0 to neural_count - 1 do
    begin
      ign := 0;  sch := 0;
      if (neural_netw[Xi].initial_x = 1) and
         (neural_netw[Xi].initial_y = 1) and
         (neural_netw[Xi].output   <> 0) // ïðîâåðêà ÷òî îïûò óæå èìååòñÿ
        then
        begin
          h := neural_netw[Xi].height;
          w := neural_netw[Xi].width;
          for i := 1 to h do
            for j := 1 to w do
              begin
                value := abs(neural_netw[Xi].x[i, j] - x[i, j]);
                if (neural_netw[Xi].x[i, j] = 0) and
                   (x[i, j]                 = 0)
                  then
                    ign := ign + 1
                  else
                if value = 0
                  then
                    sch := sch + 1;
              end;
          curr_output            := neural_netw[Xi].output;
          neural_netw[Xi].output := round(sch / ((h*w)-ign) * 100);
          if neural_netw[Xi].output < curr_output
            then
              neural_netw[Xi].output := curr_output
            else
            begin
              find := true;
              if neural_netw[Xi].output < 100 then
                begin
                // è íàäî òîãäà çàïèñàòü ïîëó÷åííûå äàííûå â ìàññèâ Y íàéäåííîãî óçëà
                  for i := 1 to 1000 do
                    for j := 1 to 1000 do
                      neural_netw[Xi].y[i, j] := x[i, j];
                end else
                neural_netw[Xi].output := curr_output;
              // è âûõîäèì                 
              break;
            end;
        end;
    end;
  if find then
    begin
      result := curr_output;
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  node_name := 'Ïðèâåò Ìèð!';
  Create_Neural_Network( 2, 1, node_name );
end;

procedure TForm1.Button1Click(Sender: TObject);
  var res : integer;
begin
  res := Load_Node_Array_From_Bmp_File('c:\temp\1.bmp', Image1);
  if res = 0 then
    res := compare_xy_in_node;
  form1.caption := inttostr(res);
  label2.Caption := inttostr(neural_count);
end;

procedure TForm1.Button2Click(Sender: TObject);
  var res : integer;
begin
  res := Load_Node_Array_From_Bmp_File('c:\temp\2.bmp', Image2);
  if res = 0 then
    res := compare_xy_in_node;
  form1.caption := inttostr(res);
  label2.Caption := inttostr(neural_count);
end;

end.
