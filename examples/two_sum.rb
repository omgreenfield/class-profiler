# frozen_string_literal: true

require_relative '../lib/class_profiler'

class TwoSumExample
  include ClassProfiler

  def initialize(nums, target)
    @nums = nums
    @target = target
  end

  def brute_force
    arr = @nums
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
    @nums.each_with_index do |num, idx|
      complement = @target - num
      j = seen[complement]
      return [j, idx] if j
      seen[num] = idx
    end
    nil
  end

  benchmark_instance_methods
  profile_instance_methods
end

if $PROGRAM_NAME == __FILE__
  srand(123)
  size = Integer(ENV.fetch('SIZE', '5000'), 10)
  nums = Array.new(size) { rand(1..10_000) }
  target = nums.sample + nums.sample

  example = TwoSumExample.new(nums, target)
  example.brute_force
  example.hashmap

  puts '=== Two Sum: brute_force (low memory, slower) vs hashmap (higher memory, faster) ==='
  puts "Input SIZE=#{size}"
  puts
  puts example.benchmark_report
  puts example.memory_report
end

