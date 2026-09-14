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

enum ExtendedProtection {
	Off
	Allowed
	Required
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

	[OutputType(
		[System.Security.Cryptography.X509Certificates.X509Certificate2Collection[]],
		[System.Array]
	)]

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

				, $X509Certificate2Collection
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

#Region Functions
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailAccount = [Microsoft.SqlServer.Management.SMO.Mail.MailAccount]::New($SmoServerObject.Mail, $MailAccountName, $Description, $EmailDisplayName, $EmailAddress)
			$MailAccount.ReplyToAddress = $ReplyToAddress

			if ($PSCmdlet.ShouldProcess($MailAccountName, 'Add SQL DatabaseMailAccount')) {
				$MailAccount.Create()

				$MailServer = $MailAccount.MailServers.Item($SmoServerObject.DomainInstanceName)

				$MailServer.Rename($SmtpServerName)
				$MailServer.EnableSsl = $UseSslConnection
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PrincipalName -notin @('public', '##MS_PolicyEventProcessingLogin##', '##MS_PolicyTsqlExecutionLogin##', 'MS_DataCollectionInternalUser')) {
				$DatabaseObject = Get-SmoDatabaseObject -SmoServerObject $SmoServerObject -DatabaseName msdb
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

			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName

			if ($ServiceRestart) {
				if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $DatabaseNameParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
			$StartupParameters = Get-SqlServerStartupParameter -SmoServerObject $SmoServerObject

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

			$Service = $SmoWmiManagedComputer.Services[$SmoServerObject.ServiceName]

			$Service.StartupParameters = [string]::Format('{0};{1}{2}', $Service.StartupParameters, $SqlStartupParameter.Option, $Value)

			if ($PSCmdlet.ShouldProcess($Name, 'Add SQL Server Startup Parameter')) {
				$Service.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, 'Restart Service')) {
					if ($SmoServerObject.NetName -eq [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$SmoServerObject.Configuration.DatabaseMailEnabled.ConfigValue = 0

			if ($PSCmdlet.ShouldProcess($SmoServerObject.Name, 'Disable SQL Database Mail')) {
				$SmoServerObject.Configuration.Alter()

				$SmoServerObject.Refresh()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			if ($ServiceRestart) {
				if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
			$ServerProtocol = Get-SqlServerProtocol -SmoServerObject $SmoServerObject -Protocol $Protocol

			if ($PSCmdlet.ShouldProcess($SqlInstanceName, 'Disable SQL Server Protocol')) {
				$ServerProtocol.IsEnabled = $false
				$ServerProtocol.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.ServiceName, 'Restart SQL Server Service')) {
					if ($SmoServerObject.NetName -eq [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			if ($ServiceRestart) {
				if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
			if ($SmoServerObject.NetName -notin @([System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
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

				if ($SmoServerObject.NetName -NotIn @([System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
					$CimSessionParameters.Add('ComputerName', $SmoServerObject.Information.FullyQualifiedNetName)
				}

				$CimSession = New-CimSession @CimSessionParameters

				$Win32ComputerSystem = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem

				$CertificateParameters = @{
					FindValue = $SmoServerObject.Information.FullyQualifiedNetName
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
			foreach ($ServiceAccount in @($SmoServerObject.ServiceAccount, $SmoServerObject.JobServer.ServiceAccount)) {
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
				SmoServerObject = $SmoServerObject
				CertificateThumbprint = $ValidCertificate.Thumbprint
			}

			if ($RequireEncryption) {
				$PropertyParameters.Add('RequireEncryption', $true)
			}

			if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, "Set encryption properties")) {
				Set-SQLProtocolProperty @PropertyParameters
			}
			#EndRegion

			#Region Restart SQL Server Service
			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.ServiceName, 'Restart SQL Server Service')) {
					if ($SmoServerObject.NetName -eq [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$SmoServerObject.Configuration.DatabaseMailEnabled.ConfigValue = 1

			if ($PSCmdlet.ShouldProcess($SmoServerObject.Name, 'Disable SQL Database Mail')) {
				$SmoServerObject.Configuration.Alter()

				$SmoServerObject.Refresh()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			if ($ServiceRestart) {
				if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
			$ServerProtocol = Get-SqlServerProtocol -SmoServerObject $SmoServerObject -Protocol $Protocol

			if ($PSCmdlet.ShouldProcess($Protocol, 'Enable SQL Server Protocol')) {
				$ServerProtocol.IsEnabled = $true
				$ServerProtocol.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.ServiceName, 'Restart SQL Server Service')) {
					if ($SmoServerObject.NetName -eq [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PSBoundParameters.ContainsKey('MailAccountName')) {
				$MailAccounts = $SmoServerObject.Mail.Accounts.Item($MailAccountName)
			} else {
				$MailAccounts = $SmoServerObject.Mail.Accounts
			}

			$MailAccounts
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PSBoundParameters.ContainsKey('MailConfigurationName')) {
				$ConfigurationValues = $SmoServerObject.Mail.ConfigurationValues.Item($MailConfigurationName)
			} else {
				$ConfigurationValues = $SmoServerObject.Mail.ConfigurationValues
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ($PSBoundParameters.ContainsKey('MailProfileName')) {
				$SmoServerObject.Mail.Profiles.Item($MailProfileName)
			} else {
				$SmoServerObject.Mail.Profiles
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

	[OutputType([SqlServerConfiguration.SqlDatabaseMailProfileAccount])]

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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$CimSessionParameters = @{
				'Name' = 'FileStreamSettings'
			}

			if ($SmoServerObject.NetName -NotIn @([System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
				$CimSessionParameters.Add('ComputerName', $SmoServerObject.Information.FullyQualifiedNetName)
			}

			$CimSession = New-CimSession @CimSessionParameters
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName

			if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
				New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
			}

			$RegistryPath = [string]::Format("HKLM:\{0}\MSSQLServer\SuperSocketNetLib", $SmoWmiManagedComputer.Services[$SmoServerObject.ServiceName].AdvancedProperties['REGROOT'].Value)

			$ScriptBlock = {
				param ($Path)

				Get-ItemProperty -Path $Path
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

			if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
				$CommandParameters.Add('Session', $PSSession)
			}

			$ItemProperties = Invoke-Command @CommandParameters

			$SqlProtocolProperty = [SqlServerConfiguration.SqlProtocolProperty]::New()

			$SqlProtocolProperty.RequireEncryption = $ItemProperties.ForceEncryption

			if ($SmoServerObject.Version -ge [version]'16.0.0.0') {
				$SqlProtocolProperty.RequireStrictEncryption = $ItemProperties.ForceStrict
			}

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			if ([string]::IsNullOrWhiteSpace($SmoServerObject.InstanceName)) {
				$SqlInstanceName = 'MSSQLSERVER'
			} else {
				$SqlInstanceName = $SmoServerObject.InstanceName
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$StartupParameters = $SmoWmiManagedComputer.Services[$SmoServerObject.ServiceName].StartupParameters.Split(';', @([system.StringSplitOptions]::RemoveEmptyEntries, [system.StringSplitOptions]::TrimEntries))

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = [Microsoft.SqlServer.Management.SMO.Mail.MailProfile]::New($SmoServerObject.Mail, $MailProfileName, $Description)

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailAccount = Get-SqlDatabaseMailAccount -SmoServerObject $SmoServerObject -MailAccountName $MailAccountName

			if ($PSCmdlet.ShouldProcess($MailAccountName, 'Remove SQL DatabaseMailAccount')) {
				$MailAccount.Drop()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

			if ($PSCmdlet.ShouldProcess($MailProfileName, 'Remove SQL DatabaseMailProfile')) {
				$MailProfile.Drop()
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$StartupParameters = Get-SqlServerStartupParameter -SmoServerObject $SmoServerObject

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

			$Service = $SmoWmiManagedComputer.Services[$SmoServerObject.ServiceName]

			$Service.StartupParameters = [string]::Join(';', $NewStartupParameters)

			if ($PSCmdlet.ShouldProcess($Name, 'Remove SQL Server Startup Parameter')) {
				$Service.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, 'Restart Service')) {
					if ($SqlInstanceName -in @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
			}
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailAccount = Get-SqlDatabaseMailAccount -SmoServerObject $SmoServerObject -MailAccountName $MailAccountName

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
				$MailServer.EnableSsl = $UseSslConnection
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
		SupportsShouldProcess = $true,
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$ConfigurationValues = $SmoServerObject.Mail.ConfigurationValues.Item($MailConfigurationName)

			$ConfigurationValues.Value = $MailConfigurationValue

			if ($PSCmdlet.ShouldProcess($MailConfigurationName, 'Set mail configuration properties.')) {
				$ConfigurationValues.Alter()
				$SmoServerObject.Mail.ConfigurationValues.Refresh()
			}

			Get-SqlDatabaseMailConfiguration -SmoServerObject $SmoServerObject -MailConfigurationName $MailConfigurationName
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
					}
				}
			}

			throw $_
		}
	}

	process {
		try {
			$MailProfile = Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $MailProfileName

			if ($PSBoundParameters.ContainsKey('NewMailProfileName')) {
				$MailProfile.Rename($NewMailProfileName)
			}

			if ($PSBoundParameters.ContainsKey('Description')) {
				$MailProfile.Description = $Description
			}

			if ($PSCmdlet.ShouldProcess($MailProfileName, 'Set mail profile properties.')) {
				$MailProfile.Alter()
				$SmoServerObject.Mail.Refresh()
			}

			Get-SqlDatabaseMailProfile -SmoServerObject $SmoServerObject -MailProfileName $NewMailProfileName
		}
		catch {
			throw $_
		}
		finally {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$CimSessionParameters = @{
				'Name' = 'FileStreamSettings'
			}

			if ($SmoServerObject.NetName -NotIn @([System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
				$CimSessionParameters.Add('ComputerName', $SmoServerObject.Information.FullyQualifiedNetName)
			}

			$CimSession = New-CimSession @CimSessionParameters

			if ($ServiceRestart) {
				if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
				if ([string]::IsNullOrWhiteSpace($SmoServerObject.InstanceName)) {
					$ShareName = 'MSSQLSERVER'
				} else {
					$ShareName = $SmoServerObject.InstanceName
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
				if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, 'Restart Service')) {
					if ($SmoServerObject.NetName -eq [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
		[ExtendedProtection]$ExtendedProtection,

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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			if ($SmoServerObject.Version -lt [version]'16.0.0.0') {
				if ($PSBoundParameters.ContainsKey('RequireStrictEncryption')) {
					throw [System.Management.Automation.ErrorRecord]::New(
						[Exception]::New('RequireStrictEncryption requires SQL Server 2022 or higher.'),
						'1',
						[System.Management.Automation.ErrorCategory]::InvalidOperation,
						$SmoServerObject.Version
					)
				}
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName

			if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
				$PSSession = New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
			}

			$RegistryPath = [string]::Format("HKLM:\{0}\MSSQLServer\SuperSocketNetLib", $SmoWmiManagedComputer.Services[$SmoServerObject.ServiceName].AdvancedProperties['REGROOT'].Value)

			$ScriptBlock = {
				param ($Path, $Name, $Value)

				Set-ItemProperty -Path $Path -Name $Name -Value $Value
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

			switch ($PSBoundParameters.Keys.where({$_ -notin @('ServerInstance', 'SmoServerObject', 'ServiceRestart', [System.Management.Automation.Cmdlet]::CommonParameters, [System.Management.Automation.Cmdlet]::OptionalCommonParameters)})) {
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
					switch ($ExtendedProtection) {
						'Off' {
							[int]$KeyValue = 0
						}
						'Allowed' {
							[int]$KeyValue = 1
						}
						'Required' {
							[int]$KeyValue = 2
						}
						Default {
							throw [System.Management.Automation.ErrorRecord]::New(
								[Exception]::New('Unknown Extended Protection Value.'),
								'1',
								[System.Management.Automation.ErrorCategory]::InvalidArgument,
								$ExtendedProtection
							)
						}
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

			if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, 'Set SQL Protocol Properties')) {
				foreach ($Item in $Settings.GetEnumerator()) {
					$CommandParameters = @{
						ScriptBlock = $ScriptBlock
						ArgumentList = @($RegistryPath, $Item.Key, $Item.Value)
					}

					if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
						$CommandParameters.Add('Session', $PSSession)
					}

					Invoke-Command @CommandParameters
				}
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, 'Restart Service')) {
					if ($SmoServerObject.NetName -eq [System.Net.Dns]::GetHostName()) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
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

				$SmoServerObject = Connect-SmoServer @SmoServerParameters
			}

			$SmoWmiManagedComputer = Connect-SmoWmiManagedComputer -ComputerName $SmoServerObject.Information.FullyQualifiedNetName

			if ($ServiceRestart) {
				if ($SmoServerObject.NetName -ne [System.Net.Dns]::GetHostName()) {
					New-PSSession -ComputerName $SmoServerObject.Information.FullyQualifiedNetName
				}
			}
		}
		catch {
			if ($PSCmdlet.ParameterSetName -in $ServerInstanceParameterSets) {
				if (Test-Path -Path Variable:\SmoServerObject) {
					if ($SmoServerObject -is [Microsoft.SqlServer.Management.Smo.Server]) {
						Disconnect-SmoServer -SmoServerObject $SmoServerObject
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
			$StartupParameters = Get-SqlServerStartupParameter -SmoServerObject $SmoServerObject

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

			$Service = $SmoWmiManagedComputer.Services[$SmoServerObject.ServiceName]

			$Service.StartupParameters = [string]::Join(';', $NewStartupParameters)

			if ($PSCmdlet.ShouldProcess($Name, 'Set SQL Server Startup Parameter')) {
				$Service.Alter()
			}

			if ($ServiceRestart) {
				if ($PSCmdlet.ShouldProcess($SmoServerObject.NetName, 'Restart Service')) {
					if ($SqlInstanceName -in @('localhost', [System.Net.Dns]::GetHostName(), [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)) {
						Restart-Service -Name $SmoServerObject.ServiceName -Force
					} else {
						Restart-RemoteService -PSSession $PSSession -ServiceName $SmoServerObject.ServiceName
					}
				}
			} else {
				Write-Warning "The Service $($SmoServerObject.ServiceName) must be restarted for the change to take effect."
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
				Disconnect-SmoServer -SmoServerObject $SmoServerObject
			}
		}
	}

	end {
	}
}
#EndRegion

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

# SIG # Begin signature block
# MIInywYJKoZIhvcNAQcCoIInvDCCJ7gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDy1bJaTslUF9a7
# JV++F7fdi9ZaDAQfE19eSRVyk/fcDKCCINswggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwgga0MIIEnKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYg
# MjAyNSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphB
# cr48RsAcrHXbo0ZodLRRF51NrY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6p
# vF4uGjwjqNjfEvUi6wuim5bap+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHe
# HYNnQxqXmRinvuNgxVBdJkf77S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEd
# gkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjU
# jsZvkgFkriK9tUKJm/s80FiocSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bR
# VFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeS
# LsJygoLPp66bkDX1ZlAeSpQl92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIV
# NSaz7BX8VtYGqLt9MmeOreGPRdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL
# 6s36czwzsucuoKs7Yk/ehb//Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2Zd
# SoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFU
# eEY0qVjPKOWug/G6X5uAiynM7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/
# BAgwBgEB/wIBADAdBgNVHQ4EFgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0j
# BBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8E
# PDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEw
# DQYJKoZIhvcNAQELBQADggIBABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/
# T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQ
# E7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9r
# EVKChHyfpzee5kH0F8HABBgr0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y
# 1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gx
# dEkMx1NKU4uHQcKfZxAvBAKqMVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3t
# y9qIijanrUR3anzEwlvzZiiyfTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcy
# tL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEB
# YTptMSbhdhGQDpOXgpIUsWTjd6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud
# /v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiS
# uEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZP
# ubdcMIIGuTCCBKGgAwIBAgIRAJmjgAomVTtlq9xuhKaz6jkwDQYJKoZIhvcNAQEM
# BQAwgYAxCzAJBgNVBAYTAlBMMSIwIAYDVQQKExlVbml6ZXRvIFRlY2hub2xvZ2ll
# cyBTLkEuMScwJQYDVQQLEx5DZXJ0dW0gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkx
# JDAiBgNVBAMTG0NlcnR1bSBUcnVzdGVkIE5ldHdvcmsgQ0EgMjAeFw0yMTA1MTkw
# NTMyMThaFw0zNjA1MTgwNTMyMThaMFYxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhB
# c3NlY28gRGF0YSBTeXN0ZW1zIFMuQS4xJDAiBgNVBAMTG0NlcnR1bSBDb2RlIFNp
# Z25pbmcgMjAyMSBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJ0j
# zwQwIzvBRiznM3M+Y116dbq+XE26vest+L7k5n5TeJkgH4Cyk74IL9uP61olRsxs
# U/WBAElTMNQI/HsE0uCJ3VPLO1UufnY0qDHG7yCnJOvoSNbIbMpT+Cci75scCx7U
# sKK1fcJo4TXetu4du2vEXa09Tx/bndCBfp47zJNsamzUyD7J1rcNxOw5g6FJg0Im
# Iv7nCeNn3B6gZG28WAwe0mDqLrvU49chyKIc7gvCjan3GH+2eP4mYJASflBTQ3HO
# s6JGdriSMVoD1lzBJobtYDF4L/GhlLEXWgrVQ9m0pW37KuwYqpY42grp/kSYE4BU
# QrbLgBMNKRvfhQPskDfZ/5GbTCyvlqPN+0OEDmYGKlVkOMenDO/xtMrMINRJS5SY
# +jWCi8PRHAVxO0xdx8m2bWL4/ZQ1dp0/JhUpHEpABMc3eKax8GI1F03mSJVV6o/n
# mmKqDE6TK34eTAgDiBuZJzeEPyR7rq30yOVw2DvetlmWssewAhX+cnSaaBKMEj9O
# 2GgYkPJ16Q5Da1APYO6n/6wpCm1qUOW6Ln1J6tVImDyAB5Xs3+JriasaiJ7P5KpX
# eiVV/HIsW3ej85A6cGaOEpQA2gotiUqZSkoQUjQ9+hPxDVb/Lqz0tMjp6RuLSKAR
# sVQgETwoNQZ8jCeKwSQHDkpwFndfCceZ/OfCUqjxAgMBAAGjggFVMIIBUTAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBTddF1MANt7n6B0yrFu9zzAMsBwzTAfBgNV
# HSMEGDAWgBS2oVQ5AsOgP46KvPrU+Bym0ToO/TAOBgNVHQ8BAf8EBAMCAQYwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwMAYDVR0fBCkwJzAloCOgIYYfaHR0cDovL2NybC5j
# ZXJ0dW0ucGwvY3RuY2EyLmNybDBsBggrBgEFBQcBAQRgMF4wKAYIKwYBBQUHMAGG
# HGh0dHA6Ly9zdWJjYS5vY3NwLWNlcnR1bS5jb20wMgYIKwYBBQUHMAKGJmh0dHA6
# Ly9yZXBvc2l0b3J5LmNlcnR1bS5wbC9jdG5jYTIuY2VyMDkGA1UdIAQyMDAwLgYE
# VR0gADAmMCQGCCsGAQUFBwIBFhhodHRwOi8vd3d3LmNlcnR1bS5wbC9DUFMwDQYJ
# KoZIhvcNAQEMBQADggIBAHWIWA/lj1AomlOfEOxD/PQ7bcmahmJ9l0Q4SZC+j/v0
# 9CD2csX8Yl7pmJQETIMEcy0VErSZePdC/eAvSxhd7488x/Cat4ke+AUZZDtfCd8y
# HZgikGuS8mePCHyAiU2VSXgoQ1MrkMuqxg8S1FALDtHqnizYS1bIMOv8znyJjZQE
# Sp9RT+6NH024/IqTRsRwSLrYkbFq4VjNn/KV3Xd8dpmyQiirZdrONoPSlCRxCIi5
# 4vQcqKiFLpeBm5S0IoDtLoIe21kSw5tAnWPazS6sgN2oXvFpcVVpMcq0C4x/CLSN
# e0XckmmGsl9z4UUguAJtf+5gE8GVsEg/ge3jHGTYaZ/MyfujE8hOmKBAUkVa7NMx
# RSB1EdPFpNIpEn/pSHuSL+kWN/2xQBJaDFPr1AX0qLgkXmcEi6PFnaw5T17UdIIn
# A58rTu3mefNuzUtse4AgYmxEmJDodf8NbVcU6VdjWtz0e58WFZT7tST6EWQmx/Oo
# HPelE77lojq7lpsjhDCzhhp4kfsfszxf9g2hoCtltXhCX6NqsqwTT7xe8LgMkH4h
# Vy8L1h2pqGLT2aNCx7h/F95/QvsTeGGjY7dssMzq/rSshFQKLZ8lPb8hFTmiGDJN
# yHga5hZ59IGynk08mHhBFM/0MLeBzlAQq1utNjQprztZ5vv/NJy8ua9AGbwkMWkO
# MIIG4DCCBMigAwIBAgIQQ7s0QZ8qUnHOP66HyvajHjANBgkqhkiG9w0BAQsFADBW
# MQswCQYDVQQGEwJQTDEhMB8GA1UEChMYQXNzZWNvIERhdGEgU3lzdGVtcyBTLkEu
# MSQwIgYDVQQDExtDZXJ0dW0gQ29kZSBTaWduaW5nIDIwMjEgQ0EwHhcNMjYwOTEy
# MjEzNTQ3WhcNMjcwOTEyMjEzNTQ2WjCBhTELMAkGA1UEBhMCVVMxFzAVBgNVBAgM
# DlNvdXRoIENhcm9saW5hMREwDwYDVQQHDAhOZXdiZXJyeTEeMBwGA1UECgwVT3Bl
# biBTb3VyY2UgRGV2ZWxvcGVyMSowKAYDVQQDDCFPcGVuIFNvdXJjZSBEZXZlbG9w
# ZXIgUm9iZXJ0IEVkZXIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC6
# 72ybkWUB620cgb49nkhI4VvtWKABeSD8277f0Jww+/5fKUxoX2vC77QjmaSXU+I9
# LB2YTj8yCSTDVlxIwJoS7KgsIN9P2EC6ehJe9FRI0n2Rt33/VlRY8kuSh2XsIVGg
# i6Y3RooWVjVmYCAOXuV5zrqjGY1P72nrSIekxcGCTo1Y0nmRwsECCIYn7b3ZM065
# u9b3AtYf3oI4grblWhtY0kbuHNCSeDjpp+qExQgeIs6OpFACJSDASFiDnF8+L+bB
# V+UtUcFbvlu0WpQyblXw9vdN7BEIdqZ/1fxyhjHxqpSuOoTqoZcyDjilXtnMOfWp
# gfgdKPFRc6NHwrmxUyNLAYHOsqBC+bMxamurB1qCJ/16lFbW/YWJRrJsaeA2WaPw
# 8ulkUnZUoP9JgyVE1nwZbhZOgE3YwlVLmBBsAKsRiyJWBYqG1VdaMpfzLYJVNTc8
# 4F/90uC2BvIoafcFfNyc8dIpdd7Ni17JmYuD0+/u1gqUi3p+Qdlk/y+Vgsb1x+0z
# kaMA6CzjFA83szdzwRLFDDnaUOVngyRR8+JLnSNuEw9nNM3G5WWRGBDOkLbwq+NO
# H1gWWAaJJYOlTARrg7ea2JHLl66CBJaaledp2u8hBl1Y5yQTpIkVYx0VPt1Oa7Nq
# kOkXlNjmmlYsZm5pe3fSTBPx5YdUOeIl1sAWXGH/+QIDAQABo4IBeDCCAXQwDAYD
# VR0TAQH/BAIwADA9BgNVHR8ENjA0MDKgMKAuhixodHRwOi8vY2NzY2EyMDIxLmNy
# bC5jZXJ0dW0ucGwvY2NzY2EyMDIxLmNybDBzBggrBgEFBQcBAQRnMGUwLAYIKwYB
# BQUHMAGGIGh0dHA6Ly9jY3NjYTIwMjEub2NzcC1jZXJ0dW0uY29tMDUGCCsGAQUF
# BzAChilodHRwOi8vcmVwb3NpdG9yeS5jZXJ0dW0ucGwvY2NzY2EyMDIxLmNlcjAf
# BgNVHSMEGDAWgBTddF1MANt7n6B0yrFu9zzAMsBwzTAdBgNVHQ4EFgQUCdHvF5Qw
# xL78QY6vfJNPC89uTWEwSwYDVR0gBEQwQjAIBgZngQwBBAEwNgYLKoRoAYb2dwIF
# AQQwJzAlBggrBgEFBQcCARYZaHR0cHM6Ly93d3cuY2VydHVtLnBsL0NQUzATBgNV
# HSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQAD
# ggIBADGvhUwApFlOiMwxr4muEgH+EK8xGwyw7qZGQZYdHQZV7E6ev+4i0u2ywMbF
# H0XcYpaB4xubprYIGbltJhIXoIM+BmIB6mgzgAtKMJBIWMECnACZKPAWPJ5vp3Xu
# GLCg0gwQGZEKJInwEFLzplH3G5g8hTO8KSLmWLVWoWHTTA3WI4LgTf/XRs3QYqur
# bB1gWRWa+vx8J/4I6znbpnpRDxy/jCYh9qtv21Dk3BovIPnfaj50JOWJhWeongQ6
# Dgd4/FZhM/U1Fj/g1W7WDMal9q43MABwmrHPbxrIEK1V5vXwAhK1m9eSaZ8bqbeA
# SId0wOYzIyEziquoO5TCdf/lSi8nD4BIm2E+h738pLQXWvr6tYWyvqaUN0uk5f27
# NsXlVRYp8EUZPP83BJMaQJFgTsYPMeZejAndk3nuqPVGeCL6WW90M7eK5sPbTAmW
# WrSnYFx4pgnMR3X3s14074ytJ3o3ycKa0bxjhMcoCTfMDmV7jUUhATpW8iZ2/E4b
# +0s7DmbN37VsBngsj04vMyVxhcNLSwdFDTQEgkEwHccChlw0anfoZJ7Xui4x5RSr
# j3rOyyrf7mFYIpsbDYjVxBo5/JVJuu5h2+BRxY9MLoSMknm391tCI7aVC/XTl/zW
# rX1kJeCx0nYBnZnmjWCRrCXWOX5V8QaLAnK/R6durGeXnlo3MIIG7TCCBNWgAwIB
# AgIQCE/cM09+RU7bww+P+ZIYNTANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRy
# dXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4X
# DTI2MDgwNTAwMDAwMFoXDTM3MTEwNDIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYg
# UlNBNDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjYgMTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALZ7pvLJ/s1K+NSbTGWz/TjGMPh8CQ6RucZCLv5a
# nHzWJjF/NWJrFIhy24fcpKXlgRiky4WAawDfU3YP0BMxt9l3Dm5oCG5Z69AqEN1k
# gHg2epx+l+lZBcmJCcN0ASURML5uFIS80sZsDwO3BSkUxDjLJhBI+qiZP3aixAC/
# qEGLjsBNlLol9VZ7pfGEXiMlneJIC5/YKuizVzNFKZZEeoy/0B8Zm+nzKBgSWG52
# lCO1w+nCg6XpCtklTJXeIg283hw7TmmsZXR+SMbjbrEOvZ3fP2VxIgeR28Y90ZSt
# d3F9VuA5RVynb/whITPAo9b75Zr4Ta6Mj3URm26QZYMn/FnbuTegcoRcFEZ9FOqM
# 5T6MTdtr/n74lIT/ug0eeOzmZ6QTFg33otX+bFRsIolvykE1jive4PuESaT8zzVe
# FWDAMDtozNgLctkGD1ZjkEyZtJrLl5ya0m5doH/ScpaZCZVl6pNUOCybMc/kxC6E
# AmSJY24L0yYKD1Nkddsnb/ItVKi/2nXpQNMu1PT5prW83vV8d67WowuUs0HdY4H8
# AMLGvdL/WHEj3ZnqMqAQQP9u3Ai9t+5eQ02GDwy0ODjdzi0xlp70W+ow63/0++YD
# EX1M0iwgUHwbrJvfpklkZQvw3+kv3vUPItdwroczk9icflf55W1zOEKAcJVAIXpc
# MCU9AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBQUyWOKMC7U
# SvtulPPm40B+9ezN4jAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAO
# BgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUF
# BwEBBIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# XQYIKwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmww
# IAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUA
# A4ICAQCNxTphHp1SCt+ZrAmAfn0oQLFr0mLywSLaDXQIENoyKqxrFbJblzCVP/pk
# XmwXOdrOpWygLzlT12os5ipDCy35RBCg2UMeApEtrfGhz45F4Wt4WGdNdIbRWt3Y
# TYJmpR+b7lr4d7Uwn+H600u4D7RnOGf8Wj4UNgAdZkfHhHv1mx9EVh71SJelcEN/
# oORSjXzdjfw1iZH9d8Nh/thn6hH23d+VsPAr6GAYyzSA02nXD1nYLI7Ijmiv+xLC
# iYC41DSFYL3GhTiy0PxpawPtGRyaBVGzq+UiTfM8pD7KVyF5aQyWP4KhVGUUTnmm
# /RlYJoW3TiXA/+t0YcT2oRVBm3JETjajHug2AL+v5jhtKVnd3D0rbHXEu27o+Q8p
# 4sEWPMqKDB+qbceb6T/6WcwTwXmQ9lOCLLYcsQeSWmvKqzpAec9etE14jOQAzLKW
# dE3w/TCaKtLRaRT7LCkRYVnhA2D73FLje1O5b3HR5eHs0NzU/+xX7NbEdcofy0W3
# Wdwd1XOqtlpg/JgwtKfZM5dqO94lbUveOiJBI+xZEbGRsMNbXmMREUTgu+Oca7Y7
# 3MPWcslIx2VhkSKSXjDbD6rgg39H5Mh7QfieAIjWagkJNt68Yfim6cjEzVSiLSeZ
# fdkr5dtFPTW6jATlWJdYeeDRGCyatf8R1hSjzSvdN8yWQPT9gzGCBkYwggZCAgEB
# MGowVjELMAkGA1UEBhMCUEwxITAfBgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMg
# Uy5BLjEkMCIGA1UEAxMbQ2VydHVtIENvZGUgU2lnbmluZyAyMDIxIENBAhBDuzRB
# nypScc4/rofK9qMeMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO3RgJ6KevfkcxJOt2uj
# RmbYsC5FDcgYHQhsyTIwFr4FMA0GCSqGSIb3DQEBAQUABIICADXE+xj5GyRB8OiI
# R+CvT0VYHmc6TUKYE3E9iGNhOcdqMty3Wovfo4pgGHccwjGpg1eVaX+beLIvac35
# vN+664wMnLOkqp1+KsbMOnRbYmWAi3SQ4hCD8ECm+LYCqfI0IXD+rDMjKZ/17lhS
# e7sV5rsWsKVj8CqGpr8iCOv9i6jgzna8614WLivWgQMtrroHVfvcTTduQXMK6Lsh
# M7iBKd3Z3wuYZ7qhOkk2VBMky/lI9YVLuvekqrdKtLFX4DIFcG1mwgpbx48UUKb3
# Py4n7CIpQ3PrnWpvBrCnxSVRqxf/AO5bTNUkWjg1+ycxkA66it3pNfPVNd8Xry1W
# nG71DMh0tkya9ORq3CcB+j7P+wsGNo7POHQ41tkRmNtEp9vX2CvQZ5Plzsgkb29E
# +vYWehmFKwKS/So456oeFprCbEfJ3+Z3Iv7IKGPWarjMzIfwA+AC6Poj4vmXzJus
# mDqpyF4X4Kj1ipZa5e7GuoBN7pLK5AoAtfe3Lx2Ylan+lA2t7I/ZboLLfbLOJICB
# rrK8rC0efEo51Uz1MYF5Ixjtz+fvOTrZkCCDMdyQBODaxr9KBnY6AP+PfvkBn2bD
# Qbq3wiCDZdn+Nf+rdiu+JPJaC3D7FcEXRrUpNAf0b9pqNI1tFeQaQUymXr4xr7DY
# fQHP8aJsl3lEo70SAJu+qb/gn3laoYIDJjCCAyIGCSqGSIb3DQEJBjGCAxMwggMP
# AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEw
# PwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2
# IFNIQTI1NiAyMDI1IENBMQIQCE/cM09+RU7bww+P+ZIYNTANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI2
# MDkxMzE5MzYxNFowLwYJKoZIhvcNAQkEMSIEIFCfHBLeFS3HgzhBTaXhwJtMkfnE
# U8sIYSTauNO4eIWSMA0GCSqGSIb3DQEBAQUABIICAGeQaD+SE3KMTVtDsJXoqlk8
# VJcI/t54qH20/QMxwM0PVMshuZRudb9KY8czXEkwD/8oAdLCVVpAAeXK/EgsfSQ6
# knRc9XssEtVhcwWscW6raOnAOiCMsgDi+tHXGyMMLcVF34kwCFsX9ZO2Tf0tvKPX
# T2rycuMgC+7JnIYG3VWTfBnXeJKg8bcpDxvE+YjUBWK85HuMuGpRx2fpuqAyebpr
# UctccG4hrsawdYUm6Jt1wXMmkvO420AZJgqmYXzHr7cnconQZQcLxOfVzVBj3LOa
# zHG2r0UK5jfkeGWxHI/AKffcd40/DkNWKNmNGzYbAUloODlHAWiTl2QaP+IHqhtu
# LB7BqwdWgraz0cqJ8+cQ4WA1UYPdpJHVA1qUmjhdMflOgDNgDkZXExTWEl/nUpne
# BeyqPdqIijiWAsrZyaEoTlHK4JPgrkL1SGw0HveAEzubz9brZrSWA5aU1ie+tbYf
# Y6tpV0ajslzB4uS5izT/LCSb4V+LTVkyXwig7GVeLse3ifHs108teAEAmQvFLLOn
# XFxkVkRgAwMvxfbchronwyrr0LbDi8kKKzcHYE/Y4XwRbjcPgD2IqT1pVtScayk+
# Uys2n4wnyLMnKdKjEnQcajsGXaxz3vj+RPZ+EUwhAZzEeO2KSHxNXlIRTfnP1y2A
# Q5gBuVOMgWcYPwcnQP8N
# SIG # End signature block
