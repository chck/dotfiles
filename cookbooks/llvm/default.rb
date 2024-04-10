case node[:platform]
when 'darwin'
  execute 'brew install llvm@11' do
    not_if 'brew info llvm@11 -q'
  end
when 'ubuntu'
  execute 'sudo apt-add-repository -y "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-9 main" && sudo apt update -y && sudo apt install -y llvm-9' do
    not_if 'which llvm-config-9'
  end
else
  raise NotImplementedError
end
