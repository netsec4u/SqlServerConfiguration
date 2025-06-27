---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Add-SqlServerStartupParameter

## SYNOPSIS
Add startup parameter to SQL Server.

## SYNTAX

### ServerInstance (Default)
```
Add-SqlServerStartupParameter
	-ServerInstance <String>
	-Name <StartupParameter>
	[-Value <String>]
	[-ServiceRestart]
	[-WhatIf]
	[-Confirm]
	[<CommonParameters>]
```

### SmoServerObject
```
Add-SqlServerStartupParameter
	-SmoServerObject <Server>
	-Name <StartupParameter>
	[-Value <String>]
	[-ServiceRestart]
	[-WhatIf]
	[-Confirm]
	[<CommonParameters>]
```

## DESCRIPTION
Add startup parameter to SQL Server.

## EXAMPLES

### Example 1
```powershell
Add-SqlServerStartupParameter -ServerInstance MyServer -Name TraceFlag -Value 1234
```

Adds trace flag 1234 on MyServer.

### Example 2
```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer

Add-SqlServerStartupParameter -SmoServerObject $SmoServer -Name TraceFlag -Value 1234
```

Adds trace flag 1234 using the specified Smo session.

## PARAMETERS

### -Name
The name of the startup option.

```yaml
Type: StartupParameter
Parameter Sets: (All)
Aliases:
Accepted values: MasterFilePath, IncreaseExtentsAllocated, ErrorLogPath, MinimalConfigurationMode, CheckpointIORequestsPerSecond, MasterLogFilePath, SingleUserMode, DisableApplicationLogLogging, TraceFlag, DisableMonitoringFeatures

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServerInstance
SQL Server host name and instance name.

```yaml
Type: String
Parameter Sets: ServerInstance
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceRestart
Restart SQL Server service.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmoServerObject
SMO Server object

```yaml
Type: Server
Parameter Sets: SmoServerObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Specifies the value of the startup parameter for parameters that requires a value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
