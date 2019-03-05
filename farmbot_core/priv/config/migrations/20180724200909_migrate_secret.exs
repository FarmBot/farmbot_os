defmodule FarmbotCore.Config.Repo.Migrations.MigrateSecret do
  use Ecto.Migration
  import Ecto.Query

  def change do
    group =
      FarmbotCore.Config.Repo.one!(
        from(g in FarmbotCore.Config.Group, where: g.group_name == "authorization")
      )

    pass_ref =
      FarmbotCore.Config.Repo.one!(
        from(c in FarmbotCore.Config.Config,
          where: c.key == "password" and c.group_id == ^group.id
        )
      )

    sec_ref =
      FarmbotCore.Config.Repo.one!(
        from(c in FarmbotCore.Config.Config, where: c.key == "secret" and c.group_id == ^group.id)
      )

    pass =
      FarmbotCore.Config.Repo.one!(
        from(s in FarmbotCore.Config.StringValue, where: s.id == ^pass_ref.string_value_id)
      )

    sec =
      FarmbotCore.Config.Repo.one!(
        from(s in FarmbotCore.Config.StringValue, where: s.id == ^sec_ref.string_value_id)
      )

    if pass.value do
      Ecto.Changeset.change(sec, %{value: pass.value})
      |> FarmbotCore.Config.Repo.update!()

      Ecto.Changeset.change(pass, %{value: nil})
      |> FarmbotCore.Config.Repo.update!()
    end
  end
end
