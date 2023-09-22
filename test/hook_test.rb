# frozen_string_literal: true

require_relative "test_helper"

class HookTest < CaptainHookTest
  def test_get_file
    Dropbox.insert(path: "/2017-01-01-new-years/01-img.jpg", processed: true)
    Dropbox.insert(path: "/2017-01-01-new-years/02-img.jpg")
    hook = Hook.new
    file = hook.get_file

    assert_equal("/2017-01-01-new-years/02-img.jpg", file.path, "We picked up a processed file by mistake #{file.path}")
  end

  def test_pid_status_returns_exited_when_pid_file_does_not_exist
    hook = Hook.new

    pidfile = ""
    result = hook.pid_status(pidfile)

    assert_equal :exited, result
  end

  def test_pid_status_returns_dead_when_pid_file_is_empty
    hook = Hook.new

    Dir.mktmpdir do |dir|
      pidfile = "#{dir}/pidfile"
      FileUtils.touch(pidfile)
      result = hook.pid_status(pidfile)

      assert_equal :dead, result
    end
  end

  def test_pid_status_returns_dead_when_pid_file_exists_and_process_is_running
    hook = Hook.new

    Dir.mktmpdir do |dir|
      pidfile = "#{dir}/pidfile"
      File.open(pidfile, "w") { |f| f.puts 999999 }

      Process.stub :kill, true do
        result = hook.pid_status(pidfile)

        assert_equal :running, result
      end
    end
  end

  def test_pid_status_returns_dead_when_pid_file_exists_but_pid_not_found
    hook = Hook.new

    Dir.mktmpdir do |dir|
      pidfile = "#{dir}/pidfile"
      File.open(pidfile, "w") { |f| f.puts 999999 }

      Process.stub :kill, proc { raise Errno::ESRCH } do
        result = hook.pid_status(pidfile)

        assert_equal :dead, result
      end
    end
  end

  def test_pid_status_returns_dead_when_pid_file_exists_but_pid_not_owned
    hook = Hook.new

    Dir.mktmpdir do |dir|
      pidfile = "#{dir}/pidfile"
      File.open(pidfile, "w") { |f| f.puts 999999 }

      Process.stub :kill, proc { raise Errno::EPERM } do
        result = hook.pid_status(pidfile)

        assert_equal :not_owned, result
      end
    end
  end
end
