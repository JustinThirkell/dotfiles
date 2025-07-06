# https://app.gitbook.com/o/RC3jQcR2lEKirucc1K5J/s/diqdUiuDNfdDISnaesvl/aws/aws-vital-overview#aws-access-and-account-switching-on-vital-issued-laptops
# https://docs.commonfate.io/granted/usage/assuming-roles

function aws-sso() {
  granted sso login --sso-region us-west-2 --sso-start-url "https://${AWS_APPS_IDENTIFIER}.awsapps.com/start/#"
}

function aws-sso-refresh-roles() {
  granted sso populate --sso-region us-west-2 "https://${AWS_APPS_IDENTIFIER}.awsapps.com/start/#"
}

function aws-dev() {
  assume dev/SandboxAdmin --duration 8h
}

function aws-daily() {
  aws-sso
  aws-dev
}

function aws-creds-clear() {
  granted cache clear --storage=sso-token
  granted cache clear --storage=session-credentials
}
