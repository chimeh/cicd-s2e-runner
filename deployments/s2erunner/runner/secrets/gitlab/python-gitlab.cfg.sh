

# check config valid, not valid will regenerate
set +e
gitlab current-user get > /dev/null 2>&1
RV=$?
set -e

if [[ ${RV} -ne 0 ]];then
  if [[ -d ${RUNNER_HOME} ]];then
# gitlab cli config file not exist
cat > ${RUNNER_HOME}/.python-gitlab.cfg <<EOF
[global]
default = default
ssl_verify = true
timeout = 5

[default]
url = ${CI_SERVER_URL}
private_token = ${CI_PRIVATE_TOKEN}
api_version = 4
EOF
perl -ni -e "s#url.+#url = ${CI_SERVER_URL}#g;print" ${RUNNER_HOME}/.python-gitlab.cfg
perl -ni -e "s#private_token.+#private_token = ${CI_PRIVATE_TOKEN}#g;print" ${RUNNER_HOME}/.python-gitlab.cfg
  fi
fi
