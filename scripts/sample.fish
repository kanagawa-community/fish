# Back up the config, then report what changed
set -l src ~/.config/fish
set -l dest "$HOME/backup/$(date +%F)"

if test -d $src; and not test -e $dest
    mkdir -p $dest
    cp -r $src/* $dest/ 2>/dev/null
    echo "Copied "(count $src/*)" files to $dest"
else
    echo "Nothing to do" >&2
end

for file in $dest/*.fish
    string match --regex '^function \w+' < $file | head -n 3
end
