#!/bin/bash

# This is test blacklist, change please
tls_version_blacklist=(tls1 tls1_1)

# This is test blacklist, change please
cipher_suites_blacklist=(AES128-SHA256 AES256-SHA256 )


function is_tls_version_blacklist(){
    local version=$1
    for element in "${tls_version_blacklist[@]}"; do
        if [[ "$version" == "$element" ]];then
            return 0
        fi
    done
    return 1
}

function is_cipher_suites_blacklist(){
    local version=$1
    for element in "${cipher_suites_blacklist[@]}"; do
        if [[ "$version" == "$element" ]];then
            return 0
        fi
    done
    return 1
}
