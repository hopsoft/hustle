# Hustle

Experiment to run Ruby blocks in a separate process

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
