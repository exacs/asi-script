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
    fi

done <$PERFIL_CONFIGURACION

# Sin errores
exit 1
