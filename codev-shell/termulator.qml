/*
terminal emulator
https://api.kde.org/mauikit/mauikit-terminal/html/index.html

term box has a maximum hight which is the reported height, but the visible height adjusts to text

prompt term:
show PWD above prompt term box
when /tmp/codevshell-term-env changes, update it
CODEVSHELL_PROMPT=true

when /tmp/codevshell-command changes, open a term box under the prompt
CODEVSHELL_COMMAND=$command
don't close on exit, if there are any text

when a term box is opened, focus
when its job is finished, focus prompt

scroll up: Page_Up
scroll down: Page_Down
copy: Control+c
paste: Control+v
next view: Control+Page_Down
previous view: Control+Page_Up
make "Escape" to act like ctrl+c (ie "\x03" character)

background=000000
foreground=FFFFFF
regular0=403E41
regular1=FF6188
regular2=A9DC76
regular3=FFD866
regular4=FC9867
regular5=AB9DF2
regular6=78DCE8
regular7=FCFCFA
bright0=727072
bright1=FF6188
bright2=A9DC76
bright3=FFD866
bright4=FC9867
bright5=AB9DF2
bright6=78DCE8
bright7=FCFCFA
selection-background=555555
selection-foreground=dddddd
*/
