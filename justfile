set shell := ["bash", "-uc"]

# Create initial project state
create-init-state folder:
    mkdir -p '{{folder}}'
    flutter create \
      --org com.datonomi \
      --project-name djambi \
      --description "An implementation of Djambi board game." \
      '{{folder}}'
