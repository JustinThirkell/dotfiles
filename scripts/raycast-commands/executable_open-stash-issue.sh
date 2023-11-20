#!/bin/bash

# @raycast.author Justin Thirkell
# @raycast.packageName Stash
# @raycast.schemaVersion 1
# @raycast.title Open stash issue from clipboard
# @raycast.description Convert Stash issue url from the clipboard to Ecosystem Jira issue url and open the issue
# @raycast.mode compact

# stash -> jira links are broken
# given https://stash.atlassian.com/plugins/servlet/jira-integration/issues/REDFOX-823, correct link is: https://ecosystem-platform.atlassian.net/browse/REDFOX-823

url=$(pbpaste)
echo "Original URL: $url"

regex='https://stash.atlassian.com*[-A-Za-z0-9\+&@#/%=~_|]'
if ! [[ $url =~ $regex ]] ; then
  echo "Not a stash url"
  exit 1
fi

# define function to replace host and path using sed
function stash_to_ecojira() {
  input=$1

  # Use sed to replace the host and path using regex
  output=$(echo $input | sed -e 's/stash.atlassian.com/ecosystem-platform.atlassian.net/g;s/plugins\/servlet\/jira-integration\/issues/browse/g')

  # print the updated URL
  echo $output
}

ecojira=$(stash_to_ecojira $url)
echo "Opening $ecojira"

open $ecojira