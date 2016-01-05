defmodule KVServer do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(KvServer.Worker, [arg1, arg2, arg3]),
			supervisor(Task.Supervisor, [[name: KVServer.TaskSupervisor]]),
			worker(Task, [KVServer, :accept, [4042]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KvServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

	def accept(port) do
		{:ok, socket} = :gen_tcp.listen(port,
																		[:binary, packet: :line, active: false,
																		 reuseaddr: true])
		IO.puts "Accepting connections on port #{port}"
		loop_acceptor(socket)
	end

	defp loop_acceptor(socket) do
		{:ok, client} = :gen_tcp.accept(socket)
		{:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
		:ok = :gen_tcp.controlling_process(client, pid)
		loop_acceptor(socket)
	end

	defp serve(socket) do
    

    msg =
			with {:ok, data} <- read_line(socket),
		    {:ok, command} <- KVServer.Command.parse(data),
		    do: KVServer.Command.run(command)
		
    write_line(socket, msg)
    serve(socket)
	end

	defp read_line(socket) do
		:gen_tcp.recv(socket, 0)
	end

	defp write_line(socket, msg) do
		:gen_tcp.send(socket, format_msg(msg))
	end


  defp format_msg({:ok, text}), do: text
  defp format_msg({:error, :unknown_command}), do: "UNKNOWN COMMAND\r\n"
  defp format_msg({:error, :not_found}), do: "NOT FOUND\r\n"
  defp format_msg({:error, _}), do: "ERROR\r\n"

end
