```
Alec recently adopted this tool and he encountered the following issues, so make sure you double check all of these:

1. Make sure you change the db script path one aliases to in your .zshrc
2. Make sure you name and set the values of the .env.local properly(postgres_host)
3. Make sure that you set $ENVIRONMENT in .zshrc
4. Wait for fora migration to finish before running fora seed
5. Ensure people add the s3 env vars or that will break local


```


add this to your .bashrc or .zshrc

```
alias fora="sh /users/luciencd/code/foracli/db.sh"
source ~/.zshrc
```

find yourself in the backend repo.

Just start running commands

```
➜  fora-advisorportal git:(lighter_cli_pr) fora list
fora-advisorportal
running fora CLI command "list" on local - fora_web $ENVIRONMENT set to {LOCAL}
Environment files required: docker/(.env .env.local .env.staging)
All environment files exist.
Available commands:
reset
up
down
envset
rebuild
status
envpull
help
list
envvalidate
dbclear
dbswap
seed
lint
rundjango
runpytest
setup

```


