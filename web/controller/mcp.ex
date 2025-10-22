# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Mcp do
  use Antikythera.Controller

  def chunked_response(conn) do
    request_body = conn.request.body

    case request_body do
      %{"method" => "initialize"} ->
        handle_initialize(conn, request_body)

      %{"method" => "notifications/initialized"} ->
        handle_notification(conn)

      %{"method" => "tools/list"} ->
        handle_tools_list(conn, request_body)

      %{"method" => "tools/call"} ->
        handle_tools_call(conn, request_body)

      _ ->
        Conn.json(conn, 400, %{error: "Unknown method"})
    end
  end

  defp handle_initialize(conn, request) do
    id = request["id"]

    response = %{
      result: %{
        protocolVersion: "2025-03-26",
        capabilities: %{
          tools: %{
            listChanged: true
          }
        },
        serverInfo: %{
          name: "stateless-server",
          version: "1.0.0"
        }
      },
      jsonrpc: "2.0",
      id: id
    }

    send_sse_response(conn, response)
  end

  defp handle_notification(conn) do
    # Notifications don't require a response
    Conn.put_status(conn, 204)
  end

  defp handle_tools_list(conn, request) do
    id = request["id"]

    response = %{
      result: %{
        tools: [
          %{
            name: "testgear",
            description: "Send Data to TestGear API",
            inputSchema: %{
              type: "object",
              properties: %{
                data: %{
                  type: "string",
                  default: "hoge",
                  description: "data to send to the API"
                }
              },
              additionalProperties: false,
              "$schema": "http://json-schema.org/draft-07/schema#"
            }
          }
        ]
      },
      jsonrpc: "2.0",
      id: id
    }

    send_sse_response(conn, response)
  end

  defp handle_tools_call(conn, request) do
    id = request["id"]
    params = request["params"] || %{}
    arguments = params["arguments"] || %{}
    data = arguments["data"] || "hoge"

    response = %{
      result: %{
        content: [
          %{
            type: "text",
            text: "API Response (200): #{data} from TestGear!"
          }
        ]
      },
      jsonrpc: "2.0",
      id: id
    }

    send_sse_response(conn, response)
  end

  defp send_sse_response(conn, response) do
    json_data = Jason.encode!(response)
    sse_message = "event: message\ndata: #{json_data}\n\n"

    conn
    |> Conn.send_chunked(200, %{"content-type" => "text/event-stream"})
    |> Conn.chunk(sse_message)
  end

  def method_not_allowed(conn) do
    response = %{
      jsonrpc: "2.0",
      error: %{
        code: -32000,
        message: "Method not allowed."
      },
      id: nil
    }

    Conn.json(conn, 405, response)
  end
end
