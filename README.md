# Hustle

Experiment to run Ruby blocks in a separate process

## Example

```ruby
while true
  r = Hustle.hustle { rand(9999) } # the block runs in a separate process
  puts r
  sleep 0.001
end
```
