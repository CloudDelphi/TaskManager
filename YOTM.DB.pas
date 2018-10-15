unit YOTM.DB;

interface
  uses SQLite3, SQLLang, SQLiteTable3, System.Generics.Collections, HGM.Controls.VirtualTable;

  type
   TDB = class
    private
     FDataBase:TSQLiteDatabase;
     FDataBaseName:string;
     FCreated:Boolean;
    public
     constructor Create(FileName:string);
     property DataBaseName:string read FDataBaseName;
     property DB:TSQLiteDatabase read FDataBase;
     property Created:Boolean read FCreated;
   end;

   TTimeItem = class;
   TTimeItems = class;

   TTimeItem = class(TObject)
    private
     FOwner:TTimeItems;
     FID:Integer;
     FDescription: string;
     FTimeTo: TTime;
     FTimeFrom: TTime;
     FDate: TDate;
    FTask: Integer;
     procedure SetOwner(const Value: TTimeItems);
     procedure SetDescription(const Value: string);
     procedure SetTimeFrom(const Value: TTime);
     procedure SetTimeTo(const Value: TTime);
     procedure SetID(const Value: Integer);
     procedure SetDate(const Value: TDate);
    procedure SetTask(const Value: Integer);
    public
     constructor Create(AOwner: TTimeItems);
     property Owner:TTimeItems read FOwner write SetOwner;
     property Description:string read FDescription write SetDescription;
     property TimeFrom:TTime read FTimeFrom write SetTimeFrom;
     property TimeTo:TTime read FTimeTo write SetTimeTo;
     property Date:TDate read FDate write SetDate;
     property ID:Integer read FID write SetID;
     property Task:Integer read FTask write SetTask;
   end;

   TTimeItems = class(TTableData<TTimeItem>)
    const
     tnTable = 'TimeItems';
     fnID = 'tiID';
     fnTask = 'tiTask';
     fnDesc = 'tiDesc';
     fnTimeFrom = 'tiTimeFrom';
     fnTimeTo = 'tiTimeTo';
     fnDate = 'tiDate';
    private
     FDataBase: TDB;
     procedure SetDataBase(const Value: TDB);
    public
     constructor Create(ADataBase:TDB; ATableEx:TTableEx);
     procedure Reload(Date:TDate);
     procedure Update(Index: Integer);
     procedure Delete(Index: Integer); override;
     procedure Save;
     property DataBase:TDB read FDataBase write SetDataBase;
   end;

   TTaskItems = class;

   TTaskType = (ttSimple, ttRepeatInDay, ttRepeatInWeek, ttRepeatInMonth, ttRepeatInYear);

   TTaskRepeat = string; //��� � ���� {1..24} � ��� ������ {1..7} � ��� ������ {1..31} � ������ {1..12}

   TTaskItem = class(TObject)
    private
     FName: string;
     FDateCreate: TDateTime;
     FDateNotify: TDateTime;
     FParent: Integer;
     FDeadline: Boolean;
     FOwner: TTaskItems;
     FNotifyComplete: Boolean;
     FDateDeadline: TDateTime;
     FID: Integer;
     FDescription: string;
     FTaskType: TTaskType;
     FTaskRepeat:string;
     FSaved:Boolean;
     function GetTaskRepeat(Index: Byte): Boolean;
     procedure SetDateCreate(const Value: TDateTime);
     procedure SetDateDeadline(const Value: TDateTime);
     procedure SetDateNotify(const Value: TDateTime);
     procedure SetDescription(const Value: string);
     procedure SetID(const Value: Integer);
     procedure SetName(const Value: string);
     procedure SetNotifyComplete(const Value: Boolean);
     procedure SetOwner(const Value: TTaskItems);
     procedure SetParent(const Value: Integer);
     procedure SetTaskRepeat(Index: Byte; const Value: Boolean);
     procedure SetTaskType(const Value: TTaskType);
     procedure SetDeadline(const Value: Boolean);
    public
     constructor Create(AOwner: TTaskItems);
     procedure Update;
     property Owner:TTaskItems read FOwner write SetOwner;
     property ID:Integer read FID write SetID;
     property Parent:Integer read FParent write SetParent;
     property Name:string read FName write SetName;
     property Description:string read FDescription write SetDescription;
     property DateCreate:TDateTime read FDateCreate write SetDateCreate;
     property TaskType:TTaskType read FTaskType write SetTaskType;
     property TaskRepeat[Index:Byte]:Boolean read GetTaskRepeat write SetTaskRepeat;
     property DateDeadline:TDateTime read FDateDeadline write SetDateDeadline;
     property DateNotify:TDateTime read FDateNotify write SetDateNotify;
     property NotifyComplete:Boolean read FNotifyComplete write SetNotifyComplete;
     property Deadline:Boolean read FDeadline write SetDeadline;
     property Saved:Boolean read FSaved;
   end;
