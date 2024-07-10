#!/bin/bash
echo
echo -e "\t\033[34mTuringSign SSL\033[0m"

echo
# Check if domain is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 domain"
    exit 1
fi

DOMAIN=$1
PORT=443

SECONDS=0

source ./ts_tls_blacklist.sh

# define global value
tls_versions=(ssl3 tls1 tls1_1 tls1_2 tls1_3)

supported_tls_version=()

cipher_suites=($(openssl ciphers 'ALL:eNULL' | tr ':' ' '))


function print_array() {
    local array=("$@")
    for element in "${array[@]}"; do
        echo -e "\t+ $element"
    done
    echo
}

# check TLS version
function check_supported_tls_version() {
    supported_tls_version=()
    echo -e "Checking supported TLS versions for domain: \033[34m${DOMAIN}\033[0m"

    for version in  ${tls_versions[@]}; do
        # echo -n "Testing $version... "
        result=$(echo | timeout 5s openssl s_client -connect ${DOMAIN}:${PORT} -${version} 2>&1)
        if [ -z "$result" ]; then
            return 0
        fi

        if [[ $result == *"no protocols"* ]]; then
            continue
        elif [[ "$result" == *"Cipher is (NONE)"* ]]; then
            continue
        fi

        if [[ $result == *"CONNECTED"* ]]; then
            supported_tls_version+=("$version")
        fi
    done
    return 1
}

# check support cipher suite
function check_cipersuite(){
    local version=$1
    local cipher_opt=cipher

    echo -e "Checking supported \033[34m${version}\033[0m cipher suites..." # Checking cipher ${#cipher_suites[@]}"

    if is_tls_version_blacklist $version; then 
        echo -e "\t\033[31m- This is a vulnerable version. Stop please.\033[0m"
        echo
        return
    fi

    if [[ "$version" == "tls1_3" ]];then
        cipher_opt=ciphersuites
    fi
    
    
    for cipher in ${cipher_suites[@]} ; do
        result=$(echo -n | openssl s_client -connect $DOMAIN:$PORT -$cipher_opt $cipher -$version 2>&1)
        if [[ "$result" =~ "Cipher is $cipher" ]]; then
            if is_cipher_suites_blacklist $cipher; then 
                echo -e "\t\033[31m- $cipher - Weak algorithm\033[0m"
            else
                echo -e "\t+ $cipher - OK"
            fi
        fi
    done
    echo
}

function print_all_cipher_suite(){
    echo "ALL Chiper Suite :"
    print_array ${cipher_suites[@]}
}


function print_supported_cipher_suite() {
    for element in "${supported_tls_version[@]}"; do
        check_cipersuite $element
    done
    echo
}

# Check CAA 
function check_caa() {
    domain=$1

    echo -e "Checking CAA records for domain: \033[34m${domain}\033[0m"
    caa_records=$(host -t CAA $domain)

    if [[ $caa_records == *"has no CAA record"* ]]; then
        echo -e "\t- No CAA records found for $domain"
    elif [[ $caa_records == *"not found"* ]]; then
        echo -e "\t- Domain not found : $domain"
    else
        echo -e "\t+ CAA records for $domain:"
        echo -e "\t+ $caa_records"
    fi
    echo
}

if check_supported_tls_version  ; then
    echo "Timeout... Please check the network."
else
echo "Supported TLS Version:"
print_array ${supported_tls_version[@]}

print_supported_cipher_suite

check_caa $DOMAIN
fi
#print_all_cipher_suite

echo "Runtime: $SECONDS seconds"
echo

