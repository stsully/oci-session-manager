#!/usr/bin/env bash
set -e

# <xbar.title>OCI Sesssion Manager</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Shea Sullivan</xbar.author>
# <xbar.author.github>stsully</xbar.author.github>
# <xbar.desc>Manages periodic OCI session authentication</xbar.desc>
#

error() {
  echo "⚠️"
  echo "error"
  return 1
}

refresh_session() {
  if ! out=$(oci session refresh ); then
    error
  fi
  echo "refreshed"
}

start_session() {
  if ! out=$(echo DEFAULT | oci session authenticate --region $REGION); then
    error
  fi
  echo "started"
}
check_session() {
  if  ! SESSION_STATUS=$(echo "n" | oci session validate 2>&1   |head -1 |cut -d" " -f1  ); then
    error
  fi

  case "${SESSION_STATUS}" in
  ERROR:) # Expired or not yet started
    echo "session expired"
    error
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
TIMESTAMP=$(date +"%Y-%m-%d:%H:%M:%S")
LOGFILE="/tmp/session_logs/session_log.txt"

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

## Get current session status.
#
#           Check Session

#          +---------------+
#          |     Active    |
#          +---------------+
#                  |
#                  |
#                  v
#          +---------------+
#          |      Expired  |
#          +---------------+
#                  |
#                  |
#                  v
#          +---------------+
#          |  Waiting      |
#          +---------------+