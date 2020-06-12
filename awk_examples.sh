# Copy files in current directory which begins with letters (a-z, ignore case) to given path
# Might be dangerous
ls -a . | awk '/^[a-zA-Z]/ { print $1 " /your/path/here" }' | xargs -n 2 cp -Ra
