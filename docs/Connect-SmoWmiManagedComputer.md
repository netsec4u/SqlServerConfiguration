---
document type: cmdlet
external help file: SqlServerConfiguration-help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 07/29/2025
PlatyPS schema version: 2024-05-01
title: Connect-SmoWmiManagedComputer
---

# Connect-SmoWmiManagedComputer

## SYNOPSIS

Connects to SMO WMI Managed Computer.

## SYNTAX

### __AllParameterSets

```
Connect-SmoWmiManagedComputer
  -ComputerName <string>
  [-Credential <pscredential>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Connects to SMO WMI Managed Computer.

## EXAMPLES

### Example 1

Connect-SmoWmiManagedComputer -ComputerName MyServer

Connects to MyServer SMO WMI manged computer.

## PARAMETERS

### -ComputerName

Specifies the computer name.

```yaml
Type: System.String
DefaultValue: None
SupportsWildcards: false
Aliases:
- SqlServer
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Specifies a user account that has permission to perform this action.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: None
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String



## OUTPUTS

### Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer



## NOTES




## RELATED LINKS

None.

