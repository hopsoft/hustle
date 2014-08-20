# Hustle

[![Code Climate](https://codeclimate.com/github/hopsoft/hustle/badges/gpa.svg)](https://codeclimate.com/github/hopsoft/hustle)

#### NOTE: This is experimental. Use at your own risk.

## Overview

Ever wish Ruby was better at CPU bound concurrency?

Hustle makes it easy by allowing you offload CPU intense blocks to separate processes.

## Examples

### Fire & Forget

```ruby
Hustle.go do
  # this block is executed in a separate process
  sleep 5 # heavy lifing...
end

# this will run immediately
foo = :bar
```

### Wait for All Blocks to Finish

```ruby
8.times do
  Hustle.go do
    # each invocation of this block is executed in a separate process
    sleep 5 # heavy lifing...
  end
end

Hustle.wait
```

### Callbacks

```ruby
print_value = -> (value) do
  # this will run when the Hustle block completes
  puts "<#{Process.pid}> #{value}" # => <99693> Hello from: <99728>
end

Hustle.go(callback: print_value) do
  # this block is executed in a separate process
  sleep 5 # heavy lifing...
  "Hello from: <#{Process.pid}>" # this is the return value
end

# this will run immediately
foo = :bar
```

### Error Handling

```ruby
callback = -> (value) do
  value.is_a? StandardError # => true
  value.message # => Error in block!
end

Hustle.go(callback: callback) do
  # this block is executed in a separate process
  raise "Error in block!"
end
```
