unit YOTM.DB.Tasks;

interface
  uses SQLite3, SQLLang, SQLiteTable3, System.Generics.Collections,
       System.SysUtils, Vcl.Graphics,
       HGM.Controls.VirtualTable, YOTM.DB, YOTM.DB.Labels, dialogs;

  type
   TTaskFilter = (tkfAll, tkfDated, tkfDeadlined, tkfNoDate);
   //������
   TTaskItems = class;

   TTaskType = (ttSimple, ttRepeatInDay, ttRepeatInWeek, ttRepeatInMonth, ttRepeatInYear);

   TTaskRepeat = string; //��� � ���� {1..24} � ��� ������ {1..7} � ��� ������ {1..31} � ������ {1..12}

   TTaskItem = class(TObject)
    private
     FName: string;
     FDateCreate: TDateTime;
     FDateNotify: TTime;
     FParent: Integer;
     FDeadline: Boolean;
     FOwner: TTaskItems;
     FNotifyComplete: Boolean;
     FDateDeadline: TDateTime;
     FID: Integer;
     FDescription: string;
     FTaskType: TTaskType;
     FTaskRepeat:string;
     FState: Boolean;
     FLabelItems:TLabelItems;
     FNotify: Boolean;
     FColor: TColor;
     FSaved:Boolean;
     function GetTaskRepeat(Index: Byte): Boolean;
     procedure SetDateDeadline(const Value: TDateTime);
     procedure SetDateNotify(const Value: TTime);
     procedure SetDescription(const Value: string);
     procedure SetID(const Value: Integer);
     procedure SetName(const Value: string);
     procedure SetNotifyComplete(const Value: Boolean);
     procedure SetOwner(const Value: TTaskItems);
     procedure SetParent(const Value: Integer);
     procedure SetTaskRepeat(Index: Byte; const Value: Boolean);
     procedure SetTaskType(const Value: TTaskType);
     procedure SetDeadline(const Value: Boolean);
     procedure SetState(const Value: Boolean);
     procedure SetLabelItems(const Value: TLabelItems);
     procedure SetNotify(const Value: Boolean);
     procedure SetColor(const Value: TColor);
    public
     constructor Create(AOwner: TTaskItems);
     destructor Destroy;
     procedure Update;
     property Owner:TTaskItems read FOwner write SetOwner;
     property ID:Integer read FID write SetID;
     property Parent:Integer read FParent write SetParent;
     property Name:string read FName write SetName;
     property Description:string read FDescription write SetDescription;
     property DateCreate:TDateTime read FDateCreate;
     property TaskType:TTaskType read FTaskType write SetTaskType;
     property TaskRepeat[Index:Byte]:Boolean read GetTaskRepeat write SetTaskRepeat;
     property DateDeadline:TDateTime read FDateDeadline write SetDateDeadline;
     property TimeNotify:TTime read FDateNotify write SetDateNotify;
     property NotifyComplete:Boolean read FNotifyComplete write SetNotifyComplete;
     property Deadline:Boolean read FDeadline write SetDeadline;
     property State:Boolean read FState write SetState;
     property Notify:Boolean read FNotify write SetNotify;
     property TaskRepeatData:string read FTaskRepeat write FTaskRepeat;
     property LabelItems:TLabelItems read FLabelItems write SetLabelItems;
     property Color:TColor read FColor write SetColor;
     property Saved:Boolean read FSaved;
   end;

   TTaskItems = class(TTableData<TTaskItem>)
    const
     tnTable = 'TaskItems';
     fnID = 'tkID';
     fnParent = 'tkParent';
     fnName = 'tkName';
     fnDesc = 'tkDesc';
     fnDateCreate = 'tkDateCreate';
     fnTaskType = 'tkTaskType';
     fnTaskRepeat = 'tkTaskRepeat';     //000000000000000000000000000000
     fnDateDeadline = 'tkDateDeadline';
     fnTimeNotify = 'tkDateNotify';
     fnNotifyComplete = 'tkNotifyComplete';
     fnNotify = 'tkNotify';
     fnDeadline = 'tkDeadline';
     fnState = 'tkState';
     fnColor = 'tkColor';
    private
     FDataBase: TDB;
     FShowEndedTask: Boolean;
     FShowDate: TDate;
     FTaskFilter: TTaskFilter;
     FUpcoming: Boolean;
     procedure SetDataBase(const Value: TDB);
     procedure SetShowEndedTask(const Value: Boolean);
     procedure SetShowDate(const Value: TDate);
     procedure SetTaskFilter(const Value: TTaskFilter);
     procedure SetUpcoming(const Value: Boolean);
    public
     constructor Create(ADataBase:TDB; ATableEx:TTableEx);
     destructor Destroy; override;
     procedure Reload;
     procedure Clear; override;
     function GetCount(Date:TDate = 0):Integer;
     function GetDeadlined(Date:TDate):Integer;
     function GetItem(ID:Integer):TTaskItem;
     procedure Update(Task: TTaskItem);
     procedure Delete(Index: Integer); override;
     procedure Save;
     property ShowEndedTask:Boolean read FShowEndedTask write SetShowEndedTask default False;
     property ShowDate:TDate read FShowDate write SetShowDate;
     property DataBase:TDB read FDataBase write SetDataBase;
     property TaskFilter:TTaskFilter read FTaskFilter write SetTaskFilter default tkfAll;
     property Upcoming:Boolean read FUpcoming write SetUpcoming default False;
   end;

