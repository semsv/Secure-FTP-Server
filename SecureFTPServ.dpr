program SecureFTPServ;

uses
  Forms,
  UFTPServ in 'UFTPServ.pas' {SecureFtpServer},
  UFTPStream in 'UFTPStream.pas',
  UStrCalculate in 'UStrCalculate.pas',
  UFTPProcessServer in 'UFTPProcessServer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSecureFtpServer, SecureFtpServer);
  Application.Run;
end.