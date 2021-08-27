defmodule Tile38 do
  @moduledoc """
  Elixir wrapper for [Tile38](https://tile38.com/). Formats responses to common queries for convenience.

  ## Getting started

  This package requires [Redix](https://github.com/whatyouhide/redix).

  ```
  # mix.exs
    defp deps do
      {:redix, ">= 0.0.0"}
    end
  ```

  Before calling any commands, you must initialize a named Redix connection, i.e.

  ```
  {:ok, _} = Redix.start_link("redis://localhost:9851/", name: :tile38)
  ```

  If you want to use a name other than `:tile38`, you can pass the name as an atom
  to any method as the second argument.
  """

  @default_redix_key :tile38

  @doc """
    Clear the entire Tile38 database.
  """
  def clear_database() do
    t38("flushdb")
  end

  @doc """
  Send a `get` command `withfields` to Tile38 and and return the response as JSON.

  ## Parameters

    - command: String of the exact command you wish to send to Tile38.
    - redix_key: (Optional) Atom with the name of the redix connection. Defaults to `:tile38`.

  ## Examples

      iex> Tile38.t38("set mycollection my_id field firstfield 10 field secondfield 20 point 10 -10 123")
      iex> Tile38.f38("get mycollection my_id withfields")
      %{
        fields: %{
          firstfield: "10",
          secondfield: "20"
        },
        coordinates: %{
          lat: 10,
          lng: -10,
          timestamp: 123,
          type: "Point"
        }
      }
  """
  def f38(command, redix_key \\ @default_redix_key) do
    resp = t38(command, redix_key)

    case resp do
      nil ->
        []

      [point, fields] ->
        %{type: type, coordinates: [lng, lat | timestamp]} = Jason.decode!(point, keys: :atoms)

        coordinates = %{type: type, lat: lat, lng: lng, timestamp: List.first(timestamp)}

        fields = list_to_map(fields, %{})

        %{
          coordinates: coordinates,
          fields: fields
        }

      [point] ->
        %{type: type, coordinates: [lng, lat | timestamp]} = Jason.decode!(point, keys: :atoms)

        coordinates = %{type: type, lat: lat, lng: lng, timestamp: List.first(timestamp)}

        %{
          coordinates: coordinates
        }
    end
  end

  @doc """
  Send a `jget` command to Tile38 and parse the response as JSON.

  ## Parameters

    - command: String of the exact command you wish to send to Tile38.
    - redix_key: (Optional) Atom with the name of the redix connection. Defaults to `:tile38`.

  ## Examples

      iex> Tile38.t38("jset user 901 name.first Tom")
      iex> Tile38.j38("jget user 901")
      %{name: %{first: "Tom"}}
  """
  def j38(command, redix_key \\ @default_redix_key) do
    resp = t38(command, redix_key)

    case resp do
      nil ->
        nil

      point ->
        Jason.decode!(point, keys: :atoms)
    end
  end

  @doc """
  Send a `nearby` or `scan` command to Tile38 and and return the response as JSON.

  ## Parameters

    - command: String of the exact command you wish to send to Tile38.
    - redix_key: (Optional) Atom with the name of the redix connection. Defaults to `:tile38`.

  ## Examples

      iex> Tile38.t38("set mycollection my_id field firstfield 10 point 10 -10 1000")
      iex> Tile38.n38("nearby mycollection point 10 -10")
      [
        %{
          id: "my_id",
          coordinates: %{
            lat: 10,
            lng: -10,
            timestamp: 1000,
            type: "Point",
          },
          fields: %{
            firstfield: "10"
          }
        }
      ]
  """
  def n38(command, redix_key \\ @default_redix_key) do
    resp = t38(command, redix_key)

    case resp do
      [_, []] ->
        []

      [_, data] ->
        parse_nearby(data, [])
    end
  end

  @doc """
  Send any command to Tile38 and return the response with no special formatting applied.

  ## Parameters

    - command: String of the exact command you wish to send to Tile38.
    - redix_key: (Optional) Atom with the name of the redix connection. Defaults to `:tile38`.

  ## Examples

      iex> Tile38.t38("set mycollection my_id field firstfield 10 point 10 -10 1000")
      iex> Tile38.t38("get mycollection my_id withfields")
      [~s/{"type":"Point","coordinates":[-10,10,1000]}/, ["firstfield", "10"] ]
  """
  def t38(command, redix_key \\ @default_redix_key) do
    # IO.inspect(command)
    {:ok, resp} = Redix.command(redix_key, ~w(#{command}))
    # IO.inspect(resp)
    resp
  end

  # Private methods

  defp list_to_map([], acc) do
    acc
  end

  defp list_to_map([key, value | tail], acc) do
    acc = Map.put(acc, String.to_atom(key), value)

    list_to_map(tail, acc)
  end

  defp parse_nearby([], acc) do
    acc
  end

  defp parse_nearby([[id, point | fields] | rest], acc) do
    point = Jason.decode!(point, keys: :atoms)

    fields =
      case is_list(fields) do
        true ->
          List.first(
            Enum.map(fields, fn field ->
              list_to_map(field, %{})
            end)
          )

        false ->
          %{}
      end

    %{coordinates: [lng, lat | timestamp], type: type} = point

    object = %{
      id: id,
      coordinates: %{
        lat: lat,
        lng: lng,
        timestamp: List.first(timestamp),
        type: type
      },
      fields: fields
    }

    acc = [object | acc]

    parse_nearby(rest, acc)
  end
end
