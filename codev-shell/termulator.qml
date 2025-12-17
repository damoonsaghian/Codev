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

/*
using "sudo" in CodevShell does not suffer from these flaws:
https://www.reddit.com/r/linuxquestions/comments/8mlil7/whats_the_point_of_the_sudo_password_prompt_if/
https://security.stackexchange.com/questions/119410/why-should-one-use-sudo
because:
, when a user enters "sudo" in command line, it will run /usr/bin/sudo
	this can't be manipulated by normal user
, reaching to terminal in CodevShell: app launcher -> space
	this can't be manipulated by normal user
, CodevShell only allows keyboard input from real keyboard, or from its built'in on'screen keyboard
, though CodevShell has access to input and video devices,
	that privilage will be dropped (using "sudo -u "$USER" ...") for all launched apps and commands
, there is no way for normal user to replace CodevShell
so a malicious program can't steal root password (eg by faking password entry)
*/
