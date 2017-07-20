defmodule Airbrake.Channel do
  @moduledoc false
  defmacro __using__(_env) do
    quote location: :keep do
      @before_compile Airbrake.Channel
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable [join: 3, handle_in: 3, handle_info: 2, terminate: 2]

      def join(channel_name, msg, socket) do
        try do
          super(channel_name, msg, socket)
        rescue
          exception ->
            send_to_airbrake(exception, socket_data(socket), message_data(msg), %{channel: channel_name})
        end
      end

      def handle_in(msg_type, msg, socket) do
        try do
          super(msg_type, msg, socket)
        rescue
          exception ->
            send_to_airbrake(exception, socket_data(socket), message_data(msg), %{msg_type: msg_type})
        end
      end

      def handle_info(msg, socket) do
        try do
          super(msg, socket)
        rescue
          exception ->
            send_to_airbrake(exception, socket_data(socket), message_data(msg))
        end
      end

      def terminate(reason, socket) do
        try do
          super(reason, socket)
        rescue
          exception ->
            send_to_airbrake(exception, socket_data(socket), %{reason: reason})
        end
      end

      defp socket_data(socket) do
        %{assigns: socket.assigns}
      end

      defp message_data(message) do
        %{message: message}
      end

      defp send_to_airbrake(exception, session, params, context \\ nil) do
        stacktrace = System.stacktrace

        Airbrake.Worker.remember(exception, [
          params: params,
          session: session,
          stacktrace: stacktrace,
          context: context
        ])

        reraise exception, stacktrace
      end
    end
  end
end
