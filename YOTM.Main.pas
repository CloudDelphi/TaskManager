unit YOTM.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Direct2D, D2D1, System.Generics.Collections,
  HGM.Controls.PanelExt, Vcl.ComCtrls, System.Types, Vcl.StdCtrls,
  HGM.Controls.SpinEdit;

type
  TDrawManager = class;

  TDrawControl = class
    FSize:TSize;
    FPos:TPoint;
    FZ:Integer;
    FColor:TColor;
    FOwner:TDrawManager;
  private
    function GetRect: TRect;
   public
    procedure Paint; virtual;
    procedure SetData(ASize:TSize; APos:TPoint; AColor:TColor; AZ:Integer); virtual;
    constructor Create(AOwner:TDrawManager); virtual;
    property Owner:TDrawManager read FOwner;
    property FormRect:TRect read GetRect;
    property Z:Integer read FZ write FZ;
  end;

  TDrawManager = class(TList<TDrawControl>)
   private
    FCanvas:TDirect2DCanvas;
   public
    procedure Paint;
    procedure Sort;
    property Canvas:TDirect2DCanvas read FCanvas;
  end;

  TForm1 = class(TForm)
    DrawPanel: TDrawPanel;
    Timer1: TTimer;
    DateTimePickerStart: TDateTimePicker;
    DateTimePickerEnd: TDateTimePicker;
    DateTimePickerCur: TDateTimePicker;
    Timer2: TTimer;
    SpinEdit1: TlkSpinEdit;
    SpinEdit2: TlkSpinEdit;
    procedure Timer1Timer(Sender: TObject);
    procedure DrawPanelPaint(Sender: TObject);
    procedure DrawPanelMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure DateTimePickerEndChange(Sender: TObject);
    procedure DateTimePickerCurChange(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    FPanelMouse:TPoint;
    FWorkTimeMin:Integer;
    FNowTimeMin:Integer;
    ScaleRect:TRect;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
 uses Math;

{$R *.dfm}

function GetMins(Time:TTime):Integer;
var H, M, S, MSec:Word;
begin
 DecodeTime(Time, H, M, S, MSec);
 Result:=H*60 + M;
end;

function GetTime(Mins:Integer):TTime;
var H, M:Word;
begin
 H:=Mins div 60;
 M:=Mins mod 60;
 Result:=EncodeTime(H, M, 0, 0);
end;

procedure TForm1.DrawPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
 FPanelMouse:=Point(X, Y);
 if ScaleRect.Contains(FPanelMouse) then DrawPanel.Cursor:=crHandPoint
 else DrawPanel.Cursor:=crDefault;
 Timer1Timer(nil);
end;

procedure TForm1.DrawPanelPaint(Sender: TObject);
var CRect, tmpRect:TRect;
    MPos, H, M:Integer;
    MProc:Double;
begin
 CRect:=DrawPanel.ClientRect;
 with TDirect2DCanvas.Create(DrawPanel.Canvas, DrawPanel.ClientRect) do
  begin
   BeginDraw;
   try
    Brush.Color:=$0043B6E3;
    FillRect(CRect);
    //--------------------------------------
    ScaleRect.Left:=50;
    ScaleRect.Right:=CRect.Right - 50;
    ScaleRect.Bottom:=CRect.Bottom - 50;
    ScaleRect.Top:=ScaleRect.Bottom - 15;
    //if ScaleRect.Contains(FPanelMouse) then Brush.Color:=$0019A0E3 else
    Brush.Color:=$0016597D;
    Pen.Color:=Brush.Color;
    RoundRect(ScaleRect, ScaleRect.Height, ScaleRect.Height);

    Brush.Style:=bsClear;
    TextOut(ScaleRect.Left - 30, ScaleRect.Top - 20, FormatDateTime('HH:mm', DateTimePickerStart.Time));
    TextOut(ScaleRect.Right, ScaleRect.Top - 20, FormatDateTime('HH:mm', DateTimePickerEnd.Time));

    tmpRect:=ScaleRect;
    tmpRect.Right:=tmpRect.Left +  Round(ScaleRect.Width / 100 * ((FNowTimeMin - GetMins(DateTimePickerStart.Time)) /  (FWorkTimeMin / 100)));
    Brush.Style:=bsSolid;
    Brush.Color:=$003C86AB;
    tmpRect.Width:=Max(tmpRect.Width, tmpRect.Height);
    RoundRect(tmpRect, tmpRect.Height, tmpRect.Height);
    Brush.Style:=bsClear;
    TextOut(tmpRect.Right - 15, tmpRect.Top - 40, FormatDateTime('HH:mm', DateTimePickerCur.Time));

    tmpRect:=ScaleRect;
    tmpRect.Inflate(5, 5);
    if tmpRect.Contains(FPanelMouse) then
     begin
      MPos:=Min(Max(FPanelMouse.X, ScaleRect.Left), ScaleRect.Right);
      MoveTo(MPos, ScaleRect.Top);
      LineTo(MPos, ScaleRect.Top - 20);

      Brush.Color:=$0019A0E3;
      tmpRect:=ScaleRect;
      tmpRect.Right:=MPos;
      Brush.Style:=bsSolid;
      tmpRect.Width:=Max(tmpRect.Width, tmpRect.Height);
      RoundRect(tmpRect, tmpRect.Height, tmpRect.Height);

      MProc:=MPos - ScaleRect.Left;
      MProc:=MProc / (ScaleRect.Width / 100);
      MProc:=MProc * (FWorkTimeMin / 100); //������

      H:=Ceil(MProc) div 60;
      M:=Trunc(Ceil(MProc) mod 60 / 5) * 5;
      Brush.Style:=bsClear;
      TextOut(MPos - 15, ScaleRect.Top - 40, Format('%.2d:%.2d', [H, M]));
      TextOut(MPos - 15, ScaleRect.Top - 60, FormatDateTime('HH:mm', GetTime(GetMins(DateTimePickerStart.Time) + (H * 60 + M))));
      TextOut(MPos - 15, ScaleRect.Top - 80, FormatDateTime('HH:mm', GetTime(Abs(GetMins(DateTimePickerCur.Time) - (H * 60 + M) - GetMins(DateTimePickerStart.Time)))));
     end;
    tmpRect:=Rect(40, 40, 120, 120);
    RoundRect(tmpRect, SpinEdit1.Value, SpinEdit2.Value);

    TextOut(10, 0, Format('%d:%d', [FPanelMouse.X, FPanelMouse.Y]));
    //--------------------------------------
   finally
    EndDraw;
   end;
   Free;
  end;
end;

procedure TForm1.DateTimePickerCurChange(Sender: TObject);
begin
 if Frac(DateTimePickerCur.Time) < Frac(DateTimePickerStart.Time) then
  DateTimePickerCur.Time:=DateTimePickerStart.Time;
 if Frac(DateTimePickerCur.Time) > Frac(DateTimePickerEnd.Time) then
  DateTimePickerCur.Time:=DateTimePickerEnd.Time;
 FNowTimeMin:=GetMins(DateTimePickerCur.Time);
end;

procedure TForm1.DateTimePickerEndChange(Sender: TObject);
begin
 if Frac(DateTimePickerEnd.Time) < Frac(DateTimePickerStart.Time) then
  DateTimePickerEnd.Time:=DateTimePickerStart.Time
 else
  if Frac(DateTimePickerStart.Time) > Frac(DateTimePickerEnd.Time) then
   DateTimePickerStart.Time:=DateTimePickerEnd.Time;
 if Frac(DateTimePickerEnd.Time) <= Frac(DateTimePickerStart.Time) then
  DateTimePickerEnd.Time:=DateTimePickerStart.Time+1/24/60;

 FWorkTimeMin:= Max(1, GetMins(DateTimePickerEnd.Time) - GetMins(DateTimePickerStart.Time));
 Caption:=IntToStr(FWorkTimeMin);
 DateTimePickerCur.MinDate:=DateTimePickerStart.Time;
 DateTimePickerCur.MaxDate:=DateTimePickerEnd.Time;
 DateTimePickerCurChange(nil);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 DateTimePickerEndChange(nil);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
 DrawPanel.Repaint;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
 DateTimePickerCur.Time:=Now;
 DateTimePickerCurChange(nil);
end;

{ TDrawControl }

constructor TDrawControl.Create(AOwner: TDrawManager);
begin
 FOwner:=AOwner;
end;

function TDrawControl.GetRect: TRect;
begin
 Result:=Rect(0, 0, FSize.Width, FSize.Height);
 Result.Offset(FPos);
end;

procedure TDrawControl.Paint;
begin
 with Owner.Canvas do
  begin
   Brush.Color:=FColor;
   Pen.Color:=Brush.Color;
   FillRect(FormRect);
  end;
end;

procedure TDrawControl.SetData(ASize:TSize; APos:TPoint; AColor:TColor; AZ:Integer);
begin
 FSize:=ASize;
 FPos:=APos;
 FColor:=AColor;
 FZ:=AZ;
end;

{ TDrawManager }

procedure TDrawManager.Paint;
var i:Integer;
begin
 for i:= 0 to Count-1 do Items[i].Paint;
end;

procedure TDrawManager.Sort;
var i, j:Integer;
    tmp:TDrawControl;
begin
 for i:= 0 to Count-2 do
  for j := i+1 to Count-1 do
   if Items[i].Z > Items[j].Z then
    begin
     tmp:=Items[i];
     Items[i]:=Items[j];
     Items[j]:=tmp;
    end;
end;

end.
