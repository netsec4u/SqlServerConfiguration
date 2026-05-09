---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: https://github.com/netsec4u/SqlServerConfiguration/blob/main/docs/Set-SqlServerStartupParameter.md
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 05/08/2026
PlatyPS schema version: 2024-05-01
title: Set-SqlServerStartupParameter
---

# Set-SqlServerStartupParameter

## SYNOPSIS

Sets a SQL Server startup parameter value.

## SYNTAX

### ServerInstance (Default)

```
Set-SqlServerStartupParameter
  -ServerInstance <string>
  -Name <StartupParameter>
  -Value <string>
  [-ServiceRestart]
  [-WhatIf]
  [-Confirm]
  [<CommonParameters>]
```

### SmoServerObject

```
Set-SqlServerStartupParameter
  -SmoServerObject <Server>
  -Name <StartupParameter>
  -Value <string>
  [-ServiceRestart]
  [-WhatIf]
  [-Confirm]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Sets a SQL Server startup parameter value.

## EXAMPLES

### Example 1

```powershell
Set-SqlServerStartupParameter -ServerInstance MyServer -Name ErrorLogPath -Value 'C:\ERRORLOG'
```

Sets SQL Server startup parameter ErrorLogPath on server MyServer.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Set-SqlServerStartupParameter -SmoServerObject $SmoServer -Name ErrorLogPath -Value 'C:\ERRORLOG'
```

Sets SQL Server startup parameter ErrorLogPath using SMO session.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

The name of the startup parameter to set.

```yaml
Type: SqlServerConfiguration.StartupParameter
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServerInstance

SQL Server host name and instance name.

```yaml
Type: System.String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ServerInstance
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServiceRestart

Restart the SQL Server service after making changes.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SmoServerObject

An existing SMO Server object representing the SQL Server instance.

```yaml
Type: Microsoft.SqlServer.Management.Smo.Server
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SmoServerObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Value

The value of the startup parameter for parameters that requires a value.

```yaml
Type: System.String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Void



## NOTES




## RELATED LINKS

