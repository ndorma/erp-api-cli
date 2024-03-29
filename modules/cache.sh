#!/usr/bin/env bash

get_cache_filename() {
    USER_ID=$(get_user_id_from_credentials_file)
    echo "$TMP_DIR/$CACHE_FILENAME_PREFIX.user-$USER_ID.$1"
}

get_cached_content() {
    CACHE_FILENAME=$(get_cache_filename "$1")

    if [ -f "$CACHE_FILENAME" ]; then
        cat "$CACHE_FILENAME"
    fi
}

set_cached_content() {
    KEY="$1"
    CONTENT="${*:2}"
    CACHE_FILENAME=$(get_cache_filename "$KEY")
    echo "$CONTENT" >"$CACHE_FILENAME"
}

remember_content() {
    KEY="$1"
    CALLABLE="${*:2}"

    CONTENT=$(get_cached_content "$KEY")
    if [ ! "$CONTENT" ]; then
        if CONTENT="$($CALLABLE)"; then
            set_cached_content "$KEY" "$CONTENT"
        else
            return $?
        fi
    fi

    echo "$CONTENT"
}

flush_cache() {
    find "$TMP_DIR/" -name "$CACHE_FILENAME_PREFIX.*" -print -delete 2>/dev/null
}

cache-flush() {
    flush_cache
}
