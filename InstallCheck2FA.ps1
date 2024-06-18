# Habilitación del segundo factor de autentificación para servidores Windows
# Irá realizando una serie de comprobaciones de servicios para el caso que sea necesario
# instalar algunos de estos servicios o crear controladores de dominio.
# Atención para la correcta ejecución del script se necesitan permisos de administrador
#
#variables a usar
$nombreDominio = "devsecops.es"
$nombreaMostrar = "Master DEVSECOPS"
#obtener nombre del equipo donde se está ejecutando el script
$nombreEquipo = (Get-ComputerInfo).CSName #Get-ComputerInfo -Property CSName

param([string]$instalarDC, [string]$instalarAD, [string]$instalarFS)

#Comprobar que el servicio de dominio está activo "Servicios de dominio de Active Directory"
try
{
    $servicioAD = Get-Service NTDS

    if ($servicioAD.Status -eq "Running")
    {
        Write-Host "Directorio Activo en funcionamiento" -ForegroundColor Green 
        Write-Host "Buscando controladores primarios en el dominio" $nombreDominio
        $controladorDominio = Get-ADDomainController -DomainName $nombreDominio -Discover

        Write-Host $ControladorDominio.Name
        if ($nombreEquipo -ne $controladorDominio.Name)
        {
            #comprobar el valor del parámetro y si su valor es si, se el servidor como controlador de dominio secundario
            if ($instalarDC -eq "si" -or $instalarDC -eq "s")
            {
                Write-Host "Asignar al equipo el papel de controlador de dominio de solo lectura"
                Install-ADDSDomainController -DomainName $nombreDominio -ReplicationSourceDC $controladorDominio.Name -Credential (Get-Credential)
                Restart-Computer -Force -Verbose
            }
        }
        #creación cuenta de servicio de gestión de grupo
        Add-kdsRootkey -EffectiveTime ((get-date).AddHours(-10))

        # comprobar si el parámetro indica que se instale el servicio de federación,
        # esto implicará que se instale AD CS primero
        if ($instalarFS -eq "si" -or $instalarFS -eq "s")
        {
            # Comprobar si AD CS ya está instalado
            $adcsInstalled = Get-WindowsFeature -Name ADCS-Cert-Authority
            if ($adcsInstalled.Installed) 
            {
                Write-Output "AD CS ya está instalado no es necesario instalarlo en $nombreEquipo." -ForegroundColor Magenta
            } 
            else 
            {

                # Instalación AD CS
                Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

                # Configurar AD CS como una CA Raíz de Empresa
                Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" -KeyLength 2048 -HashAlgorithmName SHA512 -ValidityPeriod Years -ValidityPeriodUnits 5

                Write-Output "Servicios de certificación de Active Directory se ha instalado en $nombreEquipo y configurado correctamente." -ForegroundColor Green 
            }

            # Comprobar si AD FS ya está instalado
            $adfsInstalled = Get-WindowsFeature -Name ADFS-Federation
            if ($adfsInstalled.Installed) 
            {
                Write-Output "AD FS ya está instalado no es necesario instalarlo en $nombreEquipo." -ForegroundColor Magenta
            } 
            else
            {
                # Instalación AD FS
                Install-WindowsFeature ADFS-Federation -IncludeManagementTools

                # Generar un certificado SSL autofirmado
                # "Cert:\LocalMachine\My" es la localización por defecto para los certificados
                $nombreADFS="adfs.$nombreDominio"
                $certificado = New-SelfSignedCertificate -DnsName $nombreADFS -CertStoreLocation "Cert:\LocalMachine\My"

                # Obtener la huella digital de dicho certificado creado
                $huellaCert = $certificado.Thumbprint

                # Pedir credenciales para la cuenta de servicio de AD FS
                $serviceAccount = Get-Credential -Message "Introduce las credenciales de la cuenta de servicio para AD FS" -ForegroundColor Yellow

                # Instalar y configurar AD FS con la huella digital obtenida
                Install-AdfsFarm -CertificateThumbprint $huellaCert -FederationServiceDisplayName $nombreaMostrar -FederationServiceName $nombreADFS -ServiceAccountCredential $serviceAccount
 
                Write-Output "AD FS se ha instalado y configurado correctamente en $nombreEquipo." -ForegroundColor Green
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
        if($instalarAD -eq "si" -or $instalarAD -eq "s")
        {
            Write-Host "Instalar Directorio Activo" -ForegroundColor Green
            Add-WindowsFeature -name AD-Domain-Services, DNS, -IncludeAllSubFeature -IncludeManagementTools -Restart
        
            Write-Host "Instalando Controlador de Dominio"
            Install-ADDSDomainController -DomainName $nombreDominio -InstallDNS -CreateDNSDelegation -Credential (Get-Credential) 
            Write-Host "Reiniciando servidor" -ForegroundColor Red
            Write-Host "Ejecute de nuevo el este script tras reinicio"
            Restart-Computer -Force -Verbose        
        }
    }
}
catch
{ 
    Write-Output "Problema: " $_.Exception.Message -ErrorAction Stop -ForegroundColor Magenta 
    break
}