implementation
 uses YOTM.DB.Comments, DateUtils;

{ TTaskItem }

constructor TTaskItem.Create(AOwner: TTaskItems);
begin
 inherited Create;
 FSaved:=False;
 FColor:=clNone;
 FID:=-1;
 FState:=False;
 FParent:=-1;
 FDeadline:=False;
 FLabelItems:=TLabelItems.Create(AOwner.DataBase, nil);
 FTaskRepeat:='0000000000000000000000000000000';
 Owner:=AOwner;
end;

destructor TTaskItem.Destroy;
begin
 FLabelItems.Free;
 inherited;
end;

function TTaskItem.GetTaskRepeat(Index: Byte): Boolean;
begin
 Result:=FTaskRepeat[Index] = '1';
end;

procedure TTaskItem.SetColor(const Value: TColor);
begin
 if FColor = Value then Exit;
 FColor := Value;
 FSaved:=False;
end;

procedure TTaskItem.SetDateDeadline(const Value: TDateTime);
begin
 if FDateDeadline = Value then Exit;
 FDateDeadline:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetDateNotify(const Value: TTime);
begin
 if FDateNotify = Value then Exit;
 FDateNotify:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetDeadline(const Value: Boolean);
begin
 if FDeadline = Value then Exit;
 FDeadline := Value;
 FSaved:=False;
end;

procedure TTaskItem.SetDescription(const Value: string);
begin
 if FDescription = Value then Exit;
 FDescription:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetID(const Value: Integer);
begin
 if FID = Value then Exit;
 FID:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetLabelItems(const Value: TLabelItems);
begin
 if FLabelItems = Value then Exit;
 FLabelItems := Value;
 FSaved:=False;
end;

procedure TTaskItem.SetName(const Value: string);
begin
 if FName = Value then Exit;
 FName:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetNotify(const Value: Boolean);
begin
 if FNotify = Value then Exit;
 FNotify := Value;
 FSaved:=False;
end;

procedure TTaskItem.SetNotifyComplete(const Value: Boolean);
begin
 if FNotifyComplete = Value then Exit;
 FNotifyComplete:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetOwner(const Value: TTaskItems);
begin
 if FOwner = Value then Exit;
 FOwner:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetParent(const Value: Integer);
begin
 if FParent = Value then Exit;
 FParent:=Value;
 FSaved:=False;
end;

procedure TTaskItem.SetState(const Value: Boolean);
begin
 if FState = Value then Exit;
 FState := Value;
 FSaved:=False;
end;

procedure TTaskItem.SetTaskRepeat(Index: Byte; const Value: Boolean);
begin
 if Value then FTaskRepeat[Index]:='1' else FTaskRepeat[Index]:='0';
 FSaved:=False;
