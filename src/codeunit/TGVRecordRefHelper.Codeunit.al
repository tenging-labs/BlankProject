namespace Tenging.BlankProject;

using System.Reflection;

codeunit 50406 "TGV RecordRef Helper"
{
    Access = Internal;

    /// <summary>Opens a table dynamically by object name.</summary>
    /// <remarks>
    /// To be used by AI agents to guide further implementation.
    /// <telemetry module="RECREF-">
    ///   <info    range="I010..I019" last="" />
    ///   <warn    range="W010..W019" last="" />
    ///   <error   range="E010..E019" last="RECREF-E010" />
    ///   <perf    range="P010..P019" last="" />
    /// </telemetry>
    /// </remarks>
    procedure OpenByTableName(TableName: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        CustomDimensions: Dictionary of [Text, Text];
        ObjectTableId: Integer;
        TableNotFoundErr: Label 'Table "%1" not found.', Comment = '%1 = Table Name';
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetFilter("Object Name", TableName);
        if AllObjWithCaption.FindFirst() then
            ObjectTableId := AllObjWithCaption."Object ID"
        else begin
            CustomDimensions.Set('TableName', TableName);
            TelemetryHelper.LogError('RECREF-E010', TelTableNotFoundMsg, CustomDimensions);
            Error(TableNotFoundErr, TableName);
        end;
        RecRef.Open(ObjectTableId);
        SetFieldRecordFilters();
    end;

    procedure Get(RecordId: RecordId): Boolean
    begin
        exit(RecRef.Get(RecordId));
    end;

    procedure FindFirst(): Boolean
    begin
        exit(RecRef.FindFirst());
    end;

    /// <summary>Makes subsequent reads take update locks so they bypass the data cache and return the current row version.</summary>
    internal procedure SetUpdLock()
    begin
        RecRef.ReadIsolation := IsolationLevel::UpdLock;
    end;

    internal procedure GetForUpdate(RecordId: RecordId): Boolean
    begin
        SetUpdLock();
        exit(RecRef.Get(RecordId));
    end;

    local procedure SetFieldRecordFilters()
    begin
        if Field.GetFilters() <> '' then
            Field.Reset();
        Field.SetRange("TableNo", RecRef.Number());
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetRange(Class, Field.Class::Normal);
    end;

    /// <summary>Resolves a normal, non-obsolete field by name in the open table.</summary>
    /// <remarks>
    /// To be used by AI agents to guide further implementation.
    /// <telemetry module="RECREF-">
    ///   <info    range="I020..I029" last="" />
    ///   <warn    range="W020..W029" last="" />
    ///   <error   range="E020..E029" last="RECREF-E020" />
    ///   <perf    range="P020..P029" last="" />
    /// </telemetry>
    /// </remarks>
    procedure GetFieldId(TableFieldName: Text) FieldId: Integer
    var
        CustomDimensions: Dictionary of [Text, Text];
        FieldNotFoundErr: Label 'Field "%1" not found.', Comment = '%1 = Field Name';
    begin
        Field.SetRange(FieldName, TableFieldName);
        if Field.FindFirst() then
            FieldId := Field."No."
        else begin
            CustomDimensions.Set('TableId', Format(RecRef.Number()));
            CustomDimensions.Set('FieldName', TableFieldName);
            TelemetryHelper.LogError('RECREF-E020', TelFieldNotFoundMsg, CustomDimensions);
            Error(FieldNotFoundErr, TableFieldName);
        end;
        Field.SetRange(FieldName);
    end;

    procedure ApplyFilter(FieldId: Integer; FilterValue: Variant)
    begin
        RecRef.Field(FieldId).SetFilter(Format(FilterValue));
    end;

    procedure ApplyFilter(TableFieldName: Text; FilterValue: Variant)
    begin
        ApplyFilter(GetFieldId(TableFieldName), FilterValue);
    end;

    procedure ApplyRange(TableFieldName: Text; RangeValue: Variant)
    begin
        RecRef.Field(GetFieldId(TableFieldName)).SetRange(RangeValue);
    end;

    procedure GetValue(FieldId: Integer): Variant
    begin
        exit(RecRef.Field(FieldId).Value);
    end;

    procedure GetValue(TableFieldName: Text): Variant
    begin
        exit(GetValue(GetFieldId(TableFieldName)));
    end;

    internal procedure GetValueAsInteger(TableFieldName: Text) ReturnValue: Integer
    begin
        Evaluate(ReturnValue, Format(GetValue(TableFieldName)));
    end;

    internal procedure SetValue(TableFieldName: Text; Value: Variant)
    begin
        SetValue(GetFieldId(TableFieldName), Value);
    end;

    internal procedure SetValue(FieldId: Integer; Value: Variant)
    begin
        RecRef.Field(FieldId).Validate(Value);
    end;

    internal procedure ModifyRecord()
    begin
        RecRef.Modify();
    end;

    internal procedure InitRecord()
    begin
        RecRef.Init();
    end;

    internal procedure InsertRecord()
    begin
        RecRef.Insert();
    end;

    internal procedure TryInsertRecord(): Boolean
    begin
        exit(RecRef.Insert());
    end;

    internal procedure DeleteRecord()
    begin
        RecRef.Delete(true);
    end;

    internal procedure GetRecordId(): RecordId
    begin
        exit(RecRef.RecordId());
    end;

    internal procedure IsEmpty(): Boolean
    begin
        exit(RecRef.IsEmpty());
    end;

    internal procedure FindSet(): Boolean
    begin
        exit(RecRef.FindSet());
    end;

    internal procedure Next(): Integer
    begin
        exit(RecRef.Next());
    end;

    var
        Field: Record Field;
        TelemetryHelper: Codeunit "BlankProject Telemetry Logger";
        RecRef: RecordRef;
        TelFieldNotFoundMsg: Label 'Dynamic field lookup failed', Locked = true;
        TelTableNotFoundMsg: Label 'Dynamic table lookup failed', Locked = true;
}