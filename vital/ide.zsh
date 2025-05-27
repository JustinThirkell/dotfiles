# open cursor with the pwd.code-workspace file if it exists
function cursor_katoa() {
  workspace_file=$(find . -maxdepth 1 -name "*.code-workspace")
  if [ -n "$workspace_file" ]; then
    cursor "$workspace_file"
  else
    cursor .
  fi
}
