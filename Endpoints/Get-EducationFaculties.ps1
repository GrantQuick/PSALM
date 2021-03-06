Function Get-EducationFaculties
{
    Begin{

        # Get necessary items from config file
        $config = Get-Content ".\config.json" | ConvertFrom-Json
        $api_subscription_key = ($config | Select-Object -Property "api_subscription_key").api_subscription_key
        $key_dir = ($config | Select-Object -Property "key_dir").key_dir

        # Grab the keys
        $getSecureString = Get-Content $key_dir | ConvertTo-SecureString
        $myAuth = ((New-Object PSCredential "user",$getSecureString).GetNetworkCredential().Password) | ConvertFrom-Json

        $endpoint = 'https://api.sky.blackbaud.com/constituent/v1/educations/faculties'
        $endUrl = ''

        $obj_list = @()

    }

    Process{
        # Get data
        $data = Get-UnpagedEntityRENXT $_ $endpoint $endUrl $api_subscription_key $myAuth $null
        # Convert array to object list
        $obj_list = $data.value | Select-Object @{Name='faculty';Expression={$_}}
              
    }
    End{
        $obj_list
    }
}
