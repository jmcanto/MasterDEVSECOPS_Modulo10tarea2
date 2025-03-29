# Definir el servidor DNS secundario deseado
$dnsSecundarioDeseado = "8.8.4.4"  # Dirección IP del servidor DNS secundario

# Obtener la interfaz de red activa con conexión a Internet
$interfazActiva = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
try
{
    # Verificar si se encontró una interfaz activa
    if ($interfazActiva) {
        $nombreInterfaz = $interfazActiva.Name
        $indiceInterfaz = $interfazActiva.InterfaceIndex
       -InterfaceAlias $nombreInterfaz  Write-Output "Interfaz activa detectada: $nombreInterfaz"


        # Obtener las direcciones DNS actuales de la interfaz -InterfaceAlias $nombreInterfaz 
        $dnsActuales = Get-DnsClientServerAddress -InterfaceIndex $indiceInterfaz | Select-Object -ExpandProperty ServerAddresses

        # Verificar si el DNS secundario deseado ya está configurado
        if ($dnsActuales -contains $dnsSecundarioDeseado) {
            Write-Output "El servidor DNS secundario $dnsSecundarioDeseado ya está configurado en la interfaz $nombreInterfaz."
        } else {
            # Añadir el DNS secundario deseado a la lista de servidores DNS actuales
            $nuevosDns = $dnsActuales + $dnsSecundarioDeseado
            Set-DnsClientServerAddress -InterfaceAlias $nombreInterfaz -ServerAddresses $nuevosDns
            Write-Output "Se ha añadido el servidor DNS secundario $dnsSecundarioDeseado a la interfaz $nombreInterfaz."
        }
        
    } else {
        Write-Output "No se encontró ninguna interfaz de red activa con conexión a Internet."
    }
}
catch
{
    Write-Host "Problema: " $_.Exception.Message -ErrorAction Stop -ForegroundColor Magenta
    break
}