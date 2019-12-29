# dotfiles
> Accio, My Utensils!

## Prerequisites

| Software                 | Install                     |
|--------------------------|-----------------------------|
| ruby ~> 2.7.0            | `rbenv install 2.7.0`       |
| itamae ~> 1.10.6         | `gem install itamae`        |

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
vi cookbooks/<NEW_APP>/default.rb  # add to install operation for <NEW_APP>
vi roles/$(uname)/default.rb  # add the command `include_cookbook <NEW_APP>`
```
