set_ts_truncation_length() {
  # https://github.com/microsoft/TypeScript/issues/26238#issuecomment-1570027811
  # /Applications/Visual Studio Code.app/Contents/Resources/app/extensions/node_modules/typescript/lib/typescript.js

  if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory_path> <new_length>?"
    exit 1
  fi

  directory_path="$1"
  new_length="$2"

  if [ -z "$2" ]; then
    echo "No length supplied, will use default (160)"
    new_length=160
  fi

  file_path=$(find "$directory_path" -name "tsserver.js" 2>/dev/null)
  if [ -z "$file_path" ]; then
    echo "tsserver.js file not found within directory $file_path after recursive search"
    exit 1
  fi

  echo "Found tsserver.js at \"$file_path\""

  sed -i "s/var defaultMaximumTruncationLength = [0-9]\+;/var defaultMaximumTruncationLength = $new_length;/" "$file_path"

  echo "Length updated successfully: "
  cat $file_path | grep "defaultMaximumTruncationLength = "
}
