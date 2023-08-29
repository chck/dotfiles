case node[:platform]
when 'darwin'
  execute 'mas install 1219074514' do
    # Vectornator has been renamed to Curve
    not_if 'test -d /Applications/Curve.app/'
  end
else
  raise NotImplementedError
end

