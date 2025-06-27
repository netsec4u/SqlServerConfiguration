---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Connect-SmoWmiManagedComputer

## SYNOPSIS
Connects to SMO WMI Managed Computer.

## SYNTAX

```
Connect-SmoWmiManagedComputer
	-ComputerName <String>
	[-Credential <PSCredential>]
	[<CommonParameters>]
```

## DESCRIPTION
Connects to SMO WMI Managed Computer.

## EXAMPLES

### Example 1
```powershell
Connect-SmoWmiManagedComputer -ComputerName MyServer
```

Connects to MyServer SMO WMI manged computer.

## PARAMETERS

### -ComputerName
Specifies the computer name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: SqlServer

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Credential
Specifies a user account that has permission to perform this action.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

## NOTES

## RELATED LINKS
