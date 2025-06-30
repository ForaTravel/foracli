#!/bin/bash

#create a function that pulls in all local env vars from a specific place using some kind of auth.
# perhaps leverages github private repo
# fora loadenv

#cd to the fora backend repo
# this might be bad design, consider changing the scripts to point to the right place instead

SISTER_REPO_DIR="../fora-advisorportal"
cd "$SISTER_REPO_DIR"
# Configuration
DOCKER_COMPOSE="./docker/docker-compose.dev.yml"
CURRENT_DIR=$(basename "$PWD")
echo $CURRENT_DIR

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
pull_env_vars() {
    echo "${YELLOW}Pulling env vars from github...${NC}"
    echo "${YELLOW}This is not implemented yet.${NC}"
    echo f"${YELLOW}Please create docker/(.env .env.local .env.staging .env.dev) files.${NC}"
    exit 1
}


ensure_fora_setup() {
    local expected_dir="fora-advisorportal"
    if [ "$CURRENT_DIR" != "$expected_dir" ]; then
        echo "Error: You must run this script from the $expected_dir directory. (Current: $current_dir_name)"
        exit 1
    fi
}


# Function to ensure environment file exists
ensure_env_files() {
    local env=$1
    local env_file="./docker/.env.$env"
    
    echo "${YELLOW}Environment files required: docker/(.env .env.local .env.staging)${NC}"


    if [ -z "$ENVIRONMENT" ]; then
        echo "${RED}Error: \$ENVIRONMENT is not set, set to (LOCAL) to ensure local_setup.py works"
    fi

    if [ ! -f "./docker/.env" ]; then
        echo "${RED}Error: Local environment file ($env_file) does not exist.${NC}"
        echo "${YELLOW}Please create .env file.${NC}"
    fi

    if [ ! -f "./docker/.env.staging" ]; then
        echo "${RED}Error: Staging environment file ($env_file) does not exist.${NC}"
        echo "${YELLOW}For security reasons, staging environment files must be created manually.${NC}"
        echo "${YELLOW}Please create $env_file with the correct staging credentials. Ask Zach Smith for your staging db password.${NC}"
    fi   
    
    if [ ! -f "./docker/.env.local" ]; then
        echo "${RED}Error: Local environment file ($env_file) does not exist.${NC}"
        echo "${YELLOW}Please create .env.local file.${NC}"
    fi

    #if [ ! -f "./docker/.env.dev" ]; then
    #    echo "${RED}Error: Dev environment file ($env_file) does not exist.${NC}"
    #    echo "${YELLOW}Please create .env.dev file.${NC}"
    #fi
    # && [ -f "./docker/.env.dev" 
    if [ -f "./docker/.env" ] && [ -f "./docker/.env.local" ] && [ -f "./docker/.env.staging" ]; then
        echo "${GREEN}All environment files exist.${NC}"
    fi
}

# Function to check staging safety
check_staging_safety() {
    local command=$1
    local env=$2
    
    if [ "$env" = "staging" || "$env" = "dev"]; then
        case "$command" in
            "reset")
                echo "${RED}Error: $command command is not allowed for staging/dev environment${NC}"
                echo "${YELLOW}For security reasons, these commands are restricted to local environment only.${NC}"
                exit 1
                ;;
        esac
    fi
}

seed_db(){
    
    echo "setting up local user for login"
    if [ "$FORA_ENV" = "local" ]; then
        docker exec -it fora_web python manage.py local_setup
    else
        echo "${RED}cannot seed {$FORA_ENV} db"
    fi
}

run_linter(){
    docker exec -it fora_web ./lint.sh
}
run_django(){
    read -p "Enter Django command (or press Enter to run shell): " django_command
    if [ -n "$django_command" ]; then
        # If a command is provided, run that specific Django command
        docker exec -it fora_web python manage.py $django_command
    else
        # If no command provided, run Django shell
        docker exec -it fora_web python manage.py shell
    fi
}
run_pytest(){
    read -p "Enter test path (or press Enter to run all tests): " test_path
    if [ -n "$test_path" ]; then
        # If a path is provided, run tests for that specific path
        docker exec -it fora_web python -m pytest "$test_path" --reuse-db -v --no-header -s
    else
        # If no path provided, run all tests
        docker exec -it fora_web python -m pytest --reuse-db -v --no-header --no-summary -s
    fi
    #docker exec -it fora_web python -m pytest --reuse-db -v --no-header --no-summary -s
}

