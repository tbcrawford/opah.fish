Output assets/demo/demo.gif

Require fish

Set Shell "fish"
Set FontSize 14
Set Width 1000
Set Height 500
Set Padding 16

Set Theme "Catppuccin Mocha"

Hide
Type "source tapes/setup.fish"
Enter
Sleep 1s
Show
Ctrl+L

Sleep 500ms
Type "opah refresh"
Enter
Sleep 3s

Type "opah status"
Enter
Sleep 2s

Type "opah doctor"
Enter
Sleep 3s
