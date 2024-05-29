# https://gitlab.gnome.org/GNOME/gtk/-/blob/main/docs/text_widget_internals.txt
# https://gnome.pages.gitlab.gnome.org/gtksourceview/gtksourceview5/

# next and previous: word, line, paragraph

# "psi" followed by two succesive apostrophes will be replaced by "ψ"

# white space (space, tab, new line) + space -> tab

# elastic tabstops: "http://nickgravgaard.com/elastic-tabstops/"
# https://docs.gtk.org/gtk4/property.TextTag.tabs.html

# indentation guides:
# change the background color of leading tabs; interchange between 2 colors

# store and restore undo history
# https://stackoverflow.com/questions/76096/undo-with-gtk-textview

# clipboard handling for text, image, and "text/uri-list"
# for the latter, ref'copy the files into the ".data" directory,
# 	ask for a name, and insert the path into the text buffer

# to insert a screenshot or screencast:
# move the file saved in "~/.cache/screen.png" or "~/.cache/screen.mp4" to ".data"
# ask for a name, and insert the path into the text buffer

# https://github.com/sonnyp/Workbench
# https://github.com/sriske2/umte/blob/master/umte.py
# https://github.com/Axel-Erfurt/TextEdit/blob/main/TextEdit.py
# https://gitlab.gnome.org/World/apostrophe
# https://github.com/jendrikseipp/rednotebook
# https://github.com/zim-desktop-wiki/zim-desktop-wiki
# https://github.com/TenderOwl/Norka/
# https://gitlab.gnome.org/GNOME/meld/-/tree/master/meld
# https://github.com/MightyCreak/diffuse

# https://www.gnu.org/software/diffutils/manual/html_mono/diff.html
# https://stackoverflow.com/questions/16902001/manually-merge-two-files-using-diff
# file tree diff
# https://stackoverflow.com/questions/776854/how-do-i-compare-two-source-trees-in-linux
# https://github.com/dandavison/delta
# https://github.com/so-fancy/diff-so-fancy
# https://diffoscope.org/
# https://github.com/MightyCreak/diffuse
# http://meldmerge.org/
# https://git-scm.com/docs/git-diff

# app URL
# an app is simply a source code directory, containing a file named "install.sh"
# to install an app, just add its URL (gnunet/git) to "~/.local/apps/url-list"
# there must be an empty line between URL lines
# after each URL line, there can be a public key, which will be used to check the signature of the downloaded files

class Editor(GtkSource.Editor):