run_django_test(){
    read -p "Enter Django filepath (or press Enter to run shell): " filepath
    if [ -n "$filepath" ]; then
        # If a command is provided, run that specific Django command
        echo docker exec -it fora_web python manage.py test --keepdb --settings=test_settings "$filepath"
    else
        # If no command provided, run Django shell
        docker exec -it fora_web python manage.py test --keepdb --settings=test_settings
    fi
}
# Function to show usage
show_usage() {
    echo "Usage: $0 {command} [environment] "
    echo "       $0 {command}"
    echo
    echo "Commands:"
    echo "  setup (staging,local)               - Start all containers and the database (default)"
    echo "  seed (local)                        - seeds local db with some data"
    echo "  up                                  - loads specified environment"
    echo "  dbswap (staging,local)              - Swap database to specified environment (restarts all containers too)"
    echo ""
    echo "For all other commands, run fora list"
    echo ""
    echo "Environment (optional, defaults to 'local'):"
    echo "  local     - Use local database configuration"
    echo "  staging   - Use staging database configuration"
    echo "  dev       - Use dev database configuration (support upcoming)"
    echo
    echo "Examples:"
    echo "  $0 up local       - Start local database and containers"
    echo "  $0 down staging   - Stop staging database and containers"
    echo "  $0 reset local    - Reset local database volume"
    echo "  $0 up             - Start local database and containers (default environment)"
    echo "  $0 down           - Stop all containers (default environment)"
    echo "  $0 dbswap staging - Swap to staging database only"
    echo
    echo "To view logs:"
    echo "  DB_ENV=<env> docker-compose -f $DOCKER_COMPOSE logs -f postgres"
}
set_env() {
    touch ~/.fora_env
    local env=$1
    if check_env "$env"; then
        echo "exporting FORA_ENV"
        truncate -s 0 ~/.fora_env
        echo "export FORA_ENV=$env" > ~/.fora_env
       
    else
        echo "Error: Invalid environment '$env'. Must be one of: local, staging, dev."
        exit 1
    fi
}
# Function to check if environment is valid
check_env() {
    case "$1" in
        "local"|"staging"|"dev")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to show database status
show_status() {
    docker exec fora_postgres env | grep DB_ENV
}

# Function to reset database
clear_database() {
    local env=$1
    
    if [ "$env" != "local" ]; then
        echo -e "${RED}Error: Reset is only available for local database${NC}"
        exit 1
    fi

    echo "${YELLOW}WARNING: This will delete all data in your local database!${NC}"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "${YELLOW}Reset cancelled${NC}"
        exit 1
    fi

    echo "${RED}WARNING: THIS WILL DELETE ALL YOUR LOCAL DATA!!!!!!!${NC}"
    read -p "ARE YOU SURE YOU WANT THIS? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "${YELLOW}Reset cancelled${NC}"
        exit 1
    fi

    echo "${YELLOW}Stopping all containers...${NC}"
    docker-compose -f "$DOCKER_COMPOSE" down


    echo "${YELLOW}Removing postgres volume...${NC}"
    docker volume rm fora_postgres || true

    echo "${GREEN}Database has been cleared!${NC}"
    echo
    echo "${YELLOW}To view logs:${NC}"
    echo "DB_ENV=$env docker-compose -f $DOCKER_COMPOSE logs -f postgres"
}

open_logs_window() {
    local directory="$PWD"
    osascript -e "tell application \"Terminal\" to do script \"cd '$directory' && docker-compose -f ./docker/docker-compose.dev.yml logs -f\""
    echo "${GREEN}Containers started in detached mode.${NC}"
}
# Function to swap database
swap_database() {
    local env=$1
    
    echo "${YELLOW}Swapping database to $env environment... (volumes are preserved)${NC}"
    echo "${YELLOW}Stopping all containers...${NC}"
    docker-compose -f "$DOCKER_COMPOSE" down

    
    
    echo "${YELLOW}Removing postgres container...${NC}"
    DB_ENV=$env docker-compose -f "$DOCKER_COMPOSE" rm -f postgres
    
    echo "${GREEN}Starting fresh $env database...${NC}"
    echo "${GREEN}Starting fresh containers connected to $env db...${NC}"
    DB_ENV=$env docker-compose -f "$DOCKER_COMPOSE" up -d
    
    echo "${GREEN}Database has been swapped to $env environment!${NC}"
    echo
    echo "${YELLOW}To view logs:${NC}"
    echo "DB_ENV=$env docker-compose -f $DOCKER_COMPOSE logs -f postgres"
    
    open_logs_window
        
    echo "${GREEN}Containers started in detached mode.${NC}"
}

