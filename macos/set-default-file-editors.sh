# Sets macOS file default editors.
#

EDITOR_BUNDLE="com.coteditor.CotEditor"  #"com.microsoft.VSCode" 

# Common text/code UTIs
# duti -s $EDITOR_BUNDLE public.plain-text all
# duti -s $EDITOR_BUNDLE public.source-code all
# duti -s $EDITOR_BUNDLE public.script all
# duti -s $EDITOR_BUNDLE public.data all
# duti -s $EDITOR_BUNDLE public.content all
# duti -s $EDITOR_BUNDLE public.text all

# Specific extensions if needed
duti -s $EDITOR_BUNDLE .json all
