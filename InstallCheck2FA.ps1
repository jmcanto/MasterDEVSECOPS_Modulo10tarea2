#Habilitación del segundo factor de autentificación para servidores Windows
#Irá realizando una serie de comprobaciones en el caso que sea necesario que fuera
#necesario instalar algunos servicios o controladores de dominio.
#
#variables a usar
$nombreDominio = "devsecops.es"
#obtener nombre del equipo donde se está ejecutando el script
$nombreEquipo = (Get-ComputerInfo).CSName #Get-ComputerInfo -Property CSName

param($instalardc, $instalarad)

#Comprobar que el servicio de dominio está activo "Servicios de dominio de Active Directory"
try
{
    $servicioAD = Get-Service NTDS

    if ($servicioAD.Status -eq "Running")
    {
        Write-Host "Directorio Activo en funcionamiento"  -ForegroundColor Green 
        Write-Host "Buscando controladores primarios en el dominio" $nombreDominio
        $controladorDominio = Get-ADDomainController -DomainName $nombreDominio -Discover

        Write-Host $ControladorDominio.Name
        if ($nombreEquipo -ne $controladorDominio.Name)
        {
            #comprobar el valor del parámetro y si su valor es si, se el servidor como controlador de dominio secundario
            if($instalardc -eq "si" -or $instalardc -eq "s")
            {
                Write-Host "Asignar al equipo el papel de controlador de dominio de solo lectura"
                Install-ADDSDomainController -DomainName $nombreDominio -ReplicationSourceDC $controladorDominio.Name -Credential (Get-Credential)
                Restart-Computer -Force -Verbose
            }
        }
    }
    elseif ($servicioAD.Status -eq "Stopped")
    {
        Write-Host "Arrancando el servicio" -ForegroundColor DarkGreen
        Start-Service -Name NTDS
        Write-Host "Servicio" $servicioAD.DisplayName "Arrancado" -ForegroundColor Green
        Write-Host "Ejecute de nuevo el este script"
    }
    else
    {
        #comprobar el valor del parámetro y si su valor es si, se instala
        if($instalarad -eq "si" -or $instalarad -eq "s")
        {
            Write-Host "Instalar Directorio Activo" DarkGreen
            Add-WindowsFeature -name AD-Domain-Services, DNS, -IncludeAllSubFeature -IncludeManagementTools -Restart
        
            Write-Host "Instalar Controlador de Dominio"
            Install-ADDSDomainController -DomainName $nombreDominio -InstallDNS -CreateDNSDelegation -Credential (Get-Credential) 
            Restart-Computer -Force -Verbose        
        }
    }
}
catch
{ 
    Write-Output "Problema: " $_.Exception.Message -ErrorAction Stop -ForegroundColor Magenta 
    break
}