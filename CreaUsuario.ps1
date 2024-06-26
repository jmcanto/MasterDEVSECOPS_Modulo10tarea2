﻿Import-Module ActiveDirectory

$SecurePassword = ConvertTo-SecureString "P@ssw0rd09!" -AsPlainText -Force

$NewADUserParameters = @{
    Name = "Dirección 04" 
    GivenName = "Dirección 04" 
    Surname = ""
    Path = "CN=Users,DC=devsecops,DC=es"
    SamAccountName = "direccion04"
    UserPrincipalName = "direccion04@devsecops.es" 
    AccountPassword = $SecurePassword
    Enabled = $true 
    Description = "Cuenta de usuario para Dirección 04"    
}

$grupo = "Direccion"
try {
    Write-Host "Name: $($NewADUserParameters.Name)"
    Write-Host "Surname: $($NewADUserParameters.Surname)"
    Write-Host "SamAccountName: $($NewADUserParameters.samAccountName)"
    Write-Host "UserPrincipalName: $($NewADUserParameters.userPrincipalName)"
    Write-Host "Path: $($NewADUserParameters.Path)"
    Write-Host "Description: $($NewADUserParameters.Description)"
    Write-Host "Group: $($NewADUserParameters.Group)"
    # Intentar crear el usuario
    
    New-ADUser @NewADUserParameters
    Write-Host "Usuario $($NewADUserParameters.UserPrincipalName) creado" -ForegroundColor DarkGreen
    
    # Establecer que el usuario cambie la contraseña al iniciar la sesión por primera vez
    Set-ADUser -Identity $NewADUserParameters.SamAccountName -ChangePasswordAtLogon $true
    
    # Agregar el usuario al grupo especificado
    if ($grupo -ne "") {
        Add-ADGroupMember -Identity $grupo -Members $NewADUserParameters.SamAccountName
        Write-Host "Usuario asignado al grupo: $grupo" -ForegroundColor DarkGreen
    }
} catch {
    Write-Host "Error al crear el usuario $($NewADUserParameters.SamAccountName): $_" -ForegroundColor Red
}
    