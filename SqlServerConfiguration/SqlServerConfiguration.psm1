#Requires -RunAsAdministrator

Set-StrictMode -Version Latest

#Region Global Configuration
try {
	if ($PSVersionTable.PSEdition -ne 'Desktop') {
		if ($PSVersionTable.Platform -ne 'Win32NT') {
			throw [System.Management.Automation.ErrorRecord]::New(
				[Exception]::New('Platform not supported.'),
				'1',
				[System.Management.Automation.ErrorCategory]::NotImplemented,
				$PSVersionTable.Platform
			)
		}
	}
}
catch {
	throw $_
}
#EndRegion

#Region Enumerations
enum DatabaseMailConfiguration {
	AccountRetryAttempts
	AccountRetryDelay
	DatabaseMailExeMinimumLifeTime
	DefaultAttachmentEncoding
	LoggingLevel
	MaxFileSize
	ProhibitedExtensions
}
enum ServerProtocols {
	Np
	Sm
	Tcp
}

enum SMTPAuthenticationType {
	Anonymous
	Windows
	Basic
}
#EndRegion

#Region Type Definitions
$TypeDefinition = @'
using System;
using System.IO;

namespace SqlServerConfiguration
{
	public class SqlDatabaseMailConfiguration
	{
		public string Name;
		public string Value;
		public string Description;

		public SqlDatabaseMailConfiguration (Microsoft.SqlServer.Management.Smo.Mail.ConfigurationValue ConfigurationValue)
		{
			this.Name = ConfigurationValue.Name;
			this.Value = ConfigurationValue.Value;
			this.Description = ConfigurationValue.Description;
		}
	}

	public class SqlDatabaseMailProfileAccount
	{
		public string ProfileName;
		public string AccountName;
		public int SequenceNumber;
	}

	public class SqlDatabaseMailProfilePrincipal
	{
		public string ProfileName;
		public string PrincipalName;
		public bool IsDefault;
	}

	public class SqlFilestreamSettings
	{
		public uint AccessLevel { get; private set; }
		public string AccessLevelDescription {
			get {
				switch (this.AccessLevel)
				{
					case 0:
						return "Disabled";

					case 1:
						return "FileStream enabled for T-Sql access";

					case 2:
						return "FileStream enabled for T-Sql and IO streaming access";

					case 3:
						return "FileStream enabled for T-Sql, IO streaming, and remote clients";

					default:
						return "Unknown";
				}
			}
		}
		public string ShareName;

		public SqlFilestreamSettings (uint AccessLevel)
		{
			this.AccessLevel = AccessLevel;
		}
	}

	public class SqlProtocolProperty
	{
		public string CertificateThumbprint;
		public bool HideInstance;
		public bool ExtendedProtection;
		public bool RequireEncryption;
		public bool? RequireStrictEncryption;
	}

	public class SqlStartupParameter
	{
		public string Name { get; private set; }
		public string Option  { get; private set; }
		public string Value;
		public string ValueType { get; private set; }

		public SqlStartupParameter (StartupParameter Name, string Value)
		{
			switch (Name.ToString())
			{
				case "MasterFilePath":
					this.Option = "-d";
					break;

				case "IncreaseExtentsAllocated":
					this.Option = "-E";
					break;

				case "ErrorLogPath":
					this.Option = "-e";
					break;

				case "MinimalConfigurationMode":
					this.Option = "-f";
					break;

				case "CheckpointIORequestsPerSecond":
					this.Option = "-k";
					break;

				case "MasterLogFilePath":
					this.Option = "-l";
					break;

				case "SingleUserMode":
					this.Option = "-m";
					break;

				case "DisableApplicationLogLogging":
					this.Option = "-n";
					break;

				case "TraceFlag":
					this.Option = "-T";
					break;

				case "DisableMonitoringFeatures":
					this.Option = "-x";
					break;

				default:
					throw new SqlServerConfiguration.InvalidParameter("Unknown startup parameter.");
			}

			SetProperties(Value);
		}

		public SqlStartupParameter (string Option, string Value)
		{
			this.Option = Option;

			SetProperties(Value);
		}

		private void SetProperties (string Value)
		{
			switch (this.Option)
			{
				case "-d":
					this.Name = "MasterFilePath";
					this.ValueType = "Path";
					break;

				case "-E":
					this.Name = "IncreaseExtentsAllocated";
					this.ValueType = "OptionOnly";
					break;

				case "-e":
					this.Name = "ErrorLogPath";
					this.ValueType = "Path";
					break;

				case "-f":
					this.Name = "MinimalConfigurationMode";
					this.ValueType = "OptionOnly";
					break;

				case "-k":
					this.Name = "CheckpointIORequestsPerSecond";
					this.ValueType = "Number";
					break;

				case "-l":
					this.Name = "MasterLogFilePath";
					this.ValueType = "Path";
					break;

				case "-m":
					this.Name = "SingleUserMode";
					this.ValueType = "OptionOnly";
					break;

				case "-n":
					this.Name = "DisableApplicationLogLogging";
					this.ValueType = "OptionOnly";
					break;

				case "-T":
					this.Name = "TraceFlag";
					this.ValueType = "Number";
					break;

				case "-x":
					this.Name = "DisableMonitoringFeatures";
					this.ValueType = "OptionOnly";
					break;

				default:
					throw new SqlServerConfiguration.InvalidParameter("Unknown startup parameter.");
			}

			switch (this.ValueType)
			{
				case "Number":
					var isNumeric = int.TryParse(Value, out _);
					if (isNumeric == false)
						throw new SqlServerConfiguration.InvalidValue("Integer value is required.");
					break;

				case "OptionOnly":
					if (Value != null)
						throw new SqlServerConfiguration.InvalidValue("Parameter cannot have a value.");
					break;

				case "Path":
					var isPath = ValidateFullyQualifiedPath(ref Value);
					if (isPath == false)
						throw new SqlServerConfiguration.InvalidValue("Fully qualified file path is required.");
					break;
			}

			this.Value = Value;
		}

		public override string ToString()
		{
			if (this.ValueType == "OptionOnly")
			{
				return this.Option;
			}
			else
			{
				return string.Concat(this.Option, this.Value);
			}
		}

		private static bool ValidateFullyQualifiedPath (ref string path)
		{
			if (path.IndexOfAny(Path.GetInvalidPathChars()) == -1)
			{
				try
				{
					if (!Path.IsPathRooted(path))
					{
						return false;
					}

					FileInfo fileInfo = new FileInfo(path);

					return true;
				}
				catch (Exception)
				{
					// Exception
				}
			}
			return false;
		}
	}

	public enum StartupParameter {
		MasterFilePath,
		IncreaseExtentsAllocated,
		ErrorLogPath,
		MinimalConfigurationMode,
		CheckpointIORequestsPerSecond,
		MasterLogFilePath,
		SingleUserMode,
		DisableApplicationLogLogging,
		TraceFlag,
		DisableMonitoringFeatures
	}

