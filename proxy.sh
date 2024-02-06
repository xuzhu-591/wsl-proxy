#!/bin/bash

HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }')
WSL_IP=$(hostname -I | awk '{print $1}')

# get host and internal test host for system environment
PROXY_PORT=${PROXY_PORT:-7890}
PROXY_INTERNAL_HOST=${PROXY_INTERNAL_HOST}

PROXY_HTTP="http://${HOST_IP}:${PROXY_PORT}"
PROXY_SOCKS5="socks5://${HOST_IP}:${PROXY_PORT}"

open() {
  export http_proxy="${PROXY_HTTP}"
  export HTTP_PROXY="${PROXY_HTTP}"

  export https_proxy="${PROXY_HTTP}"
  export HTTPS_PROXY="${PROXY_HTTP}"

  export ALL_PROXY="${PROXY_SOCKS5}"
  export all_proxy="${PROXY_SOCKS5}"

  git config --global http.https://github.com.proxy ${PROXY_HTTP}
  git config --global https.https://github.com.proxy ${PROXY_HTTP}

  echo "Host IP:" ${HOST_IP}
  echo "WSL IP:" ${WSL_IP}
  echo "Proxy Port:" ${PROXY_PORT}
  echo "Proxy has been opened."
  test google
}

close() {
  unset http_proxy
  unset HTTP_PROXY
  unset https_proxy
  unset HTTPS_PROXY
  unset ALL_PROXY
  unset all_proxy
  git config --global --unset http.https://github.com.proxy
  git config --global --unset https.https://github.com.proxy

  echo "Proxy has been closed."
}

status() {
  echo "Host IP:" ${HOST_IP}
  echo "WSL IP:" ${WSL_IP}
  echo "Proxy Port:" ${PROXY_PORT}
  if [ -z "$http_proxy" ]; then
    echo "Proxy Status: closed"
  else
    echo "Proxy Status: opened"
    test google
  fi
}

test() {
  endpoint="$1"
  # now, only support github, google and internal network
  if [ "$endpoint" = "google" ] || [ "$endpoint" = "github" ] || [ "$endpoint" = "internal" ]; then
    # test internal network
    if [ "$endpoint" = "internal" ]; then
      if [ ! -z "$PROXY_INTERNAL_HOST" ]; then
        endpoint=${PROXY_INTERNAL_HOST}
        do_test ${PROXY_INTERNAL_HOST}
      else
        echo "PROXY_INTERNAL_HOST is not set."
      fi
    elif [ "$endpoint" = "google" ]; then
      do_test "https://www.google.com"
    else
      do_test "https://github.com"
    fi
  else
    echo "Unsupported endpoint."
  fi
}

do_test() {
  echo "Try to connect to $1..."
  resp=$(curl -I -s --connect-timeout 5 -m 5 -w "%{http_code}" -o /dev/null $1)
  if [ ${resp} = 200 ]; then
    echo "Connect succeeded!"
  else
    echo "Connect failed!"
  fi
}

if [ "$1" = "open" ]; then
  open
elif [ "$1" = "close" ]; then
  close
elif [ "$1" = "test" ]; then
  test $2
elif [ "$1" = "status" ]; then
  status
else
  echo "Unsupported arguments."
fi
