Function New-Email
{
    [cmdletbinding()]
    param(
        [parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][string[]]$constituent_id,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][string]$address,
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][boolean]$do_not_email,
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][boolean]$inactive,
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][boolean]$primary,
        [parameter(
            Mandatory=$true,    
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )
        ][string]$type
    )
    Begin{

        # Get necessary items from config file
        $config = Get-Content ".\Config.json" | ConvertFrom-Json
        $api_subscription_key = ($config | Select-Object -Property "api_subscription_key").api_subscription_key
        $key_dir = ($config | Select-Object -Property "key_dir").key_dir

        # Grab the keys
        $getSecureString = Get-Content $key_dir | ConvertTo-SecureString
        $myAuth = ((New-Object PSCredential "user",$getSecureString).GetNetworkCredential().Password) | ConvertFrom-Json

        $endpoint = 'https://api.sky.blackbaud.com/constituent/v1/emailaddresses'

    }

    Process{
        $i = 0
        # Get data for one or more IDs
        $constituent_id | ForEach-Object {
            $i++
            Write-Host "Adding email address to Constituent ID $_ (record $i of $($constituent_id.Length))"
            # Create JSON for supplied parameters
            $parms = $PSBoundParameters
            $parms.Remove('constituent_id') | Out-Null
            $parms.Add('constituent_id',$_) | Out-Null
            # Convert the parameter hash table to a JSON
            $parmsJson = $parms | ConvertTo-Json
            # $parmsJson
            $created_id = New-SkyApiEntityRENXT $endpoint $parmsJson $api_subscription_key $myAuth
            write-host "Created email address ID $($created_id.id)"
        }
    }
    End{
    }
}
