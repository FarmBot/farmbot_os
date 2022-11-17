return function(args)
  local position = get_position()
  move_absolute({
    x = args.x or position.x,
    y = args.y or position.y,
    z = args.z or position.z,
    safe_z = args.safe_z or false,
    speed = args.speed or 100
  })
end
