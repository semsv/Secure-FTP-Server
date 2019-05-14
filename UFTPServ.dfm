object SecureFtpServer: TSecureFtpServer
  Left = 250
  Top = 200
  Width = 1045
  Height = 610
  Caption = 'FTP Server'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 257
    Top = 0
    Width = 9
    Height = 527
    Beveled = True
    ResizeStyle = rsUpdate
  end
  object Splitter3: TSplitter
    Left = 0
    Top = 527
    Width = 1029
    Height = 3
    Cursor = crVSplit
    Align = alBottom
  end
  object Panel2: TPanel
    Left = 266
    Top = 0
    Width = 763
    Height = 527
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 0
    object Splitter2: TSplitter
      Left = 409
      Top = 1
      Width = 8
      Height = 525
      Beveled = True
      ResizeStyle = rsUpdate
    end
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 408
      Height = 525
      Align = alLeft
      TabOrder = 0
      object Label1: TLabel
        Left = 241
        Top = 76
        Width = 28
        Height = 13
        Caption = #1055#1086#1088#1090':'
      end
      object Button1: TButton
        Left = 8
        Top = 40
        Width = 75
        Height = 25
        Caption = 'Start'
        TabOrder = 0
        OnClick = Button1Click
      end
      object Button2: TButton
        Left = 8
        Top = 73
        Width = 75
        Height = 25
        Caption = 'Stop'
        Enabled = False
        TabOrder = 1
        OnClick = Button2Click
      end
      object Edit1: TEdit
        Left = 88
        Top = 41
        Width = 281
        Height = 21
        TabOrder = 2
        Text = 'C:\SEMEN'
        OnChange = Edit1Change
      end
      object SpinEdit1: TSpinEdit
        Left = 280
        Top = 73
        Width = 121
        Height = 22
        MaxValue = 65535
        MinValue = 1
        TabOrder = 3
        Value = 21
        OnChange = SpinEdit1Change
      end
      object Button3: TButton
        Left = 373
        Top = 40
        Width = 26
        Height = 22
        Caption = '...'
        TabOrder = 4
        OnClick = Button3Click
      end
      object EditKey: TEdit
        Left = 8
        Top = 9
        Width = 257
        Height = 21
        TabOrder = 5
        Text = 'KEYSTR'
      end
      object Button4: TButton
        Left = 270
        Top = 8
        Width = 129
        Height = 21
        Caption = 'Init Key For Crypting ...'
        TabOrder = 6
      end
    end
    object Panel4: TPanel
      Left = 417
      Top = 1
      Width = 345
      Height = 525
      Align = alClient
      Caption = 'Panel3'
      TabOrder = 1
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 257
    Height = 527
    Align = alLeft
    Caption = 'Panel1'
    TabOrder = 1
    object ListBox1: TListBox
      Left = 1
      Top = 1
      Width = 255
      Height = 525
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
    end
  end
  object Panel5: TPanel
    Left = 0
    Top = 530
    Width = 1029
    Height = 41
    Align = alBottom
    Caption = 'Panel5'
    TabOrder = 2
  end
  object IdFTPServer1: TIdFTPServer
    Bindings = <>
    CommandHandlers = <>
    DefaultPort = 21
    Greeting.NumericCode = 220
    Greeting.Text.Strings = (
      'Indy FTP Server ready.')
    Greeting.TextCode = '220'
    MaxConnectionReply.NumericCode = 0
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 500
    ReplyUnknownCommand.Text.Strings = (
      'Syntax error, command unrecognized.')
    ReplyUnknownCommand.TextCode = '500'
    AnonymousAccounts.Strings = (
      'anonymous'
      'ftp'
      'guest')
    SystemType = 'WIN32'
    Left = 16
    Top = 152
  end
  object OpenDialog1: TOpenDialog
    Left = 56
    Top = 153
  end
end
