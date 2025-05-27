# dirs
VITAL_DIR=$PROJECTS/vital
alias katoa='cd $VITAL_DIR/katoa'
alias ddd='cd $VITAL_DIR/ddd'

# Katoa => Vital Console
# alias cdev="yarn apps/console vite dev --mode test"
# alias cui="rm -rf apps/console/dist && yarn apps/console playwright test --config playwright.ui.config.ts"
# alias cco="rm -rf apps/console/playwright/.cache && yarn apps/console playwright test --config playwright.component.config.ts"

# Katoa => Vital Health
alias hdev="yarn apps/health vite dev --mode test"
alias hui="rm -rf apps/health/dist && yarn apps/health playwright test --config playwright.ui.config.ts"
alias hco="rm -rf apps/health/playwright/.cache && yarn apps/health playwright test --config playwright.component.config.ts"

# Katoa => Vital Patient
alias pdev="yarn apps/patient vite dev --mode test"
alias pui="rm -rf apps/patient/dist && yarn apps/patient playwright test --config playwright.ui.config.ts"
alias pco="rm -rf apps/patient/playwright/.cache && yarn apps/patient playwright test --config playwright.component.config.ts"