end;

procedure TTaskItem.SetTaskType(const Value: TTaskType);
begin
 if FTaskType = Value then Exit;
 FTaskType:=Value;
 FSaved:=False;
end;

procedure TTaskItem.Update;
begin
 FSaved:=True;
end;

{ TTaskItems }

procedure TTaskItems.Clear;
var i: Integer;
begin
 for i:= 0 to Count-1 do Items[i].Free;
 inherited;
end;

constructor TTaskItems.Create(ADataBase: TDB; ATableEx: TTableEx);
begin
 inherited Create(ATableEx);
 FDataBase:=ADataBase;
 FShowEndedTask:=False;
 FUpcoming:=False;
 FTaskFilter:=tkfAll;
 if not FDataBase.DB.TableExists(tnTable) then
  with SQL.CreateTable(tnTable) do
   begin
    AddField(fnID, ftInteger, True, True);
    AddField(fnParent, ftInteger);
    AddField(fnName, ftString);
    AddField(fnDesc, ftString);
    AddField(fnDateCreate, ftDateTime);
    AddField(fnTaskType, ftInteger);
    AddField(fnTaskRepeat, ftString);
    AddField(fnDateDeadline, ftDateTime);
    AddField(fnTimeNotify, ftDateTime);
    AddField(fnNotifyComplete, ftBoolean);
    AddField(fnNotify, ftBoolean);
    AddField(fnDeadline, ftBoolean);
    AddField(fnState, ftInteger);
    AddField(fnColor, ftInteger);
    FDataBase.DB.ExecSQL(GetSQL);
    EndCreate;
   end;
end;

procedure TTaskItems.Delete(Index: Integer);
var TaskID:Integer;
begin
 TaskID:=Items[Index].ID;
 with SQL.Delete(tnTable) do
  begin
   WhereFieldEqual(fnID, TaskID);
   DataBase.DB.ExecSQL(GetSQL);
   EndCreate;
  end;
 with SQL.Delete(TCommentItems.tnTable) do
  begin
   WhereFieldEqual(TCommentItems.fnTask, TaskID);
   DataBase.DB.ExecSQL(GetSQL);
   EndCreate;
  end;
 with SQL.Delete(TLabelItems.tnTable) do
  begin
   WhereFieldEqual(TLabelItems.fnTask, TaskID);
   DataBase.DB.ExecSQL(GetSQL);
   EndCreate;
  end;
 Items[Index].Free;
 inherited;
end;

destructor TTaskItems.Destroy;
var i:Integer;
begin
 for i:= 0 to Count-1 do Items[i].Free;
 inherited;
end;

function TTaskItems.GetCount(Date: TDate): Integer;
begin
 with SQL.Select(tnTable) do
  begin
   AddField('Count(*)');
   if Date <> 0 then
    begin
     WhereFieldEqual(fnDateDeadline, Trunc(Date));
     WhereFieldEqual(fnDeadline, True);
    end
   else WhereFieldEqual(fnDeadline, False);
   if not ShowEndedTask then
    WhereFieldEqual(fnState, False);
   Result:=FDataBase.DB.GetTableValue(GetSQL);
   EndCreate;
  end;
end;

function TTaskItems.GetDeadlined(Date:TDate): Integer;
begin
 with SQL.Select(tnTable) do
  begin
   AddField('Count(*)');

   WhereParenthesesOpen;
     WhereParenthesesOpen;
       WhereParenthesesOpen;
         WhereFieldEqual(fnNotify, True);
         WhereField(fnTimeNotify, ' < ', TimeOf(Date));
       WhereParenthesesClose;
       WhereField(fnDateDeadline, ' = ', DateOf(Date));
     WhereParenthesesClose;
     WhereField(fnDateDeadline, '<', DateOf(Date), wuOR);
   WhereParenthesesClose;

   WhereNotFieldEqual(fnNotifyComplete, True);
   WhereFieldEqual(fnDeadline, True);
   WhereFieldEqual(fnState, False);
   Result:=FDataBase.DB.GetTableValue(GetSQL);
   EndCreate;
  end;
