function aws-sso() {
  granted sso login --sso-region us-east-2 --sso-start-url "https://${AWS_APPS_IDENTIFIER}.awsapps.com/start/#"
}

function aws-sso-refresh-roles() {
  granted sso populate --sso-region us-east-2 "https://${AWS_APPS_IDENTIFIER}.awsapps.com/start/#"
}

function aws-local() {
  assume local/LeadEngineer --duration 8h
}

function aws-daily() {
  aws-sso
  aws-local
}

function aws-creds-clear() {
  granted cache clear --storage=sso-token
  granted cache clear --storage=session-credentials
}

function aws-check-session() {
  aws sts get-caller-identity
}
