rm -rf public/
#!/bin/sh
USER=root
HOST=172.247.32.128
PORT=13170
DIR=www/blog   # might sometimes be empty!

hugo && rsync -avuz --delete -e 'ssh -p 13170'  public/ ${USER}@${HOST}:/${DIR}

exit 0
