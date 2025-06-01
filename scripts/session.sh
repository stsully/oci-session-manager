#!/usr/bin/env bash
set -e

# <xbar.title>OCI Sesssion Manager</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Shea Sullivan</xbar.author>
# <xbar.author.github>stsully</xbar.author.github>
# <xbar.desc>Manages periodic OCI session authentication</xbar.desc>
#

error() {
  echo "⚠️ ${1}"
  return 1
}

refresh_session() {
  if ! out=$(oci session refresh ); then
    error "can't refresh session"
  fi
  echo "refreshed"
}

start_session() {
  if ! out=$(echo DEFAULT | oci session authenticate --region $REGION); then
    error "${out}"
  fi
  echo "started"
}
check_session() {
  if  ! SESSION_STATUS=$(echo "n" | oci session validate 2>&1   |head -1 |cut -d" " -f1  ); then
    error "can't validate session"
  fi

  case "${SESSION_STATUS}" in
  ERROR:) # Expired or not yet started
    error "session expired. Start New Session."
    return 1
    ;;
  Session) # Running
    refresh_session
    ;;
  *)
    error
    ;;
  esac
  return 0
}


## MAIN ##
REGION="us-ashburn-1"
PATH=$PATH:/opt/homebrew/bin/
# @TODO: multi-region support

if ! out=$(command -v oci ); then
  echo "OCI"
  echo "---"
  echo "oci cli not available."
  exit
fi

export PATH=$PATH:/opt/homebrew/bin/

echo "OCI"
echo "---"
echo "OCI Session Manager"
echo "---"

echo "Actions"
echo "--New Session | bash='$0' param1=start terminal=false";
echo "--Refresh Session | bash='$0' param1=refresh terminal=false";
echo "--End Session | bash='$0' param1=end terminal=false";
## Default state is waiting

case $1 in
start)
  start_session || exit 1
  ;;
refresh)
  refresh_session || exit 1
  ;;
end)
  rm ~/.oci/sessions/DEFAULT/token
  ;;
*)
  check_session || exit 0
esac
echo "🤠 Active"