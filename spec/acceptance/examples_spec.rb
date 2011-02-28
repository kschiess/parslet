require 'spec_helper'
require 'open3'

describe "Regression examples from example/ directory" do

  Dir["example/*.rb"].each do |example|

    it "parses #{example} successfully" do
      stdin, stdout, stderr = Open3.popen3("ruby #{example}")

      expected_output_file = example.gsub('.rb', '.out').gsub('example/','example/output/')
      expected_error_file = example.gsub('.rb', '.err').gsub('example/','example/output/')

      if File.exists?(expected_output_file)

        stdout.readlines.join.strip.should include(File.read(expected_output_file).strip)

      elsif File.exists?(expected_error_file)
        stderr.readlines.join.strip.should include(File.read(expected_error_file).strip)
      else
        error = "Neither #{expected_output_file} nor #{expected_error_file} exists. Cannot compare results with any output or error."
        fail error
      end
      
    end

  end

end
