require 'sprockets'
require 'tilt'
require 'pathname'
require 'shellwords'
require 'subprocess'

module Sprockets
  # Postprocessor that runs the computed source of Javascript files
  # through browserify, resulting in a self-contained files including all
  # referenced modules
  class Browserify < Tilt::Template
    def prepare
    end

    def evaluate(scope, locals, &block)
      if commonjs_module?(scope)
        begin
          deps = Subprocess.check_output(
            [browserify_executable.to_s, '-t', 'coffeeify', '--list', scope.pathname.to_s],
            :cwd => gem_dir
          )
          deps.lines.drop(1).each{|path| scope.depend_on path.strip}
        rescue Subprocess::NonZeroExit => e
          raise "Error finding dependencies for #{scope.pathname}"
        end

        begin
          @output ||= Subprocess.check_output(
            [browserify_executable.to_s, '-t', 'coffeeify', '-d', scope.pathname.to_s],
            :cwd => gem_dir
          )
        rescue Subprocess::NonZeroExist => e
          raise "Error compiling dependencies"
        end

        @output
      else
        data
      end
    end

  protected

    def gem_dir
      @gem_dir ||= Pathname.new(__FILE__).dirname + '../..'
    end

    def browserify_executable
      @browserify_executable ||= gem_dir + 'node_modules/browserify/bin/cmd.js'
    end

    def commonjs_module?(scope)
      File.extname(scope.logical_path) == '.module'
    end
  end
end
