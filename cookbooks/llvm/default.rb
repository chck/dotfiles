case node[:platform]
when 'darwin'
  execute 'brew install llvm@11' do
    not_if 'which llvm@11'
  end
when 'ubuntu'
  execute 'sudo apt install -y llvm-9' do
    not_if 'which llvm-config-9'
  end
else
  raise NotImplementedError
end
