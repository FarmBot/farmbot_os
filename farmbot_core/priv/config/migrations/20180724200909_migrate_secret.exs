defmodule Farmbot.Config.Repo.Migrations.MigrateSecret do
  use Ecto.Migration
  import Ecto.Query

  def change do
    group =
      Farmbot.Config.Repo.one!(
        from(g in Farmbot.Config.Group, where: g.group_name == "authorization")
      )

    pass_ref =
      Farmbot.Config.Repo.one!(
        from(c in Farmbot.Config.Config, where: c.key == "password" and c.group_id == ^group.id)
      )

    sec_ref =
      Farmbot.Config.Repo.one!(
        from(c in Farmbot.Config.Config, where: c.key == "secret" and c.group_id == ^group.id)
      )

    pass =
      Farmbot.Config.Repo.one!(
        from(s in Farmbot.Config.StringValue, where: s.id == ^pass_ref.string_value_id)
      )

    sec =
      Farmbot.Config.Repo.one!(
        from(s in Farmbot.Config.StringValue, where: s.id == ^sec_ref.string_value_id)
      )

    if pass.value do
      Ecto.Changeset.change(sec, %{value: pass.value})
      |> Farmbot.Config.Repo.update!()

      Ecto.Changeset.change(pass, %{value: nil})
      |> Farmbot.Config.Repo.update!()
    end
  end
end