end;

function TTaskItems.GetItem(ID: Integer): TTaskItem;
var Table:TSQLiteTable;
begin
 try
  with SQL.Select(tnTable) do
    begin
     AddField(fnID);
     AddField(fnParent);
     AddField(fnName);
     AddField(fnDesc);
     AddField(fnDateCreate);
     AddField(fnTaskType);
     AddField(fnTaskRepeat);
     AddField(fnDateDeadline);
     AddField(fnTimeNotify);
     AddField(fnNotifyComplete);
     AddField(fnDeadline);
     AddField(fnState);
     AddField(fnNotify);
     AddField(fnColor);
     Table:=FDataBase.DB.GetTable(GetSQL);
     EndCreate;
     Table.MoveFirst;
     if Table.RowCount > 0 then
      begin
       Result:=TTaskItem.Create(Self);
       Result.ID:=Table.FieldAsInteger(0);
       Result.Parent:=Table.FieldAsInteger(1);
       Result.Name:=Table.FieldAsString(2);
       Result.Description:=Table.FieldAsString(3);
       Result.FDateCreate:=Table.FieldAsDateTime(4);
       Result.TaskType:=TTaskType(Table.FieldAsInteger(5));
       Result.FTaskRepeat:=Table.FieldAsString(6);
       Result.DateDeadline:=Table.FieldAsDateTime(7);
       Result.TimeNotify:=Frac(Table.FieldAsDateTime(8));
       Result.NotifyComplete:=Table.FieldAsBoolean(9);
       Result.Deadline:=Table.FieldAsBoolean(10);
       Result.State:=Table.FieldAsBoolean(11);
       Result.Notify:=Table.FieldAsBoolean(12);
       Result.Color:=TColor(Table.FieldAsInteger(13));
       Result.LabelItems.Reload(Result.ID);
       Result.Update;
      end;
     Table.Free;
    end;
 except

 end;
end;

procedure TTaskItems.Reload;
var Table, Labels:TSQLiteTable;
    Item:TTaskItem;
begin
 BeginUpdate;
 Clear;
 try
  with SQL.Select(tnTable) do
   begin
    AddField(fnID);
    AddField(fnParent);
    AddField(fnName);
    AddField(fnDesc);
    AddField(fnDateCreate);
    AddField(fnTaskType);
    AddField(fnTaskRepeat);
    AddField(fnDateDeadline);
    AddField(fnTimeNotify);
    AddField(fnNotifyComplete);
    AddField(fnDeadline);
    AddField(fnState);
    AddField(fnNotify);
    AddField(fnColor);
    case FTaskFilter of
     tkfDated:
      begin
       WhereFieldEqual(fnDateDeadline, DateOf(FShowDate));
       WhereFieldEqual(fnDeadline, True);
       if not ShowEndedTask then WhereFieldEqual(fnState, False);
      end;
     tkfDeadlined:
      begin
       WhereParenthesesOpen;
         WhereParenthesesOpen;
           WhereParenthesesOpen;
             WhereFieldEqual(fnNotify, True);
             WhereField(fnTimeNotify, ' < ', TimeOf(FShowDate));
           WhereParenthesesClose;
           WhereField(fnDateDeadline, ' = ', DateOf(FShowDate));
         WhereParenthesesClose;
         WhereField(fnDateDeadline, '<', DateOf(FShowDate), wuOR);
       WhereParenthesesClose;

       WhereNotFieldEqual(fnNotifyComplete, True);
       WhereFieldEqual(fnDeadline, True);
       WhereFieldEqual(fnState, False);
      end;
     tkfNoDate:
      begin
       WhereFieldEqual(fnDeadline, False);
       if not ShowEndedTask then WhereFieldEqual(fnState, False);
      end;
    end;
    if Upcoming then
     begin
      WhereFieldEqual(fnNotifyComplete, False);
      WhereFieldEqual(fnNotify, True);
     end;
    OrderBy(fnState);
    OrderBy(fnDateCreate, True);
    Table:=FDataBase.DB.GetTable(GetSQL);
    EndCreate;
    Table.MoveFirst;
    while not Table.EOF do
     begin
      Item:=TTaskItem.Create(Self);
      Item.ID:=Table.FieldAsInteger(0);
      Item.Parent:=Table.FieldAsInteger(1);
      Item.Name:=Table.FieldAsString(2);
      Item.Description:=Table.FieldAsString(3);
      Item.FDateCreate:=Table.FieldAsDateTime(4);
      Item.TaskType:=TTaskType(Table.FieldAsInteger(5));
      Item.FTaskRepeat:=Table.FieldAsString(6);
      Item.DateDeadline:=Table.FieldAsDateTime(7);
      Item.TimeNotify:=Frac(Table.FieldAsDateTime(8));
      Item.NotifyComplete:=Table.FieldAsBoolean(9);
      Item.Deadline:=Table.FieldAsBoolean(10);
      Item.State:=Table.FieldAsBoolean(11);
      Item.Notify:=Table.FieldAsBoolean(12);
      Item.Color:=TColor(Table.FieldAsInteger(13));
      Item.LabelItems.Reload(Item.ID);
      Item.Update;
      Add(Item);
      Table.Next;
     end;
    Table.Free;
   end;
 finally
  EndUpdate;
 end;
