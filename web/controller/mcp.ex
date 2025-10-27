# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Mcp do
  use Antikythera.Controller

  alias Antikythera.{Request, G2gResponse}
  alias Testgear.McpServerHelper
  alias Testgear.McpServerHelper.Tool

  @testgear_tool Tool.new!(%{
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
    },
    outputSchema: %{
      type: "object",
      properties: %{
        status: %{type: "integer", description: "HTTP status code"},
        body: %{type: "string", description: "Response body"}
      }
    },
    callback: &__MODULE__.handle_testgear_tool/2
  })

  @json_tool Tool.new!(%{
    name: "get_json",
    description: "Get JSON response with request and context information from /json endpoint",
    inputSchema: %{
      type: "object",
      properties: %{},
      additionalProperties: false,
      "$schema": "http://json-schema.org/draft-07/schema#"
    },
    outputSchema: %{
      type: "object",
      properties: %{
        status: %{type: "integer", description: "HTTP status code"},
        body: %{
          type: "object",
          description: "JSON response containing request and context information"
        }
      }
    },
    callback: &__MODULE__.handle_json_tool/2
  })

  use McpServerHelper,
    server_name: "testgear-mcp-server",
    server_version: "1.0.0",
    tools: [@testgear_tool, @json_tool]

  def chunked_response(conn) do
    handle_mcp_request(conn)
  end

  def handle_testgear_tool(conn, arguments) do
    data = arguments["data"] || "hoge"

    path = Testgear.Router.content_decoding_path()
    path_info = path |> String.trim_leading("/") |> String.split("/", trim: true)

    conn2 = %Conn{
      conn |
      request: %Request{
        conn.request |
        method: :post,
        path_info: path_info,
        body: data
      }
    }
    %G2gResponse{status: status, body: response_body} = Testgear.G2g.send(conn2)

    McpServerHelper.response_text("API Response (#{status}): #{response_body} from G2G")
  end

  def handle_json_tool(conn, _arguments) do
    conn2 = %Conn{
      conn |
      request: %Request{
        conn.request |
        method: :get,
        path_info: ["json"]
      }
    }
    %G2gResponse{status: status, body: body} = Testgear.G2g.send(conn2)

    McpServerHelper.response_json(%{
      status: status,
      body: body
    })
  end
end
