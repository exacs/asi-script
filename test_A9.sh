#!/bin/bash
# Este código realiza pruebas para comprobar el fichero principal
# Ver Enunciado, Apéndice A.9. Página 15

###### NO MODIFICAR ESTA SECCIÓN #########################################
# Esta sección se ha tomado de un fichero de corrección adquirido por los
# profesores de la asignatura "Programación para Sistemas"

# ejecuta un mandato, retorna el exit status del mandato previamente
# almacenado en la variable de entorno xtatus y almacena la salida
# estándar en el fichero .fd1 y la salida de error en el fichero .fd2
test_run() # Command [args...] [| Command...] [<2>> redirections...]
{
    echo "$ $@"
    [ -x $1 ] || (echo "No existe el ejecutable $1"; exit 1)
    "$@" > .fd1 2> .fd2
    xtatus=$?
    return $xtatus
}

# Comprueba que xtatus tiene como valor el indicado por el primer
# parámetro
test_status()
{
    if [ $xtatus -eq $1 ]; then
        echo "Valor de terminación correcto"
    else
        echo "Valor de terminación incorrecto"
        echo "Se esperaba $1 y pero el valor es $xtatus"
        exit 1
    fi;
    return 0
}

# Comprueba que el número de líneas de la salida estándar o de error
# son los adecudados
test_lines()
{
    typeset -i nlines=`cat .fd$1 | wc -l`
    [ $nlines $2 $3 ] && return 0

    echo "Error en el número de líneas del descriptor $1"
    echo "Se esperaba $nlines $2 $3"
    exit 1
}

# Comprueba que el contenido de la salida estándar o de la salida de
# error son adecuados
test_content()
{
    if sdiff .fd$1 ${2:--}; then
        echo "Contenido correcto"
        echo ""
    else
        echo "El contenido del descriptor $1 NO es el esperado"
        exit 1
    fi;
    return 0
}

######################################################################
#
#   PRUEBAS
#
######################################################################
# Al ejecutar el comando
# $ configurar_cluster.sh
#
# Debe retornar un código de error 1 y mostrar por la stderr
# "Uso: configurar_cluster.sh perfil_de_configuracion"
test_run ./configurar_cluster.sh
test_status 1
test_lines 1 -eq 0
test_lines 2 -eq 1
test_content 2 <<EOF
Uso: configurar_cluster.sh perfil_de_configuracion
EOF

# Al ejecutar el comando
# $ configurar_cluster.sh inexistente.conf
#
# En donde inexistente.conf es un fichero que no existe
#
# Debe retornar un código de error 1 y mostrar por la stderr
# "Perfil de configuración inexistente"
test_run ./configurar_cluster.sh inexistente
test_status 1
test_lines 1 -eq 0
test_lines 2 -eq 1
test_content 2 <<EOF
Perfil de configuración inexistente
EOF

# Al ejecutar el comando
# $ configurar_cluster.sh ilegible.conf
#
# En donde ilegible.conf es un fichero de configuración sin permisos de lectura
#
# Debe retornar un código de error 1 y mostrar por la stderr
# "Perfil de configuración ilegible"
chmod -r ilegible.conf
test_run ./configurar_cluster.sh ilegible.conf
test_status 1
test_lines 1 -eq 0
test_lines 2 -eq 1
test_content 2 <<EOF
Perfil de configuración ilegible
EOF
chmod +r ilegible.conf

# Al ejecutar el comando
# $ configurar_cluster.sh vacio.conf
#
# En donde vacio.conf es un fichero en blanco o con solo comentarios
#
# Debe retornar un código de error 1 y mostrar por la stderr
# "Perfil de configuración vacío"
test_run ./configurar_cluster.sh vacio.conf
test_status 1
test_lines 1 -eq 0
test_lines 2 -eq 1
test_content 2 <<EOF
Perfil de configuración vacío
EOF

# Al ejecutar el comando
# $ configurar_cluster.sh error_sintaxis.conf
#
# En donde error_sintaxis.conf es un fichero con un error de sintaxis en la
# línea 6
#
# Debe retornar un código de error 1 y mostrar por la stderr
# "Perfil de configuración erróneo. Error de sintaxis en línea 6"
test_run ./configurar_cluster.sh error_sintaxis.conf
test_status 1
test_lines 1 -eq 0
test_lines 2 -eq 1
test_content 2 <<EOF
Perfil de configuración erróneo. Error de sintaxis en línea 6
EOF

# Al ejecutar el comando
# $ configurar_cluster.sh servicio_inexistente.conf
#
# En donde servicio_inexistente.conf es un fichero con un error en la línea 3
#
# Debe retornar un código de error 1 y mostrar por la stderr
# "Perfil de configuración erróneo. No existe el servicio solicitado en línea 3"
test_run ./configurar_cluster.sh servicio_inexistente.conf
test_status 1
test_lines 1 -eq 0
test_lines 2 -eq 1
test_content 2 <<EOF
Perfil de configuración erróneo. No existe el servicio solicitado en línea 3
EOF
