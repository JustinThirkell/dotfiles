# Sets reasonable macOS defaults.
#
# Or, in other words, set stuff how I like in macOS.
#
# Run ./set-defaults.sh and you'll be good to go.
#
# See also https://macos-defaults.com/
# See also https://github.com/mobilutz/dotfiles/blob/main/macos/set-defaults.sh

###############################################################################
# Preamble
###############################################################################

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `set-defaults.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# Finder Settings                                                           #
###############################################################################

defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
defaults write com.apple.finder "ShowPathbar" -bool "true"
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool "true"

# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv
# Show the ~/Library folder.
chflags nohidden ~/Library

###############################################################################
# Window Settings                                                           #
###############################################################################
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
# Always show scrollbars
# Possible values: `WhenScrolling`, `Automatic` and `Always`
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
# Adjust toolbar title rollover delay
defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0
# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

###############################################################################
# Typing
###############################################################################

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Random other OS settings
defaults write com.apple.screencapture "location" -string "~/Pictures"
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"
defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool "false"
defaults write com.apple.TextEdit "RichText" -bool "false"
defaults write com.apple.ActivityMonitor "IconType" -int "6"
defaults write com.apple.dock "scroll-to-open" -bool "true"
defaults write com.apple.dock "mru-spaces" -bool "false"
defaults write com.apple.dock "expose-group-apps" -bool "true"

# Set up Spaces
defaults write com.apple.spaces "spans-displays" -bool "true"

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false
# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"
# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Run the screensaver if we're in the bottom-left hot corner.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# # Disable Resume system-wide
# defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false
# # Disable automatic termination of inactive apps
# defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
# # Disable Notification Center and remove the menu bar icon
# launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null


###############################################################################
# FireWall Settings                                                           #
###############################################################################

echo " Enable Firewall"
sudo /usr/libexec/ApplicationFirewall/socketfilterfw \
  --setblockall off \
  --setallowsigned on \
  --setallowsignedapp on \
  --setloggingmode on \
  --setstealthmode on \
  --setglobalstate on

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# # Trackpad: enable tap to click for this user and for the login screen
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# # Trackpad and Mouse Speed
# defaults write NSGlobalDomain com.apple.trackpad.scaling -float "2"
# defaults write NSGlobalDomain com.apple.mouse.scaling -float "3"

# # Trackpad: map bottom right corner to right-click
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# # Enable “natural” scrolling
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Disable press-and-hold for keys in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

# Set a really fast key repeat.
# The step values that correspond to the sliders on the GUI are as follow (lower equals faster):
# KeyRepeat: 120, 90, 60, 30, 12, 5, 2
# InitialKeyRepeat: 120, 94, 68, 35, 25, 15
defaults write NSGlobalDomain KeyRepeat -int 5
defaults write NSGlobalDomain InitialKeyRepeat -int 25

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Stop iTunes from responding to the keyboard media keys
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

###############################################################################
# Finally
###############################################################################

# Restart to pick up settings
killall Finder
killall Dock
killall SystemUIServer





# Run ./set-defaults.sh and you'll be good to go.





# Set computer name (as done via System Preferences → Sharing)
#sudo scutil --set ComputerName "0x6D746873"
#sudo scutil --set HostName "0x6D746873"
#sudo scutil --set LocalHostName "0x6D746873"
#sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "0x6D746873"

# Disable the sound effects on boot
# sudo nvram SystemAudioVolume=" "

# Set highlight color to green
# defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"



# Disable the over-the-top focus ring animation
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false


# Disable smooth scrolling
# (Uncomment if you’re on an older Mac that messes up the animation)
#defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false





# Display ASCII control characters using caret notation in standard text views
# Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true


# Fix for the ancient UTF-8 bug in QuickLook (https://mths.be/bbo)
# Commented out, as this is known to cause problems in various Adobe apps :(
# See https://github.com/mathiasbynens/dotfiles/issues/237
#echo "0x08000100:0" > ~/.CFUserTextEncoding


# Set a custom wallpaper image. `DefaultDesktop.jpg` is already a symlink, and
# all wallpapers are in `/Library/Desktop Pictures/`. The default is `Wave.jpg`.
#rm -rf ~/Library/Application Support/Dock/desktoppicture.db
#sudo rm -rf /System/Library/CoreServices/DefaultDesktop.jpg
#sudo ln -s /path/to/your/image /System/Library/CoreServices/DefaultDesktop.jpg















