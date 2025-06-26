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
