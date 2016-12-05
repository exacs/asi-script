#!/bin/bash
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
        echo $p | egrep -q '^.+ (mount|raid|lvm|nis_client|nfs_server|nfs_client|backup_server|backup_client) .+$'
        if [ $? -ne 0 ]; then
            echo "Perfil de configuración erróneo. No existe el servicio solicitado en línea $COUNT" >& 2
            exit 1
        fi

        # Extraer el nombre del fichero de configuración
        read -r -a array <<< "$p"
        IP=${array[0]}
        COMANDO=${array[1]}
        CONT=0

        for LINEA in `cat ${array[2]}`
        do
            CONT=$((CONT + 1))
            VAR[$CONT]=$LINEA
        done

        NUML=$(wc -l ${array[2]} | cut -d' ' -f1)

        #Saber que fichero debo de leer y que tengo que hacer $1 por nombre
        case "$COMANDO" in
            mount)
                if (( $CONT == 2  )); then
                    set -e
                    Mo ${VAR[1]} ${VAR[2]}
                    set +e
                else
                    echo "El fichero contiene mas lineas de las especificadas"
                fi
                ;;
            raid)
                if (( $NUML == 3  )); then
                    set -e
                    Raid ${VAR[3]}
                    set +e
                else
                    echo "El fichero contiene mas lineas de las especificadas"
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
