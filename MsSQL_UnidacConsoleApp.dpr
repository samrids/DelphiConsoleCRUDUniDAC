program MsSQL_UnidacConsoleApp;

{
  Delphi : Building a Windows CRUD Console Application with UniDAC + MSSQL

  This "CRUD"* console application demonstrates the essential steps for creating
  a Windows application in Delphi.

  Remark CRUD*
    C = Create
    R = Read
    U = Update
    D = Delete

  Platform   : Win32 Console Appplication
  Database   : MSSQL Server

  Components:
     - TDataModule
     - TSQLServerUniProvider
     - TUniConnection
     - TUniQuery
     - TUniTransaction

  Data Schema

  CREATE TABLE Persons(
    id] [int IDENTITY(1,1) NOT NULL,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255) NULL,
    Age int NULL
  )

}
{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  ActiveX,
  ComObj,
  System.Classes,
  Data.DB,
  DBAccess,
  Uni,
  MemDS,
  UniProvider,
  SQLServerUniProvider;

var
  DataModule1: TDataModule;
  UniConnection1: TUniConnection;
  TsUpdate: TUniTransaction;
  SQLServerUniProvider1: TSQLServerUniProvider;
  UniQuery1: TUniQuery;
  MenuIdx: byte;

  //Initial Component
procedure Initial;
begin
  CoInitializeEx(nil, COINIT_MULTITHREADED);

  DataModule1 := TDataModule.Create(nil);
  SQLServerUniProvider1 := TSQLServerUniProvider.Create(DataModule1);

  UniConnection1 := TUniConnection.Create(DataModule1);
  UniConnection1.LoginPrompt := False;

  UniQuery1 := TUniQuery.Create(DataModule1);
  UniQuery1.Connection := UniConnection1;

  TsUpdate := TUniTransaction.Create(DataModule1);
  TsUpdate.DefaultConnection := UniConnection1;
  UniQuery1.UpdateTransaction := TsUpdate;
end;

//Destroy and Free Components
procedure DestroyObj;
begin
  UniConnection1.Disconnect;
  UniQuery1.Free;
  TsUpdate.Free;
  DataModule1.Free;
end;

//Restore Connection
procedure RestoreConnection;
begin
  if UniConnection1.Connected then
    UniConnection1.Close;

  UniConnection1.ProviderName := 'SQL Server';
  UniConnection1.Server := 'localhost';
  UniConnection1.Username := 'user_delphi';
  UniConnection1.Password := '12345678';
  UniConnection1.Database := 'test';
  try
    UniConnection1.Connect;
    if UniConnection1.Connected then
      Writeln(format('Connected to server: %s', [UniConnection1.Server]))
    else
      Writeln(format('Disconnected %s', [UniConnection1.Server]))
  except
    on E: Exception do
    begin
      Writeln(E.Message);
    end;
  end;
end;

//Menu
procedure Menu;
  //Read data from database
  procedure ReadAll;
  var
    MenuId: Char;
  begin
    UniQuery1.SQL.Clear;
    UniQuery1.SQL.Add('SELECT Id, FirstName, LastName, Age FROM Persons');
    try
      UniQuery1.Open;
      Writeln;
      Writeln('--------------------------------------------------------');
      Writeln(format('List of Persons %d record(s)', [UniQuery1.RecordCount]));
      Writeln('--------------------------------------------------------');
      Writeln(format('%s %s %s %s %s %s %s', ['Id', Chr(9), 'First Name',
        Chr(9), 'Last Name', Chr(9), 'Age']));
      UniQuery1.First;
      while not UniQuery1.Eof do
      begin
        Writeln(format('%d %s %s %s %s %s %d',
          [UniQuery1.FieldbyName('id').AsInteger, Chr(9),
          UniQuery1.FieldbyName('FirstName').AsString, Chr(9),
          UniQuery1.FieldbyName('LastName').AsString, Chr(9),
          UniQuery1.FieldbyName('Age').AsInteger]));
        UniQuery1.Next;
      end;
      UniQuery1.Close;
      Writeln;
      repeat
        Write('Please press 0 to return to Top Menu: ');
        Readln(MenuId);
      until (MenuId = '0');
      Menu;
    except
      on E: Exception do
      begin
        UniQuery1.UpdateTransaction.Rollback;
        Writeln(E.ClassName, ': ', E.Message);
      end;
    end;
  end;

  //Create Person
  procedure CreateNew;
  var
    FName, LName: String;
    Age: byte;
  begin
    repeat
      Write('Please enter First Name: ');
      Readln(FName);
    until (Length(Trim(FName)) > 0);

    repeat
      Write('Please enter Last name: ');
      Readln(LName);
    until (Length(Trim(LName)) > 0);

    Age := 0;
    repeat
      Write('Please enter Age:');
      try
        Readln(Age);
      except
        on E: EInOutError do
        begin
          Age := 0;
        end;
      end;
    until (Age > 0);

    UniQuery1.SQL.Clear;
    UniQuery1.SQL.Add('INSERT INTO Persons (FirstName, LastName, Age)');
    UniQuery1.SQL.Add(format('VALUES(%s, %s, %d)', [QuotedStr(FName),
      QuotedStr(LName), Age]));

    UniQuery1.UpdateTransaction.StartTransaction;
    try
      UniQuery1.Execute;
      UniQuery1.UpdateTransaction.Commit;
      Writeln('Created new person complete');
      Menu;
    except
      on E: Exception do
      begin
        UniQuery1.UpdateTransaction.Rollback;
        Writeln(E.ClassName, ': ', E.Message);
      end;
    end;
  end;

  //Update Person
  procedure UpdatePerson;
  var
    Id: Integer;
    UpdateIdx: byte;
    FName, LName: String;
    Age: byte;

    procedure UpdateMod;
    begin
      Writeln('');
      Writeln('Update mode, Please choosen mode:');
      Writeln('=========================================================');
      Writeln('1 : Select new person Id');
      Writeln('2 : Update First Name');
      Writeln('3 : Update Last Name');
      Writeln('4 : Update Age');
      Writeln('----------------------------');
      Writeln('0 : Return to Top menu');
      Writeln('----------------------------');
      Write('Please selection item (0..4): ');
      try
        Readln(UpdateIdx);
      except
        on E: EInOutError do
        begin
          Id := 99;
        end;
      end;
    end;

    procedure SelectedPerson;
    begin
      Write('Please enter Id: ');
      try
        Readln(Id);
      except
        on E: EInOutError do
        begin
          Id := 0;
        end;
      end;
    end;

    procedure UpdateToDBServer;
    begin
      case UpdateIdx of
        2:
          begin
            repeat
              Write('Please enter Firstname: ');
              Readln(FName);
            until (Length(Trim(FName)) > 0);
            UniQuery1.SQL.Add
              (format('UPDATE Persons SET FirstName = %s where id = %d',
              [QuotedStr(FName), Id]));
          end;
        3:
          begin
            Write('Please enter Lastname: ');
            repeat
              Write('Please enter Last name: ');
              Readln(LName);
            until (Length(Trim(LName)) > 0);
            UniQuery1.SQL.Add
              (format('UPDATE Persons SET LastName = %s where id = %d',
              [QuotedStr(LName), Id]));
          end;
        4:
          begin
            repeat
              Write('Please enter Age:');
              try
                Readln(Age);
              except
                on E: EInOutError do
                begin
                  Age := 0;
                end;
              end;
            until (Age > 0);
            UniQuery1.SQL.Add
              (format('UPDATE Persons SET Age = %d where id = %d', [Age, Id]));
          end;
      else
        Write('Please Enter 1 .. 4');
      end;
      UniQuery1.UpdateTransaction.StartTransaction;
      try
        UniQuery1.Execute;
        UniQuery1.UpdateTransaction.Commit;
        Writeln(format('Updated Person with id: %d success!', [Id]));
      except
        on E: Exception do
        begin
          UniQuery1.UpdateTransaction.Rollback;
          Writeln(E.ClassName, ': ', E.Message);
        end;
      end;
    end;

  begin
    UpdateIdx := 1;

    repeat
      if UpdateIdx = 1 then
        SelectedPerson;

      UpdateMod;

      UniQuery1.SQL.Clear;
      case UpdateIdx of
        0:
          Menu;
        1:
          begin
            SelectedPerson;
            UpdateToDBServer;
          end;
        2, 3, 4:
          begin
            UpdateToDBServer;
          end;
      end;

    until (UpdateIdx = 0);
  end;

  //Delete person by Id
  procedure DeletePerson;
  var
    Id: Integer;
  begin
    Write('Delete Person, please enter Person Id: ');
    try
      Readln(Id);
    except
      on E: EInOutError do
      begin
        Id := 0;
      end;
    end;

    UniQuery1.SQL.Clear;
    UniQuery1.SQL.Add(format('DELETE FROM Persons WHERE id = %d', [Id]));

    UniQuery1.UpdateTransaction.StartTransaction;
    try
      UniQuery1.Execute;
      UniQuery1.UpdateTransaction.Commit;
      Writeln(format('Delete Person with Id %d from System', [Id]));
      Menu;
    except
      on E: Exception do
      begin
        UniQuery1.UpdateTransaction.Rollback;
        Writeln(E.ClassName, ': ', E.Message);
      end;
    end;
  end;

begin
  //Main Application
  Writeln('');
  Writeln('Delphi: Demo CRUD: Console application with UniDAC + MSSQL');
  Writeln('=========================================================');
  Writeln('1 : Create new Person');
  Writeln('2 : Read Persons');
  Writeln('3 : Update Person');
  Writeln('4 : Delete Person');
  Writeln('0 : Exit');

  Write('Press choose menu (0..4) [0 = Exit] : ');
  try
    Readln(MenuIdx);
  except
    on E: EInOutError do
    begin
      MenuIdx := 99; // Dummy
    end;
  end;

  case MenuIdx of
    0:
      Exit;
    1:
      CreateNew;
    2:
      ReadAll;
    3:
      UpdatePerson;
    4:
      DeletePerson;
  else
    Write('Please Enter 0 .. 4');
  end;
end;

begin
  try
    Initial;
    RestoreConnection;

    repeat
      Menu;
    until (MenuIdx = 0);

    DestroyObj;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
