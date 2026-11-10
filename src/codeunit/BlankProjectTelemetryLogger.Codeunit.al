namespace Tenging.BlankProject;
using System.Telemetry;

codeunit 50413 "BlankProject Telemetry Logger" implements "Telemetry Logger"
{
    Access = Internal;

    var
        Telemetry: Codeunit Telemetry;
        EventIdPrefixTok: Label '-BP-', Locked = true;

    procedure LogMessage(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; TelemetryScope: TelemetryScope; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope, CustomDimensions);
    end;

    /// <summary>Log the start of a procedure or operation.</summary>
    procedure LogStart(EventId: Text; Message: Text; CustomDimensions: Dictionary of [Text, Text])
    begin
        Telemetry.LogMessage(EventIdPrefixTok + EventId, Message,
            Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    /// <summary>Log the successful end of a procedure or operation, automatically appending duration.</summary>
    procedure LogEnd(EventId: Text; Message: Text; StartTime: DateTime; var CustomDimensions: Dictionary of [Text, Text])
    var
        Duration: Duration;
    begin
        Duration := CurrentDateTime - StartTime;
        if not CustomDimensions.ContainsKey('Duration') then
            CustomDimensions.Set('Duration', Format(Duration));
        if not CustomDimensions.ContainsKey('DurationMs') then
            CustomDimensions.Set('DurationMs', Format(Duration / 1));
        Telemetry.LogMessage(EventIdPrefixTok + EventId, Message,
            Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    /// <summary>Log an error, automatically appending error text and call stack.</summary>
    procedure LogError(EventId: Text; Message: Text; var CustomDimensions: Dictionary of [Text, Text])
    begin
        if not CustomDimensions.ContainsKey('ErrorCallStack') then
            CustomDimensions.Set('ErrorCallStack', GetLastErrorCallStack());
        if not CustomDimensions.ContainsKey('ErrorText') then
            CustomDimensions.Set('ErrorText', GetLastErrorText());
        Telemetry.LogMessage(EventIdPrefixTok + EventId, Message,
            Verbosity::Error, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    /// <summary>Log a warning.</summary>
    procedure LogWarning(EventId: Text; Message: Text; CustomDimensions: Dictionary of [Text, Text])
    begin
        Telemetry.LogMessage(EventIdPrefixTok + EventId, Message,
            Verbosity::Warning, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    /// <summary>Log a performance warning only if the elapsed time exceeds the given threshold in milliseconds.</summary>
    procedure LogIfDurationExceedsThreshold(EventId: Text; Message: Text; StartTime: DateTime; ThresholdMs: Integer; var CustomDimensions: Dictionary of [Text, Text])
    var
        Duration: Duration;
    begin
        Duration := CurrentDateTime() - StartTime;
        if Duration > ThresholdMs then begin
            if not CustomDimensions.ContainsKey('Duration') then
                CustomDimensions.Set('Duration', Format(Duration));
            if not CustomDimensions.ContainsKey('DurationMs') then
                CustomDimensions.Set('DurationMs', Format(Duration / 1));
            if not CustomDimensions.ContainsKey('ThresholdMs') then
                CustomDimensions.Set('ThresholdMs', Format(ThresholdMs));
            Telemetry.LogMessage(EventIdPrefixTok + EventId, Message,
                Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, CustomDimensions);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Loggers", OnRegisterTelemetryLogger, '', true, true)]
    local procedure OnRegisterTelemetryLogger(var Sender: Codeunit "Telemetry Loggers")
    begin
        Sender.Register(this);
    end;
}