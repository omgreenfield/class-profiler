# frozen_string_literal: true

require_relative '../lib/class_profiler'

class TwoSumExample
  include ClassProfiler

  def initialize(numbers, target)
    @numbers = numbers
    @target = target
  end

  def brute_force
    arr = @numbers
    len = arr.length
    i = 0
    while i < len
      j = i + 1
      while j < len
        return [i, j] if arr[i] + arr[j] == @target

        j += 1
      end
      i += 1
    end
    nil
  end

  def hashmap
    seen = {}
    @numbers.each_with_index do |number, idx|
      complement = @target - number
      j = seen[complement]
      return [j, idx] if j

      seen[number] = idx
    end
    nil
  end

  track_performance
  track_memory
end

if $PROGRAM_NAME == __FILE__
  srand(123)
  size = Integer(ENV.fetch('SIZE', '5000'), 10)
  numbers = Array.new(size) { rand(1..10_000) }
  target = numbers.sample + numbers.sample

  example = TwoSumExample.new(numbers, target)
  example.brute_force
  example.hashmap

  puts '=== Two Sum: brute_force (low memory, slower) vs hashmap (higher memory, faster) ==='
  puts "Input SIZE=#{size}"
  example.profile_report
end
