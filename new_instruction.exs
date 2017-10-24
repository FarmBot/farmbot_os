Enum.each(struct(Farmbot.CeleryScript.VirtualMachine.InstructionSet) |> Map.from_struct(), fn({snake, camel}) ->
camel = Module.split(camel)
camel = Enum.join(camel, ".")
res = "#{:code.priv_dir(:farmbot)}/instruction.ex.eex" |> EEx.eval_file(camel_instruction: camel, snake_instruction: snake)
File.write!("lib/farmbot/celery_script/virtual_machine/instruction/#{snake}.ex", res)
end
)
