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

# listando el fichero, para comprobar que los datos aparecen bien
Write-Host "Usuarios importados desde el CSV:"
$Users | Format-Table -Property FirstName,LastName,SamAccountName,UserPrincipalName,Path,Password,Description,Group

foreach ($User in $Users) {
    
    $rutaOU = $User.Path
    if (-not $rutaOU) {
        $rutaOU = $defaultPath
    }
    
    #comprobando la ruta, si no es válida se asigna el path por defecto obtenido del domino
    try {

        $ou = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$rutaOU'" -ErrorAction Stop

    } catch {
        Write-Host "Ruta OU no válida: $rutaOU. Usando la ruta por defecto." -ForegroundColor Yellow
        $rutaOU = $defaultPath
    }

    try {
        # Comprobar si no existe el usuario, en cuyo caso se crea
                    
        if(-not (Get-ADUser -Filter "SamAccountName -eq '$($User.SamAccountName)'")) {
            Write-Host "El usuario" $User.UserPrincipalName "no existe se debe crear" -ForegroundColor Magenta
            
            $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force                              
                        
            $nombre = $User.FirstName
            $apellido = $User.LastName

            # Validar y ajustar los nombres
            $nombreCuenta = $User.SamAccountName -replace "[^a-zA-Z0-9]", ""
            $usuarioPrincipal = $User.UserPrincipalName -replace "[^a-zA-Z0-9@.]", ""

            # Verificar si los campos nombreCuenta y usuarioPrincipal cumplen con los requisitos
            if ($nombreCuenta.Length -gt 20) {
                Write-Host "SamAccountName demasiado largo: $nombreCuenta" -ForegroundColor Red
                continue
            }

            if ($usuarioPrincipal -notmatch "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
                Write-Host "UserPrincipalName no válido: $usuarioPrincipal" -ForegroundColor Red
                continue
            }

            Write-Host "Nombre: $nombre"
            Write-Host "Apellido: $apellido"
            Write-Host "Nombre Cuenta: $nombreCuenta"
            Write-Host "Nombre Inicio Sesión: $usuarioPrincipal"
            Write-Host "Path: $rutaOU"
            Write-Host "Descripción: $($User.Description)"
            Write-Host "Grupo: $($User.Group)"

            New-ADUser -Name "$nombre $apellido" `
             -DisplayName "$nombre $apellido" `
             -SamAccountName $nombreCuenta `
             -UserPrincipalName $usuarioPrincipal `
             -GivenName "$nombre" `
             -Surname "$apellido" `
             -Description "$($User.Description)" `
             -AccountPassword $SecurePassword `
             -Enabled $true `
             -Path "$rutaOU" `
             -ChangePasswordAtLogon $true `
             –PasswordNeverExpires $false `
             -Server $dominio.DnsRoot            
                    
            Write-Host "Usuario" $User.UserPrincipalName "creado" -ForegroundColor Green
   
            #agregar los usuarios al grupo indicado en el fichero
            if ($User.Group -ne "") {
                Add-ADGroupMember `
                    -Identity $User.Group `
                    -Members $User.SamAccountName
                Write-Host "Usuario asignado al grupo:" $User.Group -ForegroundColor Green
            }
            Write-Host "------------\n"
        }
        else{
            Write-Host "usuario" $User.UserPrincipalName "ya existe en el dominio"  -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al crear el usuario $($User.SamAccountName): $_" -ErrorAction Stop  -ForegroundColor Red
    }   
}
Write-Host "Proceso conculido" -ForegroundColor Green