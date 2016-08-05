describe 'bin/compile' do
  it 'exits successfully' do
    expect(system("bin/compile")).to be_truthy
  end
end