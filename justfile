deploy:
    #!/usr/bin/env sh
    if [ "$(git branch --show-current)" = "main" ]; then
        hugo
        scp -r public/* homeserver:/home/cianh/blog/
    else
        echo "Must be on the branch \"main\" to deploy"
    fi
