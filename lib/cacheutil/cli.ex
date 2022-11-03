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

defmodule CacheUtil.CLI do
  def usage(mode, message \\ "")

  def usage(:terse, message) do
    IO.puts("#{message}\n")

    exit(:shutdown)
  end

  def usage(:verbose, message) do
    IO.puts("#{message}\n")

    script = :escript.script_name()

    IO.puts("""
      CacheUtil - A utility for inspecting CACHE.DAT files for the Prodigy Reception System

      Usage:

        #{script} [-h | --help] [-r | --recurse] <command> { command arguments ... }

        -h, --help    This help
        -r, --recurse Apply recursively to embedded objects

        --glob <pattern>   - only apply to objects whose name matches the
                             glob pattern <pattern>.
                             Defaults to *

      Sources and Targets:

        <source> specifies an object source and can be:

          /path/to/cache.dat - a filesystem path to a CACHE.DAT file as used by
                               the reception system

        <target> specifies the target of an operation, and can be:

          /path/to/directory - a filesystem path to a writable directory

      Commands:

        info <source>
          Displays information about <source>

        dir <source>
          Displays a directory listing of objects found at <source>

        export <source> [-d | --dest <path>] [--glob <pattern>]
          Export objects from <source>

          -d, --dest <target> - writes the files to the specified target
                                duplicate files will be suffixed with an
                                incrementing non-zero integer.
                                Defaults to the current working directory.

        list-object-types
          Lists all object types
    """)

    exit(:shutdown)
  end

  def list_object_types() do
    IO.puts("""
    Object Types

    0x0 - Page Format Object
    0x4 - Page Template Object
    0x8 - Page Element Object
    0xC - Program Object
    0xE - Window Object
    """)

    exit(:shutdown)
  end

  def main(args) do
    {parsed, rest, _invalid} =
      OptionParser.parse(args,
        aliases: [
          d: :dest,
          h: :help,
          r: :recurse
        ],
        strict: [
          help: :boolean,
          dest: :string,
          glob: :string,
          recurse: :boolean
        ]
      )

    args = Enum.into(parsed, %{})

    if Map.get(args, :help, false), do: usage(:verbose)

    if length(rest) < 1, do: usage(:verbose)

    [command | rest] = rest
    command = String.downcase(command)

    case command do
      "list-object-types" -> list_object_types()
      _ -> nil
    end

    if length(rest) < 1, do: usage(:verbose)

    [source | _rest] = rest

    source =
      case File.exists?(source) do
        true ->
          case File.stat(source) do
            {:ok, %File.Stat{type: :regular}} ->
              Path.expand(source)

            {:error, errno} ->
              usage(:terse, "Error accessing source path '#{source}': #{errno}")

            _ ->
              usage(:terse, "Error accessing source path '#{source}', it is not a regular file")
          end

        _ ->
          usage(:terse, "Source path '#{source}' does not exist.")
      end

    target = Map.get(args, :dest, ".")

    target =
      case File.exists?(target) do
        true ->
          case File.stat(target) do
            {:ok, %File.Stat{type: :directory}} ->
              Path.expand(target)

            {:error, errno} ->
              usage(:terse, "Error accessing destination path '#{target}: #{errno}")

            _ ->
              usage(:terse, "Error accessing destination path '#{target}', it is not a directory")
          end

        _ ->
          usage(:terse, "Destination path '#{target}' does not exist.")
      end

    args = %{
      glob: Map.get(args, :glob, "*"),
      target: target,
      recurse: Map.get(args, :recurse, false)
    }

    command = case command do
      "info" -> :info
      "dir" -> :dir
      "export" -> :export
      _ -> usage(:verbose)
    end

    CacheUtil.CacheFile.run(source, command, args)
  end
end
