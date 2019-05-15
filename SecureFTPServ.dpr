program SecureFTPServ;

uses
  Forms,
  UFTPServ in 'UFTPServ.pas' {SecureFtpServer};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSecureFtpServer, SecureFtpServer);
  Application.Run;
end.