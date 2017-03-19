# Set the working application directory
# working_directory "/path/to/your/app"
working_directory "/home/mike/pob/captain-hook"

# Unicorn PID file location
# pid "/path/to/pids/unicorn.pid"
pid "/home/mike/pob/captain-hook/pids/unicorn.pid"

# Path to logs
# stderr_path "/path/to/logs/unicorn.log"
# stdout_path "/path/to/logs/unicorn.log"
stderr_path "/home/mike/pob/captain-hook/logs/unicorn.log"
stdout_path "/home/mike/pob/captain-hook/logs/unicorn.log"

# Unicorn socket
# listen "/tmp/unicorn.[app name].sock"
listen "/tmp/unicorn.pob.sock"

# Number of processes
# worker_processes 4
worker_processes 2

# Time-out
timeout 30
