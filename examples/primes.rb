# frozen_string_literal: true

require_relative '../lib/class_profiler'

class PrimesExample
  include ClassProfiler

  def initialize(limit)
    @limit = limit
  end

  def trial_division
    limit = @limit
    primes = []
    (2..limit).each do |candidate|
      is_prime = true
      root = Math.sqrt(candidate).to_i
      primes.each do |p|
        break if p > root

        if (candidate % p).zero?
          is_prime = false
          break
        end
      end
      primes << candidate if is_prime
    end
    primes
  end

  def sieve_of_eratosthenes
    limit = @limit
    is_composite = Array.new(limit + 1, false)
    is_composite[0] = true
    is_composite[1] = true
    p = 2
    while p * p <= limit
      unless is_composite[p]
        step = p
        multiple = p * p
        while multiple <= limit
          is_composite[multiple] = true
          multiple += step
        end
      end
      p += 1
    end
    result = []
    i = 2
    while i <= limit
      result << i unless is_composite[i]
      i += 1
    end
    result
  end

  track_performance
  track_memory
end

if $PROGRAM_NAME == __FILE__
  limit = Integer(ENV.fetch('N', '20000'), 10)
  example = PrimesExample.new(limit)
  example.trial_division
  example.sieve_of_eratosthenes

  puts '=== Primes: trial_division (low memory, slower) vs sieve_of_eratosthenes (higher memory, faster) ==='
  puts "Input N=#{limit}"
  puts
  example.profile_report
end
