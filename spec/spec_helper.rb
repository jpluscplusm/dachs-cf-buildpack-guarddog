def expect_command_to_succeed(command)
  system(command)
  expect($?.success?).to be_truthy
end

def expect_command_to_fail_and_output(command, expected)
  output = `#{command}`
  expect($?.success?).to be_falsey
  expect(output).to include(expected)
end

def expect_command_to_succeed_and_output(command, expected)
  output = `#{command}`
  expect($?.success?).to be_truthy
  expect(output).to include(expected)
end