//000000000000000000000000000000
   TTaskItems = class(TTableData<TTaskItem>)
    const
     tnTable = 'TaskItems';
     fnID = 'tkID';
     fnParent = 'tkParent';
     fnName = 'tkName';
     fnDesc = 'tkDesc';
     fnDateCreate = 'tkDateCreate';
     fnTaskType = 'tkTaskType';
     fnTaskRepeat = 'tkTaskRepeat';
     fnDateDeadline = 'tkDateDeadline';
     fnDateNotify = 'tkDateNotify';
     fnNotifyComplete = 'tkNotifyComplete';
     fnDeadline = 'tkDeadline';
    private
     FDataBase: TDB;
     procedure SetDataBase(const Value: TDB);
    public
     constructor Create(ADataBase:TDB; ATableEx:TTableEx);
     procedure Reload(Date:TDate = 0);
     procedure Update(Index: Integer);
     procedure Delete(Index: Integer); override;
     procedure Save;
     property DataBase:TDB read FDataBase write SetDataBase;
   end;

implementation

{ TTimeItem }

constructor TTimeItem.Create(AOwner: TTimeItems);
begin
 inherited Create;
 FID:=-1;
 FTask:=-1;
 Owner:=AOwner;
end;

procedure TTimeItem.SetDate(const Value: TDate);
begin
 FDate := Value;
end;

procedure TTimeItem.SetDescription(const Value: string);
begin
 FDescription := Value;
end;

procedure TTimeItem.SetID(const Value: Integer);
begin
 FID := Value;
end;

procedure TTimeItem.SetOwner(const Value: TTimeItems);
begin
 FOwner:=Value;
end;

procedure TTimeItem.SetTask(const Value: Integer);
begin
 FTask := Value;
end;

procedure TTimeItem.SetTimeFrom(const Value: TTime);
begin
  FTimeFrom := Value;
end;

procedure TTimeItem.SetTimeTo(const Value: TTime);
begin
  FTimeTo := Value;
end;

{ TDB }

constructor TDB.Create(FileName: string);
begin
 FCreated:=False;
 try
  FDataBase:=TSQLiteDatabase.Create(FileName);
  FCreated:=True;
 finally

 end;
end;

{ TTimeItems }

constructor TTimeItems.Create(ADataBase: TDB; ATableEx:TTableEx);
begin
 inherited Create(ATableEx);
 FDataBase:=ADataBase;
 if not FDataBase.DB.TableExists(tnTable) then
  with SQL.CreateTable(tnTable) do
   begin
    AddField(fnID, ftInteger, True, True);
    AddField(fnDesc, ftString);
    AddField(fnTimeFrom, ftDateTime);
    AddField(fnTimeTo, ftDateTime);
    AddField(fnDate, ftDateTime);
    FDataBase.DB.ExecSQL(GetSQL);
    EndCreate;
   end;
end;

procedure TTimeItems.Delete(Index: Integer);
begin
 with SQL.Delete(tnTable) do
  begin
   WhereFieldEqual(fnID, Items[Index].ID);
   DataBase.DB.ExecSQL(GetSQL);
   EndCreate;
  end;
 inherited;
end;

procedure TTimeItems.Reload;
var Table:TSQLiteTable;
    Item:TTimeItem;
