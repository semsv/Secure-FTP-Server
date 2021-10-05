object SecureFtpServer: TSecureFtpServer
  Left = 253
  Top = 148
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
      object Panel6: TPanel
        Left = 1
        Top = 1
        Width = 406
        Height = 136
        Align = alTop
        TabOrder = 0
        object Label1: TLabel
          Left = 233
          Top = 84
          Width = 28
          Height = 13
          Caption = #1055#1086#1088#1090':'
        end
        object Label2: TLabel
          Left = 31
          Top = 21
          Width = 21
          Height = 13
          Caption = 'KEY'
        end
        object Label3: TLabel
          Left = 24
          Top = 53
          Width = 29
          Height = 13
          Caption = 'PATH'
        end
        object Shape1: TShape
          Left = 4
          Top = 20
          Width = 15
          Height = 15
          Brush.Color = clRed
          Shape = stCircle
        end
        object PathShape: TShape
          Left = 4
          Top = 52
          Width = 15
          Height = 15
          Brush.Color = clRed
          Shape = stCircle
        end
        object SrvShape: TShape
          Left = 4
          Top = 84
          Width = 15
          Height = 15
          Brush.Color = clRed
          Shape = stCircle
        end
        object Label4: TLabel
          Left = 24
          Top = 85
          Width = 29
          Height = 13
          Caption = 'SERV'
        end
        object Button1: TButton
          Left = 58
          Top = 80
          Width = 75
          Height = 25
          Caption = 'Start'
          TabOrder = 0
          OnClick = Button1Click
        end
        object Edit1: TEdit
          Left = 60
          Top = 50
          Width = 297
          Height = 21
          TabOrder = 1
          Text = 'C:\SEMEN'
          OnChange = Edit1Change
        end
        object BtnStop: TButton
          Left = 146
          Top = 79
          Width = 75
          Height = 25
          Caption = 'Stop'
          Enabled = False
          TabOrder = 2
          OnClick = BtnStopClick
        end
        object SpinEdit1: TSpinEdit
          Left = 268
          Top = 81
          Width = 121
          Height = 22
          MaxValue = 65535
          MinValue = 1
          TabOrder = 3
          Value = 21
          OnChange = SpinEdit1Change
        end
        object Button3: TButton
          Left = 361
          Top = 49
          Width = 26
          Height = 22
          Caption = '...'
          TabOrder = 4
          OnClick = Button3Click
        end
        object Button4: TButton
          Left = 361
          Top = 16
          Width = 26
          Height = 22
          Caption = '...'
          TabOrder = 5
          OnClick = Button4Click
        end
        object EditKey: TMaskEdit
          Left = 60
          Top = 17
          Width = 294
          Height = 21
          EditMask = '99999\-99999\-99999\-99999\-99999;1;_'
          MaxLength = 29
          TabOrder = 6
          Text = '     -     -     -     -     '
          OnChange = EditKeyChange
        end
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
  object OpenDialog1: TOpenDialog
    Left = 40
    Top = 9
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 8
    Top = 8
  end
end