	[Serializable]
	public class InvalidParameter : Exception
	{
		public InvalidParameter() : base() { }
		public InvalidParameter(string message) : base(message) { }
		public InvalidParameter(string message, Exception inner) : base(message, inner) { }
	}

	[Serializable]
	public class InvalidValue : Exception
	{
		public InvalidValue() : base() { }
		public InvalidValue(string message) : base(message) { }
		public InvalidValue(string message, Exception inner) : base(message, inner) { }
	}
}
'@

$ReferencedAssemblies = @(
	[AppDomain]::CurrentDomain.GetAssemblies().where({$_.ManifestModule.Name -eq 'Microsoft.SqlServer.Smo.dll'}).Location
	[AppDomain]::CurrentDomain.GetAssemblies().where({$_.ManifestModule.Name -eq 'Microsoft.SqlServer.Management.Sdk.Sfc.dll'}).Location
)

$TypeParameters = @{
	TypeDefinition = $TypeDefinition
	ReferencedAssemblies = $ReferencedAssemblies
	WarningAction = 'Ignore'
	IgnoreWarnings = $true
}

Add-Type @TypeParameters

Remove-Variable -Name @('TypeDefinition')
#EndRegion


#Region Supporting Functions
function Add-CertificatePrivateKeyAccessRule {
	<#
	.SYNOPSIS
	Sets private key access rules.
	.DESCRIPTION
	Sets private key access rules.
	.PARAMETER Certificate
	The certificate to set access rights.
	.PARAMETER Grantee
	Specifies the account to set access rights to.
	.PARAMETER FileSystemRights
	Specifies the access rights use when creating access rule.
	.PARAMETER AccessControlType
	Specifies whether a access is allowed or denied.
	.EXAMPLE
	Add-CertificatePrivateKeyAccessRule -Certificate $Certificate -Grantee domain\JSmith
	.NOTES
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High'
	)]

	[OutputType([Void])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[System.Security.Principal.NTAccount]$Grantee,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateSet('FullControl', 'Read')]
		[System.Security.AccessControl.FileSystemRights]$FileSystemRights = 'Read',

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[System.Security.AccessControl.AccessControlType]$AccessControlType = 'Allow'
	)

	begin {
	}

	process {
		try {
			#$FileSystemAccessRule = [System.Security.AccessControl.FileSystemAccessRule]::New($Grantee, $FileSystemRights, 'None', 'None', $AccessControlType)
			$FileSystemAccessRule = [System.Security.AccessControl.FileSystemAccessRule]::New($Grantee, $FileSystemRights, $AccessControlType)

			$PrivateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)

			$PrivateKeyPath = Get-KeyContainerPath -Name $PrivateKey.key.UniqueName

			$PrivateKeyFileAcl = Get-Acl -Path $PrivateKeyPath.FullName

			$PrivateKeyFileAcl.AddAccessRule($FileSystemAccessRule)

			if ($PSCmdlet.ShouldProcess($PrivateKeyPath.FullName, "Add access rule")) {
				Set-Acl -Path $PrivateKeyPath.FullName -AclObject $PrivateKeyFileAcl
			}
		}
		catch {
			throw $_
		}
	}

	end {
	}
}

function Find-Certificate {
	<#
	.SYNOPSIS
	Finds certificate.
	.DESCRIPTION
	Finds certificate.
	.PARAMETER FindValue
	Specifies the value to search for.
	.PARAMETER StoreLocation
	Specifies the certificate store location to search.
	.PARAMETER StoreName
	Specifies the certificate store to search.
	.PARAMETER X509FindType
	Specifies the Type of value being searched.
	.PARAMETER OpenFlag
	Specifies the flags to use for opening the certificate.
	.PARAMETER ValidOnly
	Specifies to find only valid certificates.
	.EXAMPLE
	Find-Certificate -FindValue '894CB8DF8177ACCC72D0CE14526869C7E549DD50' -StoreLocation 'LocalMachine' -StoreName 'My'
	.EXAMPLE
	Find-Certificate -FindValue '*.domain.com' -X509FindType 'FindBySubjectName' -StoreLocation 'LocalMachine' -StoreName 'My'
	.EXAMPLE
	Find-Certificate -FindValue '*.domain.com' -X509FindType 'FindBySubjectName' -StoreLocation 'LocalMachine' -StoreName '\\server\My'
	.NOTES
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low'
	)]

	[OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2Collection])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[string]$FindValue,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[String]$StoreName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[System.Security.Cryptography.X509Certificates.X509FindType]$X509FindType = 'FindByThumbprint',

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[System.Security.Cryptography.X509Certificates.OpenFlags]$OpenFlag = 'ReadOnly',

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[bool]$ValidOnly = $true
	)

	begin {
	}

	process {
		try {
			try {
				$X509Store = [System.Security.Cryptography.X509Certificates.X509Store]::New($StoreName, $StoreLocation)
				$X509Store.Open($OpenFlag)

				$X509Certificate2Collection = $X509Store.Certificates.Find($X509FindType, $FindValue, $ValidOnly)

				$X509Certificate2Collection
			}
			catch {
				throw $_
			}
		}
		catch {
			throw $_
		}

	}

	end {
	}
}

