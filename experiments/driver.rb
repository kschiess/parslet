require 'benchmark'

def run(lib, input_name)
  system "ruby #{lib}.rb #{input_name}"
end

def num(input)
  input.match(/\d+/)[0]
end

input_files = Dir['input/*chars.st'].sort_by { |file| num(file).to_i }
libs = ARGV.empty? ? %w(parslet treetop) : ARGV

Benchmark.bm do |bm|
  input_files.each do |input_name|
    libs.each do |lib|
      run_name = sprintf("%s-%06d", lib[0,4], num(input_name).to_i)
      bm.report(run_name) { run(lib, input_name) }
    end
  end
end

