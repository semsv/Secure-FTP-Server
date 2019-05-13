object Form1: TForm1
  Left = 249
  Top = 185
  Width = 423
  Height = 549
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
  object Label1: TLabel
    Left = 241
    Top = 91
    Width = 28
    Height = 13
    Caption = #1055#1086#1088#1090':'
  end
  object Button1: TButton
    Left = 8
    Top = 55
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 8
    Top = 88
    Width = 75
    Height = 25
    Caption = 'Stop'
    Enabled = False
    TabOrder = 1
    OnClick = Button2Click
  end
  object ListBox1: TListBox
    Left = 8
    Top = 120
    Width = 393
    Height = 385
    ItemHeight = 13
    TabOrder = 2
  end
  object Edit1: TEdit
    Left = 88
    Top = 56
    Width = 313
    Height = 21
    TabOrder = 3
    Text = 'C:\SEMEN'
    OnChange = Edit1Change
  end
  object SpinEdit1: TSpinEdit
    Left = 280
    Top = 88
    Width = 121
    Height = 22
    MaxValue = 65535
    MinValue = 1
    TabOrder = 4
    Value = 21
    OnChange = SpinEdit1Change
  end
end
