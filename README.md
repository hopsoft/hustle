# Hustle

[![Code Climate](https://codeclimate.com/github/hopsoft/hustle/badges/gpa.svg)](https://codeclimate.com/github/hopsoft/hustle)

#### NOTE: This is experimental. Use at your own risk.

## Overview

Ever wish MRI was better at CPU bound concurrency?

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
  # this will run when the Hustle.go block completes
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

### Arguments, Context, & Lexical Scope

__Important__:
Traditional lexical scoping of Ruby blocks does not work as you might expect.
This is because the block gets executed in a separate process.

Think of the `Hustle.go` block as a "true" lambda i.e. an anonymous function, not a closure.

Hustle allows you to pass a context object.
This feature allows you to make lexically scoped data available within the `Hustle.go` block.

```ruby
data = { message: "I'm from the parent process." }

print_data = -> (value) do
  puts data.inspect # => {:message=>"I'm from the parent process."}
  puts value.inspect # => {:message=>"I'm from the child process."}
end

Hustle.go context: data, callback: print_data do
  # this block is executed in a separate process
  # the "data" variable will NOT be available
  # the "context" variable is available
  # you can think of "context" as a copy of "data" in this case
  context[:message] = "I'm from the child process."
  context
end
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
