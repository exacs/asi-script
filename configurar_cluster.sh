#!/bin/bash

############################################################
#
# MOUNT - fichero de dos lineas
#
############################################################
### $1 = nombre-del-dispositivo
### $2 = punto-de-montaje
function Mo(){
    echo "--- Servicio mount -------------------------------"
    echo "máquina:          $IP"
    echo "dispositivo:      $1"
    echo "punto de montaje: $2"
    echo ""

    if $( ssh -oStrictHostKeyChecking=no $IP "test -d $2" ); then
        if [ $( ssh $IP "ls -A $2" ) ]; then
            echo "Error. El punto de montaje $2 no es un directorio vacío." >&2
            return 1
        else
            echo "Directorio $2 vacío. Válido."
        fi
    else
        echo "El punto de montaje no existe. Creando directorio $2"
        $( ssh $IP "mkdir $2")
    fi

    # Escribir el fichero /etc/fstab
    echo "Editando el fichero /etc/fstab para hacer permanente el montaje"
    ssh $IP "echo '$1 $2 ext3 defaults 0 0' >> /etc/fstab"
    echo "Montando todos los dispositivos"
    ssh $IP "mount -a"

    echo "--- Terminando servicio mount --------------------"
    exit 0
}

############################################################
#
# RAID - fichero de 3 líneas
#
############################################################
### $1 = nombre-del-nuevo-dispositivo-raid
### $2 = nivel-de-raid
### $3 = dispositivo-1  dispositivo-2... (separado por espacios)
function Raid(){
    echo "--- Servicio raid --------------------------------"
    echo "máquina:                $IP"
    echo "nuevo dispositivo RAID: $1"
    echo "nivel de RAID:          $2"
    echo "dispositivos:           $3"
    echo ""

    WORDS=( $3 )
    NUMERO_DISPOSITIVOS=${#WORDS[@]}

    # Comprobar nivel de RAID (0 ~ 6)
    if [ $2 -gt 6 ] && [ $2 -lt 0 ]; then
        echo "El nivel de RAID especificado no es válido." >&2
        return 1
    fi

    # Comprobar que existen todos los dispositivos
    for dispositivo in $3; do
        if $( ssh $IP "test -e $dispositivo" ); then
            echo "Dispositivo \"$dispositivo\" existe"
        else
            echo "ERROR: El dispositivo \"$dispositivo\" no existe" >&2
            return 1
        fi
    done


    # Instalar mdadm
    echo "Instalando mdadm"
    set +e
    ssh $IP "sudo aptitude install mdadm" > /dev/null

    if [ $? -ne 0 ]; then
       set -e
       echo "Error en la instalación" >&2
       return 1
    fi

    set -e
    echo "Instalación terminada"

    # Crear vector RAID
    echo "Creando RAID"

    set +e
    ssh $IP "mdadm --create $1 --level=$2 --force --raid-devices=$NUMERO_DISPOSITIVOS $3"

    if [ $? -ne 0 ]; then
        set -e
        echo "Error creando RAID" >&2
        return 1
    fi
    set -e

    return 0
    echo "RAID creado con exito"
}

############################################################
#
# LMV - fichero de dos o más lineas
#
############################################################
### $1 = nombre-del-dispositivo
### $2 = punto-de-montaje
function Log(){
  echo "en ello"
}

############################################################
#
# Servidor NIS - fichero de una línea
#
############################################################
### $1 = nombre-de-dominio-nis
function NisSer(){
    echo "--- Servicio Servidor NIS --------------------------------"
    echo "máquina:            $IP"
    echo "nombre del dominio: $1"
    echo ""

    echo "Instalando paquete nis"
    set +e
    ssh $IP "sudo aptitude -y -q install nis" > /dev/null

    if [ $? -ne 0 ]; then
        set -e
        echo "Error en la instalación" >&2
        return 1
    fi

    set -e

    echo "Definiendo nombre del dominio"
    ssh $IP "nisdomainname $1"

    echo "Reiniciando demonio NIS"
    ssh $IP "sudo /etc/init.d/nis restart"

    echo "Servidor NIS configurado con éxito"
    return 0
}


############################################################
#
# Cliente NIS - fichero de dos líneas
#
############################################################
### $1 = nombre-de-dominio-nis
### $2 = servidor-nis-al-que-se-desea-conectar
function NisCli(){
    echo "--- Servicio Cliente NIS --------------------------------"
    echo "máquina:                    $IP"
    echo "nombre del dominio:         $1"
    echo "dirección del servidor NIS: $2"
    echo ""

    echo "Instalando paquete nis"
    set +e
    ssh $IP "sudo aptitude -y -q install nis" > /dev/null

    if [ $? -ne 0 ]; then
        set -e
        echo "Error en la instalación" >&2
        return 1
    fi

    set -e
    echo "Añadiendo nombre de dominio"
    ssh $IP "echo 'domain $1 server $2' >> /etc/yp.conf"

    echo "Permitiendo que el usuario 'practicas' se conecte"
    ssh $IP "sed -i 's/passwd:[ ]*compat/passwd:         nis compat/' /etc/nsswitch.conf"
    ssh $IP "sed -i 's/group[ ]*compat/group:          nis compat/' /etc/nsswitch.conf"
    ssh $IP "sed -i 's/shadow:[ ]*compat/shadow:         nis compat/' /etc/nsswitch.conf"

    echo "--- Terminando servicio Cliente NIS  --------------------"
}

############################################################
#
# Servidor NFS - fichero de N líneas
#
############################################################
### Cada línea es una ruta-de-directorio-exportado
function NfsSer(){
    echo "--- Servicio Servidor NIS --------------------------------"
    echo "máquina:            $IP"
    echo ""
}


############################################################
#
# Cliente NIS - fichero de N líneas
#
############################################################
### Cada línea es ip-servidor ruta-de-directorio punto-de-montaje
function NfsCli(){
    echo "--- Servicio Servidor NIS --------------------------------"
    echo ""
}


############################################################
#
# Backup Server - fichero de una linea
#
############################################################
### $1 = directorio-donde-se-realiza-el-backup
function BackSer(){
  echo "--- Servicio backup_server -------------------------------"
  echo "máquina:          $IP"
  echo "directorio:       $1"
  echo ""

  #Comprobar que el directorio existe
  if $( ssh -oStrictHostKeyChecking=no $IP "test -d $1" ); then
      if [ $( ssh $IP "ls -A $1" ) ]; then
          echo "Error. El directorio $1 NO es un directorio vacío." >&2
          return 1
      else
          echo "Directorio $1 vacío. Válido."
      fi
  else
      echo "El directorio donde se desea realiza el backup del servidor no existe."
  fi

  echo "--- Terminando servicio backup_server --------------------"
  exit 0
}

############################################################
#
# Backup Cliente - fichero de cuatro lineas
#
############################################################
### $1 = ruta-del-directorio-del-que-se-desea-hacer-backup
### $2 = direccion-del-servidor-de-backup
### $3 = ruta-de-directorio-destino-del-backup
### $4 = periodicidad-del-backup-en-horas
function BackCli(){
  echo "--- Servicio backup_client -------------------------------"
  echo "máquina:          $IP"
  echo "directorio:       $1"
  echo "directorio:       $2"
  echo "directorio:       $3"
  echo "directorio:       $4"
  echo ""


  echo "--- Terminando servicio backup_client --------------------"
  exit 0
}
############################################################
#
# PRINCIPAL.
#
############################################################
# Comprobar que el número de argumentos es exactamente 1
if [ ! $1 ]; then
    echo 'Uso: configurar_cluster.sh perfil_de_configuracion' >&2
    exit 1
fi

if [ $2 ]; then
    echo 'Uso: configurar_cluster.sh perfil_de_configuracion' >&2
    exit 1
fi

PERFIL_CONFIGURACION=$1

# Comprobar que el perfil de configuración existe
if [ ! -f $PERFIL_CONFIGURACION ]; then
    echo 'Perfil de configuración inexistente' >& 2
    exit 1
fi

# Comprobar que el perfil de configuración es legible
if [ ! -r $PERFIL_CONFIGURACION ]; then
    echo 'Perfil de configuración ilegible' >& 2
    exit 1
fi

# Comprobar que el perfil de configuración no está vacío
if [ ! -s $PERFIL_CONFIGURACION ]; then
    echo 'Perfil de configuración vacío' >& 2
    exit 1
fi

# Comprobar que no hay error de sintaxis
# (no falta el fichero de configuración en ninguno)
COUNT=0
while read p; do
    COUNT=$(( COUNT + 1))

    if [ -z "$p" ]; then
        : # Se trata de una línea vacía
    elif [[ $p = \#* ]]; then
        : # Se trata de un comentario
    else
        # Comprobar que la línea tiene un patrón determinado
        echo $p | egrep -q "^.+ .+ .+$"
        if [ $? -ne 0 ]; then
            echo "Perfil de configuración erróneo. Error de sintaxis en línea $COUNT" >& 2
            exit 1
        fi

        # Comprobar que la segunda palabra es un comando válido
        echo $p | egrep -q '^.+ (mount|raid|lvm|nis_server|nis_client|nfs_server|nfs_client|backup_server|backup_client) .+$'
        if [ $? -ne 0 ]; then
            echo "Perfil de configuración erróneo. No existe el servicio solicitado en línea $COUNT" >& 2
            exit 1
        fi

        # Extraer el nombre del fichero de configuración
        read -r -a array <<< "$p"
        IP=${array[0]}
        COMANDO=${array[1]}
        CONT=0

        # Leer fichero de configuración  array[2]
        while IFS= read line; do
            CONT=$((CONT + 1))
            VAR[$CONT]=$line    #contenido de la línea
        done < ${array[2]}

        # Guardar solo el número de líneas
        NUML=$(wc -l ${array[2]} | cut -d' ' -f1)

        # Saber que fichero debo de leer y que tengo que hacer $1 por nombre
        case "$COMANDO" in
            mount)
                if (( $NUML == 2  )); then
                    set -e
                    Mo ${VAR[1]} ${VAR[2]}    #función que ejecuta mount
                    set +e
                else
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene DOS lineas para MOUNT"
                fi
                ;;
            raid)
                if (( $NUML == 3  )); then
                    set -e
                    Raid ${VAR[1]} ${VAR[2]} "${VAR[3]}"    #función que ejecua mdam
                    set +e
                else
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene TRES lineas para RAID"
                fi
                ;;
            lvm)
                if (( $NUML -gt 2 )); then
                   set -e
                   Log ${VAR[3]}    #función que ejecua lvm
                   set +e
                else
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene DOS o más lineas para LVM"
                fi
                ;;
            nis_server)
                if (( $NUML == 1 )); then
                    set -e
                    NisSer ${VAR[1]}
                    set +e
                else
                    echo $NUML
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene UNA línea"
                    exit 1
                fi
                ;;
            nis_client)
                if (( $NUML == 2 )); then
                    set -e
                    NisCli ${VAR[1]} ${VAR[2]}
                    set +e
                else
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene DOS líneas"
                fi
                ;;
            backup_server)
                if (( $NUML == 1 )); then
                   set -e
                   BackSer ${VAR[1]}    #función que ejecua backup_server
                   set +e
                else
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene UNA linea para BACKUP_SERVER"
                fi
                ;;
            backup_client)
                if (( $NUML == 4 )); then
                   set -e
                   BackCli ${VAR[1]} ${VAR[2]} ${VAR[3]} ${VAR[4]}    #función que ejecua backup_client
                   set +e
                else
                    echo "Error de sintaxis: El fichero de perfil de servicio NO contiene CUATRO lineas para BACKUP_CLIENT"
                fi
                ;;
            *)
                ;;
        esac
    fi

done <$PERFIL_CONFIGURACION

echo "Terminando operación sin errores"
# Sin errores
exit 0
