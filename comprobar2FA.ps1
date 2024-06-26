Install-Module AzureAD
Install-Module Microsoft.Graph -Scope CurrentUser -Force

Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"

#obtener todos los usuarios del dominio
$Users = Get-ADUser -Filter * | Select-object DistinguishedName,Name,Surname,GivenName,SamAccountName,UserPrincipalName,Description,Group

foreach ($User in $Users) {
    Write-Host "FirstName: $($User.Name)"
    Write-Host "LastName: $($User.Surname)"
    Write-Host "GivenName: $($User.GivenName)"

    Write-Host "SamAccountName: $($User.SamAccountName)"
    Write-Host "UserPrincipalName: $($User.UserPrincipalName)"
    Write-Host "Path: $($User.DistinguishedName)"
    Write-Host "Description: $($User.Description)"
    Write-Host "Group: $($User.Group)"
    try {
        $nombreUsuarioDom = $User.UserPrincipalName

        $user = Get-MgUser -UserId $nombreUsuarioDom

        if ($user -ne $null) {
            # Habilitar 2FA para el usuario
            $politica2FA = @{
                "methodType" = "microsoftAuthenticator"
                "enabled" = $true
                "enforced" = $true
            }

            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/users/$($user.Id)/authentication/methods/microsoftAuthenticatorAuthenticationMethod" -Body ($politica2FA | ConvertTo-Json -Depth 10)

            Write-Host "MFA habilitado para el usuario: $($User.UserPrincipalName)" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error al habilitar MFA para el usuario $($User.UserPrincipalName): $_" -ForegroundColor Red
    }
}
Write-Host "Proceso concluido"