function Get-CertificateKeySpec {
	<#
	.SYNOPSIS
	Gets the certificate key spec.
	.DESCRIPTION
	Gets the certificate key spec.
	.PARAMETER Thumbprint
	Specifies the certificate thumbprint.
	.PARAMETER StoreLocation
	Specifies the certificate store location to search.
	.PARAMETER StoreName
	Specifies the certificate store to search.
	.EXAMPLE
	Get-CertificateKeySpec -Thumbprint '894CB8DF8177ACCC72D0CE14526869C7E549DD50' -StoreLocation 'LocalMachine' -StoreName 'My'
	.NOTES
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low'
	)]

	[OutputType([System.Security.Cryptography.KeyNumber])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[string]$Thumbprint,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[String]$StoreName
	)

	begin {
		$OpenFlag = [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly
		$X509FindType = [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint
	}

	process {
		try {
			$X509Store = [System.Security.Cryptography.X509Certificates.X509Store]::New($StoreName, $StoreLocation)
			$X509Store.Open($OpenFlag)

			$X509Certificate2Collection = $X509Store.Certificates.Find($X509FindType, $Thumbprint, $true)

			if ($X509Certificate2Collection.Count -gt 1) {
				throw 'found more than one'
			}

			foreach ($X509Certificate in $X509Certificate2Collection) {
				$PrivateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($X509Certificate)

				$CngProvider = [System.Security.Cryptography.CngProvider]::new($PrivateKey.Key.Provider)
				$CngKey = [System.Security.Cryptography.CngKey]::Open($PrivateKey.Key.KeyName, $CngProvider, [System.Security.Cryptography.CngKeyOpenOptions]::MachineKey)

				$CngKey.Dispose()

				$CspParameters = [System.Security.Cryptography.CspParameters]::New(1, $CngKey.Provider, $CngKey.KeyName)
				$CspParameters.Flags = [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
				$CspKeyContainerInfo = [System.Security.Cryptography.CspKeyContainerInfo]::New($CspParameters)

				$CspKeyContainerInfo.KeyNumber
			}
		}
		catch {
			throw $_
		}
	}

	end {
	}
}

function Get-KeyContainerPath {
	<#
	.SYNOPSIS
	Gets the key container path.
	.DESCRIPTION
	Gets the key container path.
	.PARAMETER Name
	Specifies the container name.
	.EXAMPLE
	Get-KeyContainerPath -Name '18a063eab563f02c3236e52d67c1665a_f61e86e9-ed5b-4caa-a43-f2124e097512'
	.NOTES
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low'
	)]

	[OutputType([System.IO.FileInfo])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[string]$Name
	)

	begin {
		$CryptoFolder = Join-Path -Path $([Environment]::GetFolderPath("CommonApplicationData")) -ChildPath 'Microsoft\Crypto'
	}

	process {
		try {
			$privateKeyFile = Get-ChildItem -Path $CryptoFolder -Filter $Name -Recurse

			$privateKeyFile
		}
		catch {
			throw $_
		}
	}

	end {
	}
}

function Restart-RemoteService {
	<#
	.SYNOPSIS
	Restarts service on remote computer.
	.DESCRIPTION
	Restarts service on remote computer.
	.PARAMETER PSSession
	Specifies session
	.PARAMETER ServiceName
	Specifies the service name.
	.EXAMPLE
	$PSSession = New-PSSession -ComputerName MyServer

	Restart-RemoteService -PSSession $PSSession -ServiceName 'MSSQLServer'
	.NOTES
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High'
	)]

	[OutputType([void])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		$PSSession,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		$ServiceName
	)

	begin {
		$ScriptBlock = {
			param ($Name)

			Restart-Service -Name $Name -Force
		}
	}

	process {
		if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Restart service")) {
			Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock -ArgumentList $ServiceName
		}
	}

	end {
	}
}

function Test-SQLCertificateRequirement {
	<#
	.SYNOPSIS
	Verifies certificate requirements.
	.DESCRIPTION
	Verifies certificate requirements for SQL Server.
	.PARAMETER Certificate
	The certificate to set access rights.
	.PARAMETER StoreLocation
	Specifies the certificate store location.
	.PARAMETER StoreName
	Specifies the certificate store.
	.EXAMPLE
	Test-SQLCertificateRequirement -Certificate $Certificate -StoreLocation 'LocalMachine' -StoreName 'My'
	.NOTES
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'High'
	)]

	[OutputType([boolean])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateNotNullOrEmpty()]
		[String]$StoreName
	)

	begin {
		$Result = $true
	}

	process {
		try {
			if ($Certificate.NotBefore -gt [DateTime]::Now) {
				Write-Error "Certificate not valid until $($Certificate.NotBefore)"

				$Result = $false
			}

			if ($Certificate.NotAfter -lt [DateTime]::Now) {
				Write-Error "Certificate Expired $($Certificate.NotAfter)"

				$Result = $false
			}

			$EnhancedKeyUsageExtension = $Certificate.Extensions.Where({$_ -match 'X509EnhancedKeyUsageExtension'})

			if ($EnhancedKeyUsageExtension.EnhancedKeyUsages.Value -NotContains '1.3.6.1.5.5.7.3.1') {
				Write-Error 'Enhanced Key Usage property does not include Server Authentication.'

				$Result = $false
			}

			$KeySpec = Get-CertificateKeySpec -Thumbprint $Certificate.Thumbprint -StoreLocation $StoreLocation -StoreName $StoreName

			if ($KeySpec -ne 'Exchange') {
				Write-Error 'KeySpec value of AT_EXCHANGE required.'

				$Result = $false
			}

			$Result
		}
		catch {
			throw $_
		}
	}

	end {
	}
}
#EndRegion


