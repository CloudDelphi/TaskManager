object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 315
  ClientWidth = 747
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object DrawPanel: TDrawPanel
    Left = 8
    Top = 16
    Width = 425
    Height = 137
    Caption = 'DrawPanel'
    DefaultPaint = False
    OnPaint = DrawPanelPaint
    ParentBackground = False
    TabOrder = 0
    OnMouseMove = DrawPanelMouseMove
  end
  object Timer1: TTimer
    Interval = 20
    OnTimer = Timer1Timer
    Left = 384
    Top = 104
  end
end