# Main script
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

# Check if first argument is one that doesn't require an environment to be set explicitly
if [[ "$1" =~ ^(up|down|restart|status|reset|rebuild|envvalidate|envpull|help|setup|pytest|djangotest|django|lint|seed|list)$ ]]; then
    COMMAND=$1
    if [ -n "$2" ]; then # $2 is set, env is set in args
        FORA_ENV=$2
        export FORA_ENV=$2
    fi
    # $FORA_ENV should have been set at the start at some point.
    if [ -z "$FORA_ENV" ]; then
        #pulling environment from the local history
        source ~/.fora_env
        if [ -z "$FORA_ENV" ]; then
            echo "${RED} Missing Environment - Not In Local "
            exit 1
        fi
    else
        set_env $FORA_ENV   
    fi



elif [[ "$1" =~ ^(dbswap|dbclear|envset)$ ]]; then
    COMMAND=$1
    #commands that are 
    #if env not set, it will have been preserved from last time
    
    if [ -n "$2" ]; then # $2 is set, env is set in args
        FORA_ENV=$2
        export FORA_ENV=$2
    fi

    if ! check_env "$FORA_ENV"; then
        echo "${RED} Invalid environment: $FORA_ENV${NC}"
        exit 1
    else
        #setting environment to the local history
        echo "${GREEN} Setting environment to file"
        set_env $FORA_ENV
    fi

    if [ -z "$FORA_ENV" ]; then
        #pulling environment from the local history
        source ~/.fora_env
        if [ -z "$FORA_ENV" ]; then
            echo "${RED} Missing Environment - Not In Local "
            exit 1
        fi
    fi
fi

echo "running fora CLI command \"$COMMAND\" on $FORA_ENV - fora_web \$ENVIRONMENT set to {$ENVIRONMENT}"
ensure_fora_setup
ensure_env_files

echo "${RED}Still in Alpha mode, use at own risk 🥴 ${NC}"

if [ -z "$COMMAND" ]; then
    echo "${RED}No command specified${NC}"
    show_usage
    exit 1
fi

case "$COMMAND" in
    "up")
        echo "${GREEN}Starting $FORA_ENV database and related containers...${NC}"
        # Start containers in detached mode
        
        DB_ENV=$FORA_ENV docker-compose -f "$DOCKER_COMPOSE" up -d
        #telling applescript to open an empty terminal to log the docker containers
        open_logs_window    
        ;;
    "down")
        echo "${YELLOW}Stopping all containers...${NC}"
        docker-compose -f "$DOCKER_COMPOSE" down
        ;;
    "envset")
        set_env "$FORA_ENV"
        ;;
    "rebuild")
        echo "${YELLOW}Stopping all containers...${NC}"
        docker-compose -f "$DOCKER_COMPOSE" down
        clear_database local

        docker-compose -f docker/docker-compose.dev.yml up -d --build
        open_logs_window

        ;;
    "status")
        show_status
        ;;
    "envpull")
        pull_env_vars // not defined yet
        ;;
    "help")
        show_usage
        ;;
    "list")
        echo "Available commands:"
        grep -E '^\s*"?[a-zA-Z0-9_-]+"?\)' "$0" | sed 's/)//;s/^[ \t]*//;s/"//g'
        ;;
    "envvalidate")
        ensure_env_files
        ;;
    "dbclear")
        clear_database "$FORA_ENV"
        ;;
    "dbswap")
        swap_database "$FORA_ENV"
        ;;
    "seed")
        seed_db "$FORA_ENV"
        ;;
    "lint")
        run_linter
        ;;
    "djangotest")
        run_django_test
        ;;
    "pytest")
        run_pytest
        ;;
    "django")
        run_django
        ;;
    "setup")
        echo "\n${GREEN}Setting up for the first time, setting env to local and double checking dir"
        #can we ensure that the db is fully migrated?
        ensure_fora_setup
        ensure_env_files
        set_env "local"
        seed_db "local"
        ;;
    *)
        echo "${RED}Invalid command: $COMMAND${NC}"
        show_usage
        exit 1
        ;;
esac 