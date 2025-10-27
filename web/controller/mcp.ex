# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Mcp do
  use Antikythera.Controller

  alias Antikythera.{Request, G2gResponse}
  alias Testgear.McpServerHelper
  alias Testgear.McpServerHelper.Tool

  # Tool Definitions
  # ================

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

  # MCP Server Configuration
  # ========================

  use McpServerHelper,
    server_name: "testgear-mcp-server",
    server_version: "1.0.0",
    tools: [@testgear_tool]

  # Controller Actions
  # ==================

  def chunked_response(conn) do
    handle_mcp_request(conn)
  end

  # Tool Handlers
  # =============

  def handle_testgear_tool(conn, arguments) do
    data = arguments["data"] || "hoge"

    # Get the path from the router helper and convert to path_info
    path = Testgear.Router.content_decoding_path()
    path_info = path |> String.trim_leading("/") |> String.split("/", trim: true)

    # Create a new connection to call the /content_decoding endpoint
    conn2 = %Conn{
      conn |
      request: %Request{
        conn.request |
        method: :post,
        path_info: path_info,
        body: data
      }
    }

    # Call the /content_decoding endpoint
    %G2gResponse{status: status, body: response_body} = Testgear.G2g.send(conn2)

    # Return response using the helper
    McpServerHelper.response_text("API Response (#{status}): #{response_body} from G2G")
  end

  # This function is now provided by McpServerHelper
  # def method_not_allowed(conn) do
  #   McpServerHelper.method_not_allowed(conn)
  # end
end