begin
 BeginUpdate;
 Clear;
 try
  with SQL.Select(tnTable) do
   begin
    AddField(fnID);
    AddField(fnTask);
    AddField(fnDesc);
    AddField(fnTimeFrom);
    AddField(fnTimeTo);
    AddField(fnDate);
    if Date <> 0 then
     WhereFieldEqual(fnDate, Trunc(Date));
    OrderBy(fnTimeFrom, True);
    Table:=FDataBase.DB.GetTable(GetSQL);
    EndCreate;
    Table.MoveFirst;
    while not Table.EOF do
     begin
      Item:=TTimeItem.Create(Self);
      Item.ID:=Table.FieldAsInteger(0);
      Item.Task:=Table.FieldAsInteger(1);
      Item.Description:=Table.FieldAsString(2);
      Item.TimeFrom:=Frac(Table.FieldAsDateTime(3));
      Item.TimeTo:=Frac(Table.FieldAsDateTime(4));
      Item.Date:=Trunc(Table.FieldAsDateTime(5));
      Add(Item);
      Table.Next;
     end;
    Table.Free;
   end;
 finally
  EndUpdate;
 end;
end;

procedure TTimeItems.Update(Index:Integer);
begin
 if Items[Index].ID < 0 then
  with SQL.InsertInto(tnTable) do
   begin
    AddValue(fnTask, Items[Index].Task);
    AddValue(fnDesc, Items[Index].Description);
    AddValue(fnTimeFrom, Items[Index].TimeFrom);
    AddValue(fnTimeTo, Items[Index].TimeTo);
    AddValue(fnDate, Items[Index].Date);
    DataBase.DB.ExecSQL(GetSQL);
    Items[Index].ID:=DataBase.DB.GetLastInsertRowID;
    EndCreate;
   end
 else
  with SQL.Update(tnTable) do
   begin
    AddValue(fnTask, Items[Index].Task);
    AddValue(fnDesc, Items[Index].Description);
    AddValue(fnTimeFrom, Items[Index].TimeFrom);
    AddValue(fnTimeTo, Items[Index].TimeTo);
    AddValue(fnDate, Items[Index].Date);
    WhereFieldEqual(fnID, Items[Index].ID);
    DataBase.DB.ExecSQL(GetSQL);
    EndCreate;
   end;
end;

procedure TTimeItems.Save;
var i:Integer;
begin
 for i := 0 to Count-1 do Update(i);
end;

procedure TTimeItems.SetDataBase(const Value: TDB);
begin
 FDataBase:=Value;
end;

{ TTaskItem }

constructor TTaskItem.Create(AOwner: TTaskItems);
begin
 inherited Create;
 FSaved:=False;
 FID:=-1;
 FParent:=-1;
 FDeadline:=False;
 FTaskRepeat:='0000000000000000000000000000000';
 Owner:=AOwner;
end;

function TTaskItem.GetTaskRepeat(Index: Byte): Boolean;
begin
 Result:=FTaskRepeat[Index] = '1';
end;

procedure TTaskItem.SetDateCreate(const Value: TDateTime);
begin
 FDateCreate:=Value;
end;

procedure TTaskItem.SetDateDeadline(const Value: TDateTime);
begin
 FDateDeadline:=Value;
end;

procedure TTaskItem.SetDateNotify(const Value: TDateTime);
begin
 FDateNotify:=Value;
end;

procedure TTaskItem.SetDeadline(const Value: Boolean);
begin
 FDeadline := Value;
end;

procedure TTaskItem.SetDescription(const Value: string);
begin
 FDescription:=Value;
end;

procedure TTaskItem.SetID(const Value: Integer);
begin
 FID:=Value;
end;

procedure TTaskItem.SetName(const Value: string);
begin
 FName:=Value;
end;

procedure TTaskItem.SetNotifyComplete(const Value: Boolean);
begin
 FNotifyComplete:=Value;
end;

procedure TTaskItem.SetOwner(const Value: TTaskItems);
begin
 FOwner:=Value;
end;

procedure TTaskItem.SetParent(const Value: Integer);
begin
 FParent:=Value;
end;

