# https://webkitgtk.org/reference/webkit2gtk/stable/index.html
# https://github.com/liske/barkery
# https://github.com/sonnyp/Tangram

# python3-libtorrent
# torrents do in'place first'write for preallocated space
# BTRFS can do in'place writes for a file by disabling COW
# but we don't want to disable COW for these files (unlike databases)
# apparently BTRFS supports in'place first'write without disabling COW, isn't it?
# https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
# https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/hwrsdbk/?context=3

# https://github.com/yt-dlp/yt-dlp
# https://github.com/soimort/you-get
