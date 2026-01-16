# frozen_string_literal: true

require 'escape'
require 'open3'
require 'colored'

# Implement the module
module Sh
  @active_pids = []

  Signal.trap('INT') do
    puts "\nShutdown signal received. Cleaning up..."
    @active_pids.each do |pid|
      Process.kill('TERM', pid)
    rescue StandardError
      nil
    end
    exit
  end

  def self.register_pid(pid)
    @active_pids << pid
  end

  # Catch-all exception
  class AppErr < StandardError; end

  # Custom exception when command is not found in $PATH
  class CommandNotFound < AppErr; end

  INFO_COLOR = 'green'
  ERROR_COLOR = 'red'

  class << self
    attr_accessor :verbose
  end

  # Represent the result of a command execution
  class CmdResult
    attr_reader :stdout, :stderr, :status, :stdin

    def initialize(status:, stdin: nil, stdout: nil, stderr: nil)
      @stdout = stdout
      @stderr = stderr
      @status = status
      @stdin = stdin
    end

    def to_s
      stdout
    end
  end

  # Represent a command
  class Cmd
    attr_accessor :stdin

    def initialize(cmd = '')
      validate(cmd)
      @cmd = cmd
      @args = []
      yield self if block_given?
    end

    def arg(*args)
      @args += args
      self
    end
    alias opt arg

    def to_s
      [@cmd].concat(@args).map(&:to_s).map { |word| escape(word) }.join(' ')
    end

    def print_header
      return unless Sh.verbose

      msg = "=> Executing #{self}"
      msg = msg.send(INFO_COLOR) if msg.respond_to?(INFO_COLOR)
      puts msg
    end

    def stream(fd, result)
      Thread.new do
        fd.each_line do |line|
          puts line
          result << line
        end
      rescue IOError
        # expected
      end
    end

    def exec
      print_header
      Open3.popen3(to_s) do |stdin, stdout, stderr, wait_thr|
        Sh.register_pid(wait_thr.pid)
        if @stdin
          stdin.puts @stdin.stdout
          stdin.close
        end
        stdout_lines = []
        stderr_lines = []
        out_thread = stream(stdout, stdout_lines)
        err_thread = stream(stderr, stderr_lines)
        status = wait_thr.value
        [out_thread, err_thread].each(&:join)
        unless status.exitstatus.zero?
          raise Sh.error_for_status(status.exitstatus), \
                "ERROR: Could not execute '#{self}':\n#{stderr_text}"
        end
        return CmdResult.new(
          stdout: stdout_lines.join,
          stderr: stderr_lines.join,
          status: status
        )
      end

      @stdout
    end

    # http://stackoverflow.com/questions/1306680/Shwords-Shescape-implementation-for-ruby-1-8
    def escape(str)
      Escape.shell_single_word(str).to_s
    end

    private

    def in_path?(cmd)
      (ENV['PATH'] || []).split(':').each do |path|
        full_path = File.join(path, cmd)
        return full_path if File.exist?(full_path)
      end
      nil
    end

    def composite_path?(cmd)
      ['.', '/'].any? { |chr| cmd.include?(chr) }
    end

    def validate(cmd)
      return if File.exist?(cmd)

      raise CommandNotFound, "No such command: '#{cmd}'" if \
        composite_path?(cmd) || !(full_path = in_path?(cmd))

      @full_path = full_path
    end
  end

  def self.method_missing(name, *args)
    make_cmd(name, *args).exec
  end

  def self.Cmd(name, *args)
    make_cmd(name, *args)
  end

  # Returns a dynamic exception class for a given return code
  def self.error_for_status(status)
    class_name = "ErrorReturnCode_#{status}"

    # If already defined, return it
    return const_get(class_name) if const_defined?(class_name)

    # Otherwise, define a new class inheriting from AppErr
    const_set(class_name, Class.new(AppErr))
  end

  def self.const_missing(name)
    if name.to_s =~ /^ErrorReturnCode_(\d+)$/
      # Define the class on the fly and return it
      const_set(name, Class.new(AppErr))
    else
      super # Fallback to normal behavior
    end
  end

  # Private methods

  def self.process_args(*args)
    processed_args = {
      args: [],
      properties: {}
    }
    args.each do |arg|
      processed_args[:args].push(arg) if arg.is_a?(String)
      next unless arg.is_a?(Hash)

      arg.each do |key, val|
        if key.to_s == '_in'
          processed_args[:properties][:stdin] = val
          next
        end
        processed_args.push("--#{key}=#{val}")
      end
    end
    processed_args
  end

  def self.make_cmd(name, *args)
    processed_args = process_args(*args)
    args = processed_args[:args]
    props = processed_args[:properties]
    Cmd.new(name.to_s) do |cmd|
      args.each(&cmd.method(:arg))
      cmd.stdin = props[:stdin] if props[:stdin]
    end
  end

  private_class_method :make_cmd, :process_args
end

def sh
  Sh
end