procedure TTaskItem.SetTaskRepeat(Index: Byte; const Value: Boolean);
begin
 if Value then FTaskRepeat[Index]:='1' else FTaskRepeat[Index]:='0';
end;

procedure TTaskItem.SetTaskType(const Value: TTaskType);
begin
 FTaskType:=Value;
end;

procedure TTaskItem.Update;
begin
 FSaved:=True;
end;

{ TTaskItems }

constructor TTaskItems.Create(ADataBase: TDB; ATableEx: TTableEx);
begin
 inherited Create(ATableEx);
 FDataBase:=ADataBase;
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
    AddField(fnDateNotify, ftDateTime);
    AddField(fnNotifyComplete, ftBoolean);
    AddField(fnDeadline, ftBoolean);
    FDataBase.DB.ExecSQL(GetSQL);
    EndCreate;
   end;
end;

procedure TTaskItems.Delete(Index: Integer);
begin
 with SQL.Delete(tnTable) do
  begin
   WhereFieldEqual(fnID, Items[Index].ID);
   DataBase.DB.ExecSQL(GetSQL);
   EndCreate;
  end;
 inherited;
end;

procedure TTaskItems.Reload(Date: TDate = 0);
var Table:TSQLiteTable;
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
    AddField(fnDateNotify);
    AddField(fnNotifyComplete);
    AddField(fnDeadline);
    if Date <> 0 then
     begin
      WhereFieldEqual(fnDateCreate, Trunc(Date));
      WhereFieldEqual(fnDeadline, False, wuOR);
     end
    else WhereFieldEqual(fnDeadline, False);
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
      Item.DateCreate:=Table.FieldAsDateTime(4);
      Item.TaskType:=TTaskType(Table.FieldAsInteger(5));
      Item.FTaskRepeat:=Table.FieldAsString(6);
      Item.DateDeadline:=Table.FieldAsDateTime(7);
      Item.DateNotify:=Table.FieldAsDateTime(8);
      Item.NotifyComplete:=Table.FieldAsBoolean(9);
      Item.Deadline:=Table.FieldAsBoolean(10);
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
 for i := 0 to Count-1 do Update(i);
end;

procedure TTaskItems.SetDataBase(const Value: TDB);
begin
 FDataBase:=Value;
end;

procedure TTaskItems.Update(Index: Integer);
begin
 if Items[Index].ID < 0 then
  with SQL.InsertInto(tnTable) do
   begin
    AddValue(fnParent, Items[Index].Parent);
    AddValue(fnName, Items[Index].Name);
    AddValue(fnDesc, Items[Index].Description);
    AddValue(fnDateCreate, Items[Index].DateCreate);
    AddValue(fnTaskType, Ord(Items[Index].TaskType));
    AddValue(fnTaskRepeat, Items[Index].FTaskRepeat);
    AddValue(fnDateDeadline, Items[Index].DateDeadline);
    AddValue(fnDateNotify, Items[Index].DateNotify);
    AddValue(fnNotifyComplete, Items[Index].NotifyComplete);
    AddValue(fnDeadline, Items[Index].Deadline);
    DataBase.DB.ExecSQL(GetSQL);
    Items[Index].ID:=DataBase.DB.GetLastInsertRowID;
    EndCreate;
   end
 else
  with SQL.Update(tnTable) do
   begin
    AddValue(fnParent, Items[Index].Parent);
    AddValue(fnName, Items[Index].Name);
    AddValue(fnDesc, Items[Index].Description);
    AddValue(fnDateCreate, Items[Index].DateCreate);
    AddValue(fnTaskType, Ord(Items[Index].TaskType));
    AddValue(fnTaskRepeat, Items[Index].FTaskRepeat);
    AddValue(fnDateDeadline, Items[Index].DateDeadline);
    AddValue(fnDateNotify, Items[Index].DateNotify);
    AddValue(fnNotifyComplete, Items[Index].NotifyComplete);
    AddValue(fnDeadline, Items[Index].Deadline);
    WhereFieldEqual(fnID, Items[Index].ID);
    DataBase.DB.ExecSQL(GetSQL);
    EndCreate;
   end;
 Items[Index].Update;
end;

end.
