deploy:
    hugo
    scp -r public/* homeserver:/home/cianh/blog/
