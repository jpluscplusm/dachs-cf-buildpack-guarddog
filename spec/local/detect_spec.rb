describe '/bin/detect/' do
  it 'always exists successfully' do
    expect(system('bin/detect')).to be_truthy
  end
end