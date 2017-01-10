Manual de Instalación de Alfresco
=================================

Requisitos:
-----------

### Hardware (Servidor Alfresco)

  * \> 4GB RAM (Mejor o mas).

  * Espacio en disco "suficiente" en /home/alfresco
    - Preferentemente volumen LVM con bloques libres en su Volume Group


### Software

  * **Sistema Operativo:** Ubuntu Xenial64 o posterior (preferentemente LTS).

  * **Instalador de Alfresco**:

    - *Version anteriormente instalada:* 201602
        - Fichero `alfresco-community-installer-201602-linux-x64.bin`
          (localizar en el archivo documental)
        - Si no lo tenemos, puede descargarse del [Repositorio de Alfresco
          Community](http://dl.alfresco.com/release/community/201612-build-00014/alfresco-community-installer-201602-linux-x64.bin)

        > NOTA: Ésta es versión instalada al momento de redactar ésta IT. Hay
        > que asegurarse de que realmente sea ésta la que debemos instalar y no
        > una posterior si ésta IT estuviera desactualizada.

    - *Última versión:* Descargar de [Alfresco Community
      Site](https://www.alfresco.com/alfresco-community-download).

  * **BBDD:**

    - El requerimiento mínimo de Alfresco es Postgresql 9.4

    - Nosotros usaremos dos servidores de BBDD PostgreSQL 9.6 o superior en
      configuración de Master/Esclavo (hot-standby) ya sean compartidos con
      otras BBDD o dedicados para éste servicio.


Preparación de la Base de Datos
-------------------------------


### Creación del usuario *alfresco*

    $ sudo -u postgres createuser -P alfresco
    Enter password for new role:
    Enter it again:

### Creación de la Base de Datos

    $ sudo -u postgres psql
    psql (9.6.1)
    Type "help" for help.

    postgres=# create database alfresco owner alfresco;
    CREATE DATABASE
    postgres=# \q

### Otros ajustes

  * Requisitos de Alfresco:
    - postgresql.conf
      - max_connections = 275
  * Conectividad:
    - Debemos verificar que tanto la configuración del servidor de BBDD como
      los firewall intermedios que puedan haber nos permiten establecer
      conexiones al servidor de PostgreSQL por el puerto en el que éste escucha
      (típicamente el 5432).
    - Para ello lo mas fácil será instalar un cliente de postgres en éste e
      intentar la conexion.
    

### Bibliografia

  * [Configuración PostgreSQL para Alfresco](http://docs.alfresco.com/4.1/tasks/postgresql-config.html)



Instalación de Alfresco Community
---------------------------------


### 1. Preparación de la máquina.

  * Hardware segun apartado "Requisitos del sistema".
  * Ajustes en /etc/fstab para el montado del volumen de datos en /home/alfresco
  * Ejecutar `sudo mount -a` para que se procese y verificar que el volumen se monta correctamente en dicha ruta.


### 2. Ejecutar script de preparación `alfSetup.sh`

Éste script nos realizará las siguientes tareas:

  * Instalación de dependencias necesarias.
  * Creación del usuario *alfresco*.
    - No pasa nada si /home/alfresco ya existe.
    - ...en dicho caso, el própio script ya ajusta el propietario tras su creación.
  * Configuración IPtables
    - Se añaden las siguientes redirecciones de puertos:
        - 80 al 8080 (http)
        - 443 al 8443 (https)
    - Se vuelca `iptables-save` en /etc/firewall.iptables
    - Se configura cron (root) para su restauración tras cada reboot.

### 3. Ejecutar instalador de Alfresco:

Debemos ejecutarlo con el usuario *alfresco* para lo que primeramente ejecutaremos:

    sudo su - alfresco


Seguidamente ejecutamos el instalador y responderemos a lo que se nos pregunte segun el siguiente criterio:

  > **NOTA:** Los parámetros que se muestran entre "[" y "]" son (o deberian
  > ser) en realidad los valores por defecto. Se indican aquí únicamente a
  > efectos de confirmación.

  * *Idioma:* 3 (Spanish).
  * *Tipo de instalación:* 2 (Avanzada)
  * *PostgreSQL*: n (NO: Puesto que utilizaremos un servidor externo).
  * *Carpeta de instalacion:* [/home/alfresco/alfresco-community]
  * *Dominio de Servidor Web:* IP del servidor (para el ejemplo usaremos 172.30.7.24).
  * Puerto del servidor Tomcat: [8080]
  * Para el **resto de parámetros** dejaremos el valor por defecto (pulsar "Enter"):

#### Ejemplo:

```sh

    $ sudo su - alfresco
    alfresco@Alfresco:~$ /vagrant/alfresco-community-installer-201602-linux-x64.bin 
    Language Selection

    Please select the installation language
    [1] English - English
    [2] French - Français
    [3] Spanish - Español
    [4] Italian - Italiano
    [5] German - Deutsch
    [6] Japanese - 日本語
    [7] Dutch - Nederlands
    [8] Russian - Русский
    [9] Simplified Chinese - 简体中文
    [10] Norwegian - Norsk bokmål
    [11] Brazilian Portuguese - Português Brasileiro
    Please choose an option [1] : 3
    ----------------------------------------------------------------------------
    Bienvenido a la instalación de Alfresco Community.

    ----------------------------------------------------------------------------
    Tipo de instalación

    [1] Fácil: instalación con la configuración predeterminada.
    [2] Avanzada: configura las propiedades de servicio y los puertos de servidor.: También puede elegir componentes opcionales para instalar.
    Por favor seleccione una opción [1] : 2

    ----------------------------------------------------------------------------
    Seleccione los componentes que desea instalar; desmarque aquellos que no desea.

    Java [Y/n] :

    PostgreSQL [Y/n] :n

    LibreOffice [Y/n] :

    Alfresco Community : Y (Cannot be edited)

    Solr1 [y/N] : 

    Solr4 [Y/n] :

    Alfresco Office Services [Y/n] :

    Web Quick Start [y/N] : 

    Integración de Google Docs [Y/n] :

    ¿Es correcta la selección que se muestra aqui arriba? [Y/n]: 

    ----------------------------------------------------------------------------
    Carpeta de instalación

    Elija una carpeta para instalar Alfresco Community.

    Seleccionar una carpeta: [/home/alfresco/alfresco-community]: 

    ----------------------------------------------------------------------------
    Configuración de la base de datos

    URL de JDBC: [jdbc:postgresql://localhost/alfresco]: jdbc:postgresql://172.30.7.18/alfresco

    Controlador JDBC: [org.postgresql.Driver]: 

    Database name: [alfresco]: 

    Nombre de usuario: []: alfresco

    Contraseña: :
    Verificar: :
    ----------------------------------------------------------------------------
    Configuración de puerto Tomcat

    Introduzca sus parámetros de configuración de Tomcat.

    Dominio de Servidor Web: [127.0.0.1]: 172.30.7.26

    Puerto del servidor Tomcat: [8080]: 

    Puerto de cierre de Tomcat: [8005]: 

    Puerto SSL de Tomcat: [8443]: 

    Puerto AJP de Tomcat: [8009]: 

    ----------------------------------------------------------------------------
    Puerto de servidor LibreOffice

    Introduzca el puerto en el que escuchará el servidor de LibreOffice.

    Puerto de servidor LibreOffice: [8100]: 

    ----------------------------------------------------------------------------
    Puerto FTP de Alfresco

    Elija un número de puerto para el servidor FTP integrado de Alfresco.

    Puerto: [2121]: 

    ----------------------------------------------------------------------------
    Contraseña de admin

    Especifique una contraseña para la cuenta de administrador de Alfresco.

    Contraseña de admin: :
    Repita la contraseña: :
    ----------------------------------------------------------------------------
    El programa está listo para iniciar la instalación de Alfresco Community en su 
    ordenador.

    ¿Desea continuar? [Y/n]: 

    ----------------------------------------------------------------------------
    Por favor espere mientras se instala Alfresco Community en su ordenador.

     Instalando
     0% ______________ 50% ______________ 100%
     #########################################

    ----------------------------------------------------------------------------
    El programa terminó la instalación de Alfresco Community en su ordenador.

    Ver el archivo Léeme [Y/n]: n

    Lanzar Alfresco Community [Y/n]: n


```


Configuración
-------------


  * tomcat/shared/classes/alfresco-global.properties

  * bin/ocr-simply.py

  * tomcat/shared/classes/alfresco/extension/ocr-context.xml

  * solr4/*



Solución de Problemas
---------------------


