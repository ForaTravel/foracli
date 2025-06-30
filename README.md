```
Alec recently adopted this tool and he encountered the following issues, 
so make sure you double check all of these:

1. Make sure your .zshrc or .bashrc has the db.sh on the PATH
2. Make sure your .zshrc or .bashrc has the scrip aliased(check below for example)
3. Make sure you name and set the values of the .env.local and .env.staging properly next to the current .env (examples in this folder)
4. Make sure that you set $ENVIRONMENT in .zshrc
5. Wait for fora migration to finish before running fora seed
6. Ensure you've add the s3 env vars or that will break local


```


add this to your .bashrc or .zshrc

```
export PATH="/users/luciencd/code/fora-advisorportal/scripts/db.sh:$PATH"
alias fora="sh /users/YOUR-USERNAME-HERE/YOUR-CODE-DIR-HERE/foracli/db.sh"
source ~/.zshrc
```

find yourself in the backend repo.
```
➜  fora-advisorportal git:(lighter_cli_pr) fora
```
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


