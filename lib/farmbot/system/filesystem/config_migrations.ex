defmodule Farmbot.System.FS.ConfigFileMigrations do
  @moduledoc """
    Migrates a state map to the current form.

    # Heres how they work
      * this module lists all the files in "#{:code.priv_dir(:farmbot)}/migrations"
      * it sorts them in order of dates.
      * those files are just elixir script files `*.exs`
      * said file must export ONE module, with one function function named `run\1`
      * it takes a json map, and must return that map, but updated
      * when the migration runs successfully, it writes a file under the same name, but with `.migrated` at the
         _end of the file name, so we know not to migrate this again.
      * does this for every file in the list, passing the last one to the next one.

    # example
      * we needed to change "steps_per_mm" from an integer, to a map: `%{x: int, y: int, z: int}`
      * so we took the version with an int, and changed it, and returned the new verion. Simple.
  """

  require Logger
  @save_dir Application.get_env(:farmbot, :path)

  @doc """
    Does the migrations
  """
  def migrate(json_map) do
    list_of_files = get_migrations()
    Enum.reduce(list_of_files, json_map, fn(file,json) ->
      migrated = "#{@save_dir}/#{file}.migrated"
      # if there is no <timestamp>-<description>_migration.exs.migrated file
      # run the migration

      # Check the file existance.
      if File.exists?(migrated) do
        # if we don't run a migration, just take the accumulator
        json
      else
        # Run the migration
        Logger.info ">> running config migration: #{file}"
        {{:module, m, _s, _}, _} = Code.eval_file file, migrations_dir()

        # TODO(Connor): Find out why m.run can return nil?
        next = m.run(json) || %{}

        Farmbot.System.FS.transaction fn() ->
          # write the contents of this migration, to the .migrated file.
          File.write(migrated, Poison.encode!(next))
          Logger.info ">> #{file} migration complete", type: :success
        end, true

        # merge the current acc, with the just run migration
        Map.merge(json, next)
      end
    end)
  end

  @doc """
    returns a list of file sorted by date
  """
  @spec get_migrations :: [String.t]
  def get_migrations do
    migrations_dir()
    |> File.ls!
    |> Enum.sort(fn(migration, last) ->
      [time_stampa, _desca] = String.split(migration, "-")
      int_time_stampa = String.to_integer(time_stampa)

      [time_stampb, _descb] = String.split(last, "-")
      int_time_stampb = String.to_integer(time_stampb)
      int_time_stampa <= int_time_stampb
    end)
  end

  defp migrations_dir, do: "#{:code.priv_dir(:farmbot)}/migrations"

end
