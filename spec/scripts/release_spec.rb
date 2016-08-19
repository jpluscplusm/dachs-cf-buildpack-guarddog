describe 'bin/release' do
  it 'exits successfully' do
    `bin/release`
    expect($?.success?).to be_truthy
  end

  it 'returns a command to loop indefinitely with caning the CPU' do
    expect(`bin/release`).to eq("---\ndefault_process_types:\n  web: ./haproxy -f haproxy.cfg\n")
  end
end