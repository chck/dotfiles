include_recipe 'recipe_helper'

node.reverse_merge!(
  user: ENV['SUDO_USER'] || ENV['USER'],
  profile: ENV['DOTFILES_PROFILE'],
)
include_role node[:platform]
include_profile node[:platform], node[:profile]
