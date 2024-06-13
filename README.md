# MasterDEVSECOPS_Modulo10tarea2
Tarea 2 del Módulo 10 ingeniería de la identidad del master  del Master desarrollo seguro y DEVSECOPS<br>
<p>Como parte de las tareas a realizar en este módulo, el cliente ficticio del que se habla en el planteamiento del ejercicio, nos solicita que le entreguemos un script/herramienta que su equipo de sistemas pueda utilizar, para automatizar ciertas tareas que deban ejecutar al seguir dicha guía, u otras actividades relacionadas.</p>
<p></p>En mi caso me decanté por implementar el segundo factor de autentificación para usuarios de un dominio windows<br>
Inicialmente, había pensado en incluirlo todo en un mismo script, pero por simplificar los scripts de powershell, se va a hacer por separado. En prinipio se crearan los siguientes scripts:</p>
<ul>
  <li>script para crear dominio si no está creado anteriormente.</li>
  <li>script para crear usuarios guardados en fichero texto.</li>
  <li>script comprobación para los usuarios del dominio si tienen habilitado el segundo factor de autentificación.</li>
</ul>

El escenario planteado existen 4 grupos de usuarios y la empresa ficticia en el momento cuenta con 20 trabajadores, que se repartirán equitativamente por los 4 grupos. Los grupos son los siguientes:
- Dirección
- Recursos Humanos
- TI
  - Desarrollo
  - Sistemas  
