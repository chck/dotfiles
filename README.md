# dotfiles
> Accio, My Utensils!

## Requirements
```sh
ruby ~> 2.3.7
```

## Installation
```sh
gem install itamae
```

## Usage
```sh
# clone
git clone --recursive https://github.com/chck/dotfiles.git

# dry-run
./install.sh -n

# apply
./install.sh

# add new cookbook
itamae g cookbook <NEW_APP>  # generate template
vi cookbooks/<NEW_APP>/default.rb  # add install operation
vi roles/$(uname)/default.rb  # add include_cookbook <NEW_APP>
```
