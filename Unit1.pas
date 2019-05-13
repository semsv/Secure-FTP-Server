unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    procedure Edit1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Edit1Change(Sender: TObject);
  Var
    s : string;
begin
{}
  S          := Edit1.Text;
  IF LENGTH(S) > 0 THEN
    Edit2.Text := INTTOSTR(ORD(S[1])) ELSE
    Edit2.Text := '';
{}
end;

end.