function Add-SqlDatabaseMailAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Mail.MailAccount])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailAccountName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Description,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$EmailDisplayName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$EmailAddress,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$ReplyToAddress,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$SmtpServerName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[int]$SmtpServerPort = 25,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[boolean]$UseSslConnection = $true,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[SMTPAuthenticationType]$SMTPAuthenticationType = 'Anonymous',

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[PSCredential]$Credential
	)

	begin {
		$ServerInstanceParameterSets = @('ServerInstance')

		try {
			if ($SMTPAuthenticationType -in @('Anonymous', 'Windows')) {
				if ($PSBoundParameters.ContainsKey('Credential')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Credential parameter is invalid when SMTPAuthenticationType is Anonymous or Windows.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$SMTPAuthenticationType
					)
				}
			} else {
				if (-not $PSBoundParameters.ContainsKey('Credential')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Credential parameter is required when SMTPAuthenticationType is Basic.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$SMTPAuthenticationType
					)
				}
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailAccount = [Microsoft.SqlServer.Management.SMO.Mail.MailAccount]::New($SmoServer.Mail, $MailAccountName, $Description, $EmailDisplayName, $EmailAddress)
			$MailAccount.ReplyToAddress = $ReplyToAddress

			if ($PSCmdlet.ShouldProcess($MailAccountName, 'Add SQL DatabaseMailAccount')) {
				$MailAccount.Create()

				$MailServer = $MailAccount.MailServers.Item($SmoServer.DomainInstanceName)

				$MailServer.Rename($SmtpServerName)
				$MailServer.UseSSLConnection = $UseSslConnection
				$MailServer.Port = $SmtpServerPort

				switch ($SMTPAuthenticationType) {
					'Anonymous' {
						$MailServer.UseDefaultCredentials = $false
					}
					'Windows' {
						$MailServer.UseDefaultCredentials = $true
					}
					'Basic' {
						$MailServer.UseDefaultCredentials = $false

						$MailServer.SetAccount($Credential.UserName, $Credential.Password)
					}
				}

				$MailAccount.Alter()
			}

			$MailAccount
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Add-SqlDatabaseMailProfileAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailAccountName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[int]$SequenceNumber
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			$MailProfile.AddAccount($MailAccountName, $SequenceNumber)

			if ($PSCmdlet.ShouldProcess($MailProfileName, 'Add SQL DatabaseMailProfile Account.')) {
				$MailProfile.Alter()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Add-SqlDatabaseMailProfilePrincipal {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$PrincipalName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[bool]$DefaultProfile = $false
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PrincipalName -notin @('public', '##MS_PolicyEventProcessingLogin##', '##MS_PolicyTsqlExecutionLogin##', 'MS_DataCollectionInternalUser')) {
				$DatabaseObject = Get-SmoDatabaseObject -SmoServerObject $SmoServer -DatabaseName msdb
				$RoleMembers = $DatabaseObject.Roles['DatabaseMailUserRole'].EnumMembers()

				if ($PrincipalName -notin $RoleMembers) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New("Principal '$PrincipalName' is not a member of DatabaseMailUserRole."),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$PrincipalName
					)
				}
			}

			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			$MailProfile.AddPrincipal($PrincipalName, $DefaultProfile)

			if ($PSCmdlet.ShouldProcess($MailProfileName, 'Add SQL DatabaseMailProfile Principal.')) {
				$MailProfile.Alter()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Add-SqlServerStartupParameter {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[SqlServerConfiguration.StartupParameter]$Name,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Value,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		$ServerInstanceParameterSets = @('ServerInstance')

		try {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $DatabaseNameParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$StartupParameters = Get-SqlServerStartupParameter -SmoServerObject $SmoServer

			if ($Name -eq 'TraceFlag') {
				$TraceFlag = $StartupParameters.where({$_.Name -eq 'TraceFlag' -and $_.Value -eq $Value})

				if ($TraceFlag.Count -gt 0) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Trace flag already exists.'),
						'1',
						[System.Management.Automation.ErrorCategory]::ResourceExists,
						$Value
					)
				}
			} else {
				if ($StartupParameters -contains $Name) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Parameter already exists.'),
						'1',
						[System.Management.Automation.ErrorCategory]::ResourceExists,
						$Name
					)
				}
			}

			if (-not $PSBoundParameters.ContainsKey('Value')) {
				$Value = $null
			}

			$SqlStartupParameter = [SqlServerConfiguration.SqlStartupParameter]::New([SqlServerConfiguration.StartupParameter]$Name, $Value)

			$Service = $SmoWmiManagedComputer.Services[$SmoServer.ServiceName]

			$Service.StartupParameters = [string]::Format('{0};{1}{2}', $Service.StartupParameters, $SqlStartupParameter.Option, $Value)

			if ($PSCmdlet.ShouldProcess($Name, 'Add SQL Server Startup Parameter')) {
				$Service.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.NetName, 'Restart Service')) {
					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:\PSSession) {
				Remove-PSSession -Session $PSSession
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Disable-SqlDatabaseMail {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$SmoServer.Configuration.DatabaseMailEnabled.ConfigValue = 0

			if ($PSCmdlet.ShouldProcess($SmoServer.Name, 'Disable SQL Database Mail')) {
				$SmoServer.Configuration.Alter()

				$SmoServer.Refresh()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Disable-SqlServerProtocol {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ServerProtocols]$Protocol,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$ServerProtocol = Get-SqlServerProtocol -SmoServerObject $SmoServer -Protocol $Protocol

			if ($PSCmdlet.ShouldProcess($SqlInstanceName, 'Disable SQL Server Protocol')) {
				$ServerProtocol.IsEnabled = $false
				$ServerProtocol.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.ServiceName, 'Restart SQL Server Service')) {
					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:\PSSession) {
				Remove-PSSession -Session $PSSession
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Enable-SqlConnectionEncryption {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1, 128)]
		[string]$CertificateThumbprint,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$RequireEncryption,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}

		$ValidCertificate = $null
	}

	process {
		try {
			if ($SmoServer.NetName -notin @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
				throw [System.Management.Automation.ErrorRecord]::New(
					[Exception]::New('Remote SQL Server instances are not supported.'),
					'1',
					[System.Management.Automation.ErrorCategory]::NotImplemented,
					$Name
				)
			}

			#Region Select Certificate
			if ($PSBoundParameters.ContainsKey("CertificateThumbprint")) {
				$CertificateParameters = @{
					FindValue = $CertificateThumbprint
					StoreLocation = 'LocalMachine'
					StoreName = 'My'
				}

				[System.Security.Cryptography.X509Certificates.X509Certificate2[]]$X509Certificate2Collection = Find-Certificate @CertificateParameters

				if ($X509Certificate2Collection.Count -gt 0) {
					foreach ($X509Certificate in $X509Certificate2Collection) {
						if (Test-SQLCertificateRequirement -Certificate $X509Certificate -StoreLocation 'LocalMachine' -StoreName 'My') {
							$ValidCertificate = $X509Certificate
						}
					}
				}
			} else {
				$CimSessionParameters = @{
					'Name' = 'SQLCertificate'
				}

				if ($SmoServer.NetName -NotIn @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
					$CimSessionParameters.Add('ComputerName', $SmoServer.Information.FullyQualifiedNetName)
				}

				$CimSession = New-CimSession @CimSessionParameters

				$Win32ComputerSystem = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem

				$CertificateParameters = @{
					FindValue = $SmoServer.Information.FullyQualifiedNetName
					X509FindType = 'FindBySubjectName'
					StoreLocation = 'LocalMachine'
					StoreName = 'My'
				}

				$X509Certificate2Collection = Find-Certificate @CertificateParameters

				if ($X509Certificate2Collection.Count -gt 0) {
					foreach ($X509Certificate in $X509Certificate2Collection) {
						if (Test-SQLCertificateRequirement -Certificate $X509Certificate -StoreLocation 'LocalMachine' -StoreName 'My') {
							$ValidCertificate = $X509Certificate
						}
					}
				}

				if ($null -eq $ValidCertificate) {
					$WildCard = [string]::Format("{0}.{1}", '*', $Win32ComputerSystem.Domain)

					$X509Certificate2Collection = Find-Certificate -FindValue $WildCard -X509FindType 'FindBySubjectName' -StoreLocation 'LocalMachine' -StoreName 'My'

					foreach ($X509Certificate in $X509Certificate2Collection) {
						if (Test-SQLCertificateRequirement -Certificate $X509Certificate -StoreLocation 'LocalMachine' -StoreName 'My') {
							$ValidCertificate = $X509Certificate
						}
					}
				}
			}

			if ($null -eq $ValidCertificate) {
				throw 'No suitable certificate found'
			}
			#Endregion

			#Region Set Private Key Permissions
			foreach ($ServiceAccount in @($SmoServer.ServiceAccount, $SmoServer.JobServer.ServiceAccount)) {
				$AccessRuleParameters = @{
					Certificate = $ValidCertificate
					Grantee = $ServiceAccount
					FileSystemRights = 'Read'
					AccessControlType = 'Allow'
				}

				if ($PSCmdlet.ShouldProcess($ValidCertificate.Subject, "Add private key access rule")) {
					Add-CertificatePrivateKeyAccessRule @AccessRuleParameters
				}
			}
			#EndRegion

			#Region Set Encryption Properties
			$PropertyParameters = @{
				SmoServerObject = $SmoServer
				CertificateThumbprint = $ValidCertificate.Thumbprint
			}

			if ($RequireEncryption) {
				$PropertyParameters.Add('RequireEncryption', $true)
			}

			if ($PSCmdlet.ShouldProcess($SmoServer.NetName, "Set encryption properties")) {
				Set-SQLProtocolProperty @PropertyParameters
			}
			#EndRegion

			#Region Restart SQL Server Service
			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.ServiceName, 'Restart SQL Server Service')) {
					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
			#EndRegion

			Write-Warning 'Legacy certificates used for connection encryption are not removed. Please review and remove any legacy certificates if necessary.'
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:\CimSession) {
				if ($CimSession -is [Microsoft.Management.Infrastructure.CimSession]) {
					Remove-CimSession -CimSession $CimSession
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Enable-SqlDatabaseMail {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$SmoServer.Configuration.DatabaseMailEnabled.ConfigValue = 1

			if ($PSCmdlet.ShouldProcess($SmoServer.Name, 'Disable SQL Database Mail')) {
				$SmoServer.Configuration.Alter()

				$SmoServer.Refresh()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Enable-SqlServerProtocol {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ServerProtocols]$Protocol,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$ServerProtocol = Get-SqlServerProtocol -SmoServerObject $SmoServer -Protocol $Protocol

			if ($PSCmdlet.ShouldProcess($SqlInstanceName, 'Enable SQL Server Protocol')) {
				$ServerProtocol.IsEnabled = $false
				$ServerProtocol.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.ServiceName, 'Restart SQL Server Service')) {
					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:\PSSession) {
				Remove-PSSession -Session $PSSession
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlDatabaseMailAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Mail.MailAccount])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailAccountName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PSBoundParameters.ContainsKey('MailAccountName')) {
				$MailAccounts = $SmoServer.Mail.Accounts.Item($MailAccountName)
			} else {
				$MailAccounts = $SmoServer.Mail.Accounts
			}

			$MailAccounts
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlDatabaseMailConfiguration {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlDatabaseMailConfiguration])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[DatabaseMailConfiguration]$MailConfigurationName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PSBoundParameters.ContainsKey('MailConfigurationName')) {
				$ConfigurationValues = $SmoServer.Mail.ConfigurationValues.Item($MailConfigurationName)
			} else {
				$ConfigurationValues = $SmoServer.Mail.ConfigurationValues
			}

			foreach ($ConfigurationValue in $ConfigurationValues) {
				$SqlDatabaseMailConfiguration = [SqlServerConfiguration.SqlDatabaseMailConfiguration]::New($ConfigurationValue)

				$SqlDatabaseMailConfiguration
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlDatabaseMailProfile {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Mail.MailProfile])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PSBoundParameters.ContainsKey('MailProfileName')) {
				$SmoServer.Mail.Profiles.Item($MailProfileName)
			} else {
				$SmoServer.Mail.Profiles
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlDatabaseMailProfileAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlDatabaseMailProfilePrincipal])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$AccountName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			if ($PSBoundParameters.ContainsKey('AccountName')) {
				$Accounts = $MailProfile.EnumAccounts().where({$_.AccountName -eq $AccountName})
			} else {
				$Accounts = $MailProfile.EnumAccounts()
			}

			foreach ($Account in $Accounts) {
				$SqlDatabaseMailProfileAccount = [SqlServerConfiguration.SqlDatabaseMailProfileAccount]::New()

				$SqlDatabaseMailProfileAccount.ProfileName = $MailProfile.Name
				$SqlDatabaseMailProfileAccount.AccountName = $Account.AccountName
				$SqlDatabaseMailProfileAccount.SequenceNumber = $Account.SequenceNumber

				$SqlDatabaseMailProfileAccount
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlDatabaseMailProfilePrincipal {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlDatabaseMailProfilePrincipal])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$PrincipalName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			if ($PSBoundParameters.ContainsKey('PrincipalName')) {
				$Principals = $MailProfile.EnumPrincipals().where({$_.PrincipalName -eq $PrincipalName})
			} else {
				$Principals = $MailProfile.EnumPrincipals()
			}

			foreach ($Principal in $Principals) {
				$SqlDatabaseMailProfilePrincipal = [SqlServerConfiguration.SqlDatabaseMailProfilePrincipal]::New()

				$SqlDatabaseMailProfilePrincipal.ProfileName = $MailProfile.Name
				$SqlDatabaseMailProfilePrincipal.PrincipalName = $Principal.PrincipalName
				$SqlDatabaseMailProfilePrincipal.IsDefault = $Principal.IsDefault

				$SqlDatabaseMailProfilePrincipal
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlFilestreamSetting {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlFilestreamSettings])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$CimSessionParameters = @{
				'Name' = 'FileStreamSettings'
			}

			if ($SmoServer.NetName -NotIn @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
				$CimSessionParameters.Add('ComputerName', $SmoServer.Information.FullyQualifiedNetName)
			}

			$CimSession = New-CimSession @CimSessionParameters
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\CimSession) {
				if ($CimSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-CimSession -CimSession $CimSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$CimInstanceParameters = @{
				CimSession  = $CimSession
				Namespace = 'root\Microsoft\SQLServer'
				Query = "SELECT NAME FROM __NAMESPACE WHERE NAME LIKE 'ComputerManagement%'"
			}

			$NameSpace = Get-CimInstance @CimInstanceParameters | Sort-Object -Property Name -Descending | Select-Object -First 1

			$CimInstanceParameters = @{
				CimSession  = $CimSession
				Namespace = $("root\Microsoft\SQLServer\" + $Namespace.Name)
				ClassName = 'FilestreamSettings'
			}

			$CimFilestreamSettings = Get-CimInstance @CimInstanceParameters

			$SqlFilestreamSettings = [SqlServerConfiguration.SqlFilestreamSettings]::New($CimFilestreamSettings.AccessLevel)

			$SqlFilestreamSettings.ShareName = $CimFilestreamSettings.ShareName

			$SqlFilestreamSettings
		}
		catch {
			throw $_
		}
		finally {
			Remove-CimSession -CimSession $CimSession

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlProtocolProperty {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlProtocolProperty])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName

			if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
				New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
			}

			$RegistryPath = [string]::Format("HKLM:\{0}\MSSQLServer\SuperSocketNetLib", $SmoWmiManagedComputer.Services[$SmoServer.ServiceName].AdvancedProperties['REGROOT'].Value)

			$ScriptBlock = {
				param ($Path)

				Get-ItemProperty -Path $Path
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$CommandParameters = @{
				ScriptBlock = $ScriptBlock
				ArgumentList = @($RegistryPath)
			}

			if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
				$CommandParameters.Add('Session', $PSSession)
			}

			$ItemProperties = Invoke-Command @CommandParameters

			$SqlProtocolProperty = [SqlServerConfiguration.SqlProtocolProperty]::New()

			$SqlProtocolProperty.RequireEncryption = $ItemProperties.ForceEncryption
			$SqlProtocolProperty.RequireStrictEncryption = $ItemProperties.ForceStrict
			$SqlProtocolProperty.HideInstance = $ItemProperties.HideInstance
			$SqlProtocolProperty.CertificateThumbprint = $ItemProperties.Certificate
			$SqlProtocolProperty.ExtendedProtection = $ItemProperties.ExtendedProtection

			$SqlProtocolProperty
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:\PSSession) {
				Remove-PSSession -Session $PSSession
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlServerProtocol {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ServerProtocols]$Protocol
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ([string]::IsNullOrWhiteSpace($SmoServer.InstanceName)) {
				$SqlInstanceName = 'MSSQLSERVER'
			} else {
				$SqlInstanceName = $SmoServer.InstanceName
			}

			$ServerProtocols = $SmoWmiManagedComputer.ServerInstances[$SqlInstanceName].ServerProtocols

			if ($PSBoundParameters.ContainsKey('Protocol')) {
				$SmoObject = $SmoWmiManagedComputer.GetSmoObject($ServerProtocols.where({$_.Name -eq $Protocol}).Urn)

				$SmoObject
			} else {
				foreach ($ServerProtocol in $ServerProtocols) {
					$SmoObject = $SmoWmiManagedComputer.GetSmoObject($ServerProtocol.Urn)

					$SmoObject
				}
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlServerService {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$ServiceName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$Services = $SmoWmiManagedComputer.Services

			if ($PSBoundParameters.ContainsKey('ServiceName')) {
				$SmoObject = $SmoWmiManagedComputer.GetSmoObject($Services.where({$_.DisplayName -eq $ServiceName}).Urn)

				$SmoObject
			} else {
				foreach ($Service in $Services) {
					$SmoObject = $SmoWmiManagedComputer.GetSmoObject($Service.Urn)

					$SmoObject
				}
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Get-SqlServerStartupParameter {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlStartupParameter])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$StartupParameters = $SmoWmiManagedComputer.Services[$SmoServer.ServiceName].StartupParameters.Split(';', @([system.StringSplitOptions]::RemoveEmptyEntries, [system.StringSplitOptions]::TrimEntries))

			$RegExPattern = '^(?<Option>\-.)(?<Value>.+)'
			$RegEx = [regex]::New($RegExPattern, [System.Text.RegularExpressions.RegexOptions]::None)

			foreach ($StartupParameter in $StartupParameters) {
				$RegExMatches = $RegEx.Matches($StartupParameter)

				$SqlStartupParameter = [SqlServerConfiguration.SqlStartupParameter]::New(
					$RegExMatches.Groups.Where({$_.Name -eq 'Option'}).Value,
					$RegExMatches.Groups.Where({$_.Name -eq 'Value'}).Value
				)

				$SqlStartupParameter
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function New-SqlDatabaseMailProfile {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Mail.MailProfile])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Description
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = [Microsoft.SqlServer.Management.SMO.Mail.MailProfile]::New($SmoServer.Mail, $MailProfileName, $Description)

			if ($PSCmdlet.ShouldProcess($MailProfileName, 'Create SQL DatabaseMailProfile')) {
				$MailProfile.Create()

				$MailProfile
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Remove-SqlDatabaseMailAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailAccountName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailAccount = Get-SqlDatabaseMailAccount -SmoServerObject $SmoServer -MailAccountName $MailAccountName

			if ($PSCmdlet.ShouldProcess($MailAccountName, 'Remove SQL DatabaseMailAccount')) {
				$MailAccount.Drop()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Remove-SqlDatabaseMailProfile {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			if ($PSCmdlet.ShouldProcess($MailProfileName, 'Remove SQL DatabaseMailProfile')) {
				$MailProfile.Drop()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Remove-SqlDatabaseMailProfileAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailAccountName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			$MailProfile.RemoveAccount($MailAccountName)

			if ($PSCmdlet.ShouldProcess($MailAccountName, 'Remove SQL Database Mail Profile Account.')) {
				$MailProfile.Alter()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Remove-SqlDatabaseMailProfilePrincipal {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$PrincipalName
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			$MailProfile.RemovePrincipal($PrincipalName)

			if ($PSCmdlet.ShouldProcess($PrincipalName, 'Remove SQL Database Mail Profile Principal.')) {
				$MailProfile.Alter()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Remove-SqlServerStartupParameter {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[SqlServerConfiguration.StartupParameter]$Name,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Value,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			if ($Name -eq 'TraceFlag') {
				if (-not $PSBoundParameters.ContainsKey('Value')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Value parameter is required when Name is TraceFlag.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$Name
					)
				}
			} else {
				if ($PSBoundParameters.ContainsKey('Value')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Value parameter is not valid with provided Name.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$Name
					)
				}
			}

			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$StartupParameters = Get-SqlServerStartupParameter -SmoServerObject $SmoServer

			if ($Name -eq 'TraceFlag') {
				$StartupParameter = $StartupParameters.where({$_.Name -eq $Name -and $_.Value -eq $Value})
			} else {
				$StartupParameter = $StartupParameters.where({$_.Name -eq $Name})
			}

			if ($StartupParameter.Count -eq 0) {
				throw [System.Management.Automation.ErrorRecord]::New(
					[Exception]::New('Parameter does not exists.'),
					'1',
					[System.Management.Automation.ErrorCategory]::ObjectNotFound,
					$Name
				)
			}

			$NewStartupParameters = [System.Collections.Generic.List[string]]::New()

			foreach ($Parameter in $StartupParameters) {
				if ($Parameter.ToString() -eq $StartupParameter[0].ToString()) {
					continue
				} else {
					$NewStartupParameters.Add($Parameter.ToString())
				}
			}

			$Service = $SmoWmiManagedComputer.Services[$SmoServer.ServiceName]

			$Service.StartupParameters = [string]::Join(';', $NewStartupParameters)

			if ($PSCmdlet.ShouldProcess($Name, 'Remove SQL Server Startup Parameter')) {
				$Service.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.NetName, 'Restart Service')) {
					if ($SqlInstanceName -in @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Set-SqlDatabaseMailAccount {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailAccountName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$NewMailAccountName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Description,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$EmailDisplayName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$EmailAddress,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$ReplyToAddress,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$SmtpServerName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[int]$SmtpServerPort,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[boolean]$UseSslConnection,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[SMTPAuthenticationType]$SMTPAuthenticationType,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[PSCredential]$Credential
	)

	begin {
		$ServerInstanceParameterSets = @('ServerInstance')

		try {
			if ($SMTPAuthenticationType -in @('Anonymous', 'Windows')) {
				if ($PSBoundParameters.ContainsKey('Credential')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Credential parameter is invalid when SMTPAuthenticationType is Anonymous or Windows.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$SMTPAuthenticationType
					)
				}
			} else {
				if (-not $PSBoundParameters.ContainsKey('Credential')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('Credential parameter is required when SMTPAuthenticationType is Basic.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$SMTPAuthenticationType
					)
				}
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailAccount = Get-SqlDatabaseMailAccount -SmoServerObject $SmoServer -MailAccountName $MailAccountName

			if ($PSBoundParameters.ContainsKey('NewMailAccountName')) {
				$MailAccount.Rename($NewMailAccountName)
			}

			if ($PSBoundParameters.ContainsKey('Description')) {
				$MailAccount.Description = $Description
			}

			if ($PSBoundParameters.ContainsKey('EmailDisplayName')) {
				$MailAccount.EmailDisplayName = $EmailDisplayName
			}

			if ($PSBoundParameters.ContainsKey('EmailAddress')) {
				$MailAccount.EmailAddress = $EmailAddress
			}

			if ($PSBoundParameters.ContainsKey('ReplyToAddress')) {
				$MailAccount.ReplyToAddress = $ReplyToAddress
			}

			$MailServer = $MailAccount.MailServers[0]

			if ($PSBoundParameters.ContainsKey('SmtpServerName')) {
				$MailServer.Rename($SmtpServerName)
			}

			if ($PSBoundParameters.ContainsKey('SmtpServerPort')) {
				$MailServer.Port = $SmtpServerPort
			}

			if ($PSBoundParameters.ContainsKey('UseSslConnection')) {
				$MailServer.UseSSLConnection = $UseSslConnection
			}

			switch ($SMTPAuthenticationType) {
				'Anonymous' {
					$MailServer.UseDefaultCredentials = $false
					$MailServer.SetAccount('', '')
				}
				'Windows' {
					$MailServer.UseDefaultCredentials = $true
				}
				'Basic' {
					$MailServer.UseDefaultCredentials = $false
					$MailServer.SetAccount($Credential.UserName, $Credential.Password)
				}
			}

			if ($PSCmdlet.ShouldProcess($MailAccountName, 'Add SQL DatabaseMailAccount')) {
				$MailAccount.Alter()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Set-SqlDatabaseMailConfiguration {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlDatabaseMailConfiguration])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[DatabaseMailConfiguration]$MailConfigurationName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$MailConfigurationValue
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$ConfigurationValues = $SmoServer.Mail.ConfigurationValues.Item($MailConfigurationName)

			$ConfigurationValues.Value = $MailConfigurationValue


			$ConfigurationValues.Alter()
			$SmoServer.Mail.Refresh()

			Get-SqlDatabaseMailConfiguration -SmoServerObject $SmoServer -MailConfigurationName $MailConfigurationName
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Set-SqlDatabaseMailProfile {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Mail.MailProfile])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$MailProfileName,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1,128)]
		[string]$NewMailProfileName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Description
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $MailProfileName

			if ($PSBoundParameters.ContainsKey('NewMailProfileName')) {
				$MailProfile.Rename($NewMailProfileName)
			}

			if ($PSBoundParameters.ContainsKey('Description')) {
				$MailProfile.Description = $Description
			}

			$MailProfile.Alter()
			$SmoServer.Mail.Refresh()

			Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName $NewMailProfileName
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Set-SqlFilestreamSetting {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'Medium',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([SqlServerConfiguration.SqlFilestreamSettings])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateRange(0,3)]
		[uint]$AccessLevel,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$ShareName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$CimSessionParameters = @{
				'Name' = 'FileStreamSettings'
			}

			if ($SmoServer.NetName -NotIn @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
				$CimSessionParameters.Add('ComputerName', $SmoServer.Information.FullyQualifiedNetName)
			}

			$CimSession = New-CimSession @CimSessionParameters

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\CimSession) {
				if ($CimSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-CimSession -CimSession $CimSession
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$CimInstanceParameters = @{
				CimSession  = $CimSession
				Namespace = 'root\Microsoft\SQLServer'
				Query = "SELECT NAME FROM __NAMESPACE WHERE NAME LIKE 'ComputerManagement%'"
			}

			$NameSpace = Get-CimInstance @CimInstanceParameters | Sort-Object -Property Name -Descending | Select-Object -First 1

			if (-not $PSBoundParameters.ContainsKey('ShareName')) {
				if ([string]::IsNullOrWhiteSpace($SmoServer.InstanceName)) {
					$ShareName = 'MSSQLSERVER'
				} else {
					$ShareName = $SmoServer.InstanceName
				}
			}

			$CimMethodParameters = @{
				CimSession = $CimSession
				Namespace = $("root\Microsoft\SQLServer\" + $Namespace.Name)
				ClassName = 'FilestreamSettings'
				MethodName = 'EnableFilestream'
				Arguments = @{
					AccessLevel = $AccessLevel
					ShareName = $ShareName
				}
			}

			Invoke-CimMethod @CimMethodParameters

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.NetName, 'Restart Service')) {
					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:PSSession) {
				Remove-PSSession -Session $PSSession
			}

			Remove-CimSession -CimSession $CimSession

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Set-SqlProtocolProperty {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		$CertificateThumbprint,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[bool]$RequireEncryption,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[bool]$RequireStrictEncryption,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[bool]$HideInstance,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[bool]$ExtendedProtection,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			$HasParameterToChange = $false

			foreach ($Key in $PSBoundParameters.Keys) {
				if ($Key -in @('CertificateThumbprint', 'CertificateThumbprint', 'RequireEncryption', 'RequireStrictEncryption', 'HideInstance', 'ExtendedProtection')) {
					$HasParameterToChange = $true

					break
				}
			}

			if (-not $HasParameterToChange) {
				throw [System.Management.Automation.ErrorRecord]::New(
					[Exception]::New('Required parameters not supplied.'),
					'1',
					[System.Management.Automation.ErrorCategory]::InvalidArgument,
					$PSBoundParameters.Keys
				)
			}

			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}

			$RegistryPath = [string]::Format("HKLM:\{0}\MSSQLServer\SuperSocketNetLib", $SmoWmiManagedComputer.Services[$SmoServer.ServiceName].AdvancedProperties['REGROOT'].Value)

			$ScriptBlock = {
				param ($Path, $Name, $Value)

				Set-ItemProperty -Path $Path -Name $Name -Value $Value
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$Settings = @{}

			switch ($PSBoundParameters.Keys) {
				'CertificateThumbprint' {
					$CertificateParameters = @{
						FindValue = $CertificateThumbprint
						StoreLocation = 'LocalMachine'
						StoreName = 'My'
					}

					[System.Security.Cryptography.X509Certificates.X509Certificate2[]]$X509Certificate2Collection = Find-Certificate @CertificateParameters

					if ($X509Certificate2Collection.Count -eq 0) {
						throw [System.Management.Automation.ErrorRecord]::New(
							[Exception]::New('Thumbprint not found.'),
							'1',
							[System.Management.Automation.ErrorCategory]::ObjectNotFound,
							$CertificateThumbprint
						)
					}

					$Settings.Add('Certificate', $CertificateThumbprint)
				}
				'ExtendedProtection' {
					if ($ExtendedProtection) {
						[int]$KeyValue = 1
					} else {
						[int]$KeyValue = 0
					}

					$Settings.Add('ExtendedProtection', $KeyValue)
				}
				'HideInstance' {
					if ($HideInstance) {
						[int]$KeyValue = 1
					} else {
						[int]$KeyValue = 0
					}

					$Settings.Add('HideInstance', $KeyValue)
				}
				'RequireEncryption' {
					if ($RequireEncryption) {
						[int]$KeyValue = 1
					} else {
						[int]$KeyValue = 0
					}

					$Settings.Add('ForceEncryption', $KeyValue)
				}
				'RequireStrictEncryption' {
					if ($RequireStrictEncryption) {
						[int]$KeyValue = 1
					} else {
						[int]$KeyValue = 0
					}

					$Settings.Add('ForceStrict', $KeyValue)
				}
				Default {
					if ($_ -notin @('ServerInstance', 'SmoServerObject')) {
						throw [System.Management.Automation.ErrorRecord]::New(
							[Exception]::New('Unknown parameter.'),
							'1',
							[System.Management.Automation.ErrorCategory]::InvalidOperation,
							$_
						)
					}
				}
			}

			if ($PSCmdlet.ShouldProcess($SmoServer.NetName, 'Set SQL Protocol Properties')) {
				foreach ($Item in $Settings.GetEnumerator()) {
					$CommandParameters = @{
						ScriptBlock = $ScriptBlock
						ArgumentList = @($RegistryPath, $Item.Key, $Item.Value)
					}

					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						$CommandParameters.Add('Session', $PSSession)
					}

					Invoke-Command @CommandParameters
				}
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.NetName, 'Restart Service')) {
					if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:PSSession) {
				Remove-PSSession -Session $PSSession
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

function Set-SqlServerStartupParameter {
	<#
	.EXTERNALHELP
	SqlServerConfiguration-Help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $true,
		ConfirmImpact = 'High',
		DefaultParameterSetName = 'ServerInstance'
	)]

	[OutputType([void])]

	PARAM (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'ServerInstance'
		)]
		[ValidateLength(1,128)]
		[string]$ServerInstance,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false,
			ParameterSetName = 'SmoServerObject'
		)]
		[Microsoft.SqlServer.Management.Smo.Server]$SmoServerObject,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[SqlServerConfiguration.StartupParameter]$Name,

		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[string]$Value,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[switch]$ServiceRestart
	)

	begin {
		try {
			if ($Name -eq 'TraceFlag') {
				if (-not $PSBoundParameters.ContainsKey('Value')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('TraceFlag parameter cannot be modified.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidArgument,
						$Name
					)
				}
			}

			$ServerInstanceParameterSets = @('ServerInstance')

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				$SmoServerParameters = @{
					'ServerInstance' = $ServerInstance
					'DatabaseName' = 'master'
				}

				$SmoServer = Connect-SmoServer @SmoServerParameters
			} else {
				$SmoServer = $SmoServerObject
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServer.NetName

			if ($ServiceRestart) {
				if ($SmoServer.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServer.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServer) {
					if ($SmoServer -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServer
					}
				}
			}

			if (Test-Path -Path Variable:\PSSession) {
				if ($PSSession -is [System.Management.Automation.Runspaces.PSSession]) {
					Remove-PSSession -Session $PSSession
				}
			}

			throw $_
		}
	}

	process {
		try {
			$StartupParameters = Get-SqlServerStartupParameter -SmoServerObject $SmoServer

			$StartupParameter = $StartupParameters.where({$_.Name -eq $Name})

			if ($StartupParameter.Count -eq 0) {
				throw [System.Management.Automation.ErrorRecord]::New(
					[Exception]::New('Parameter does not exists.'),
					'1',
					[System.Management.Automation.ErrorCategory]::ObjectNotFound,
					$Name
				)
			}

			if ($StartupParameter.ValueType -eq "OptionOnly") {
				throw [System.Management.Automation.ErrorRecord]::New(
					[Exception]::New('Parameter does not have a value to modify.'),
					'1',
					[System.Management.Automation.ErrorCategory]::InvalidArgument,
					$Name
				)
			}

			$StartupParameter[0].Value = $Value

			$NewStartupParameters = [System.Collections.Generic.List[string]]::New()

			foreach ($Parameter in $StartupParameters) {
				$NewStartupParameters.Add($Parameter.ToString())
			}

			$Service = $SmoWmiManagedComputer.Services[$SmoServer.ServiceName]

			$Service.StartupParameters = [string]::Join(';', $NewStartupParameters)

			if ($PSCmdlet.ShouldProcess($Name, 'Set SQL Server Startup Parameter')) {
				$Service.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServer.NetName, 'Restart Service')) {
					if ($SqlInstanceName -in @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
						Restart-Service -Name $SmoServer.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServer.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServer.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if (Test-Path -Path Variable:PSSession) {
				Remove-PSSession -Session $PSSession
			}

			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServer
			}
		}
	}

	end {
	}
}

#Region Smo Managed Computer
function Connect-SmoWmiManagedComputer {
	<#
	.EXTERNALHELP
	SqlServerTools-help.xml
	#>

	[System.Diagnostics.DebuggerStepThrough()]

	[CmdletBinding(
		PositionalBinding = $false,
		SupportsShouldProcess = $false,
		ConfirmImpact = 'Low'
	)]

	[OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])]

	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $false
		)]
		[ValidateLength(1, 128)]
		[Alias('SqlServer')]
		[string]$ComputerName,

		[Parameter(
			Mandatory = $false,
			ValueFromPipeline = $false,
			ValueFromPipelineByPropertyName = $false
		)]
		[System.Management.Automation.PSCredential]$Credential
	)

	begin {
	}

	process {
		Try {
			if ($PSBoundParameters.ContainsKey('Credential')) {
				$ManagedComputer = [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]::New(
					$ComputerName,
					$Credential.UserName,
					[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
				)
			} else {
				$ManagedComputer = [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]::New($ComputerName)
			}

			$ManagedComputer
		}
		Catch [Microsoft.SqlServer.Management.Common.ConnectionFailureException] {
			throw $_
		}
		Catch {
			throw $_
		}
	}

	end {
	}
}
#EndRegion
