object frmliquidacion: Tfrmliquidacion
  Left = 348
  Top = 238
  BorderStyle = bsDialog
  Caption = 'Liquidaci'#243'n'
  ClientHeight = 239
  ClientWidth = 283
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 8
    Top = 8
    Width = 265
    Height = 150
  end
  object Label1: TLabel
    Left = 96
    Top = 39
    Width = 30
    Height = 13
    Caption = 'Fecha'
  end
  object Label2: TLabel
    Left = 67
    Top = 102
    Width = 67
    Height = 13
    Caption = 'N'#176' Asignacion'
  end
  object Button1: TButton
    Left = 48
    Top = 186
    Width = 75
    Height = 25
    Caption = 'Ok'
    ModalResult = 1
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 152
    Top = 188
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancelar'
    TabOrder = 4
    OnClick = Button2Click
  end
  object PB1: TProgressBar
    Left = 0
    Top = 223
    Width = 283
    Height = 16
    Align = alBottom
    TabOrder = 5
  end
  object TXTdesde: TsDateEdit
    Left = 93
    Top = 62
    Width = 89
    Height = 21
    EditMask = '!99/99/9999;1; '
    MaxLength = 10
    TabOrder = 1
    Text = '  /  /    '
    StartOfWeek = dowMonday
    Weekends = [dowSaturday, dowSunday]
  end
  object st1: TStaticText
    Left = 32
    Top = 24
    Width = 217
    Height = 17
    AutoSize = False
    Caption = '.'
    TabOrder = 0
  end
  object txtasignacion: TEdit
    Left = 67
    Top = 119
    Width = 143
    Height = 21
    TabOrder = 2
  end
end
