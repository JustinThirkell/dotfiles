# dirs
VITAL_DIR=$PROJECTS/vital
alias katoa='cd $VITAL_DIR/katoa'
alias ddd='cd $VITAL_DIR/ddd'

# Katoa => Care API
alias apisst="yarn apps/care sst dev"
alias apitype="yarn nx run care:types"
alias apitest="yarn nx run care:test"
alias apiinttest="yarn nx run care:integration-tests"

# Katoa => Vital Console
alias csst="yarn apps/console sst dev"
alias ctype="yarn nx run console:types"
alias ctest="yarn nx run console:test"
alias cinttest="yarn nx run console:integration-tests"
alias capp="yarn apps/console start"
alias cfe="yarn apps/console vite dev --mode test"
alias ctestui="rm -rf apps/console/dist && yarn apps/console playwright test --config playwright.ui.config.ts"
alias ctestco="rm -rf apps/console/playwright/.cache && yarn apps/console playwright test --config playwright.component.config.ts"

# Katoa => Vital Health
alias hsst="yarn apps/health sst dev"
alias htype="yarn nx run health:types"
alias htest="yarn nx run health:test"
alias hinttest="yarn nx run health:integration-tests"
alias happ="yarn apps/health start"
alias hfe="yarn apps/health vite dev --mode test"
alias htestui="rm -rf apps/health/dist && yarn apps/health playwright test --config playwright.ui.config.ts"
alias htestco="rm -rf apps/health/playwright/.cache && yarn apps/health playwright test --config playwright.component.config.ts"

# Katoa => Vital Patient
alias psst="yarn apps/patient sst dev"
alias ptype="yarn nx run patient:types"
alias ptest="yarn nx run patient:test"
alias pinttest="yarn nx run patient:integration-tests"
alias papp="yarn apps/patient start"
alias pfe="yarn apps/patient vite dev --mode test"
alias pui="rm -rf apps/patient/dist && yarn apps/patient playwright test --config playwright.ui.config.ts"
alias pco="rm -rf apps/patient/playwright/.cache && yarn apps/patient playwright test --config playwright.component.config.ts"

alias determine-shard="npx tsx $PROJECTS/vital/katoa/apps/care/cli/determine-shard.ts"
alias get-visit="$PROJECTS/vital/katoa/apps/care/cli/get-visit.sh"
