# Copyright 2022, Phillip Heller
#
# This file is part of CacheUtil.
#
# CacheUtil is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# CacheUtil is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with StageUtil. If not,
# see <https://www.gnu.org/licenses/>.

defmodule CacheUtil.CacheFile do
  import ExPrintf

  def run(source, action, %{} = args \\ %{}) do
    open(source, action, args)
  end

  defmodule Dir do
    def pre(source) do
      IO.puts(String.trim("""
      Source: #{source}

      Name          Seq Type # in Set Length Version Storage     Version Check
      ------------  --- ---- -------- ------ ------- ----------- -------------
      """))
    end

    def each(filename, sequence, type, length, setsize, candidacy, version, _data, _args) do
      candidacy_str = case candidacy do
        0 -> "Cache"
        1 -> "None"
        2 -> "Stage"
        3 -> "Stage"
        4 -> "Required"
        5 -> "Required"
        6 -> "Large Stage"
        7 -> "Large Stage"
      end

      version_check = if candidacy in [3, 5, 6], do: "No", else: "Yes"

      IO.puts(sprintf("%-12s  %3d %4x %8d %6d %7d %-11s %-3s", [filename, sequence, type, setsize, length, version, candidacy_str, version_check]))
    end

    def post do
    end
  end

  defmodule Export do
    def pre(_source) do
    end

    def each(filename, _sequence, _type, length, _setsize, _candidacy, _version, data, args) do
      case File.open(Path.join(args.target, filename), [:write]) do
        {:ok, out} ->
          IO.binwrite(out, binary_part(data, 0, length))
          File.close(out)

        {:error, :eilseq} ->
          IO.puts("ERROR: illegal filename '#{inspect(filename, base: :hex)}'")
      end

    end

    def post do
    end
  end

  defmodule Info do
    def pre(source) do
      IO.puts("""
      Source: #{source}

      """)
    end

    def each(_filename, _sequence, _type, _length, _setsize, _candidacy, _version, _data, _args) do
    end

    def post do
    end
  end

  def open(source, action, %{} = args \\ %{}) do
    action = case action do
      :dir -> Dir
      :export -> Export
      :info -> Info
      _ -> nil
    end

    {:ok, %File.Stat{size: size}} = File.stat(source)
    {:ok, cache} = File.open(source, [:binary, :read])

    blocks = div(size, 128)
    excess = rem(size, 128)

    action.pre(source)

    for block <- 0..blocks do
      buf = <<>>
      :file.position cache, block*128
      # read 11 bytes and see if it looks like an object id
      case IO.binread(cache, 15) do
        :eof -> :error
        {:error, reason} -> :error
        data ->
          << name::binary-size(8), ext::binary-size(3), seq, type, object_size::16-little >> = data
          if Regex.match?(~r/[A-Z0-9]{8}([A-Z]  |[A-Z]{2} |[A-Z]{3})/, name <> ext) do
            ext = String.trim(ext)
            ext = case String.length(ext) do
              1 -> sprintf("%s%02d",[ext,seq])
              2 -> sprintf("%s%01d",[ext,seq])
              3 -> ext
            end
            :file.position cache, block*128
            content = IO.binread(cache, object_size)
            try do
              # parse it once, recursively, but without any action; invalid objects will
              # raise an error.  Inefficient, but easy.
              ObjectUtil.Object.parse_object(content, nil, %{recurse: true})

              # process it a second time, this time with the action and optional recursion
              ObjectUtil.Object.parse_object(content, &action.each/9, args)
            rescue
              _ in MatchError -> :error
            catch
              {:invalid_segment, type} -> :error
            end
          end
      end
    end
  end
end
