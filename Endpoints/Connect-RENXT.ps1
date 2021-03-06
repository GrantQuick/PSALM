Function Connect-RENXT {
    [CmdletBinding()]
    param([Switch]$force)

    # Database Parameters
    $authorize_uri = "https://oauth2.sky.blackbaud.com/authorization"
    $redirect_uri = "http://localhost/5000"

    $config = Get-Content ".\config.json" | ConvertFrom-Json
    $key_dir = ($config | Select-Object -Property "key_dir").key_dir
    $client_id = ($config | Select-Object -Property "client_id").client_id
    $client_secret = ($config | Select-Object -Property "client_secret").client_secret

    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

    # Build authorisation URI
    $strUri = $authorize_uri +
        "?client_id=$client_id" +
        "&redirect_uri=" + [System.Web.HttpUtility]::UrlEncode($redirect_uri) +
        '&response_type=code&state=state'

    Function Get-NewTokenRENXT
    {
        [CmdletBinding()]
        param($fileLocation)

        $authOutput = Show-OAuthWindowRENXT -URL $strUri

        # Get auth token
        $Authorization = Get-SkyApiAuthTokenRENXT 'authorization_code' $client_id $redirect_uri $client_secret $authOutput["code"]

        # Swap token for a refresh token
        $Authorization = Get-RefreshTokenRENXT 'refresh_token' $client_id $redirect_uri $client_secret $authorization.refresh_token

        # Save credentials to file
        $Authorization | Select-Object access_token, refresh_token | ConvertTo-Json `
            | ConvertTo-SecureString -AsPlainText -Force `
            | ConvertFrom-SecureString `
            | Out-File -FilePath $fileLocation -Force

    }

    # If key file does not exist
    if ((-not (Test-Path $key_dir)) -or ($force))
    {
        Get-NewTokenRENXT $key_dir
    }

    # Check if refresh token is nearing expiry, and if so get a new one
    $lastWrite = (get-item $key_dir).LastWriteTime
    $minTimespan = new-timespan -minutes 59
    $maxTimespan = new-timespan -days 60

    # If token has expired
    if (((get-date) - $lastWrite) -gt $maxTimespan) {
        Get-NewTokenRENXT $key_dir
    }

    # Token is older than 59 minutes and but younger than 60 days
    # Refresh token
    if ((((get-date) - $lastWrite) -gt $minTimespan) -and (((get-date) - $lastWrite) -lt $maxTimespan))  {
        
        $getSecureString = Get-Content $key_dir | ConvertTo-SecureString
        $myAuth = ((New-Object PSCredential "user",$getSecureString).GetNetworkCredential().Password) | ConvertFrom-Json

        $Authorization = Get-RefreshTokenRENXT 'refresh_token' $client_id $redirect_uri $client_secret $($myAuth.refresh_token)
        
        # Save credentials to file
        $Authorization | Select-Object access_token, refresh_token | ConvertTo-Json `
            | ConvertTo-SecureString -AsPlainText -Force `
            | ConvertFrom-SecureString `
            | Out-File -FilePath $key_dir -Force
    }

}



