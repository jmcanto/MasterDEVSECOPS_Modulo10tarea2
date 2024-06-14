#
# Script para la creación de usuarios en un dominio almacenados en un archivo CSV
#

# Verificar si el módulo Active Directory está disponible e impórtalo
# en principio, esta comprobación  no sería necesaria, pero no está de más hacerla

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "El módulo Active Directory no está instalado. Instalando..." -ForegroundColor Yellow
    Install-WindowsFeature -Name RSAT-AD-PowerShell
    Import-Module ActiveDirectory
} else {
    Write-Host "El módulo Active Directory está disponible. Importando..." -ForegroundColor Green
    Import-Module ActiveDirectory
}

#obtener la configuración del dominio
$dominio = Get-ADDomain
# Si en el fichero de usuarios no se indica Ruta se usa la definida en el dominio
$defaultPath = $dominio.UsersContainer

$csvPath = "C:\utilidades\nuevos_usuarios.csv"

#leyendo los usuarios del fichero
$Users = Import-Csv -Path $csvPath
#si necesitamos ver los datos de
Write-Host "Usuarios importados desde el CSV:"
$Users | Format-Table -Property FirstName,LastName,SamAccountName,UserPrincipalName,Path,Password,Description,Group

foreach ($User in $Users) {
    
    $rutaOU = $User.Path
    if (-not $rutaOU) {
        $rutaOU = $defaultPath
    }
     
    #comprobando la ruta, si no es válida se asigna el path por defecto obtenido del domino
    $ou = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$rutaOU'"          
    if (-not $ou) {
        $rutaOU = $defaultPath
    }
    try {
        #comprobar si existe el usuario
        $creado = $(try {Get-ADUser $User.SamAccountName} catch {$null})
            
        if($creado -eq $null) {
             Write-Host "El usuario" $User.UserPrincipalName "no existe se debe crear" -ForegroundColor Magenta

            $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force

            # Validar y ajustar los nombres
                $nombre = $User.FirstName -replace "[^a-zA-Z0-9]", ""
                $apellido = $User.LastName -replace "[^a-zA-Z0-9]", ""
                $nombreCuenta = $User.SamAccountName -replace "[^a-zA-Z0-9]", ""
                $usuarioPrincipal = $User.UserPrincipalName -replace "[^a-zA-Z0-9@.]", ""

            # Verificar si los campos SamAccountName y UserPrincipalName cumplen con los requisitos
                if ($nombreCuenta.Length -gt 20) {
                    Write-Host "SamAccountName demasiado largo: $samAccountName" -ForegroundColor Red
                    continue
                }
                if ($usuarioPrincipal -notmatch "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
                    Write-Host "UserPrincipalName no válido: $userPrincipalName" -ForegroundColor Red
                    continue
                }

                Write-Host "FirstName: $firstName"
                Write-Host "LastName: $lastName"
                Write-Host "SamAccountName: $samAccountName"
                Write-Host "UserPrincipalName: $userPrincipalName"
                Write-Host "Path: $rutaOU"
                Write-Host "Description: $($User.Description)"
                Write-Host "Group: $($User.Group)"

            #creación del usuario
            $NewADUserParam = @{
                Name = "$nombre $apellido"
                GivenName = $nombre
                Surname = $apellido
                SamAccountName = $nombreCuenta
                UserPrincipalName = $usuarioPrincipal
                Path = $User.Path
                AccountPassword = $SecurePassword 
                Enabled = $true
                Description = $User.Description
            }
            New-ADUser $NewADUserParam
                    
            Write-Host "Usuario" $User.UserPrincipalName "creado" -ForegroundColor DarkGreen
   
            #establecer que el usuario cambie la contraseña al iniciar la sesión por primera vez
            Set-ADUser `
                -Identity $User.SamAccountName `
                -ChangePasswordAtLogon $true

            #agregar los usuarios al grupo indicado en el fichero
            if ($User.Group -ne "") {
                Add-ADGroupMember `
                    -Identity $User.Group `
                    -Members $User.SamAccountName
                Write-Host "Usuario asignado al grupo:" $User.Group -ForegroundColor DarkGreen
            }
        }
        else{
            Write-Host "usuario" $User.UserPrincipalName "ya existe en el dominio"  -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al crear el usuario $($User.SamAccountName): $_" -ErrorAction Stop  -ForegroundColor Red
    }   
}
Write-Host "Proceso conculido" -ForegroundColor Green