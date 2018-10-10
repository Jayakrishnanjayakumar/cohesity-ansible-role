#!powershell
# Copyright (c) 2017 Ansible Project
# GNU General Public License v3.0+ (see COPYING or
# https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

Function Set-CohesityValidation{
    try {

      if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
      {
      $certCallback = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class ServerCertificateValidationCallback
{
    public static void Ignore()
    {
        if(ServicePointManager.ServerCertificateValidationCallback ==null)
        {
            ServicePointManager.ServerCertificateValidationCallback +=
                delegate
                (
                    Object obj,
                    X509Certificate certificate,
                    X509Chain chain,
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
}
"@
          Add-Type $certCallback
       }
      [ServerCertificateValidationCallback]::Ignore()
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    catch {
      throw $_.Exception.Message
    }

}

Function New-TemporaryDirectory {
    # => https://stackoverflow.com/a/34559554
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $new_dir = New-Item -ItemType Directory -Path (Join-Path $parent $name)
    return $new_dir.FullName
}

Function New-CohesityToken {
    param(
        [parameter(valuefrompipeline=$true)]
        $self
    )
    try {
      Set-CohesityValidation

      $url = $("https://" + $self.server + "/irisservices/api/v1/public/accessTokens")

      $headers = @{
        Accept      = "application/json"
        ContentType = "application/json"
      }

      $payload = @{
        "username"       = $self.username
        "password"       = $self.password
      }

      if ( $self.domain ) {
        $payload.domain = $self.domain
      }

      # => Need to convert the PowerShell hash collection into JSON
      # => before submitting to the Invoke-RestMethod call.
      $payload =  ($payload | ConvertTo-Json)

      $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $payload
    }
    catch {
      $errors = @{
        changed = $False
        step = "Failed while trying to get a new Access Token"
        command = $request
        uri = $url
      }
      Fail-Json $errors $_.Exception.Message
    }

    return $response.accessToken

}

Function Get-CohesityAgent {
  Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{$_.DisplayName -like "Cohesity Agent *"}
}

Function Check-CohesityAgent {
    param(
        [parameter(valuefrompipeline=$true)]
        $state
    )

    $agent = Get-CohesityAgent
    if ( $agent ) {
      if ( $state -eq "present" ){
        $results = @{
          changed = $False
          version = $agent.DisplayVersion
          msg     = "Cohesity Agent is currently installed."
        }
        Exit-Json $results
      } else {
        $agent.UninstallString
      }
    } else {
      if ( $state -eq "absent" ){
        $results = @{
          changed = $False
          version = ""
          msg     = "Cohesity Agent is currently not installed."
        }
        Exit-Json $results
      } else {
        $False
      }
    }

}

Function Invoke-AgentDownload {
    param(
        [parameter(valuefrompipeline=$true)]
        $self
    )

    $filename = ""
    # => Create a new Temporary Directory to which we can download
    # => the agent file.
    $tmpdir   = New-TemporaryDirectory

    try {
      # => Grabe a new Cohesity Access Token
      $token =  New-CohesityToken -Self $self

      $url = $("https://" + $self.server + "/irisservices/api/v1/public/physicalAgents/download?hostType=kWindows")

      $headers = @{
        Accept      = "application/octet-stream"
        authorization = $("bearer "+$token)
      }

      # => Run a simple Head method check to get the Actual FileName as reported by the
      # => Cohesity Cluster
      $response = Invoke-WebRequest $url -UseBasicParsing -Method Head -Headers $headers
      $agent_name  = $response.Headers.'Content-Disposition'.split("=")[1]

      # => The Full Filename of the agent once downloaded.
      $filename = $($tmpdir + "\" + $agent_name)

      # => Simple .Net Downloader but we must send in our Headers.
      $file = New-Object System.Net.WebClient;
      $file.Headers['Accept'] = $headers.accept
      $file.Headers['authorization'] = $headers.authorization
      $file.DownloadFile($url, $filename)

      # => Return the Downloaded Agent File Path.
      return $filename
    }
    catch {
      # => Generate a clean error handler and Fail the Ansible run.
      $errors = @{
        changed = $False
        step = "Failed while trying to download Windows Agent"
        command = $request
        uri = $url
        filename = $filename
      }
      Remove-Item $tmpdir -Confirm:$False -Force -Recurse
      Fail-Json $errors $_.Exception.Message
    }

    return $filename

}

Function Install-CohesityAgent {
    param(
        [parameter(valuefrompipeline=$true)]
        $self
    )

    $tmpdir = (Get-Item $self.filename).DirectoryName

    $arguments = "/verysilent /norestart /suppressmsgboxes /type=" + $self.args.install_type

    if ( $self.args.service_user ){
      if ( !$self.args.service_password ){
        $results = @{
          changed = $False
          step = "Validating Agent Credentials"
        }
        Fail-Json $results "Error: Must provide a password when setting the Cohesity Agent username"
      }
      $arguments += "/username=" + $self.args.username + " /password=" + $self.args.password
    }

    try {
      # => Attempt to Install the Cohesity Agent and Wait until completed.
      Start-Process -FilePath $self.filename -ArgumentList $arguments -Wait
    }
    catch {
      # => Generate a clean error handler and Fail the Ansible run.
      $errors = @{
        changed = $False
        step = "Failed while trying to install Windows Agent"
      }
      Fail-Json $errors $_.Exception.Message

    }
    finally {
      # => Remove the downloaded file and temporary directory.
      Remove-Item $tmpdir -Confirm:$False -Force -Recurse
    }

    $results = @{
      changed = $True
      version = (Get-CohesityAgent).DisplayVersion
      msg = "Successfully Installed Cohesity Agent from Host"
    }
    Exit-Json $results


}

Function Remove-CohesityAgent {
    param(
        [parameter(valuefrompipeline=$true)]
        $Uninstaller,
        [parameter(valuefrompipeline=$true)]
        $PreserveSettings
    )

    try {
      $arguments = "/silent /norestart "
      if ( $PreserveSettings ){
        $arguments += "/preservesettings"
      }
      Start-Process -FilePath $Uninstaller -ArgumentList $arguments -Wait
    }
    catch {
      # => Generate a clean error handler and Fail the Ansible run.
      $errors = @{
        changed = $False
        step = "Failed while trying to uninstall Windows Agent"
        command = $request
        uri = $url
        filename = $filename
      }
      Fail-Json $errors $_.Exception.Message

    }

    $results = @{
      changed = $True
      version = ""
      msg     = "Uninstalled Cohesity Agent from Host"
    }
    Exit-Json $results


}

$results = @{
    changed = $false
    args = ""
    actions = @() # More for debug purposes
}

$params = Parse-Args $args -supports_check_mode $true

$module = @{}

$module.check_mode     = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

# => Standard Parameters
$module.server         = Get-AnsibleParam -obj $params -name "server" -type "str" -failifempty $true
$module.username       = Get-AnsibleParam -obj $params -name "username" -type "str" -failifempty $true
$module.password       = Get-AnsibleParam -obj $params -name "password" -type "str" -failifempty $true
$module.validate_certs = Get-AnsibleParam -obj $params -name "validate_certs" -type "str" -failifempty $true

# => Agent Specific Parameters
$module.service_user     = Get-AnsibleParam -obj $params -name "service_user" -type "str"
$module.service_password = Get-AnsibleParam -obj $params -name "service_password" -type "str"
$module.install_type     = Get-AnsibleParam -obj $params -name "type" -type "str" -default "volcbt" -validateset "volcbt","fscbt","allcbt","onlyagent"
$module.preservesettings = Get-AnsibleParam -obj $params -name "password" -type "bool" -default $False
$module.state            = Get-AnsibleParam -obj $params -name "state" -type "str" -default "present" -validateset "present","absent"


# => Check if the Agent is currently installed and handle State validation.
# => If the State should be absent then return the uninstaller string.
$uninstaller = Check-CohesityAgent -State $module.state

switch($module.state){
  "present" {
    if ( $module.check_mode ){
      $results.actions = "CheckMode: Will install the Cohesity Agent"
      break
    }
    $results.args = $module
    $results.filename = Invoke-AgentDownload -Self $module
    Install-CohesityAgent -Self $results
  }
  "absent" {
    if ( $module.check_mode ){
      $results.actions = "CheckMode: Will remove the Cohesity Agent" + (if ($module.preservesettings) { " and will PreserveSettings. "})
      break
    }
    if ( $module.preservesettings ) {
      Remove-CohesityAgent -Uninstaller $uninstaller -PreserveSettings $True
    }
    else {
      Remove-CohesityAgent -Uninstaller $uninstaller
    }
  }
  default {
    $results = @{
        changed = $false
        state   = $module.state
    }
    Fail-Json $results "Invalid State Selected"
  }
}
Exit-Json $results
