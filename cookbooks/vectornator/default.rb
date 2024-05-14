case node[:platform]
when 'darwin'
  execute 'mas install 1219074514' do
    # Vectornator has been renamed to Linearity Curve
    not_if 'test -d /Applications/Linearity\ Curve.app/'
  end
else
  raise NotImplementedError
end

