#!/usr/bin/env bash

plain_request() {
    URL_PATH="$1"
    EXTRA_PARAMS="${*:2}"
    if [ "$EAC_DEBUG_CURL" == 1 ]; then
        echo "curl --silent -k -X POST $ERP_API_URL/$URL_PATH -H 'accept: application/json' -H 'Content-Type: application/json' $EXTRA_PARAMS"
    else
        eval "curl --silent -k -X POST $ERP_API_URL/$URL_PATH -H 'accept: application/json' -H 'Content-Type: application/json' $EXTRA_PARAMS"
    fi
}

auth_request() {
    if ! check_credentials; then
        print_cli_error_message 19
        return 19
    fi

    USER_ID=$(get_user_id_from_credentials_file)
    HASH=$(get_hash_from_credentials_file)
    URL_PATH="$1"
    # EXTRA_PARAMS="${*:2}"

    # if there is input from stdin, read it from it, otherwise from arguments. put those in EXTRA_PARAMS:
    if [ -t 0 ]; then
        EXTRA_PARAMS="${*:2}"
    else
        EXTRA_PARAMS="-d '$(< /dev/stdin)' ${*:2}"
    fi

    REQUEST=$(plain_request "$URL_PATH" "-H 'usuario: $USER_ID' -H 'hash: $HASH' $EXTRA_PARAMS")
    check_response_error "$REQUEST"
    RETVAL=$?
    echo "$REQUEST"
    return $RETVAL
}

api_sessioncheck() {
    plain_request "user/sessioncheck" -d "'{\"user_token\": \"$1\", \"hash\": \"$2\"}'"
}

api_authcheck() {
    plain_request "user/authcheck" -d "'{\"username\": \"$1\", \"password\": \"$2\"}'"
}

api_echo() {
    auth_request "echo" -d "'{\"response\": \"$1\"}'"
}

api_repertorio() {
    auth_request "repertorio"
}

api_sitios() {
    auth_request "servicio/get/sitios" -d "'{\"full\": \"1\"}'"
}

api_salas() {
    ID_SITIO="$1"
    auth_request "servicio/get/salas/$ID_SITIO"
}

api_interpretes() {
    auth_request "servicio/get/interpretes"
}

api_ritos() {
    auth_request "servicio/get/ritos"
}

api_servicio-info() {
    local N_FAX="$1"
    auth_request "servicio/get/info/$N_FAX" -d "'{\"full\": \"1\"}'"
}

api_servicio-create() {
    options=$(getopt --name "api servicio-create" --options f:h:s:t:l:i:r:d:q: --longoptions fecha:,hora:,sitio:,sala:,lugar:,interpretes:,rito:,difunto:,repertorio: -- "$@")
    if [ $? != 0 ]; then
        echo "Failed to parse options...exiting." >&2
        return 1
    fi

    eval set -- "$options"

    while true; do
        case "$1" in
            --fecha | -f)
                FECHA="$2"
                shift 2
                ;;
            --hora | -h)
                HORA="$2"
                shift 2
                ;;
            --sitio | -s)
                ID_SITIO="$2"
                shift 2
                ;;
            --sala | -t)
                ID_SALA="$2"
                shift 2
                ;;
            --lugar | -l)
                LUGAR_CEREMONIA="$2"
                shift 2
                ;;
            --interpretes | -i)
                ID_INTERPRETES="$2"
                shift 2
                ;;
            --rito | -r)
                ID_RITO="$2"
                shift 2
                ;;
            --difunto | -d)
                DIFUNTO="$2"
                shift 2
                ;;
            --repertorio | -q)
                REPERTORIO="$2"
                shift 2
                ;;
            --)
                RESTO="${*:2}"
                shift
                break
                ;;
            *)
                echo "Internal error!"
                return 1
                ;;
        esac
    done

    auth_request "servicio/create" "-d '{
        \"fecha\": \"$FECHA\",
        \"hora\": \"$HORA\",
        \"id_interpretes\": \"$ID_INTERPRETES\",
        \"id_rito\": \"$ID_RITO\",
        \"id_sitio\": \"$ID_SITIO\",
        \"id_sala\": \"$ID_SALA\",
        \"lugar_ceremonia\": \"$LUGAR_CEREMONIA\",
        \"nombre_difunto\": \"$DIFUNTO\",
        \"repertorio\": [$REPERTORIO]
    }'"
}