end;

procedure TTaskItems.Save;
var i:Integer;
begin
 for i := 0 to Count-1 do Update(Items[i]);
end;

procedure TTaskItems.SetDataBase(const Value: TDB);
begin
 FDataBase:=Value;
end;

procedure TTaskItems.SetUpcoming(const Value: Boolean);
begin
 FUpcoming := Value;
end;

procedure TTaskItems.SetShowDate(const Value: TDate);
begin
 FShowDate := Value;
end;

procedure TTaskItems.SetShowEndedTask(const Value: Boolean);
begin
 FShowEndedTask := Value;
end;

procedure TTaskItems.SetTaskFilter(const Value: TTaskFilter);
begin
 FTaskFilter := Value;
end;

procedure TTaskItems.Update(Task: TTaskItem);
begin
 if Task.ID < 0 then
  with SQL.InsertInto(tnTable) do
   begin
    AddValue(fnParent, Task.Parent);
    AddValue(fnName, Task.Name);
    AddValue(fnDesc, Task.Description);
    AddValue(fnDateCreate, Now);
    AddValue(fnTaskType, Ord(Task.TaskType));
    AddValue(fnTaskRepeat, Task.FTaskRepeat);
    AddValue(fnDateDeadline, Task.DateDeadline);
    AddValue(fnTimeNotify, Task.TimeNotify);
    AddValue(fnNotifyComplete, Task.NotifyComplete);
    AddValue(fnDeadline, Task.Deadline);
    AddValue(fnState, Task.State);
    AddValue(fnNotify, Task.Notify);
    AddValue(fnColor, Integer(Task.Color));
    DataBase.DB.ExecSQL(GetSQL);
    Task.ID:=DataBase.DB.GetLastInsertRowID;
    EndCreate;
   end
 else
  with SQL.Update(tnTable) do
   begin
    AddValue(fnParent, Task.Parent);
    AddValue(fnName, Task.Name);
    AddValue(fnDesc, Task.Description);
    AddValue(fnTaskType, Ord(Task.TaskType));
    AddValue(fnTaskRepeat, Task.FTaskRepeat);
    AddValue(fnDateDeadline, Task.DateDeadline);
    AddValue(fnTimeNotify, Task.TimeNotify);
    AddValue(fnNotifyComplete, Task.NotifyComplete);
    AddValue(fnDeadline, Task.Deadline);
    AddValue(fnState, Task.State);
    AddValue(fnNotify, Task.Notify);
    AddValue(fnColor, Integer(Task.Color));
    WhereFieldEqual(fnID, Task.ID);
    DataBase.DB.ExecSQL(GetSQL);
    EndCreate;
   end;
 Task.Update;
 UpdateTable;
end;

end.
